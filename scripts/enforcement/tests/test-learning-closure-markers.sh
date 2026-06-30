#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
GATE="$ROOT/scripts/enforcement/enforce-learning-capture.sh"
FIXTURE="$ROOT/scripts/enforcement/tests/test-learning-capture.sh"

python3 - "$GATE" "$FIXTURE" <<'PY'
import sys
from pathlib import Path

gate = Path(sys.argv[1]).read_text(encoding='utf-8')
fixture = Path(sys.argv[2]).read_text(encoding='utf-8')

required_gate_markers = [
    'Prevention[[:space:]/-]+Enforcement[[:space:]]+Update',
    'Prevention[[:space:]/-]+Enforcement[[:space:]]+Waiver',
    'Prevention/Enforcement Update or Waiver',
]
missing = [m for m in required_gate_markers if m not in gate]
if missing:
    print('missing learning closure markers in gate:')
    for item in missing:
        print('-', item)
    raise SystemExit(1)

if 'Prevention/Enforcement Update' not in fixture:
    raise SystemExit('valid lesson fixture must include prevention/enforcement closure')

mutated = gate.replace("'Prevention[[:space:]/-]+Enforcement[[:space:]]+Update'", "'Disabled[[:space:]]+Marker'", 1)
mutated = mutated.replace("'Prevention[[:space:]/-]+Enforcement[[:space:]]+Waiver'", "'Disabled[[:space:]]+Waiver'", 1)
if 'Prevention[[:space:]/-]+Enforcement[[:space:]]+Update' in mutated:
    raise SystemExit('mutation failed')

print('learning closure markers validated')
PY
