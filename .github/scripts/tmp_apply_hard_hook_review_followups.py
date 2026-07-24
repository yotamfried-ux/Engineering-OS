#!/usr/bin/env python3
from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    target = Path(path)
    text = target.read_text(encoding="utf-8")
    if old not in text:
        raise SystemExit(f"expected text not found in {path}: {old!r}")
    target.write_text(text.replace(old, new, 1), encoding="utf-8")


# Validate only the requested direct unit during registry lookup. A broken sibling
# sharing the same event/matcher must not contaminate a healthy invocation.
replace_once(
    "scripts/enforcement/lib/hook-gate.sh",
    '''try:
    unit_rel = unit_arg_raw.relative_to(root)
except ValueError:
    raise SystemExit(f"hard-hook unit argument escapes ENGINEERING_OS_HOME: {unit_arg_raw}")
unit_arg = trusted_path(str(unit_rel))

matches = [r for r in rows if r["event"] == event and r["matcher"] == matcher and
           r["wiring"] == "direct" and trusted_path(r["unit"]) == unit_arg]
if len(matches) != 1:
    raise SystemExit(f"expected exactly one direct registry row for {event}/{matcher}/{unit_arg}, found {len(matches)}")
row = matches[0]
''',
    '''try:
    unit_rel = unit_arg_raw.relative_to(root)
except ValueError:
    raise SystemExit(f"hard-hook unit argument escapes ENGINEERING_OS_HOME: {unit_arg_raw}")
unit_arg = trusted_path(str(unit_rel))
unit_lexical = Path(os.path.abspath(unit_arg_raw))

matches = [r for r in rows if r["event"] == event and r["matcher"] == matcher and
           r["wiring"] == "direct" and Path(os.path.abspath(root / r["unit"])) == unit_lexical]
if len(matches) != 1:
    raise SystemExit(f"expected exactly one direct registry row for {event}/{matcher}/{unit_arg}, found {len(matches)}")
row = matches[0]
if trusted_path(row["unit"]) != unit_arg:
    raise SystemExit(f"requested hard-hook unit does not match its canonical registry path: {row['unit']}")
''',
)

# Require an actual event-token boundary for soft-wrapped telemetry commands.
replace_once(
    "scripts/monitoring/require-telemetry-session.sh",
    '''import json
import sys
from pathlib import Path
''',
    '''import json
import re
import sys
from pathlib import Path
''',
)
replace_once(
    "scripts/monitoring/require-telemetry-session.sh",
    '''                    command.rstrip().endswith(" pre_tool_use")
                    or "-- pre_tool_use" in command
''',
    '''                    command.rstrip().endswith(" pre_tool_use")
                    or re.search(r"--\\s+pre_tool_use(?:\\s|$)", command)
''',
)

# Use the canonical grep-count form. `grep -c` already emits zero on no match;
# placing the fallback inside command substitution avoids duplicate output.
replace_once(
    ".claude/settings.json",
    '''TOTAL=$(grep -cE '^\\- \\[(x| )\\]' \"$F\" 2>/dev/null) || TOTAL=0;''',
    '''TOTAL=$(grep -cE '^\\- \\[(x| )\\]' \"$F\" 2>/dev/null || true);''',
)

# Runtime regression: a missing sibling hard unit must not block a healthy unit.
replace_once(
    "scripts/enforcement/tests/test-hook-gate.sh",
    '''# 19. Stop hard failures use the current top-level decision=block schema.
root="$(make_root stop-deny Stop '*' stop_json)"
printf '#!/usr/bin/env bash\\necho "runtime evidence missing" >&2\\nexit 1\\n' > "$root/scripts/enforcement/unit.sh"
run_gate "$root" Stop '*' "$stop_event"
if [ "$RUN_CODE" -eq 0 ] && [ "$(printf '%s' "$RUN_OUT" | json_field decision)" = block ] && printf '%s' "$RUN_OUT" | grep -q 'runtime evidence missing'; then ok "Stop hard failure uses decision=block"; else bad "Stop failure should block (code=$RUN_CODE out=$RUN_OUT err=$RUN_ERR)"; fi

printf '\\nhook-gate: %d passed, %d failed\\n' "$pass" "$fail"
''',
    '''# 19. Stop hard failures use the current top-level decision=block schema.
root="$(make_root stop-deny Stop '*' stop_json)"
printf '#!/usr/bin/env bash\\necho "runtime evidence missing" >&2\\nexit 1\\n' > "$root/scripts/enforcement/unit.sh"
run_gate "$root" Stop '*' "$stop_event"
if [ "$RUN_CODE" -eq 0 ] && [ "$(printf '%s' "$RUN_OUT" | json_field decision)" = block ] && printf '%s' "$RUN_OUT" | grep -q 'runtime evidence missing'; then ok "Stop hard failure uses decision=block"; else bad "Stop failure should block (code=$RUN_CODE out=$RUN_OUT err=$RUN_ERR)"; fi

# 20. A missing sibling sharing event/matcher must not contaminate the requested unit.
root="$(make_root sibling-isolation)"
printf '#!/usr/bin/env bash\\ncat >/dev/null\\nexit 0\\n' > "$root/scripts/enforcement/unit.sh"
printf 'PreToolUse\\tBash\\tscripts/enforcement/missing-sibling.sh\\thard\\tfail_closed\\tdirect\\t-\\tboth\\t-\\tpretool_json\\n' >> "$root/scripts/enforcement/hook-criticality.tsv"
run_gate "$root" PreToolUse Bash "$pre_event"
if [ "$RUN_CODE" -eq 0 ] && [ -z "$RUN_OUT" ]; then ok "missing sibling does not block a healthy requested unit"; else bad "missing sibling contaminated healthy unit (code=$RUN_CODE out=$RUN_OUT err=$RUN_ERR)"; fi

printf '\\nhook-gate: %d passed, %d failed\\n' "$pass" "$fail"
''',
)

# Telemetry regression: a prefix collision is not a valid pre_tool_use recorder.
replace_once(
    "scripts/enforcement/tests/test-project8-telemetry-readiness.sh",
    '''pass preflight_detects_direct_recorder bash -c "cd '$TARGET' && EOS_CLAUDE_SETTINGS_FILE='$DIRECT_SETTINGS' EOS_TELEMETRY_FILE='$EVENTS' EOS_TELEMETRY_RUN_ID_FILE='$RUN_ID' bash '$REQUIRE'"

printf '%s' '{"session_id":"first-session","tool_name":"Bash","tool_input":{"command":"npm test"}}' | \\
''',
    '''pass preflight_detects_direct_recorder bash -c "cd '$TARGET' && EOS_CLAUDE_SETTINGS_FILE='$DIRECT_SETTINGS' EOS_TELEMETRY_FILE='$EVENTS' EOS_TELEMETRY_RUN_ID_FILE='$RUN_ID' bash '$REQUIRE'"

PREFIX_SETTINGS="$TMP/prefix-settings.json"
python3 - "$TARGET/.claude/settings.json" "$PREFIX_SETTINGS" <<'PY_PREFIX'
import json, sys
src, dst = sys.argv[1:]
data = json.load(open(src, encoding='utf-8'))
replaced = False
for block in data.get('hooks', {}).get('PreToolUse', []):
    if block.get('matcher') not in (None, '.*'):
        continue
    for hook in block.get('hooks', []):
        command = hook.get('command', '') if isinstance(hook, dict) else ''
        if 'eos-telemetry-event.sh' in command and '-- pre_tool_use' in command:
            hook['command'] = command.replace('-- pre_tool_use', '-- pre_tool_use_extra', 1)
            replaced = True
if not replaced:
    raise SystemExit('soft-wrapped pre_tool_use recorder was not found')
json.dump(data, open(dst, 'w', encoding='utf-8'), indent=2)
PY_PREFIX
blockcase preflight_rejects_recorder_prefix_collision bash -c "cd '$TARGET' && EOS_CLAUDE_SETTINGS_FILE='$PREFIX_SETTINGS' EOS_TELEMETRY_FILE='$EVENTS' EOS_TELEMETRY_RUN_ID_FILE='$RUN_ID' bash '$REQUIRE'"

printf '%s' '{"session_id":"first-session","tool_name":"Bash","tool_input":{"command":"npm test"}}' | \\
''',
)
