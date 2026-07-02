#!/usr/bin/env bash
# check-readiness-audit.sh — deterministic operational-readiness audit classification gate.
#
# Extracted from .github/workflows/enforcement-tests.yml so it is fixture-testable,
# then strengthened: the audit can no longer hold an unclassified partial row.
#
# Rules (all previous workflow checks are preserved, none weakened):
#   - required headings and readiness status definitions must exist;
#   - matrix rows must use an allowed status; plain "Manual" is vocabulary-only and
#     invalid inside the matrix (use "Manual by design" with a checklist);
#   - every "Partially enforced" / "Missing enforcement" row must carry a
#     gap:<gap_id> link to a non-closed row in docs/operations/known-gaps.tsv;
#   - every "Manual by design" row must name an existing Checklist: doc;
#   - matrix rows without a gap link must not contain deferred language
#     (todo, tbd, pending, not yet, future loop);
#   - every non-closed gap in known-gaps.tsv, including accepted-manual, must be
#     referenced by at least one matrix row, so open gaps cannot hide outside the audit;
#   - required coverage rows and ROI priority terms must remain present.
#
# Fixture knobs (tests only; CI uses defaults):
#   EOS_READINESS_MIN_ROWS      minimum matrix rows (default 25)
#   EOS_READINESS_REQUIRE_TERMS set to 0 to skip required/priority term checks
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AUDIT="${1:-$ROOT/docs/operations/operational-readiness-audit.md}"
GAPS="${2:-$ROOT/docs/operations/known-gaps.tsv}"

python3 - "$AUDIT" "$GAPS" "$ROOT" <<'PY'
import os
import re
import sys
from pathlib import Path

audit_path = Path(sys.argv[1])
gaps_path = Path(sys.argv[2])
root = Path(sys.argv[3])
min_rows = int(os.environ.get('EOS_READINESS_MIN_ROWS', '25'))
require_terms = os.environ.get('EOS_READINESS_REQUIRE_TERMS', '1') != '0'
failures = []

def require(condition, message):
    if not condition:
        failures.append(message)

if not audit_path.exists():
    print(f'operational readiness audit failed: missing audit file {audit_path}', file=sys.stderr)
    sys.exit(1)
if not gaps_path.exists():
    print(f'operational readiness audit failed: missing known-gaps file {gaps_path}', file=sys.stderr)
    sys.exit(1)

text = audit_path.read_text(encoding='utf-8')

def normalize(value):
    return re.sub(r'\s+', ' ', value).strip().lower()

def section_between(start_heading):
    captured = []
    in_section = False
    for line in text.splitlines():
        if line == start_heading:
            in_section = True
            continue
        if in_section and line.startswith('## '):
            break
        if in_section:
            captured.append(line)
    return '\n'.join(captured)

for heading in [
    'Readiness statuses',
    'Coverage contract',
    'Current status matrix',
    'Definition of full operational readiness',
    'Highest-priority gaps by ROI',
]:
    require(re.search(rf'^## {re.escape(heading)}$', text, re.MULTILINE), f'missing heading: {heading}')

defined_statuses = {
    'Enforced',
    'Partially enforced',
    'Manual',
    'Manual by design',
    'Waiver-gated',
    'Missing enforcement',
    'Not applicable',
}
for status in defined_statuses:
    require(f'**{status}**' in text, f'missing readiness status definition: {status}')

# Plain "Manual" stays in the vocabulary above but is not a terminal matrix state:
# a manual row must be "Manual by design" with a checklist, or become a gap.
matrix_statuses = {
    'Enforced',
    'Partially enforced',
    'Manual by design',
    'Waiver-gated',
    'Missing enforcement',
    'Not applicable',
}
gap_required_statuses = {'Partially enforced', 'Missing enforcement'}

matrix = section_between('## Current status matrix')
rows = []
for line in matrix.splitlines():
    if not line.startswith('|') or line.startswith('|---') or ' Area ' in line:
        continue
    parts = [part.strip() for part in line.strip('|').split('|')]
    if len(parts) == 4:
        rows.append(parts)

require(len(rows) >= min_rows, f'expected at least {min_rows} readiness rows, found {len(rows)}')
invalid = [(area, status) for area, status, _, _ in rows if status not in matrix_statuses]
require(not invalid, f'invalid matrix status values (plain Manual is not a terminal matrix state): {invalid}')

known_gaps = {}
for raw in gaps_path.read_text(encoding='utf-8').splitlines():
    if not raw or raw.startswith('#'):
        continue
    parts = raw.split('\t')
    if len(parts) >= 4:
        known_gaps[parts[0].strip()] = parts[2].strip()

non_closed_statuses = {'open', 'mitigated', 'blocked', 'accepted-manual'}
deferred_re = re.compile(r'\b(todo|tbd|not yet|future loop|pending)\b', re.I)
referenced = set()

for area, status, enforcement, gap_cell in rows:
    row_text = f'{area} {status} {enforcement} {gap_cell}'
    gap_ids = re.findall(r'gap:([a-z0-9][a-z0-9-]*)', row_text)
    referenced.update(gap_ids)
    for gap_id in gap_ids:
        if gap_id not in known_gaps:
            require(False, f'{area}: references unknown gap id gap:{gap_id}')
        elif status in gap_required_statuses and known_gaps[gap_id] not in non_closed_statuses:
            require(False, f'{area}: {status} row links gap:{gap_id} whose status is '
                           f'{known_gaps[gap_id]}; a partial row needs a non-closed gap')
    if status in gap_required_statuses and not gap_ids:
        require(False, f'{area}: status {status} requires an explicit gap:<gap_id> link '
                       f'to docs/operations/known-gaps.tsv in the remaining-gap cell')
    if status == 'Manual by design':
        checklist = re.search(r'Checklist:\s*`?([A-Za-z0-9_./-]+)`?', enforcement)
        if not checklist:
            require(False, f'{area}: Manual by design rows must name Checklist: <path> '
                           f'in the enforcement cell')
        elif not (root / checklist.group(1)).is_file():
            require(False, f'{area}: checklist doc not found: {checklist.group(1)}')
    if not gap_ids and deferred_re.search(row_text):
        require(False, f'{area}: matrix row uses deferred language '
                       f'({deferred_re.search(row_text).group(1)}) without a gap:<gap_id> link')

hidden = sorted(gap_id for gap_id, status in known_gaps.items()
                if status in non_closed_statuses and gap_id not in referenced)
require(not hidden, f'non-closed known gaps are not referenced by any matrix row: {hidden}')

row_areas = {normalize(area) for area, _, _, _ in rows}

if require_terms:
    required_terms = [
        'claude entrypoint',
        'canonical ownership',
        'enforcement coverage inventory',
        'route plan',
        'dod completion',
        'progress validation',
        'connector selection',
        'connector correctness',
        'template selection',
        'pattern usage',
        'skill selection',
        'skill runtime evidence',
        'rtk context optimization',
        'graphify context graph',
        'claude memory',
        'capability registry',
        'learning schema',
        'learning reuse',
        'learning closure',
        'claude run trace',
        'positive/negative simulations',
        'tests/lint',
        'cleanup debug leftovers',
        'cleanup semantic hygiene',
        'project install contract',
        'git/branch policy',
        'pr review',
        'merge safety',
        'post-merge validation',
        'known gaps register',
    ]
    for term in required_terms:
        require(any(term in area for area in row_areas), f'audit missing required coverage row: {term}')

    priority_section = section_between('## Highest-priority gaps by ROI').lower()
    priority_terms = [
        'coverage map hardening',
        'rtk runtime hardening',
        'route plan quality gate',
        'learning closure gate',
        'progress lifecycle',
        'connector correctness',
        'simulation completeness',
        'post-merge validation',
        'documentation hygiene',
        'semantic cleanup',
    ]
    for term in priority_terms:
        require(term in priority_section, f'audit missing priority gap: {term}')

if failures:
    print('❌ operational readiness audit coverage failed')
    for failure in failures:
        print(f' - {failure}')
    raise SystemExit(1)

print('✅ operational readiness audit coverage is complete')
print(f'   readiness rows: {len(rows)}')
PY
