#!/usr/bin/env bash
set -euo pipefail

# Proves coexistence between user-level dispatcher hooks and direct project-local
# hooks. Suppression is allowed only for a complete active direct installation in
# the native repository of the actual SessionStart. Partial or sibling settings
# remain dispatchable.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DISPATCH="$ROOT/scripts/monitoring/eos-telemetry-dispatch.sh"
RESOLVER="$ROOT/scripts/monitoring/eos-telemetry-dispatch-resolve.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

init_managed_repo() {
  local dir="$1" mode="${2:-complete}"
  mkdir -p "$dir/.engineering-os" "$dir/.claude"
  git init -q "$dir"
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name test
  git -C "$dir" commit -q --allow-empty -m init
  cat > "$dir/.engineering-os/telemetry-policy.json" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"disabled"}}
JSON
  if [ "$mode" = "partial" ]; then
    cat > "$dir/.claude/settings.json" <<JSON
{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash \"$ROOT/scripts/monitoring/eos-telemetry-session-start.sh\""}]}]}}
JSON
  else
    cat > "$dir/.claude/settings.json" <<JSON
{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash \"$ROOT/scripts/monitoring/eos-telemetry-session-start.sh\""}]}],"PreToolUse":[{"matcher":".*","hooks":[{"type":"command","command":"bash \"$ROOT/scripts/monitoring/require-telemetry-session.sh\""},{"type":"command","command":"bash \"$ROOT/scripts/monitoring/eos-telemetry-event.sh\" pre_tool_use"}]}],"Stop":[{"hooks":[{"type":"command","command":"bash \"$ROOT/scripts/monitoring/record-and-sync-telemetry.sh\" stop"}]}],"StopFailure":[{"hooks":[{"type":"command","command":"bash \"$ROOT/scripts/monitoring/record-and-sync-telemetry.sh\" stop_failure"}]}],"SessionEnd":[{"hooks":[{"type":"command","command":"bash \"$ROOT/scripts/monitoring/record-and-sync-telemetry.sh\" session_end"}]}]}}
JSON
  fi
}

run_dispatch() {
  local home_dir="$1" event="$2" payload="$3"
  printf '%s' "$payload" | \
    HOME="$home_dir" \
    EOS_DISPATCH_HOME="$home_dir" \
    EOS_DISPATCH_CACHE_DIR="$home_dir/.cache" \
    bash "$DISPATCH" "$event"
}

# Case A: a real SessionStart inside a repository with a complete direct install.
# Claude also runs those direct hooks, so dispatcher suppression prevents duplicates.
CASE_A="$TMP/case-a"
NATIVE="$CASE_A/native-direct-repo"
mkdir -p "$CASE_A"
init_managed_repo "$NATIVE" complete
PAYLOAD_A=$(python3 -c "import json; print(json.dumps({'session_id':'native-direct','cwd':'$NATIVE','hook_event_name':'SessionStart'}))")
run_dispatch "$CASE_A" session_start "$PAYLOAD_A" >/dev/null
if [ -e "$NATIVE/.engineering-os/telemetry/run_id" ]; then
  echo "ERROR_FOR_AGENT: dispatcher duplicated a complete active native direct installation" >&2
  exit 1
fi
echo "OK: complete native direct-hook SessionStart is suppressed"

# Case B: parent-started sibling settings exist on disk but are not active.
CASE_B="$TMP/case-b"
PARENT_REPO="$CASE_B/sibling-with-direct-settings"
mkdir -p "$CASE_B"
init_managed_repo "$PARENT_REPO" complete
PAYLOAD_B=$(python3 -c "import json; print(json.dumps({'session_id':'parent-start','cwd':'$CASE_B','hook_event_name':'SessionStart'}))")
run_dispatch "$CASE_B" session_start "$PAYLOAD_B" >/dev/null
if [ ! -s "$PARENT_REPO/.engineering-os/telemetry/run_id" ]; then
  echo "ERROR_FOR_AGENT: parent-started sibling was skipped merely because settings existed on disk" >&2
  exit 1
fi
echo "OK: inactive sibling direct settings do not suppress dispatch"

# Case C: a non-SessionStart cache miss inside a repo remains dispatchable.
CASE_C="$TMP/case-c"
MID_SESSION_REPO="$CASE_C/mid-session-repo"
mkdir -p "$CASE_C"
init_managed_repo "$MID_SESSION_REPO" complete
PAYLOAD_C=$(python3 -c "import json; print(json.dumps({'session_id':'mid-session-install','cwd':'$MID_SESSION_REPO','hook_event_name':'PostToolUse','tool_name':'Read','tool_input':{'file_path':'$MID_SESSION_REPO/README.md'}}))")
RESOLVED_C=$(printf '%s' "$PAYLOAD_C" | \
  HOME="$CASE_C" \
  EOS_DISPATCH_HOME="$CASE_C" \
  EOS_DISPATCH_CACHE_DIR="$CASE_C/.cache" \
  python3 "$RESOLVER" post_tool_use)
printf '%s\n' "$RESOLVED_C" | grep -Fxq "$MID_SESSION_REPO" || {
  echo "ERROR_FOR_AGENT: cache-miss event was suppressed because settings existed on disk" >&2
  exit 1
}
echo "OK: mid-session cache-miss resolves to the managed repository"

# Case D: a partial native project configuration cannot suppress the dispatcher.
# Otherwise a lone SessionStart entry would leave guard/recorder/boundaries absent.
CASE_D="$TMP/case-d"
PARTIAL="$CASE_D/native-partial-repo"
mkdir -p "$CASE_D"
init_managed_repo "$PARTIAL" partial
PAYLOAD_D=$(python3 -c "import json; print(json.dumps({'session_id':'native-partial','cwd':'$PARTIAL','hook_event_name':'SessionStart'}))")
run_dispatch "$CASE_D" session_start "$PAYLOAD_D" >/dev/null
if [ ! -s "$PARTIAL/.engineering-os/telemetry/run_id" ]; then
  echo "ERROR_FOR_AGENT: partial native project hooks incorrectly suppressed dispatcher coverage" >&2
  exit 1
fi
echo "OK: partial native direct settings remain dispatchable"

echo "dispatch/project-local coexistence tests passed: only complete active native direct hooks are suppressed"
