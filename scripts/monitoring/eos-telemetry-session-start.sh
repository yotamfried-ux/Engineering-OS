#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_RUNTIME="$SCRIPT_DIR/../enforcement/lib/python-runtime.sh"
[ -f "$PYTHON_RUNTIME" ] && [ -r "$PYTHON_RUNTIME" ] || {
  echo "ERROR_FOR_AGENT: missing Python runtime resolver: $PYTHON_RUNTIME" >&2
  exit 2
}
# shellcheck source=../enforcement/lib/python-runtime.sh
. "$PYTHON_RUNTIME"
eos_python_preflight || exit 2
export BASH_ENV="$PYTHON_RUNTIME"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUT="${EOS_TELEMETRY_FILE:-$ROOT/.engineering-os/telemetry/events.jsonl}"
RUN_ID_FILE="${EOS_TELEMETRY_RUN_ID_FILE:-$ROOT/.engineering-os/telemetry/run_id}"
SUMMARY="${EOS_TELEMETRY_SUMMARY_FILE:-$(dirname "$OUT")/latest-summary.md}"
HISTORY_ROOT="${EOS_TELEMETRY_HISTORY_DIR:-$(dirname "$OUT")/history}"
RECORDER="$SCRIPT_DIR/eos-telemetry-event.sh"
SYNC="$SCRIPT_DIR/sync-telemetry-run.py"

mkdir -p "$(dirname "$OUT")" "$(dirname "$RUN_ID_FILE")" "$HISTORY_ROOT"

old_run_id=""
if [ -f "$RUN_ID_FILE" ]; then
  old_run_id="$(head -1 "$RUN_ID_FILE" | tr -cd 'a-zA-Z0-9_.:-')"
fi

if [ -s "$OUT" ]; then
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  safe_old="${old_run_id:-unknown-run}"
  archive="$HISTORY_ROOT/${stamp}-${safe_old}"
  suffix=0
  while [ -e "$archive" ]; do
    suffix=$((suffix + 1))
    archive="$HISTORY_ROOT/${stamp}-${safe_old}-${suffix}"
  done
  mkdir -p "$archive"
  mv "$OUT" "$archive/events.jsonl"
  [ -f "$SUMMARY" ] && mv "$SUMMARY" "$archive/latest-summary.md"
  [ -f "$RUN_ID_FILE" ] && cp "$RUN_ID_FILE" "$archive/run_id"
fi

new_run_id="$(python3 - <<'PY'
import hashlib
import os
import secrets
seed = os.environ.get("EOS_TELEMETRY_RUN_ID", "")
nonce = secrets.token_hex(32)
print(hashlib.sha256(f"{seed}:{nonce}".encode()).hexdigest()[:32])
PY
)"

printf '%s\n' "$new_run_id" > "$RUN_ID_FILE"
: > "$OUT"
rm -f "$SUMMARY"

[ -f "$RECORDER" ] || { echo "ERROR_FOR_AGENT: telemetry recorder missing beside session wrapper: $RECORDER" >&2; exit 1; }
[ -f "$SYNC" ] || { echo "ERROR_FOR_AGENT: telemetry handoff runtime missing beside session wrapper: $SYNC" >&2; exit 2; }

payload="$(cat || true)"
printf '%s' "$payload" | bash "$RECORDER" session_start
python3 "$SYNC" --event session_start
