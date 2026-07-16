#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SYNC="$ROOT/scripts/monitoring/sync-telemetry-run.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
REMOTE="$TMP/remote.git"
TARGET="$TMP/target"
HANDOFF="$TMP/handoff"
REPO="example/progress-target"
RUN_ID="progress-run"

export GITHUB_REPOSITORY="$REPO"
export EOS_TELEMETRY_HANDOFF_DISPATCH=0
export EOS_TELEMETRY_PR_NUMBER=42

git init --bare -q "$REMOTE"
git init -q "$TARGET"
git -C "$TARGET" config user.email telemetry@example.invalid
git -C "$TARGET" config user.name telemetry
printf 'base\n' > "$TARGET/README.md"
git -C "$TARGET" add README.md
git -C "$TARGET" commit -qm base
git -C "$TARGET" branch -M feature/progress
git -C "$TARGET" remote add origin "$REMOTE"
git -C "$TARGET" push -q -u origin feature/progress

mkdir -p "$TARGET/.engineering-os/telemetry"
printf '%s\n' "$RUN_ID" > "$TARGET/.engineering-os/telemetry/run_id"
cat > "$TARGET/.engineering-os/telemetry-policy.json" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"required","remote":"origin","branch":"engineering-os-telemetry"}}
JSON
cat > "$TARGET/.engineering-os/telemetry/events.jsonl" <<JSON
{"name":"eos.session_start","trace_id":"$RUN_ID","attributes":{"eos.event.name":"session_start"}}
{"name":"eos.stop","trace_id":"$RUN_ID","attributes":{"eos.event.name":"stop"}}
{"name":"eos.post_tool_use","trace_id":"$RUN_ID","attributes":{"eos.event.name":"post_tool_use"}}
JSON

(
  cd "$TARGET"
  python3 "$SYNC" --repo "$REPO" >/dev/null
)
git clone -q --branch engineering-os-telemetry "$REMOTE" "$HANDOFF"
python3 - "$HANDOFF/runs/$RUN_ID/manifest.json" <<'PY'
import json
import sys
manifest = json.load(open(sys.argv[1]))
assert manifest["event_count"] == 3
assert manifest["handoff"]["boundary_position"] == 2
PY

# This local snapshot has more events but an older lifecycle boundary. It is
# incomparable with the remote bundle and must not be allowed to downgrade it.
cat > "$TARGET/.engineering-os/telemetry/events.jsonl" <<JSON
{"name":"eos.session_start","trace_id":"$RUN_ID","attributes":{"eos.event.name":"session_start"}}
{"name":"eos.post_tool_use","trace_id":"$RUN_ID","attributes":{"eos.event.name":"post_tool_use"}}
{"name":"eos.post_tool_use","trace_id":"$RUN_ID","attributes":{"eos.event.name":"post_tool_use"}}
{"name":"eos.post_tool_use","trace_id":"$RUN_ID","attributes":{"eos.event.name":"post_tool_use"}}
JSON
if (
  cd "$TARGET"
  python3 "$SYNC" --repo "$REPO" >/dev/null 2>&1
); then
  echo 'unexpected pass: incomparable local progress downgraded remote boundary'; exit 1
fi

git -C "$HANDOFF" pull -q
python3 - "$HANDOFF/runs/$RUN_ID/manifest.json" <<'PY'
import json
import sys
manifest = json.load(open(sys.argv[1]))
assert manifest["event_count"] == 3
assert manifest["handoff"]["boundary_position"] == 2
PY

echo 'telemetry progress ordering tests passed'
