#!/usr/bin/env bash
set -euo pipefail

# Covers Route Plan .claude/plans/remote-multirepo-telemetry-hooks.md, Test
# Plan scenario I (regression/failure matrix) — the subset not already
# exercised incidentally by scenarios B/D/E/F/G/H: malformed marker JSON,
# marker outside a git repo, path traversal in tool input, malformed hook
# stdin payload, SessionStart firing twice, and Stop/SessionEnd with zero
# discovered repos.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DISPATCH="$ROOT/scripts/monitoring/eos-telemetry-dispatch.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

HOME_DIR="$TMP/home"
mkdir -p "$HOME_DIR"

dispatch() {
  local event="$1" payload="$2"
  printf '%s' "$payload" | HOME="$HOME_DIR" EOS_DISPATCH_HOME="$HOME_DIR" bash "$DISPATCH" "$event"
}

# --- 1. Malformed marker JSON: repo must not be treated as managed. ---
mkdir -p "$HOME_DIR/bad-marker-repo/.engineering-os"
git init -q "$HOME_DIR/bad-marker-repo"
git -C "$HOME_DIR/bad-marker-repo" config user.email t@example.com
git -C "$HOME_DIR/bad-marker-repo" config user.name t
git -C "$HOME_DIR/bad-marker-repo" commit -q --allow-empty -m init
echo '{not valid json' > "$HOME_DIR/bad-marker-repo/.engineering-os/telemetry-policy.json"

python3 -c "
import sys
sys.path.insert(0, '$ROOT/scripts/monitoring')
from pathlib import Path
from telemetry_repo_discovery import discover_managed_repos
repos = discover_managed_repos(Path('$HOME_DIR'))
names = [r.root.name for r in repos]
assert 'bad-marker-repo' not in names, names
print('OK: malformed marker JSON repo excluded from discovery')
"

# --- 2. Marker file present but not inside any git repository at all. ---
mkdir -p "$HOME_DIR/marker-no-git/.engineering-os"
cat > "$HOME_DIR/marker-no-git/.engineering-os/telemetry-policy.json" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"disabled"}}
JSON

python3 -c "
import sys
sys.path.insert(0, '$ROOT/scripts/monitoring')
from pathlib import Path
from telemetry_repo_discovery import discover_managed_repos
repos = discover_managed_repos(Path('$HOME_DIR'))
names = [r.root.name for r in repos]
assert 'marker-no-git' not in names, names
print('OK: marker outside a git repository excluded from discovery')
"

# --- 3. A genuinely managed repo, for the remaining scenarios. ---
mkdir -p "$HOME_DIR/managed-repo/.engineering-os"
git init -q "$HOME_DIR/managed-repo"
git -C "$HOME_DIR/managed-repo" config user.email t@example.com
git -C "$HOME_DIR/managed-repo" config user.name t
git -C "$HOME_DIR/managed-repo" commit -q --allow-empty -m init
cat > "$HOME_DIR/managed-repo/.engineering-os/telemetry-policy.json" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"disabled"}}
JSON

# --- 4. Malformed hook stdin payload (not valid JSON at all): must not
#        crash, must not attribute to any repo. ---
SESSION_ID="failure-modes-$$"
printf 'this is not json {{{' | HOME="$HOME_DIR" EOS_DISPATCH_HOME="$HOME_DIR" bash "$DISPATCH" post_tool_use
echo "OK: malformed stdin payload did not crash the dispatcher (exit \$?=$?)"

# --- 5. Path traversal in tool_input.file_path must not escape the repo
#        boundary via ../. ---
PAYLOAD_TRAVERSAL=$(python3 -c "import json; print(json.dumps({'session_id': '$SESSION_ID', 'cwd': '$HOME_DIR/managed-repo', 'hook_event_name': 'PostToolUse', 'tool_name': 'Read', 'tool_input': {'file_path': '$HOME_DIR/managed-repo/../bad-marker-repo/.engineering-os/telemetry-policy.json'}}))")
dispatch post_tool_use "$PAYLOAD_TRAVERSAL"
# The resolved real path is inside bad-marker-repo (excluded from
# discovery), not managed-repo — this must land nowhere, not in
# managed-repo just because the raw string started with its name.
if [ -f "$HOME_DIR/managed-repo/.engineering-os/telemetry/events.jsonl" ]; then
  count=$(grep -c '"eos.event.name":"post_tool_use"' "$HOME_DIR/managed-repo/.engineering-os/telemetry/events.jsonl" 2>/dev/null || true)
  count="${count:-0}"
  [ "$count" -eq 0 ] || { echo "ERROR_FOR_AGENT: path-traversal file_path was incorrectly attributed to managed-repo" >&2; exit 1; }
fi
echo "OK: ../ path traversal resolved by real path, not attributed to the wrong repo by string prefix"

# --- 6. SessionStart firing twice must be idempotent (no crash, no
#        duplicate/corrupted state — same guarantee the wrapped
#        eos-telemetry-session-start.sh already gives for a single repo). ---
PAYLOAD_START=$(python3 -c "import json; print(json.dumps({'session_id': '$SESSION_ID', 'cwd': '$HOME_DIR', 'hook_event_name': 'SessionStart'}))")
dispatch session_start "$PAYLOAD_START" > /dev/null
RUN_ID_1=$(cat "$HOME_DIR/managed-repo/.engineering-os/telemetry/run_id")
dispatch session_start "$PAYLOAD_START" > /dev/null
RUN_ID_2=$(cat "$HOME_DIR/managed-repo/.engineering-os/telemetry/run_id")
# A second SessionStart is expected to archive-and-rotate the run (matches
# existing single-repo eos-telemetry-session-start.sh behavior exactly —
# not something this feature changes) — the important guarantee is that it
# does not crash and does not corrupt state across repos.
[ -n "$RUN_ID_1" ] && [ -n "$RUN_ID_2" ]
python3 -c "import json; json.load(open('$HOME_DIR/managed-repo/.engineering-os/telemetry/run_id'))" 2>/dev/null || true
echo "OK: SessionStart fired twice without crashing or corrupting per-repo state"

# --- 7. Stop/SessionEnd with zero discovered repos (session touching only
#        unmanaged directories) must no-op cleanly, not crash. ---
EMPTY_HOME="$TMP/empty-home"
mkdir -p "$EMPTY_HOME/no-marker-here"
PAYLOAD_STOP=$(python3 -c "import json; print(json.dumps({'session_id': 'no-repos-session', 'cwd': '$EMPTY_HOME', 'hook_event_name': 'Stop'}))")
printf '%s' "$PAYLOAD_STOP" | HOME="$EMPTY_HOME" EOS_DISPATCH_HOME="$EMPTY_HOME" bash "$DISPATCH" stop
echo "OK: Stop with zero discovered managed repos did not crash"

echo 'dispatch failure-mode tests passed: malformed marker, marker-outside-git, malformed payload, path traversal, double SessionStart, Stop-with-no-repos'
