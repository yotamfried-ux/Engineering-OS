#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INSTALLER="$ROOT/scripts/install-policy-gates.sh"
SESSION_START="$ROOT/scripts/monitoring/eos-telemetry-session-start.sh"
REQUIRE="$ROOT/scripts/monitoring/require-telemetry-session.sh"
RECORDER="$ROOT/scripts/monitoring/eos-telemetry-event.sh"
ENRICHER="$ROOT/scripts/monitoring/enrich-work-history-ci-history.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() { local name="$1"; shift; "$@" >/dev/null 2>&1 || { echo "fail: $name"; "$@"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "unexpected pass: $name"; exit 1; else echo "ok: $name"; fi; }

TARGET="$TMP/target"
mkdir -p "$TARGET"
git -C "$TARGET" init -q
git -C "$TARGET" config user.email telemetry@example.invalid
git -C "$TARGET" config user.name telemetry

ENGINEERING_OS_HOME="$ROOT" EOS_CONTRACT_TEST=1 bash "$INSTALLER" "$TARGET" >/dev/null
pass direct_install_creates_settings test -f "$TARGET/.claude/settings.json"
pass settings_has_session_start grep -q 'eos-telemetry-session-start.sh' "$TARGET/.claude/settings.json"
pass settings_has_recorder grep -q 'eos-telemetry-event.sh' "$TARGET/.claude/settings.json"
pass settings_has_preflight grep -q 'require-telemetry-session.sh' "$TARGET/.claude/settings.json"
pass settings_rendered_to_reference grep -q "$ROOT/scripts/monitoring" "$TARGET/.claude/settings.json"

EVENTS="$TARGET/.engineering-os/telemetry/events.jsonl"
RUN_ID="$TARGET/.engineering-os/telemetry/run_id"
SUMMARY="$TARGET/.engineering-os/telemetry/latest-summary.md"

failcase preflight_fails_before_session bash -c "cd '$TARGET' && EOS_CLAUDE_SETTINGS_FILE='$TARGET/.claude/settings.json' EOS_TELEMETRY_FILE='$EVENTS' EOS_TELEMETRY_RUN_ID_FILE='$RUN_ID' bash '$REQUIRE'"

printf '%s' '{"session_id":"first-session","hook_event_name":"SessionStart"}' | \
  (cd "$TARGET" && ENGINEERING_OS_HOME="$ROOT" EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" \
  EOS_TELEMETRY_FILE="$EVENTS" EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID" EOS_TELEMETRY_SUMMARY_FILE="$SUMMARY" \
  bash "$SESSION_START")
first_run="$(cat "$RUN_ID")"
pass preflight_passes_after_session bash -c "cd '$TARGET' && EOS_CLAUDE_SETTINGS_FILE='$TARGET/.claude/settings.json' EOS_TELEMETRY_FILE='$EVENTS' EOS_TELEMETRY_RUN_ID_FILE='$RUN_ID' bash '$REQUIRE'"

printf '%s' '{"tool_name":"Bash","tool_input":{"command":"npm test"}}' | \
  (cd "$TARGET" && ENGINEERING_OS_HOME="$ROOT" EOS_TELEMETRY_FILE="$EVENTS" EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID" bash "$RECORDER" post_tool_use_bash)

printf '%s' '{"session_id":"second-session","hook_event_name":"SessionStart"}' | \
  (cd "$TARGET" && ENGINEERING_OS_HOME="$ROOT" EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" \
  EOS_TELEMETRY_FILE="$EVENTS" EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID" EOS_TELEMETRY_SUMMARY_FILE="$SUMMARY" \
  bash "$SESSION_START")
second_run="$(cat "$RUN_ID")"
[ "$first_run" != "$second_run" ] || { echo "fail: session run id did not rotate"; exit 1; }
pass previous_session_archived bash -c "find '$TARGET/.engineering-os/telemetry/history' -name events.jsonl -type f | grep -q ."
python3 - "$EVENTS" "$second_run" <<'PY'
import json, sys
lines = [json.loads(x) for x in open(sys.argv[1]) if x.strip()]
assert len(lines) == 1, lines
assert lines[0]['trace_id'] == sys.argv[2]
assert lines[0]['name'] == 'eos.session_start'
PY
pass current_session_isolated true

CUSTOM="$TMP/custom"
mkdir -p "$CUSTOM/.claude"
git -C "$CUSTOM" init -q
cat > "$CUSTOM/.claude/settings.json" <<'JSON'
{"hooks":{"PreToolUse":[{"matcher":"CustomTool","hooks":[{"type":"command","command":"echo custom-hook"}]}]}}
JSON
ENGINEERING_OS_HOME="$ROOT" EOS_CONTRACT_TEST=1 EOS_SKIP_SETTINGS_PATCH=1 bash "$INSTALLER" "$CUSTOM" >/dev/null
pass custom_hook_preserved grep -q 'custom-hook' "$CUSTOM/.claude/settings.json"
pass custom_settings_receive_telemetry grep -q 'eos-telemetry-session-start.sh' "$CUSTOM/.claude/settings.json"
first_count="$(grep -o 'require-telemetry-session.sh' "$CUSTOM/.claude/settings.json" | wc -l | xargs)"
ENGINEERING_OS_HOME="$ROOT" EOS_CONTRACT_TEST=1 EOS_SKIP_SETTINGS_PATCH=1 bash "$INSTALLER" "$CUSTOM" >/dev/null
second_count="$(grep -o 'require-telemetry-session.sh' "$CUSTOM/.claude/settings.json" | wc -l | xargs)"
[ "$first_count" = "$second_count" ] || { echo "fail: telemetry patch duplicated hooks"; exit 1; }
pass telemetry_patch_idempotent true

ARTIFACT="$TMP/latest.json"
SUMMARY_FILE="$TMP/latest-summary.md"
HISTORY="$TMP/history.json"
cat > "$ARTIFACT" <<'JSON'
{"friction_signals":{"any":false},"privacy_contract":"metadata-only"}
JSON
printf '# Operational Work History Summary\n' > "$SUMMARY_FILE"
cat > "$HISTORY" <<'JSON'
[
  {"workflowName":"pr-policy","status":"completed","conclusion":"failure","headSha":"aaa","createdAt":"2026-07-10T10:00:00Z"},
  {"workflowName":"pr-policy","status":"completed","conclusion":"success","headSha":"aaa","createdAt":"2026-07-10T10:10:00Z"},
  {"workflowName":"enforcement-tests","status":"completed","conclusion":"failure","headSha":"bbb","createdAt":"2026-07-10T10:20:00Z"},
  {"workflowName":"old-run","status":"completed","conclusion":"failure","headSha":"old","createdAt":"2026-07-01T10:00:00Z"}
]
JSON
python3 "$ENRICHER" --artifact "$ARTIFACT" --summary "$SUMMARY_FILE" --ci-history-json "$HISTORY" --since "2026-07-10T09:00:00Z" >/dev/null
python3 - "$ARTIFACT" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
assert r['ci_history_runs_count'] == 3, r
assert r['ci_history_failure_count'] == 2, r
assert r['ci_history_failed_workflow_counts'] == {'enforcement-tests': 1, 'pr-policy': 1}, r
assert r['friction_signals']['ci_historical_failures'] == 2, r
assert r['friction_signals']['any'] is True, r
assert r['privacy_contract'] == 'metadata-only'
PY
pass historical_ci_friction_preserved true
pass summary_includes_history grep -q 'historical failing runs: 2' "$SUMMARY_FILE"

echo "project8 telemetry readiness tests passed"
