#!/usr/bin/env bash
set -euo pipefail

EVENT_NAME="${1:-unknown}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECORDER="$SCRIPT_DIR/eos-telemetry-event.sh"
SYNC="$SCRIPT_DIR/sync-telemetry-run.py"
ARCHIVER="$SCRIPT_DIR/archive-local-telemetry-run.py"

[ -f "$RECORDER" ] || { echo "ERROR_FOR_AGENT: telemetry recorder missing: $RECORDER" >&2; exit 2; }
[ -f "$SYNC" ] || { echo "ERROR_FOR_AGENT: telemetry handoff runtime missing: $SYNC" >&2; exit 2; }

payload="$(cat || true)"
printf '%s' "$payload" | bash "$RECORDER" "$EVENT_NAME"

sync_status=0
python3 "$SYNC" --event "$EVENT_NAME" || sync_status=$?

# Best-effort local archive import into ENGINEERING_OS_HOME/telemetry-archive/, kept
# independent of the remote handoff above: it must run even when the required-mode
# push failed, and its own failure must never change this script's exit status.
if [ -f "$ARCHIVER" ]; then
  python3 "$ARCHIVER" --event "$EVENT_NAME" || true
fi

exit "$sync_status"
