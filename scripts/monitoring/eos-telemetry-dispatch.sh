#!/usr/bin/env bash
set -euo pipefail

# User-level hook entry point. It resolves a hook payload to zero or more
# managed repositories, then delegates to the existing per-repository scripts.
# Unrelated or ambiguous events never inherit a managed repository by guess.

EVENT_NAME="${1:-unknown}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVER="$SCRIPT_DIR/eos-telemetry-dispatch-resolve.py"
SESSION_START="$SCRIPT_DIR/eos-telemetry-session-start.sh"
RECORDER="$SCRIPT_DIR/eos-telemetry-event.sh"
BOUNDARY="$SCRIPT_DIR/record-and-sync-telemetry.sh"
GUARD="$SCRIPT_DIR/require-telemetry-session.sh"
HOST_TELEMETRY_DIR="${EOS_DISPATCH_HOST_TELEMETRY_DIR:-$HOME/.engineering-os/telemetry}"
UNATTRIBUTED_LOG="${EOS_DISPATCH_UNATTRIBUTED_LOG:-$HOST_TELEMETRY_DIR/unattributed.jsonl}"
ERROR_LOG="${EOS_DISPATCH_ERROR_LOG:-$HOST_TELEMETRY_DIR/dispatch-errors.jsonl}"

[ -f "$RESOLVER" ] || {
  echo "ERROR_FOR_AGENT: telemetry dispatch resolver missing: $RESOLVER" >&2
  exit 0
}

PAYLOAD="$(cat || true)"
resolver_err="$(mktemp)"
trap 'rm -f "$resolver_err"' EXIT

set +e
RESOLVED="$(printf '%s' "$PAYLOAD" | python3 "$RESOLVER" "$EVENT_NAME" 2>"$resolver_err")"
resolver_status=$?
set -e

if [ "$resolver_status" -ne 0 ]; then
  mkdir -p "$(dirname "$ERROR_LOG")"
  python3 - "$ERROR_LOG" "$EVENT_NAME" "$resolver_status" "$resolver_err" <<'PY' || true
import hashlib
import json
import sys
import time
from pathlib import Path

log_path = Path(sys.argv[1])
event_name = sys.argv[2]
status = int(sys.argv[3])
stderr_path = Path(sys.argv[4])
diagnostic = stderr_path.read_bytes() if stderr_path.is_file() else b""
record = {
    "schema_version": "eos.dispatch.error.v1",
    "event_name": event_name,
    "error_type": "resolver_failure",
    "exit_status": status,
    "diagnostic_sha256": hashlib.sha256(diagnostic).hexdigest(),
    "timestamp": time.time(),
}
with log_path.open("a", encoding="utf-8") as handle:
    handle.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")
PY
  echo "ERROR_FOR_AGENT: telemetry dispatch resolver failed (status=$resolver_status); recorded a privacy-safe diagnostic in $ERROR_LOG" >&2
  # A resolver failure cannot safely prove that this event belongs to a
  # managed repository. Do not turn a system-wide user hook into a global
  # blocker; record the failure and leave attribution empty.
  RESOLVED=""
fi

CORRELATION_ID=""
REPOS=()
while IFS= read -r line; do
  [ -z "$line" ] && continue
  case "$line" in
    CORRELATION:*) CORRELATION_ID="${line#CORRELATION:}" ;;
    *) REPOS+=("$line") ;;
  esac
done <<< "$RESOLVED"

dispatch_to_repo() {
  local repo_root="$1"
  case "$EVENT_NAME" in
    session_start)
      (cd "$repo_root" && printf '%s' "$PAYLOAD" | EOS_TELEMETRY_HOST_CORRELATION_ID="$CORRELATION_ID" bash "$SESSION_START")
      ;;
    guard)
      (cd "$repo_root" && printf '%s' "$PAYLOAD" | EOS_TELEMETRY_HOST_CORRELATION_ID="$CORRELATION_ID" bash "$GUARD")
      ;;
    stop|stop_failure|session_end)
      (cd "$repo_root" && printf '%s' "$PAYLOAD" | EOS_TELEMETRY_HOST_CORRELATION_ID="$CORRELATION_ID" bash "$BOUNDARY" "$EVENT_NAME")
      ;;
    *)
      (cd "$repo_root" && printf '%s' "$PAYLOAD" | EOS_TELEMETRY_HOST_CORRELATION_ID="$CORRELATION_ID" bash "$RECORDER" "$EVENT_NAME")
      ;;
  esac
}

if [ "${#REPOS[@]}" -eq 0 ]; then
  # Fan-out events with no managed repositories are legitimate no-ops. A guard
  # with no safely attributed repository must also no-op: the following
  # recorder hook will create the single unattributed diagnostic.
  case "$EVENT_NAME" in
    session_start|stop|stop_failure|session_end|guard) exit 0 ;;
  esac

  mkdir -p "$(dirname "$UNATTRIBUTED_LOG")"
  python3 - "$UNATTRIBUTED_LOG" "$EVENT_NAME" "$CORRELATION_ID" <<'PY' || true
import json
import sys
import time
from pathlib import Path

log_path = Path(sys.argv[1])
event_name = sys.argv[2]
correlation_id = sys.argv[3]
record = {
    "schema_version": "eos.dispatch.unattributed.v1",
    "event_name": event_name,
    "host_correlation_id": correlation_id,
    "timestamp": time.time(),
}
log_path.parent.mkdir(parents=True, exist_ok=True)
with log_path.open("a", encoding="utf-8") as handle:
    handle.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")
PY
  exit 0
fi

if [ "$EVENT_NAME" = "guard" ]; then
  # Per-tool resolution returns at most one repository. Preserve the existing
  # fail-closed guard result for that attributed managed repository.
  dispatch_to_repo "${REPOS[0]}"
  exit $?
fi

for repo_root in "${REPOS[@]}"; do
  dispatch_to_repo "$repo_root" || true
done
