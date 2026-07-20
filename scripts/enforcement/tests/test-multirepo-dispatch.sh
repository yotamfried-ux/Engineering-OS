#!/usr/bin/env bash
set -euo pipefail

# Remote-like simulation for parent-directory discovery, per-repository
# attribution, explicit GitHub/MCP repository routing, isolation, and
# privacy-safe unattributed diagnostics. This is not a live Remote-host proof.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DISPATCH="$ROOT/scripts/monitoring/eos-telemetry-dispatch.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

HOME_DIR="$TMP/home"
mkdir -p "$HOME_DIR"

init_managed_repo() {
  local dir="$1" mode="$2"
  local repo_name
  repo_name="$(basename "$dir")"
  mkdir -p "$dir/.engineering-os"
  git init -q "$dir"
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name test
  git -C "$dir" commit -q --allow-empty -m init
  git -C "$dir" remote add origin "https://github.com/yotamfried-ux/$repo_name.git"
  cat > "$dir/.engineering-os/telemetry-policy.json" <<JSON
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"$mode","remote":"origin","branch":"engineering-os-telemetry"}}
JSON
}

init_managed_repo "$HOME_DIR/project-8" required
init_managed_repo "$HOME_DIR/Engineering-OS" disabled
mkdir -p "$HOME_DIR/unrelated-repo" "$HOME_DIR/random-folder"
git init -q "$HOME_DIR/unrelated-repo"
echo harmless > "$HOME_DIR/random-folder/note.txt"

SESSION_ID="test-session-$$"
dispatch() {
  local event="$1" cwd="$2" extra_json="${3:-}"
  python3 -c "
import json
payload = {'session_id':'$SESSION_ID','cwd':'$cwd','hook_event_name':'$event'}
extra = json.loads('''$extra_json''') if '''$extra_json''' else {}
payload.update(extra)
print(json.dumps(payload))
" | HOME="$HOME_DIR" EOS_DISPATCH_HOME="$HOME_DIR" \
    EOS_DISPATCH_CACHE_DIR="$HOME_DIR/.dispatch-cache" \
    bash "$DISPATCH" "$event" >/dev/null
}

# Parent-started SessionStart discovers both managed siblings only.
dispatch session_start "$HOME_DIR"
for repo in project-8 Engineering-OS; do
  [ -s "$HOME_DIR/$repo/.engineering-os/telemetry/run_id" ] || {
    echo "ERROR_FOR_AGENT: missing run_id for managed repository $repo" >&2
    exit 1
  }
done
for unmanaged in unrelated-repo random-folder; do
  [ ! -e "$HOME_DIR/$unmanaged/.engineering-os" ] || {
    echo "ERROR_FOR_AGENT: unmanaged directory $unmanaged was touched" >&2
    exit 1
  }
done

# Explicit path and cwd attribution.
dispatch post_tool_use "$HOME_DIR" '{"tool_name":"Read","tool_input":{"file_path":"'"$HOME_DIR"'/project-8/src/x.py"}}'
dispatch post_tool_use "$HOME_DIR/Engineering-OS" '{"tool_name":"Bash","tool_input":{"command":"npm test"}}'

# Explicit GitHub repository identifier disambiguates a parent-cwd event.
dispatch post_tool_use "$HOME_DIR" '{"tool_name":"mcp__github__fetch_pr","tool_input":{"repository_full_name":"yotamfried-ux/project-8","pr_number":9}}'

# Both an ambiguous parent-cwd Bash event and an explicit unmanaged path must
# remain unattributed. The single-repo fallback may never override an explicit
# out-of-repository path/cwd signal.
dispatch post_tool_use "$HOME_DIR" '{"tool_name":"Bash","tool_input":{"command":"ls"}}'
dispatch post_tool_use "$HOME_DIR" '{"tool_name":"Read","tool_input":{"file_path":"'"$HOME_DIR"'/random-folder/note.txt"}}'

python3 - "$HOME_DIR" <<'PY'
import json
import sys
from pathlib import Path

home = Path(sys.argv[1])

def events(repo: str):
    path = home / repo / ".engineering-os" / "telemetry" / "events.jsonl"
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]

p8 = events("project-8")
eos = events("Engineering-OS")
p8_names = [row["attributes"]["eos.event.name"] for row in p8]
eos_names = [row["attributes"]["eos.event.name"] for row in eos]
assert p8_names == ["session_start", "post_tool_use", "post_tool_use"], p8_names
assert eos_names == ["session_start", "post_tool_use"], eos_names
assert p8[1]["attributes"].get("eos.tool.name") == "Read", p8[1]
assert p8[2]["attributes"].get("eos.tool.name") == "mcp__github__fetch_pr", p8[2]
assert eos[1]["attributes"].get("eos.tool.name") == "Bash", eos[1]

p8_run = (home / "project-8" / ".engineering-os" / "telemetry" / "run_id").read_text().strip()
eos_run = (home / "Engineering-OS" / ".engineering-os" / "telemetry" / "run_id").read_text().strip()
assert p8_run and eos_run and p8_run != eos_run
corr_p8 = p8[0]["attributes"].get("eos.session.host_correlation_id")
corr_eos = eos[0]["attributes"].get("eos.session.host_correlation_id")
assert corr_p8 and corr_p8 == corr_eos, (corr_p8, corr_eos)

unattributed = home / ".engineering-os" / "telemetry" / "unattributed.jsonl"
rows = [json.loads(line) for line in unattributed.read_text().splitlines() if line.strip()]
assert len(rows) == 2, rows
serialized = json.dumps(rows)
for forbidden in ("command", "file_path", "random-folder", "note.txt"):
    assert forbidden not in serialized, (forbidden, serialized)

assert not (home / "unrelated-repo" / ".engineering-os").exists()
assert not (home / "random-folder" / ".engineering-os").exists()
print("multirepo dispatch verified: discovery, path/cwd/repo-id attribution, isolation, and unmanaged exclusion")
PY

echo 'multirepo telemetry dispatch tests passed (simulation; fresh Remote validation remains separate)'
