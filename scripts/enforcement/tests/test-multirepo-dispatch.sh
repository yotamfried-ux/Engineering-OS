#!/usr/bin/env bash
set -euo pipefail

# Covers Route Plan .claude/plans/remote-multirepo-telemetry-hooks.md, Test Plan
# scenarios B (discovery from a parent directory), D (per-event attribution),
# E (multi-repository session isolation), and H (remote-like smoke test —
# explicitly a simulation, not proof of a real Claude Code Remote host; see
# the Route Plan's "Real Claude Code Remote experiment" section for the live
# closure condition this test does not and cannot provide).

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

init_managed_repo "$HOME_DIR/project-8" "required"
init_managed_repo "$HOME_DIR/Engineering-OS" "disabled"

mkdir -p "$HOME_DIR/unrelated-repo"
git init -q "$HOME_DIR/unrelated-repo"

mkdir -p "$HOME_DIR/random-folder"
echo "not a repo" > "$HOME_DIR/random-folder/note.txt"

SESSION_ID="test-session-$$"

dispatch() {
  local event="$1" cwd="$2" extra_json="${3:-}"
  python3 -c "
import json
payload = {'session_id': '$SESSION_ID', 'cwd': '$cwd', 'hook_event_name': '$event'}
extra = json.loads('''$extra_json''') if '''$extra_json''' else {}
payload.update(extra)
print(json.dumps(payload))
" | HOME="$HOME_DIR" EOS_DISPATCH_HOME="$HOME_DIR" bash "$DISPATCH" "$event" >/dev/null
}

# SessionStart from the parent directory (simulates a Claude Code Remote
# session whose cwd is /home/user, not any single repo root).
dispatch session_start "$HOME_DIR"

for repo in project-8 Engineering-OS; do
  [ -s "$HOME_DIR/$repo/.engineering-os/telemetry/run_id" ] || {
    echo "ERROR_FOR_AGENT: expected run_id for managed repo $repo after SessionStart" >&2
    exit 1
  }
done

for unmanaged in unrelated-repo random-folder; do
  [ -e "$HOME_DIR/$unmanaged/.engineering-os" ] && {
    echo "ERROR_FOR_AGENT: unmanaged directory $unmanaged was touched by discovery" >&2
    exit 1
  }
done

# Tier-1 attribution: explicit file path inside project-8.
dispatch post_tool_use "$HOME_DIR" '{"tool_name": "Read", "tool_input": {"file_path": "'"$HOME_DIR"'/project-8/src/x.py"}}'

# Tier-2 attribution: Bash with an explicit cwd inside Engineering-OS.
dispatch post_tool_use "$HOME_DIR/Engineering-OS" '{"tool_name": "Bash", "tool_input": {"command": "npm test"}}'

# Ambiguous Bash from the parent dir with 2 discovered repos -> must be
# unattributed, must NOT land in either repo's bundle.
dispatch post_tool_use "$HOME_DIR" '{"tool_name": "Bash", "tool_input": {"command": "ls"}}'

python3 - "$HOME_DIR" <<'PY'
import json
import sys
from pathlib import Path

home = Path(sys.argv[1])

def events(repo):
    path = home / repo / ".engineering-os" / "telemetry" / "events.jsonl"
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]

p8 = events("project-8")
eos = events("Engineering-OS")

p8_names = [e["attributes"]["eos.event.name"] for e in p8]
eos_names = [e["attributes"]["eos.event.name"] for e in eos]

assert p8_names == ["session_start", "post_tool_use"], p8_names
assert eos_names == ["session_start", "post_tool_use"], eos_names

p8_tool = p8[1]["attributes"].get("eos.tool.name")
eos_tool = eos[1]["attributes"].get("eos.tool.name")
assert p8_tool == "Read", p8_tool
assert eos_tool == "Bash", eos_tool

# Isolation: neither repo's bundle contains the other's tool event, and the
# ambiguous Bash from the parent dir landed in neither.
assert len(p8) == 2, "project-8 must not have received the unattributed/ambiguous event"
assert len(eos) == 2, "Engineering-OS must not have received the unattributed/ambiguous event"

# Both repos share one host correlation id, but each keeps its own run_id.
p8_run_id = (home / "project-8" / ".engineering-os" / "telemetry" / "run_id").read_text().strip()
eos_run_id = (home / "Engineering-OS" / ".engineering-os" / "telemetry" / "run_id").read_text().strip()
assert p8_run_id != eos_run_id, "each repo must keep its own independent run_id"

corr_p8 = p8[0]["attributes"].get("eos.session.host_correlation_id")
corr_eos = eos[0]["attributes"].get("eos.session.host_correlation_id")
assert corr_p8 and corr_p8 == corr_eos, (corr_p8, corr_eos)

unattributed_log = home / ".engineering-os" / "telemetry" / "unattributed.jsonl"
assert unattributed_log.is_file(), "ambiguous event must be logged as unattributed, not silently dropped"
rows = [json.loads(line) for line in unattributed_log.read_text().splitlines() if line.strip()]
assert len(rows) == 1, rows
assert "command" not in json.dumps(rows[0]), "unattributed diagnostic must not contain raw command text"

print("multirepo dispatch smoke test: discovery, isolation, attribution, unattributed handling all verified")
PY

echo 'multirepo telemetry dispatch tests passed (simulation — see test header for real-Remote-experiment scope note)'
