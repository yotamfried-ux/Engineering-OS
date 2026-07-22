#!/usr/bin/env bash
# check-readiness-audit.sh — deterministic operational-readiness audit gate.
#
# Normal mode validates that an honestly incomplete audit is complete, classified,
# self-contained, and synchronized with docs/operations/known-gaps.tsv.
#
# --assert-full-ready is intentionally stricter: it fails while any registered gap
# is not closed or any matrix row is Missing enforcement / Partially enforced.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AUDIT=""
GAPS=""
ASSERT_FULL_READY=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --assert-full-ready)
      ASSERT_FULL_READY=1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "unknown argument: $1" >&2
      exit 2
      ;;
    *)
      if [ -z "$AUDIT" ]; then
        AUDIT="$1"
      elif [ -z "$GAPS" ]; then
        GAPS="$1"
      else
        echo "unexpected positional argument: $1" >&2
        exit 2
      fi
      shift
      ;;
  esac
done

AUDIT="${AUDIT:-$ROOT/docs/operations/operational-readiness-audit.md}"
GAPS="${GAPS:-$ROOT/docs/operations/known-gaps.tsv}"

python3 - "$AUDIT" "$GAPS" "$ROOT" "$ASSERT_FULL_READY" <<'PY'
import os
import re
import sys
from pathlib import Path

audit_path = Path(sys.argv[1])
gaps_path = Path(sys.argv[2])
root = Path(sys.argv[3])
assert_full_ready = sys.argv[4] == "1"
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


def field_value(section, field):
    match = re.search(
        rf'^\s*[-*]\s*(?:\*\*)?{re.escape(field)}\s*:(?:\*\*)?\s*(.+)$',
        section,
        re.I | re.M,
    )
    return match.group(1).strip() if match else ''


required_headings = [
    'Audit metadata',
    'Purpose and audience',
    'System and repository context',
    'Non-negotiable decisions',
    'How an LLM must use this audit',
    'Source-of-truth hierarchy',
    'Evidence and closure standard',
    'Glossary',
    'Readiness statuses',
    'Coverage contract',
    'Readiness-claim contract',
    'Known gaps freshness ledger',
    'Current status matrix',
    'Dependency-ordered closure plan',
    'Definition of full operational readiness',
    'Mandatory end-to-end closure checklists',
    'Highest-priority gaps by ROI',
    'Experiment start decision',
    'Future Project 8 workload acceptance contract',
    'Current audit scope',
]
for heading in required_headings:
    require(re.search(rf'^## {re.escape(heading)}$', text, re.MULTILINE), f'missing heading: {heading}')

metadata = section_between('## Audit metadata')
for field in [
    'Audit owner',
    'Canonical repository',
    'Target repository',
    'Canonical gap registry',
    'Last verified',
    'Intended readers',
]:
    value = field_value(metadata, field)
    require(len(value) >= 3, f'audit metadata missing concrete {field}: value')

purpose = section_between('## Purpose and audience')
require('without prior chat context' in purpose.lower(), 'Purpose and audience must state that prior chat context is not required')

llm_use = section_between('## How an LLM must use this audit').lower()
for term in ['verify live state', 'do not guess', 'gap', 'checklist', 'pull request', 'tests', 'owner approval']:
    require(term in llm_use, f'LLM usage procedure missing required concept: {term}')

source_hierarchy = section_between('## Source-of-truth hierarchy').lower()
for term in ['live github', 'repository code', 'known-gaps.tsv', 'operational-readiness-audit.md', 'runbooks', 'plans', 'chat']:
    require(term in source_hierarchy, f'source-of-truth hierarchy missing: {term}')

evidence_standard = section_between('## Evidence and closure standard').lower()
for term in ['exact repository', 'commit sha', 'positive', 'negative', 'installed target', 'review', 'post-merge', 'secret']:
    require(term in evidence_standard, f'evidence and closure standard missing: {term}')

glossary = section_between('## Glossary').lower()
for term in [
    'engineering os',
    'project 8',
    'behavioral experiment',
    'technical qualification session',
    'operational work history',
    'telemetry bundle',
    'exact-head',
    'hard hook',
    'full operational readiness',
]:
    require(term in glossary, f'glossary missing required term: {term}')

experiment_decision = section_between('## Experiment start decision').lower()
for term in ['every registered gap', 'closed', '--assert-full-ready', 'technical qualification', 'behavioral experiment', 'owner approval']:
    require(term in experiment_decision, f'experiment start decision missing required rule: {term}')

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
        'audit self-contained contract',
        'documentation runtime state',
        'route plan',
        'dod completion',
        'progress validation',
        'connector selection',
        'connector correctness',
        'template selection',
        'pattern usage',
        'pattern evidence maturity',
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

if assert_full_ready:
    not_closed = sorted(gap_id for gap_id, status in known_gaps.items() if status != 'closed')
    require(not not_closed, f'full readiness blocked by non-closed gaps: {not_closed}')
    blocking_rows = sorted(
        area for area, status, _, _ in rows
        if status in {'Missing enforcement', 'Partially enforced'}
    )
    require(not blocking_rows, f'full readiness blocked by matrix rows: {blocking_rows}')

if failures:
    label = 'full operational readiness assertion failed' if assert_full_ready else 'operational readiness audit coverage failed'
    print(f'❌ {label}')
    for failure in failures:
        print(f' - {failure}')
    raise SystemExit(1)

if assert_full_ready:
    print('✅ full operational readiness assertion passed')
else:
    print('✅ operational readiness audit coverage is complete and self-contained')
print(f'   readiness rows: {len(rows)}')
PY
