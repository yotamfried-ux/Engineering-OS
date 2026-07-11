#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUT="${EOS_TELEMETRY_FILE:-$ROOT/.engineering-os/telemetry/events.jsonl}"
RUN_ID_FILE="${EOS_TELEMETRY_RUN_ID_FILE:-$ROOT/.engineering-os/telemetry/run_id}"
SUMMARY="${EOS_TELEMETRY_SUMMARY_FILE:-$ROOT/.engineering-os/telemetry/latest-summary.md}"
HISTORY_ROOT="${EOS_TELEMETRY_HISTORY_DIR:-$ROOT/.engineering-os/telemetry/history}"
RECORDER="${ENGINEERING_OS_HOME:-$ROOT}/scripts/monitoring/eos-telemetry-event.sh"

mkdir -p "$(dirname "$OUT")" "$(dirname "$RUN_ID_FILE")" "$HISTORY_ROOT"

old_run_id=""
if [ -f "$RUN_ID_FILE" ]; then
  old_run_id="$(head -1 "$RUN_ID_FILE" | tr -cd 'a-zA-Z0-9_.:-')"
fi

if [ -s "$OUT" ]; then
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  safe_old="${old_run_id:-unknown-run}"
  archive="$HISTORY_ROOT/${stamp}-${safe_old}"
  mkdir -p "$archive"
  mv "$OUT" "$archive/events.jsonl"
  [ -f "$SUMMARY" ] && mv "$SUMMARY" "$archive/latest-summary.md"
  [ -f "$RUN_ID_FILE" ] && cp "$RUN_ID_FILE" "$archive/run_id"
fi

if [ -n "${EOS_TELEMETRY_RUN_ID:-}" ]; then
  new_run_id="$(python3 - <<'PY'
import hashlib, os
print(hashlib.sha256(os.environ['EOS_TELEMETRY_RUN_ID'].encode()).hexdigest()[:32])
PY
)"
else
  new_run_id="$(python3 - <<'PY'
import secrets
print(secrets.token_hex(16))
PY
)"
fi

printf '%s\n' "$new_run_id" > "$RUN_ID_FILE"
: > "$OUT"
rm -f "$SUMMARY"

if [ ! -f "$RECORDER" ]; then
  echo "ERROR_FOR_AGENT: telemetry recorder missing: $RECORDER" >&2
  exit 1
fi

exec bash "$RECORDER" session_start
