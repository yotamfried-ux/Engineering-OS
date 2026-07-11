#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUT="${EOS_TELEMETRY_FILE:-$ROOT/.engineering-os/telemetry/events.jsonl}"
RUN_ID_FILE="${EOS_TELEMETRY_RUN_ID_FILE:-$ROOT/.engineering-os/telemetry/run_id}"
SUMMARY="${EOS_TELEMETRY_SUMMARY_FILE:-$(dirname "$OUT")/latest-summary.md}"
HISTORY_ROOT="${EOS_TELEMETRY_HISTORY_DIR:-$(dirname "$OUT")/history}"
RECORDER="$SCRIPT_DIR/eos-telemetry-event.sh"

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

# EOS_TELEMETRY_RUN_ID is treated as an optional correlation seed, not a stable
# trace id. Every SessionStart adds fresh entropy so two Claude sessions cannot
# silently share one run id. The recorder prefers this run-id file thereafter.
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

if [ ! -f "$RECORDER" ]; then
  echo "ERROR_FOR_AGENT: telemetry recorder missing beside session wrapper: $RECORDER" >&2
  exit 1
fi

exec bash "$RECORDER" session_start
