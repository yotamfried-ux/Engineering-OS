#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DISPATCH="$ROOT/scripts/monitoring/eos-telemetry-dispatch.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

HOME_DIR="$TMP/home"
mkdir -p "$HOME_DIR"

dispatch() {
  local event="$1" payload="$2"
  printf '%s' "$payload" | HOME="$HOME_DIR" EOS_DISPATCH_HOME="$HOME_DIR" \
    EOS_DISPATCH_CACHE_DIR="$HOME_DIR/.dispatch-cache" bash "$DISPATCH" "$event"
}

init_git_repo() {
  local dir="$1"
  mkdir -p "$dir"
  git init -q "$dir"
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name test
  git -C "$dir" commit -q --allow-empty -m init
}

# Invalid marker JSON is excluded.
init_git_repo "$HOME_DIR/bad-marker-repo"
mkdir -p "$HOME_DIR/bad-marker-repo/.engineering-os"
echo '{not valid json' > "$HOME_DIR/bad-marker-repo/.engineering-os/telemetry-policy.json"
python3 -c "
import sys
sys.path.insert(0, '$ROOT/scripts/monitoring')
from pathlib import Path
from telemetry_repo_discovery import discover_managed_repos
assert 'bad-marker-repo' not in [r.root.name for r in discover_managed_repos(Path('$HOME_DIR'))]
"

# A marker outside Git is excluded.
mkdir -p "$HOME_DIR/marker-no-git/.engineering-os"
cat > "$HOME_DIR/marker-no-git/.engineering-os/telemetry-policy.json" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"disabled"}}
JSON
python3 -c "
import sys
sys.path.insert(0, '$ROOT/scripts/monitoring')
from pathlib import Path
from telemetry_repo_discovery import discover_managed_repos
assert 'marker-no-git' not in [r.root.name for r in discover_managed_repos(Path('$HOME_DIR'))]
"

# One managed repository with a direct settings file. In a parent-started
# session these on-disk hooks are inactive and the dispatcher must initialize it.
MANAGED="$HOME_DIR/managed-repo"
init_git_repo "$MANAGED"
mkdir -p "$MANAGED/.engineering-os" "$MANAGED/.claude"
cat > "$MANAGED/.engineering-os/telemetry-policy.json" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"disabled"}}
JSON
cat > "$MANAGED/.claude/settings.json" <<JSON
{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash \"$ROOT/scripts/monitoring/eos-telemetry-session-start.sh\""}]}],"PreToolUse":[{"matcher":".*","hooks":[{"type":"command","command":"bash \"$ROOT/scripts/monitoring/require-telemetry-session.sh\""},{"type":"command","command":"bash \"$ROOT/scripts/monitoring/eos-telemetry-event.sh\" pre_tool_use"}]}],"Stop":[{"hooks":[{"type":"command","command":"bash \"$ROOT/scripts/monitoring/record-and-sync-telemetry.sh\" stop"}]}]}}
JSON

# Malformed payload is a privacy-safe no-op, not a crash.
printf 'not-json' | HOME="$HOME_DIR" EOS_DISPATCH_HOME="$HOME_DIR" \
  EOS_DISPATCH_CACHE_DIR="$HOME_DIR/.dispatch-cache" bash "$DISPATCH" post_tool_use

# Traversal resolves to the real unmanaged target rather than the raw prefix.
SESSION_ID="failure-modes-$$"
PAYLOAD_TRAVERSAL=$(python3 -c "import json; print(json.dumps({'session_id':'$SESSION_ID','cwd':'$MANAGED','tool_name':'Read','tool_input':{'file_path':'$MANAGED/../bad-marker-repo/file.txt'}}))")
dispatch post_tool_use "$PAYLOAD_TRAVERSAL"
if [ -f "$MANAGED/.engineering-os/telemetry/events.jsonl" ]; then
  count=$(grep -c '"eos.event.name":"post_tool_use"' "$MANAGED/.engineering-os/telemetry/events.jsonl" 2>/dev/null || true)
  [ "${count:-0}" -eq 0 ] || { echo "ERROR_FOR_AGENT: traversal attributed to wrong repo" >&2; exit 1; }
fi

# Repository-scoped guard regression. An explicit unmanaged path must not inherit
# the sole managed sibling. An explicit managed path remains fail-closed until
# that session has a matching SessionStart.
mkdir -p "$HOME_DIR/unmanaged-folder"
echo harmless > "$HOME_DIR/unmanaged-folder/note.txt"
GUARD_SESSION="guard-scope-$$"
PAYLOAD_OUTSIDE=$(python3 -c "import json; print(json.dumps({'session_id':'$GUARD_SESSION','cwd':'$HOME_DIR','tool_name':'Read','tool_input':{'file_path':'$HOME_DIR/unmanaged-folder/note.txt'}}))")
dispatch guard "$PAYLOAD_OUTSIDE" >/dev/null

PAYLOAD_INSIDE=$(python3 -c "import json; print(json.dumps({'session_id':'$GUARD_SESSION','cwd':'$MANAGED','tool_name':'Read','tool_input':{'file_path':'$MANAGED/README.md'}}))")
if dispatch guard "$PAYLOAD_INSIDE" >"$TMP/guard.out" 2>"$TMP/guard.err"; then
  echo "ERROR_FOR_AGENT: managed guard passed before SessionStart" >&2
  exit 1
fi
grep -Eq 'SessionStart hook did not initialize|no matching session_start' "$TMP/guard.err" || {
  cat "$TMP/guard.err" >&2
  exit 1
}

PAYLOAD_GUARD_START=$(python3 -c "import json; print(json.dumps({'session_id':'$GUARD_SESSION','cwd':'$HOME_DIR'}))")
dispatch session_start "$PAYLOAD_GUARD_START" >/dev/null
dispatch guard "$PAYLOAD_INSIDE" >/dev/null

# Repeated SessionStart rotates to a distinct non-empty run id.
ROTATE_SESSION="rotation-$$"
PAYLOAD_START=$(python3 -c "import json; print(json.dumps({'session_id':'$ROTATE_SESSION','cwd':'$HOME_DIR'}))")
dispatch session_start "$PAYLOAD_START" >/dev/null
RUN_ID_1=$(tr -d '\r\n' < "$MANAGED/.engineering-os/telemetry/run_id")
dispatch session_start "$PAYLOAD_START" >/dev/null
RUN_ID_2=$(tr -d '\r\n' < "$MANAGED/.engineering-os/telemetry/run_id")
[ -n "$RUN_ID_1" ] && [ -n "$RUN_ID_2" ] || { echo "ERROR_FOR_AGENT: empty run id" >&2; exit 1; }
[ "$RUN_ID_1" != "$RUN_ID_2" ] || { echo "ERROR_FOR_AGENT: run id did not rotate" >&2; exit 1; }

# Stop with no managed repositories is a clean no-op.
EMPTY_HOME="$TMP/empty-home"
mkdir -p "$EMPTY_HOME/no-marker"
PAYLOAD_STOP=$(python3 -c "import json; print(json.dumps({'session_id':'empty','cwd':'$EMPTY_HOME'}))")
printf '%s' "$PAYLOAD_STOP" | HOME="$EMPTY_HOME" EOS_DISPATCH_HOME="$EMPTY_HOME" \
  EOS_DISPATCH_CACHE_DIR="$EMPTY_HOME/.dispatch-cache" bash "$DISPATCH" stop

echo 'dispatch failure-mode tests passed: invalid inputs, traversal, scoped guard, run rotation, and empty fan-out'
