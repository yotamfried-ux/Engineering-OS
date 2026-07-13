#!/usr/bin/env bash
set -euo pipefail

EVENT_NAME="${1:-unknown}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RECORDER="$SCRIPT_DIR/eos-telemetry-event.sh"
SYNC="$SCRIPT_DIR/sync-telemetry-run.py"

[ -f "$RECORDER" ] || { echo "ERROR_FOR_AGENT: telemetry recorder missing: $RECORDER" >&2; exit 2; }
[ -f "$SYNC" ] || { echo "ERROR_FOR_AGENT: telemetry handoff runtime missing: $SYNC" >&2; exit 2; }

repo_slug="$(python3 - "$ROOT" <<'PY'
import subprocess,sys
from pathlib import Path
root=Path(sys.argv[1])
try:
    value=subprocess.check_output(['git','-C',str(root),'remote','get-url','origin'],text=True,stderr=subprocess.DEVNULL).strip()
except Exception:
    value=''
trimmed=value[:-4] if value.endswith('.git') else value
slug=''
for marker in ('github.com/','github.com:'):
    if marker in trimmed:
        candidate=trimmed.split(marker,1)[1].strip('/')
        if candidate.count('/')==1:
            slug=candidate
            break
print(slug or root.name)
PY
)"

payload="$(cat || true)"
printf '%s' "$payload" | bash "$RECORDER" "$EVENT_NAME"
python3 "$SYNC" --event "$EVENT_NAME" --repo "$repo_slug"
