#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
AUDIT="$ROOT/docs/operations/operational-readiness-audit.md"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

python3 - "$AUDIT" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding='utf-8')
inside = False
rows = []
for line in text.splitlines():
    if line == '## Current status matrix':
        inside = True
        continue
    if inside and line.startswith('## '):
        break
    if not inside:
        continue
    if not line.startswith('|') or line.startswith('|---') or ' Area ' in line:
        continue
    parts = [part.strip() for part in line.strip('|').split('|')]
    if len(parts) == 4:
        rows.append(parts)

failures = []
if len(rows) < 25:
    failures.append(f'expected at least 25 rows, found {len(rows)}')
for area, status, enforced, gap in rows:
    lower = enforced.lower()
    for marker in ['gate:', 'owner:', 'evidence:']:
        if marker not in lower:
            failures.append(f'{area} missing {marker}')
    if not gap.strip():
        failures.append(f'{area} missing remaining gap text')

if failures:
    print('coverage map metadata validation failed')
    for failure in failures:
        print(f'- {failure}')
    raise SystemExit(1)
print(f'coverage map metadata validated: {len(rows)} rows')
PY

# Negative simulation: removing a marker must fail.
python3 - "$AUDIT" "$TMP/bad.md" <<'PY'
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding='utf-8')
Path(sys.argv[2]).write_text(text.replace('Gate:', 'Gate-', 1), encoding='utf-8')
PY

if python3 - "$TMP/bad.md" <<'PY'
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding='utf-8')
inside = False
for line in text.splitlines():
    if line == '## Current status matrix':
        inside = True
        continue
    if inside and line.startswith('## '):
        break
    if inside and line.startswith('|') and not line.startswith('|---') and ' Area ' not in line:
        parts = [part.strip() for part in line.strip('|').split('|')]
        if len(parts) == 4 and 'gate:' not in parts[2].lower():
            raise SystemExit(1)
raise SystemExit(0)
PY
then
  echo "expected missing gate marker simulation to fail"
  exit 1
fi

echo "readiness coverage map tests passed"
