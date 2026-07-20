#!/usr/bin/env bash
set -euo pipefail

# Proves coexistence between user-level dispatcher hooks and direct project-local
# hooks. A direct install is suppressed only when that repository is the native
# repository of the actual SessionStart. Merely having settings on disk must not
# suppress a sibling in a parent-started session or a cache-miss event after a
# mid-session user-level install.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DISPATCH="$ROOT/scripts/monitoring/eos-telemetry-dispatch.sh"
RESOLVER="$ROOT/scripts/monitoring/eos-telemetry-dispatch-resolve.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

init_managed_repo() {
  local dir="$1"
  mkdir -p "$dir/.engineering-os" "$dir/.claude"
  git init -q "$dir"
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name test
  git -C "$dir" commit -q --allow-empty -m init
  cat > "$dir/.engineering-os/telemetry-policy.json" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"disabled"}}
JSON
  cat > "$dir/.claude/settings.json" <<JSON
{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash \"$ROOT/scripts/monitoring/eos-telemetry-session-start.sh\""}]}],"PreToolUse":[{"matcher":".*","hooks":[{"type":"command","command":"bash \"$ROOT/scripts/monitoring/require-telemetry-session.sh\""}]}]}}
JSON
}

run_dispatch() {
  local home_dir="$1" event="$2" payload="$3"
  printf '%s' "$payload" | \
    HOME="$home_dir" \
    EOS_DISPATCH_HOME="$home_dir" \
    EOS_DISPATCH_CACHE_DIR="$home_dir/.cache" \
    bash "$DISPATCH" "$event"
}

# Case A: a real SessionStart inside a repository with direct hooks. Claude will
# also run the direct SessionStart hook, so the user-level dispatcher must skip
# this native repository to avoid duplicate recording.
CASE_A="$TMP/case-a"
NATIVE="$CASE_A/native-direct-repo"
mkdir -p "$CASE_A"
init_managed_repo "$NATIVE"
PAYLOAD_A=$(python3 -c "import json; print(json.dumps({'session_id':'native-direct','cwd':'$NATIVE','hook_event_name':'SessionStart'}))")
run_dispatch "$CASE_A" session_start "$PAYLOAD_A" >/dev/null
if [ -e "$NATIVE/.engineering-os/telemetry/run_id" ]; then
  echo "ERROR_FOR_AGENT: dispatcher duplicated the native repository's active project-local SessionStart" >&2
  exit 1
fi
echo "OK: actual native direct-hook SessionStart is suppressed"

# Case B: a SessionStart from a parent directory. Sibling project settings are
# present on disk but are not loaded by Claude for this session, so the
# dispatcher must initialize the sibling rather than treating it as self-sufficient.
CASE_B="$TMP/case-b"
PARENT_REPO="$CASE_B/sibling-with-direct-settings"
mkdir -p "$CASE_B"
init_managed_repo "$PARENT_REPO"
PAYLOAD_B=$(python3 -c "import json; print(json.dumps({'session_id':'parent-start','cwd':'$CASE_B','hook_event_name':'SessionStart'}))")
run_dispatch "$CASE_B" session_start "$PAYLOAD_B" >/dev/null
if [ ! -s "$PARENT_REPO/.engineering-os/telemetry/run_id" ]; then
  echo "ERROR_FOR_AGENT: parent-started sibling was skipped merely because project-local settings existed on disk" >&2
  exit 1
fi
echo "OK: parent-started sibling with inactive on-disk project hooks remains dispatchable"

# Case C: cache-miss non-SessionStart event, matching the live experiment where
# user-level hooks were installed after the session began. The resolver must not
# suppress an in-repo event merely because direct settings exist on disk.
CASE_C="$TMP/case-c"
MID_SESSION_REPO="$CASE_C/mid-session-repo"
mkdir -p "$CASE_C"
init_managed_repo "$MID_SESSION_REPO"
PAYLOAD_C=$(python3 -c "import json; print(json.dumps({'session_id':'mid-session-install','cwd':'$MID_SESSION_REPO','hook_event_name':'PostToolUse','tool_name':'Read','tool_input':{'file_path':'$MID_SESSION_REPO/README.md'}}))")
RESOLVED_C=$(printf '%s' "$PAYLOAD_C" | \
  HOME="$CASE_C" \
  EOS_DISPATCH_HOME="$CASE_C" \
  EOS_DISPATCH_CACHE_DIR="$CASE_C/.cache" \
  python3 "$RESOLVER" post_tool_use)
printf '%s\n' "$RESOLVED_C" | grep -Fxq "$MID_SESSION_REPO" || {
  echo "ERROR_FOR_AGENT: cache-miss event was suppressed because project-local settings existed on disk" >&2
  exit 1
}
echo "OK: mid-session cache-miss event resolves to the managed repository"

echo "dispatch/project-local coexistence tests passed: native active hooks deduplicated; parent and mid-session inactive settings remain dispatchable"
