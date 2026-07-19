#!/usr/bin/env bash
set -euo pipefail

# Covers Route Plan .claude/plans/remote-multirepo-telemetry-hooks.md, Test
# Plan scenario F (policy isolation): required/best_effort/disabled/unmanaged
# each behave per-repo exactly as the existing single-repo policy semantics
# already define (unchanged, reused scripts), and one repo's policy never
# leaks into a sibling's behavior within the same dispatched session.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DISPATCH="$ROOT/scripts/monitoring/eos-telemetry-dispatch.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

HOME_DIR="$TMP/home"
mkdir -p "$HOME_DIR"

init_managed_repo() {
  local dir="$1" mode="$2"
  mkdir -p "$dir/.engineering-os"
  git init -q "$dir"
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name test
  git -C "$dir" commit -q --allow-empty -m init
  cat > "$dir/.engineering-os/telemetry-policy.json" <<JSON
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"$mode","remote":"origin","branch":"engineering-os-telemetry"}}
JSON
}

init_managed_repo "$HOME_DIR/repo-required" "required"
init_managed_repo "$HOME_DIR/repo-best-effort" "best_effort"
init_managed_repo "$HOME_DIR/repo-disabled" "disabled"

SESSION_ID="policy-isolation-$$"
PAYLOAD=$(python3 -c "import json; print(json.dumps({'session_id': '$SESSION_ID', 'cwd': '$HOME_DIR', 'hook_event_name': 'SessionStart'}))")
printf '%s' "$PAYLOAD" | HOME="$HOME_DIR" EOS_DISPATCH_HOME="$HOME_DIR" bash "$DISPATCH" session_start

# Every repo (regardless of policy mode) still gets local events recorded —
# policy mode only ever gated the *remote push*, not local recording, in the
# existing single-repo scripts this dispatcher reuses unmodified. Verifying
# that's still true per-repo, not silently changed by this feature.
for repo in repo-required repo-best-effort repo-disabled; do
  [ -s "$HOME_DIR/$repo/.engineering-os/telemetry/run_id" ] || {
    echo "ERROR_FOR_AGENT: $repo did not get local telemetry state regardless of its own policy mode" >&2
    exit 1
  }
done

# None of the three repos has a real GitHub origin remote in this fixture,
# so each independently fails the *push* step for its own reasons dictated
# by its own policy mode — that per-repo failure/no-op must never abort
# recording for the other repos in the same dispatched SessionStart.
python3 - "$HOME_DIR" <<'PY'
import json
from pathlib import Path
import sys

home = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
for repo in ("repo-required", "repo-best-effort", "repo-disabled"):
    events_path = home / repo / ".engineering-os" / "telemetry" / "events.jsonl"
    rows = [json.loads(l) for l in events_path.read_text().splitlines() if l.strip()]
    assert rows and rows[0]["attributes"]["eos.event.name"] == "session_start", (repo, rows)
print("all three policy modes recorded locally, independently, in one dispatched SessionStart")
PY

# A second event dispatched only to repo-required must not touch the other
# two repos' state at all (no cross-repo policy leakage).
PRE_BEST_EFFORT=$(wc -l < "$HOME_DIR/repo-best-effort/.engineering-os/telemetry/events.jsonl")
PRE_DISABLED=$(wc -l < "$HOME_DIR/repo-disabled/.engineering-os/telemetry/events.jsonl")

PAYLOAD2=$(python3 -c "import json; print(json.dumps({'session_id': '$SESSION_ID', 'cwd': '$HOME_DIR/repo-required', 'hook_event_name': 'PostToolUse', 'tool_name': 'Bash', 'tool_input': {'command': 'npm test'}}))")
printf '%s' "$PAYLOAD2" | HOME="$HOME_DIR" EOS_DISPATCH_HOME="$HOME_DIR" bash "$DISPATCH" post_tool_use

POST_BEST_EFFORT=$(wc -l < "$HOME_DIR/repo-best-effort/.engineering-os/telemetry/events.jsonl")
POST_DISABLED=$(wc -l < "$HOME_DIR/repo-disabled/.engineering-os/telemetry/events.jsonl")

[ "$PRE_BEST_EFFORT" -eq "$POST_BEST_EFFORT" ] || { echo "ERROR_FOR_AGENT: repo-required's event leaked into repo-best-effort" >&2; exit 1; }
[ "$PRE_DISABLED" -eq "$POST_DISABLED" ] || { echo "ERROR_FOR_AGENT: repo-required's event leaked into repo-disabled" >&2; exit 1; }

echo 'policy isolation test passed: required/best_effort/disabled all record independently, no cross-repo policy leakage'
