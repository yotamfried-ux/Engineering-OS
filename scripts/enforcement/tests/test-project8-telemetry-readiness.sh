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
blockcase() {
  local name="$1"; shift
  set +e
  "$@" >/dev/null 2>&1
  local rc=$?
  set -e
  if [ "$rc" -ne 2 ]; then
    echo "fail: $name expected exit 2, got $rc"
    exit 1
  fi
  echo "ok: $name"
}

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
pass settings_has_prompt_event grep -q 'user_prompt_submit' "$TARGET/.claude/settings.json"
pass settings_has_failure_event grep -q 'post_tool_use_failure' "$TARGET/.claude/settings.json"
pass settings_has_instruction_event grep -q 'instructions_loaded' "$TARGET/.claude/settings.json"
pass settings_rendered_to_reference grep -q "$ROOT/scripts/monitoring" "$TARGET/.claude/settings.json"

EVENTS="$TARGET/.engineering-os/telemetry/events.jsonl"
RUN_ID="$TARGET/.engineering-os/telemetry/run_id"
SUMMARY="$TARGET/.engineering-os/telemetry/latest-summary.md"
SEED="stable-process-level-seed"

blockcase preflight_blocks_before_session bash -c "cd '$TARGET' && EOS_CLAUDE_SETTINGS_FILE='$TARGET/.claude/settings.json' EOS_TELEMETRY_FILE='$EVENTS' EOS_TELEMETRY_RUN_ID_FILE='$RUN_ID' bash '$REQUIRE'"
blockcase preflight_blocks_when_disabled bash -c "cd '$TARGET' && EOS_TELEMETRY_DISABLED=1 EOS_CLAUDE_SETTINGS_FILE='$TARGET/.claude/settings.json' EOS_TELEMETRY_FILE='$EVENTS' EOS_TELEMETRY_RUN_ID_FILE='$RUN_ID' bash '$REQUIRE'"

printf '%s' '{"session_id":"first-session","hook_event_name":"SessionStart","source":"startup","model":"claude-test"}' | \
  (cd "$TARGET" && EOS_TELEMETRY_RUN_ID="$SEED" EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" \
  EOS_TELEMETRY_FILE="$EVENTS" EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID" EOS_TELEMETRY_SUMMARY_FILE="$SUMMARY" \
  bash "$SESSION_START")
first_run="$(cat "$RUN_ID")"
pass preflight_detects_soft_wrapped_recorder bash -c "cd '$TARGET' && EOS_CLAUDE_SETTINGS_FILE='$TARGET/.claude/settings.json' EOS_TELEMETRY_FILE='$EVENTS' EOS_TELEMETRY_RUN_ID_FILE='$RUN_ID' bash '$REQUIRE'"

DIRECT_SETTINGS="$TMP/direct-settings.json"
python3 - "$TARGET/.claude/settings.json" "$DIRECT_SETTINGS" "$RECORDER" <<'PY_DIRECT'
import json, sys
src, dst, recorder = sys.argv[1:]
data = json.load(open(src, encoding='utf-8'))
replaced = False
for block in data.get('hooks', {}).get('PreToolUse', []):
    if block.get('matcher') not in (None, '.*'):
        continue
    for hook in block.get('hooks', []):
        command = hook.get('command', '') if isinstance(hook, dict) else ''
        if 'eos-telemetry-event.sh' in command and 'pre_tool_use' in command:
            hook['command'] = f'bash "{recorder}" pre_tool_use'
            replaced = True
if not replaced:
    raise SystemExit('soft-wrapped pre_tool_use recorder was not found')
json.dump(data, open(dst, 'w', encoding='utf-8'), indent=2)
PY_DIRECT
pass preflight_detects_direct_recorder bash -c "cd '$TARGET' && EOS_CLAUDE_SETTINGS_FILE='$DIRECT_SETTINGS' EOS_TELEMETRY_FILE='$EVENTS' EOS_TELEMETRY_RUN_ID_FILE='$RUN_ID' bash '$REQUIRE'"

printf '%s' '{"session_id":"first-session","tool_name":"Bash","tool_input":{"command":"npm test"}}' | \
  (cd "$TARGET" && EOS_TELEMETRY_RUN_ID="$SEED" EOS_TELEMETRY_FILE="$EVENTS" EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID" bash "$RECORDER" post_tool_use)

PROMPT_SECRET="do-not-store-this-prompt-value"
printf '%s' "{\"session_id\":\"first-session\",\"prompt_id\":\"prompt-1\",\"hook_event_name\":\"UserPromptSubmit\",\"prompt\":\"$PROMPT_SECRET\"}" | \
  (cd "$TARGET" && EOS_TELEMETRY_RUN_ID="$SEED" EOS_TELEMETRY_FILE="$EVENTS" EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID" bash "$RECORDER" user_prompt_submit)

ERROR_SECRET="do-not-store-this-error-value"
printf '%s' "{\"session_id\":\"first-session\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"npm test\"},\"error\":\"$ERROR_SECRET\"}" | \
  (cd "$TARGET" && EOS_TELEMETRY_RUN_ID="$SEED" EOS_TELEMETRY_FILE="$EVENTS" EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID" bash "$RECORDER" post_tool_use_failure)

INSTRUCTION_PATH="/home/example/project/CLAUDE.md"
printf '%s' "{\"session_id\":\"first-session\",\"hook_event_name\":\"InstructionsLoaded\",\"file_path\":\"$INSTRUCTION_PATH\",\"memory_type\":\"Project\",\"load_reason\":\"session_start\"}" | \
  (cd "$TARGET" && EOS_TELEMETRY_RUN_ID="$SEED" EOS_TELEMETRY_FILE="$EVENTS" EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID" bash "$RECORDER" instructions_loaded)

python3 - "$EVENTS" "$first_run" "$PROMPT_SECRET" "$ERROR_SECRET" "$INSTRUCTION_PATH" <<'PY'
import json, sys
path, run_id, prompt_secret, error_secret, instruction_path = sys.argv[1:]
raw = open(path, encoding='utf-8').read()
assert prompt_secret not in raw, raw
assert error_secret not in raw, raw
assert instruction_path not in raw, raw
lines = [json.loads(x) for x in raw.splitlines() if x.strip()]
assert len(lines) == 5, lines
assert all(item['trace_id'] == run_id for item in lines), lines
by_name = {item['name']: item for item in lines}
prompt = by_name['eos.user_prompt_submit']['attributes']
assert prompt['eos.prompt.present'] is True
assert prompt['eos.prompt.hash']
assert prompt['eos.prompt.length_bucket'] != 'none'
failure = by_name['eos.post_tool_use_failure']['attributes']
assert failure['eos.tool.error.present'] is True
assert failure['eos.tool.error.hash']
instructions = by_name['eos.instructions_loaded']['attributes']
assert instructions['eos.claude.instruction.target']['present'] is True
assert instructions['eos.claude.instruction.target']['extension'] == '.md'
assert instructions['eos.claude.instruction.memory_type'] == 'Project'
assert instructions['eos.claude.instruction.load_reason'] == 'session_start'
PY
pass privacy_safe_lifecycle_events true
pass run_id_file_precedes_process_seed true

printf '%s' '{"session_id":"first-session","hook_event_name":"Stop"}' | \
  (cd "$TARGET" && EOS_TELEMETRY_RUN_ID="$SEED" EOS_TELEMETRY_FILE="$EVENTS" EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID" EOS_TELEMETRY_SUMMARY_FILE="$SUMMARY" bash "$RECORDER" stop)
pass stop_summary_created_without_home test -f "$SUMMARY"

printf '%s' '{"session_id":"second-session","hook_event_name":"SessionStart"}' | \
  (cd "$TARGET" && EOS_TELEMETRY_RUN_ID="$SEED" EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" \
  EOS_TELEMETRY_FILE="$EVENTS" EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID" EOS_TELEMETRY_SUMMARY_FILE="$SUMMARY" \
  bash "$SESSION_START")
second_run="$(cat "$RUN_ID")"
[ "$first_run" != "$second_run" ] || { echo "fail: session run id did not rotate with stable seed"; exit 1; }
pass previous_session_archived bash -c "find '$TARGET/.engineering-os/telemetry/history' -name events.jsonl -type f | grep -q ."
pass previous_summary_archived bash -c "find '$TARGET/.engineering-os/telemetry/history' -name latest-summary.md -type f | grep -q ."
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
  {"workflowName":"yaml-validation","status":"completed","conclusion":"startup_failure","headSha":"ccc","createdAt":"2026-07-10T10:30:00Z"},
  {"workflowName":"old-run","status":"completed","conclusion":"failure","headSha":"old","createdAt":"2026-07-01T10:00:00Z"}
]
JSON
python3 "$ENRICHER" --artifact "$ARTIFACT" --summary "$SUMMARY_FILE" --ci-history-json "$HISTORY" --since "2026-07-10T09:00:00Z" >/dev/null
python3 - "$ARTIFACT" <<'PY'
import json, sys
r = json.load(open(sys.argv[1]))
assert r['ci_history_runs_count'] == 4, r
assert r['ci_history_failure_count'] == 3, r
assert r['ci_history_failed_workflow_counts'] == {'enforcement-tests': 1, 'pr-policy': 1, 'yaml-validation': 1}, r
assert r['friction_signals']['ci_historical_failures'] == 3, r
assert r['friction_signals']['any'] is True, r
assert r['privacy_contract'] == 'metadata-only'
PY
pass historical_ci_friction_preserved true
pass startup_failure_friction_preserved true
pass summary_includes_history grep -q 'historical failing runs: 3' "$SUMMARY_FILE"

echo "project8 telemetry readiness tests passed"
