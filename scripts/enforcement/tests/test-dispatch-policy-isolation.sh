#!/usr/bin/env bash
set -euo pipefail

# Covers Route Plan scenario F: required/best_effort/disabled repositories keep
# independent local state and handoff semantics within one dispatched session.

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

init_managed_repo "$HOME_DIR/repo-required" required
init_managed_repo "$HOME_DIR/repo-best-effort" best_effort
init_managed_repo "$HOME_DIR/repo-disabled" disabled

SESSION_ID="policy-isolation-$$"
PAYLOAD=$(python3 -c "import json; print(json.dumps({'session_id':'$SESSION_ID','cwd':'$HOME_DIR','hook_event_name':'SessionStart'}))")
printf '%s' "$PAYLOAD" | HOME="$HOME_DIR" EOS_DISPATCH_HOME="$HOME_DIR" \
  EOS_DISPATCH_CACHE_DIR="$HOME_DIR/.dispatch-cache" bash "$DISPATCH" session_start

# Policy mode affects handoff, not local initialization. Every managed repo gets
# independent state even though this fixture intentionally has no origin remote.
for repo in repo-required repo-best-effort repo-disabled; do
  [ -s "$HOME_DIR/$repo/.engineering-os/telemetry/run_id" ] || {
    echo "ERROR_FOR_AGENT: $repo did not get local telemetry state" >&2
    exit 1
  }
done

python3 - "$HOME_DIR" <<'PY'
import json
import sys
from pathlib import Path

home = Path(sys.argv[1])
for repo in ("repo-required", "repo-best-effort", "repo-disabled"):
    events_path = home / repo / ".engineering-os" / "telemetry" / "events.jsonl"
    rows = [json.loads(line) for line in events_path.read_text().splitlines() if line.strip()]
    assert rows and rows[0]["attributes"]["eos.event.name"] == "session_start", (repo, rows)
PY

# A normal event attributed only to repo-required must not touch either sibling.
PRE_BEST_EFFORT=$(wc -l < "$HOME_DIR/repo-best-effort/.engineering-os/telemetry/events.jsonl")
PRE_DISABLED=$(wc -l < "$HOME_DIR/repo-disabled/.engineering-os/telemetry/events.jsonl")
PAYLOAD2=$(python3 -c "import json; print(json.dumps({'session_id':'$SESSION_ID','cwd':'$HOME_DIR/repo-required','hook_event_name':'PostToolUse','tool_name':'Bash','tool_input':{'command':'npm test'}}))")
printf '%s' "$PAYLOAD2" | HOME="$HOME_DIR" EOS_DISPATCH_HOME="$HOME_DIR" \
  EOS_DISPATCH_CACHE_DIR="$HOME_DIR/.dispatch-cache" bash "$DISPATCH" post_tool_use
POST_BEST_EFFORT=$(wc -l < "$HOME_DIR/repo-best-effort/.engineering-os/telemetry/events.jsonl")
POST_DISABLED=$(wc -l < "$HOME_DIR/repo-disabled/.engineering-os/telemetry/events.jsonl")
[ "$PRE_BEST_EFFORT" -eq "$POST_BEST_EFFORT" ] || { echo "ERROR_FOR_AGENT: required event leaked into best-effort repo" >&2; exit 1; }
[ "$PRE_DISABLED" -eq "$POST_DISABLED" ] || { echo "ERROR_FOR_AGENT: required event leaked into disabled repo" >&2; exit 1; }

# Boundary fan-out must visit every repository but retain a required handoff
# failure. Without this assertion, `|| true` could silently convert an absent
# required durable handoff into session success.
PAYLOAD_STOP=$(python3 -c "import json; print(json.dumps({'session_id':'$SESSION_ID','cwd':'$HOME_DIR','hook_event_name':'Stop'}))")
set +e
printf '%s' "$PAYLOAD_STOP" | HOME="$HOME_DIR" EOS_DISPATCH_HOME="$HOME_DIR" \
  EOS_DISPATCH_CACHE_DIR="$HOME_DIR/.dispatch-cache" bash "$DISPATCH" stop \
  >"$TMP/stop.out" 2>"$TMP/stop.err"
STOP_STATUS=$?
set -e
[ "$STOP_STATUS" -ne 0 ] || {
  echo "ERROR_FOR_AGENT: required boundary handoff failure was swallowed" >&2
  exit 1
}

python3 - "$HOME_DIR" <<'PY'
import json
import sys
from pathlib import Path

home = Path(sys.argv[1])
for repo in ("repo-required", "repo-best-effort", "repo-disabled"):
    events_path = home / repo / ".engineering-os" / "telemetry" / "events.jsonl"
    rows = [json.loads(line) for line in events_path.read_text().splitlines() if line.strip()]
    names = [row["attributes"]["eos.event.name"] for row in rows]
    assert "stop" in names, (repo, names)
PY

echo 'policy isolation test passed: independent state, no event leakage, and required boundary failure propagation after full fan-out'
