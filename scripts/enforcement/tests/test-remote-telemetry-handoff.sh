#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SESSION_START="$ROOT/scripts/monitoring/eos-telemetry-session-start.sh"
RECORDER="$ROOT/scripts/monitoring/eos-telemetry-event.sh"
BOUNDARY="$ROOT/scripts/monitoring/record-and-sync-telemetry.sh"
REQUIRE="$ROOT/scripts/monitoring/require-telemetry-session.sh"
SELECT="$ROOT/scripts/monitoring/select-pr-telemetry.py"
COLLECT="$ROOT/scripts/monitoring/collect-pr-work-history.py"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
REMOTE="$TMP/remote.git"; TARGET="$TMP/target"
git init --bare -q "$REMOTE"
git init -q "$TARGET"
git -C "$TARGET" config user.email telemetry@example.invalid
git -C "$TARGET" config user.name telemetry
printf 'base\n' > "$TARGET/README.md"
git -C "$TARGET" add README.md && git -C "$TARGET" commit -qm base
git -C "$TARGET" branch -M feature/test
BASE="$(git -C "$TARGET" rev-parse HEAD)"
printf 'change\n' > "$TARGET/app.txt"
git -C "$TARGET" add app.txt && git -C "$TARGET" commit -qm change
HEAD="$(git -C "$TARGET" rev-parse HEAD)"
git -C "$TARGET" remote add origin "$REMOTE"
git -C "$TARGET" push -q -u origin feature/test
mkdir -p "$TARGET/.engineering-os" "$TARGET/.claude"
cat > "$TARGET/.engineering-os/telemetry-policy.json" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"required","remote":"origin","branch":"engineering-os-telemetry"}}
JSON
cat > "$TARGET/.claude/settings.json" <<JSON
{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash $SESSION_START"}]}],"PreToolUse":[{"matcher":".*","hooks":[{"type":"command","command":"bash $REQUIRE"},{"type":"command","command":"bash $RECORDER pre_tool_use"}]}],"PostToolUse":[{"matcher":".*","hooks":[{"type":"command","command":"bash $RECORDER post_tool_use"}]}],"Stop":[{"hooks":[{"type":"command","command":"bash $BOUNDARY stop"}]}]}}
JSON

export EOS_TELEMETRY_HANDOFF_DISPATCH=0
printf '%s' '{"session_id":"remote-session","hook_event_name":"SessionStart"}' | (cd "$TARGET" && bash "$SESSION_START")
(cd "$TARGET" && EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" bash "$REQUIRE") >/dev/null
RUN_ID="$(cat "$TARGET/.engineering-os/telemetry/run_id")"
git --git-dir="$REMOTE" show-ref --verify --quiet refs/heads/engineering-os-telemetry
printf '%s' '{"session_id":"remote-session","hook_event_name":"Stop"}' | (cd "$TARGET" && bash "$BOUNDARY" stop)
(cd "$TARGET" && EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" bash "$REQUIRE") >/dev/null

HANDOFF="$TMP/handoff"
git clone -q --branch engineering-os-telemetry "$REMOTE" "$HANDOFF"
SELECTED="$TMP/selected"
python3 "$SELECT" --root "$TARGET" --handoff-root "$HANDOFF" --repo target --pr-number 0 --head-ref feature/test --head-sha "$HEAD" --out "$SELECTED" >/dev/null
python3 - "$SELECTED" "$RUN_ID" <<'PY'
import json, sys
from pathlib import Path
bundle=Path(sys.argv[1]); run_id=sys.argv[2]
m=json.loads((bundle/'manifest.json').read_text())
rows=[json.loads(x) for x in (bundle/'events.jsonl').read_text().splitlines() if x.strip()]
assert m['event_count']==len(rows)>=2
assert all(x['trace_id']==run_id for x in rows)
assert m['handoff']['boundary_position']==len(rows)
raw=(bundle/'events.jsonl').read_text()
assert '"eos.git.branch"' not in raw
assert 'eos.git.branch.hash' in raw
PY

for bad in \
  "--repo target --pr-number 9 --head-ref feature/test --head-sha $HEAD" \
  "--repo target --pr-number 0 --head-ref other --head-sha $HEAD" \
  "--repo target --pr-number 0 --head-ref feature/test --head-sha 0000000000000000000000000000000000000000"; do
  if python3 "$SELECT" --root "$TARGET" --handoff-root "$HANDOFF" $bad --out "$TMP/bad" >/dev/null 2>&1; then
    echo "unexpected pass: mismatched bundle $bad"; exit 1
  fi
done

cp -R "$HANDOFF" "$TMP/corrupt"
printf 'tamper\n' >> "$TMP/corrupt/runs/$RUN_ID/events.jsonl"
if python3 "$SELECT" --root "$TARGET" --handoff-root "$TMP/corrupt" --repo target --pr-number 0 --head-ref feature/test --head-sha "$HEAD" --out "$TMP/bad" >/dev/null 2>&1; then
  echo 'unexpected pass: checksum mismatch'; exit 1
fi

CHECKOUT="$TMP/checkout"
git clone -q "$REMOTE" "$CHECKOUT"
git -C "$CHECKOUT" checkout -q feature/test
cat > "$TMP/body.md" <<'MD'
## Operational Work History Evidence
selected_result_loop_contract: booking-system
MD
python3 "$COLLECT" --root "$CHECKOUT" --pr-head-sha "$HEAD" --base-sha "$BASE" --pr-number 1 \
  --pr-body-file "$TMP/body.md" --telemetry-file "$SELECTED/events.jsonl" --out "$TMP/work-history" >/dev/null
python3 - "$TMP/work-history/latest.json" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))
assert r['telemetry_available'] is True
assert r['telemetry_events_count'] >= 2
PY

rm -f "$TARGET/.engineering-os/telemetry/handoff-state.json"
if (cd "$TARGET" && EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" bash "$REQUIRE") >/dev/null 2>&1; then
  echo 'unexpected pass: missing durable handoff state'; exit 1
fi

echo 'remote telemetry handoff tests passed'
