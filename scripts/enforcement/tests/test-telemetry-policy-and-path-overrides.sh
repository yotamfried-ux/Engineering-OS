#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SYNC="$ROOT/scripts/monitoring/sync-telemetry-run.py"
REQUIRE="$ROOT/scripts/monitoring/require-telemetry-session.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
REMOTE="$TMP/remote.git"
TARGET="$TMP/target"
CUSTOM="$TMP/custom-telemetry"
REPO="example/policy-target"

export GITHUB_REPOSITORY="$REPO"
export EOS_TELEMETRY_HANDOFF_DISPATCH=0
export EOS_TELEMETRY_FILE="$CUSTOM/events.jsonl"
export EOS_TELEMETRY_RUN_ID_FILE="$CUSTOM/run_id"
export EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json"

git init --bare -q "$REMOTE"
git init -q "$TARGET"
git -C "$TARGET" config user.email telemetry@example.invalid
git -C "$TARGET" config user.name telemetry
printf 'base\n' > "$TARGET/README.md"
git -C "$TARGET" add README.md
git -C "$TARGET" commit -qm base
git -C "$TARGET" remote add origin "$REMOTE"

mkdir -p "$CUSTOM" "$TARGET/.engineering-os" "$TARGET/.claude"
printf '%s\n' 'override-run' > "$EOS_TELEMETRY_RUN_ID_FILE"
cat > "$EOS_TELEMETRY_FILE" <<'JSON'
{"name":"eos.session_start","trace_id":"override-run","attributes":{"eos.event.name":"session_start","eos.git.branch.hash":"11111111111111111111111111111111"}}
JSON
cat > "$EOS_CLAUDE_SETTINGS_FILE" <<'JSON'
{"hooks":{"SessionStart":[{"hooks":[{"command":"eos-telemetry-session-start.sh"}]}],"PreToolUse":[{"hooks":[{"command":"require-telemetry-session.sh"},{"command":"eos-telemetry-event.sh"}]}],"Stop":[{"hooks":[{"command":"record-and-sync-telemetry.sh"}]}]}}
JSON
cat > "$TARGET/.engineering-os/telemetry-policy.json" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"required","remote":"origin","branch":"engineering-os-telemetry"}}
JSON

(
  cd "$TARGET"
  python3 "$SYNC" --repo "$REPO" >/dev/null
)

[ ! -e "$TARGET/.engineering-os/telemetry/events.jsonl" ] || {
  echo 'unexpected default telemetry events file'; exit 1;
}
[ ! -e "$TARGET/.engineering-os/telemetry/run_id" ] || {
  echo 'unexpected default telemetry run_id file'; exit 1;
}
git --git-dir="$REMOTE" show-ref --verify --quiet refs/heads/engineering-os-telemetry
python3 - "$TARGET/.engineering-os/telemetry/handoff-state.json" "$REPO" <<'PY'
import json,sys
state=json.load(open(sys.argv[1]))
assert state['repo']==sys.argv[2]
assert state['event_count']==1
assert state['boundary_position']==1
assert state['remote_branch']=='engineering-os-telemetry'
assert state['remote_commit']
PY

rm -f "$TARGET/.engineering-os/telemetry/handoff-state.json"
cat > "$TARGET/.engineering-os/telemetry-policy.json" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"best_effort","remote":"origin","branch":"engineering-os-telemetry"}}
JSON
(
  cd "$TARGET"
  bash "$REQUIRE" >/dev/null
)

cat > "$TARGET/.engineering-os/telemetry-policy.json" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"required","remote":"origin","branch":"engineering-os-telemetry"}}
JSON
if (
  cd "$TARGET"
  bash "$REQUIRE" >/dev/null 2>&1
); then
  echo 'unexpected pass: required mode without durable state'; exit 1
fi

echo 'telemetry policy and path override tests passed'
