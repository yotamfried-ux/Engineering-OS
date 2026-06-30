#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCRIPT="$ROOT/scripts/session-setup.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

python3 - "$SCRIPT" <<'PY'
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding='utf-8')
required = [
    'rtk_block()',
    'RTK is mandatory for every Engineering OS project',
    'RTK install failed (network/cargo issue)',
    'RTK unavailable: cargo not found',
    'RTK still unavailable after install attempt',
    'rtk init -g failed',
]
missing = [item for item in required if item not in text]
if missing:
    print('missing required RTK blocking markers:')
    for item in missing:
        print('-', item)
    raise SystemExit(1)
if 'warn "RTK install failed' in text or 'warn "RTK unavailable' in text or 'warn "rtk init -g failed' in text:
    raise SystemExit('RTK setup still warns instead of blocking')
print('RTK blocking markers validated')
PY

# Negative simulation: if the install failure is downgraded to warn, validation must fail.
BAD="$TMP/session-setup-bad.sh"
python3 - "$SCRIPT" "$BAD" <<'PY'
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding='utf-8')
text = text.replace('|| rtk_block "RTK install failed (network/cargo issue)"', '|| warn "RTK install failed (network/cargo issue)"', 1)
Path(sys.argv[2]).write_text(text, encoding='utf-8')
PY

if python3 - "$BAD" <<'PY'
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(encoding='utf-8')
if 'warn "RTK install failed' in text or 'warn "RTK unavailable' in text or 'warn "rtk init -g failed' in text:
    raise SystemExit(1)
raise SystemExit(0)
PY
then
  echo "expected downgraded RTK install failure to be rejected"
  exit 1
fi

echo "RTK session blocking tests passed"
