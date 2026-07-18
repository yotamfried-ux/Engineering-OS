#!/usr/bin/env bash
set -euo pipefail

EVENT_NAME="${1:-unknown}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECORDER="$SCRIPT_DIR/eos-telemetry-event.sh"
SYNC="$SCRIPT_DIR/sync-telemetry-run.py"

[ -f "$RECORDER" ] || { echo "ERROR_FOR_AGENT: telemetry recorder missing: $RECORDER" >&2; exit 2; }
[ -f "$SYNC" ] || { echo "ERROR_FOR_AGENT: telemetry handoff runtime missing: $SYNC" >&2; exit 2; }

payload="$(cat || true)"
printf '%s' "$payload" | bash "$RECORDER" "$EVENT_NAME"
python3 "$SYNC" --event "$EVENT_NAME"
