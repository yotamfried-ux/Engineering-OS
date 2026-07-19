#!/usr/bin/env bash
set -euo pipefail

# User-level hook entry point. Installed (only) at $HOME/.claude/settings.json
# by install-user-level-telemetry-hooks.sh, so it is the thing Claude Code
# actually invokes for a session that did not start inside a single managed
# repository. Its only job: resolve which managed repo(s) an event belongs
# to, then cd into each and exec the existing, per-repo scripts unmodified
# in how they compute their own root (they still use
# `git rev-parse --show-toplevel || pwd`; cd-ing first makes that correct).
#
# Project-local installs (patch-settings-telemetry.py against a single
# project's own .claude/settings.json) do NOT go through this dispatcher —
# they call the per-repo scripts directly, exactly as before this change.

EVENT_NAME="${1:-unknown}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVER="$SCRIPT_DIR/eos-telemetry-dispatch-resolve.py"
SESSION_START="$SCRIPT_DIR/eos-telemetry-session-start.sh"
RECORDER="$SCRIPT_DIR/eos-telemetry-event.sh"
BOUNDARY="$SCRIPT_DIR/record-and-sync-telemetry.sh"
UNATTRIBUTED_LOG="${EOS_DISPATCH_UNATTRIBUTED_LOG:-$HOME/.engineering-os/telemetry/unattributed.jsonl}"

[ -f "$RESOLVER" ] || { echo "ERROR_FOR_AGENT: telemetry dispatch resolver missing: $RESOLVER" >&2; exit 0; }

PAYLOAD="$(cat || true)"

RESOLVED="$(printf '%s' "$PAYLOAD" | python3 "$RESOLVER" "$EVENT_NAME" 2>/dev/null || true)"

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
  repo_root="$1"
  case "$EVENT_NAME" in
    session_start)
      (cd "$repo_root" && printf '%s' "$PAYLOAD" | EOS_TELEMETRY_HOST_CORRELATION_ID="$CORRELATION_ID" bash "$SESSION_START")
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
  # Fan-out events with zero discovered repos are a legitimate no-op (session
  # not touching any managed repo). Per-tool events with zero repos means the
  # event could not be safely attributed — record a minimal diagnostic only,
  # never guess a repository.
  case "$EVENT_NAME" in
    session_start|stop|stop_failure|session_end) exit 0 ;;
  esac
  mkdir -p "$(dirname "$UNATTRIBUTED_LOG")"
  python3 - "$UNATTRIBUTED_LOG" "$EVENT_NAME" "$CORRELATION_ID" <<'PY' || true
import json
import sys
import time
from pathlib import Path

log_path, event_name, correlation_id = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
record = {
    "schema_version": "eos.dispatch.unattributed.v1",
    "event_name": event_name,
    "host_correlation_id": correlation_id,
    "timestamp": time.time(),
}
log_path.parent.mkdir(parents=True, exist_ok=True)
with log_path.open("a", encoding="utf-8") as fh:
    fh.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")
PY
  exit 0
fi

for repo_root in "${REPOS[@]}"; do
  dispatch_to_repo "$repo_root" || true
done
