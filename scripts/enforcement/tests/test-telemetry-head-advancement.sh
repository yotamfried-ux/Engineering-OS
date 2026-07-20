#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SYNC="$ROOT/scripts/monitoring/sync-telemetry-run.py"
REQUIRE="$ROOT/scripts/monitoring/require-telemetry-session.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
REMOTE="$TMP/remote.git"
TARGET="$TMP/target"
REPO="example/head-target"

export GITHUB_REPOSITORY="$REPO"
export EOS_TELEMETRY_HANDOFF_DISPATCH=0
export EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json"

git init --bare -q "$REMOTE"
git init -q "$TARGET"
git -C "$TARGET" config user.email telemetry@example.invalid
git -C "$TARGET" config user.name telemetry
printf 'base\n' > "$TARGET/README.md"
git -C "$TARGET" add README.md
git -C "$TARGET" commit -qm base
git -C "$TARGET" branch -M feature/head-advance
git -C "$TARGET" remote add origin "$REMOTE"
git -C "$TARGET" push -q -u origin feature/head-advance
OLD_HEAD="$(git -C "$TARGET" rev-parse HEAD)"

mkdir -p "$TARGET/.engineering-os/telemetry" "$TARGET/.claude"
printf '%s\n' 'head-run' > "$TARGET/.engineering-os/telemetry/run_id"
cat > "$TARGET/.engineering-os/telemetry/events.jsonl" <<'JSON'
{"name":"eos.session_start","trace_id":"head-run","attributes":{"eos.event.name":"session_start"}}
JSON
cat > "$TARGET/.engineering-os/telemetry-policy.json" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"required","remote":"origin","branch":"engineering-os-telemetry"}}
JSON
cat > "$EOS_CLAUDE_SETTINGS_FILE" <<'JSON'
{"hooks":{"SessionStart":[{"hooks":[{"command":"eos-telemetry-session-start.sh"}]}],"PreToolUse":[{"hooks":[{"command":"require-telemetry-session.sh"},{"command":"eos-telemetry-event.sh pre_tool_use"}]}],"Stop":[{"hooks":[{"command":"record-and-sync-telemetry.sh stop"}]}],"StopFailure":[{"hooks":[{"command":"record-and-sync-telemetry.sh stop_failure"}]}],"SessionEnd":[{"hooks":[{"command":"record-and-sync-telemetry.sh session_end"}]}]}}
JSON

(
  cd "$TARGET"
  python3 "$SYNC" --repo "$REPO" >/dev/null
  bash "$REQUIRE" >/dev/null
)

printf 'new head\n' > "$TARGET/change.txt"
git -C "$TARGET" add change.txt
git -C "$TARGET" commit -qm 'advance product head'
NEW_HEAD="$(git -C "$TARGET" rev-parse HEAD)"

if (
  cd "$TARGET"
  bash "$REQUIRE" >/dev/null 2>&1
); then
  echo 'unexpected pass: old durable state accepted after head advance'; exit 1
fi

(
  cd "$TARGET"
  python3 "$SYNC" --repo "$REPO" >/dev/null
  bash "$REQUIRE" >/dev/null
)

HANDOFF="$TMP/handoff"
git clone -q --branch engineering-os-telemetry "$REMOTE" "$HANDOFF"
python3 - "$HANDOFF/runs/head-run/manifest.json" "$NEW_HEAD" <<'PY'
import json,sys
manifest=json.load(open(sys.argv[1]))
assert manifest['head_sha']==sys.argv[2]
assert manifest['handoff']['head_sha']==sys.argv[2]
assert manifest['event_count']==1
PY

git -C "$TARGET" reset -q --hard "$OLD_HEAD"
if (
  cd "$TARGET"
  python3 "$SYNC" --repo "$REPO" >/dev/null 2>&1
); then
  echo 'unexpected pass: stale product head downgraded remote telemetry'; exit 1
fi

git -C "$TARGET" reset -q --hard "$NEW_HEAD"
(
  cd "$TARGET"
  bash "$REQUIRE" >/dev/null
)

echo 'telemetry head advancement tests passed'
