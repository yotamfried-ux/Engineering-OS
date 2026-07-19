#!/usr/bin/env bash
set -euo pipefail

# Covers Route Plan .claude/plans/remote-multirepo-telemetry-hooks.md — the
# double-recording risk found during review: Claude Code merges hooks across
# settings scopes rather than overriding (confirmed against official docs),
# so a repo that already has its own working project-local
# .claude/settings.json (installed the "direct" way, e.g. via
# install-policy-gates.sh) would fire its own hooks directly AND, without
# this guard, the user-level dispatcher would resolve to the same repo and
# record the same event a second time. The dispatcher must skip any repo
# that already has a working project-local installation — see
# telemetry_repo_discovery.has_conflicting_project_local_hooks().

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DISPATCH="$ROOT/scripts/monitoring/eos-telemetry-dispatch.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

HOME_DIR="$TMP/home"
mkdir -p "$HOME_DIR"

init_managed_repo() {
  local dir="$1"
  mkdir -p "$dir/.engineering-os"
  git init -q "$dir"
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name test
  git -C "$dir" commit -q --allow-empty -m init
  cat > "$dir/.engineering-os/telemetry-policy.json" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"disabled"}}
JSON
}

# A repo with a valid marker AND its own already-working project-local
# hooks (simulates a repo that had install-policy-gates.sh run in it).
init_managed_repo "$HOME_DIR/self-sufficient-repo"
mkdir -p "$HOME_DIR/self-sufficient-repo/.claude"
cat > "$HOME_DIR/self-sufficient-repo/.claude/settings.json" <<JSON
{"hooks": {"SessionStart": [{"hooks": [{"type": "command", "command": "bash \"$ROOT/scripts/monitoring/eos-telemetry-session-start.sh\""}]}]}}
JSON

# A sibling repo with a valid marker but no project-local hooks of its own —
# this is the actual case the dispatcher exists for.
init_managed_repo "$HOME_DIR/sibling-needs-dispatcher"

SESSION_ID="coexistence-test-$$"
PAYLOAD=$(python3 -c "import json; print(json.dumps({'session_id': '$SESSION_ID', 'cwd': '$HOME_DIR', 'hook_event_name': 'SessionStart'}))")
printf '%s' "$PAYLOAD" | HOME="$HOME_DIR" EOS_DISPATCH_HOME="$HOME_DIR" bash "$DISPATCH" session_start

if [ -f "$HOME_DIR/self-sufficient-repo/.engineering-os/telemetry/run_id" ]; then
  echo "ERROR_FOR_AGENT: dispatcher recorded into a repo that already has its own project-local hooks — this would double-record every event in a real session" >&2
  exit 1
fi

if [ ! -f "$HOME_DIR/sibling-needs-dispatcher/.engineering-os/telemetry/run_id" ]; then
  echo "ERROR_FOR_AGENT: dispatcher must still record normally for a repo with no project-local hooks of its own" >&2
  exit 1
fi

echo 'dispatch/project-local coexistence test passed: self-sufficient repo skipped (no double-recording), sibling repo still dispatched to normally'
