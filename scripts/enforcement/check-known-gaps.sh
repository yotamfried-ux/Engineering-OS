#!/usr/bin/env bash
set -euo pipefail
EOS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" python3 - "$@" <<'PY'
import os, re, sys
from pathlib import Path
root = Path(os.environ.get('ENGINEERING_OS_HOME') or os.environ.get('EOS_ROOT') or Path.cwd())
file_path = Path(sys.argv[1]) if len(sys.argv) > 1 else root / 'docs/operations/known-gaps.tsv'
audit_path = Path(sys.argv[2]) if len(sys.argv) > 2 else root / 'docs/operations/operational-readiness-audit.md'
min_rows = int(os.environ.get('EOS_KNOWN_GAPS_MIN_ROWS', '5'))
skip_audit = os.environ.get('EOS_SKIP_AUDIT_FRESHNESS') == '1'
failures = []

def err(msg):
    failures.append(msg)

def resolve(value):
    if value in {'NONE', 'none', 'n/a', 'N/A'}:
        return None
    p = Path(value)
    return p if p.is_absolute() else root / value

if not file_path.exists():
    print(f'known gaps failed: missing {file_path}', file=sys.stderr)
    sys.exit(1)

rows = []
seen = set()
for raw in file_path.read_text(encoding='utf-8').splitlines():
    if not raw or raw.startswith('#'):
        continue
    parts = raw.split('\t')
    if len(parts) != 10:
        gap = parts[0] if parts else '<empty>'
        err(f'{gap}: expected 10 columns, found {len(parts)}')
        continue
    gap, owner, status, priority, risk, mitigation, test, closure, evidence, notes = parts
    values = {
        'gap': gap, 'owner': owner, 'status': status, 'priority': priority,
        'risk': risk, 'mitigation': mitigation, 'test': test,
        'closure': closure, 'evidence': evidence, 'notes': notes,
    }
    for key, value in values.items():
        if not value:
            err(f'{gap}: missing {key}')
    if re.search(r'\s', gap):
        err(f'{gap}: gap_id must not contain whitespace')
    if gap in seen:
        err(f'{gap}: duplicate gap_id')
    seen.add(gap)
    if status not in {'open', 'mitigated', 'closed', 'accepted-manual', 'blocked'}:
        err(f'{gap}: invalid status {status}')
    if priority not in {'P0', 'P1', 'P2', 'P3'}:
        err(f'{gap}: invalid priority {priority}')
    if len(risk) < 20:
        err(f'{gap}: risk too short')
    if len(mitigation) < 20:
        err(f'{gap}: mitigation too short')
    if len(closure) < 20:
        err(f'{gap}: closure too short')
    test_path = resolve(test)
    if test_path is not None and not test_path.is_file():
        err(f'{gap}: test file not found: {test}')
    evidence_path = resolve(evidence)
    if evidence_path is not None and not evidence_path.exists():
        err(f'{gap}: evidence path not found: {evidence}')
    if status == 'closed' and not re.search(r'merged|verified|closed|done|complete', closure, re.I):
        err(f'{gap}: closed gap needs closure proof')
    rows.append((gap, status, priority))

if len(rows) < min_rows:
    err(f'expected at least {min_rows} rows, found {len(rows)}')

if not skip_audit:
    if not audit_path.exists():
        err(f'missing audit file: {audit_path}')
    else:
        text = audit_path.read_text(encoding='utf-8')
        match = re.search(r'^## Known gaps freshness ledger[ \t]*$(.*?)(?=^##[ \t]+|\Z)', text, re.M | re.S)
        if not match:
            err('audit missing ## Known gaps freshness ledger')
        else:
            ledger = {}
            for line in match.group(1).splitlines():
                if not line.startswith('|') or line.startswith('|---') or ' gap_id ' in line:
                    continue
                cols = [col.strip() for col in line.strip('|').split('|')]
                if len(cols) < 3:
                    continue
                gap, status, priority = cols[:3]
                if gap in ledger:
                    err(f'audit duplicate ledger row: {gap}')
                ledger[gap] = (status, priority)
            expected = {gap: (status, priority) for gap, status, priority in rows}
            missing = sorted(set(expected) - set(ledger))
            extra = sorted(set(ledger) - set(expected))
            for gap in missing:
                err(f'audit freshness ledger missing gap: {gap}')
            for gap in extra:
                err(f'audit freshness ledger has unknown gap: {gap}')
            for gap in sorted(set(expected) & set(ledger)):
                if expected[gap] != ledger[gap]:
                    err(f'audit freshness mismatch for {gap}: known-gaps={expected[gap][0]}/{expected[gap][1]} audit={ledger[gap][0]}/{ledger[gap][1]}')

if failures:
    for failure in failures:
        print(f'known gaps failed: {failure}', file=sys.stderr)
    sys.exit(1)
print(f'known gaps checks passed ({len(rows)} gaps)')
PY
