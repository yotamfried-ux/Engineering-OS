#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT/docs/operations/documentation-ownership.tsv"
ALLOW_WAIVER=0

while [ $# -gt 0 ]; do
  case "$1" in
    --root) shift; ROOT="${1:-}" ;;
    --manifest) shift; MANIFEST="${1:-}" ;;
    --allow-waiver) ALLOW_WAIVER=1 ;;
    -h|--help) echo "Usage: check-documentation-hygiene.sh [--root PATH] [--manifest PATH] [--allow-waiver]"; exit 0 ;;
    *) echo "ERROR_FOR_AGENT: unknown argument '$1'" >&2; exit 2 ;;
  esac
  shift
done

[ -d "$ROOT" ] || { echo "ERROR_FOR_AGENT: root not found: $ROOT" >&2; exit 2; }
[ -f "$MANIFEST" ] || { echo "ERROR_FOR_AGENT: ownership manifest missing: $MANIFEST" >&2; exit 1; }

python3 - "$ROOT" "$MANIFEST" "$ALLOW_WAIVER" <<'PY'
import fnmatch
import re
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
manifest = Path(sys.argv[2]).resolve()
allow_waiver = sys.argv[3] == '1'
required = {
    'entrypoint','workflow-order','task-routing','documentation-hygiene',
    'capability-vocabulary','connector-policy','skill-policy','hooks-policy',
    'quality-gates','git-policy','learning-loop','docs-index',
    'operational-readiness-audit',
}
allowed = {'active','temporary','deprecated','waived'}
failures = []

def fail(message): failures.append(message)

def exists(pattern):
    if any(ch in pattern for ch in '*?['):
        return any(fnmatch.fnmatch(p.relative_to(root).as_posix(), pattern) for p in root.rglob('*') if p.is_file())
    return (root / pattern).exists()

seen = set()
rows = []
for line_no, raw in enumerate(manifest.read_text(encoding='utf-8').splitlines(), 1):
    if not raw.strip() or raw.startswith('#'):
        continue
    parts = [part.strip() for part in raw.split('\t')]
    if len(parts) != 5:
        fail(f'line {line_no}: expected 5 fields')
        continue
    scope, owner, pattern, status, notes = parts
    rows.append(parts)
    if not all(parts): fail(f'line {line_no}: empty field')
    if scope in seen: fail(f'duplicate ownership scope: {scope}')
    seen.add(scope)
    if re.search(r'\s', scope): fail(f'line {line_no}: scope has whitespace')
    if status not in allowed: fail(f'{scope}: invalid status {status}')
    if status == 'deprecated' and 'replacement:' not in notes.lower(): fail(f'{scope}: deprecated status requires replacement')
    if status == 'waived' and len(notes) < 30: fail(f'{scope}: waiver notes too short')
    if status in {'active','temporary'} and not exists(pattern): fail(f'{scope}: missing path {pattern}')

for scope in sorted(required - seen): fail(f'missing required ownership scope: {scope}')
if any(row[3] == 'waived' for row in rows) and not allow_waiver: fail('waived rows require --allow-waiver')

for md in root.rglob('*.md'):
    rel = md.relative_to(root).as_posix()
    for idx, line in enumerate(md.read_text(encoding='utf-8', errors='ignore').splitlines(), 1):
        value = line.strip().lower()
        if value.startswith('status: deprecated') and 'replacement:' not in value:
            fail(f'{rel}:{idx}: deprecated status requires replacement')

if failures:
    print('ERROR_FOR_AGENT: documentation hygiene failed', file=sys.stderr)
    for failure in failures: print(f'- {failure}', file=sys.stderr)
    raise SystemExit(1)
print(f'documentation hygiene checks passed ({len(rows)} ownership rows)')
PY
