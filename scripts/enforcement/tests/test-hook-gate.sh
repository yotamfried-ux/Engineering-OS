#!/usr/bin/env bash
# Focused runtime tests for the fail-closed hard-hook runner.
set -euo pipefail

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SOURCE_GATE="$SOURCE_ROOT/scripts/enforcement/lib/hook-gate.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { printf '  ✅ %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf '  ❌ %s\n' "$1"; fail=$((fail + 1)); }

make_root() {
  local name="$1" event="${2:-PreToolUse}" matcher="${3:-Bash}" mode="${4:-pretool_json}"
  local root="$WORK/$name"
  mkdir -p "$root/scripts/enforcement/lib"
  cp "$SOURCE_GATE" "$root/scripts/enforcement/lib/hook-gate.sh"
  cat > "$root/scripts/enforcement/hook-criticality.tsv" <<EOF_REG
$event	$matcher	scripts/enforcement/unit.sh	hard	fail_closed	direct	-	both	-	$mode
EOF_REG
  printf '%s\n' "$root"
}

pre_event='{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"printf ok"}}'
stop_event='{"hook_event_name":"Stop","stop_hook_active":false,"last_assistant_message":"done"}'

run_gate() {
  local root="$1" event="$2" matcher="$3" input="$4"
  shift 4
  set +e
  RUN_OUT="$(printf '%s' "$input" | env "$@" bash "$root/scripts/enforcement/lib/hook-gate.sh" --event "$event" --matcher "$matcher" --unit "$root/scripts/enforcement/unit.sh" 2>"$root/run.err")"
  RUN_CODE=$?
  set -e
  RUN_ERR="$(cat "$root/run.err")"
}

json_field() {
  python3 -c 'import json,sys; d=json.load(sys.stdin); cur=d
for key in sys.argv[1].split("."):
    cur=cur[key]
print(cur)' "$1"
}

# 1. Valid success allows.
root="$(make_root allow)"
cat > "$root/scripts/enforcement/unit.sh" <<'EOF_UNIT'
#!/usr/bin/env bash
cat >/dev/null
exit 0
EOF_UNIT
run_gate "$root" PreToolUse Bash "$pre_event"
if [ "$RUN_CODE" -eq 0 ] && [ -z "$RUN_OUT" ]; then ok "valid hard-hook success passes"; else bad "valid success should pass (code=$RUN_CODE out=$RUN_OUT err=$RUN_ERR)"; fi

# 2. Explicit legacy policy denial becomes structured deny.
root="$(make_root policy-deny)"
cat > "$root/scripts/enforcement/unit.sh" <<'EOF_UNIT'
#!/usr/bin/env bash
cat >/dev/null
echo 'ERROR_FOR_AGENT: policy denied this request' >&2
exit 1
EOF_UNIT
run_gate "$root" PreToolUse Bash "$pre_event"
if [ "$RUN_CODE" -eq 0 ] && [ "$(printf '%s' "$RUN_OUT" | json_field hookSpecificOutput.permissionDecision)" = deny ] && printf '%s' "$RUN_OUT" | grep -q 'policy denied'; then ok "explicit policy denial blocks with a reason"; else bad "policy denial should produce deny JSON (code=$RUN_CODE out=$RUN_OUT err=$RUN_ERR)"; fi

# 3-4. Malformed and invalid JSON block through exit 2.
root="$(make_root invalid-json)"
printf '#!/usr/bin/env bash\nexit 0\n' > "$root/scripts/enforcement/unit.sh"
run_gate "$root" PreToolUse Bash '{"hook_event_name":"PreToolUse","tool_name":' 
if [ "$RUN_CODE" -eq 2 ] && printf '%s' "$RUN_ERR" | grep -qi 'input validation'; then ok "invalid JSON blocks"; else bad "invalid JSON should exit 2 (code=$RUN_CODE err=$RUN_ERR)"; fi
run_gate "$root" PreToolUse Bash '[]'
if [ "$RUN_CODE" -eq 2 ] && printf '%s' "$RUN_ERR" | grep -qi 'JSON object'; then ok "malformed input shape blocks"; else bad "non-object input should exit 2 (code=$RUN_CODE err=$RUN_ERR)"; fi

# 5. Missing enforcer blocks.
root="$(make_root missing-enforcer)"
run_gate "$root" PreToolUse Bash "$pre_event"
if [ "$RUN_CODE" -eq 2 ] && printf '%s' "$RUN_ERR" | grep -qi 'enforcer is missing'; then ok "missing enforcer blocks"; else bad "missing enforcer should exit 2 (code=$RUN_CODE err=$RUN_ERR)"; fi

# 6. Wrong event identity blocks.
root="$(make_root wrong-event)"
printf '#!/usr/bin/env bash\nexit 0\n' > "$root/scripts/enforcement/unit.sh"
run_gate "$root" PreToolUse Bash '{"hook_event_name":"Stop","tool_name":"Bash","tool_input":{"command":"x"}}'
if [ "$RUN_CODE" -eq 2 ] && printf '%s' "$RUN_ERR" | grep -qi 'mismatch'; then ok "event mismatch blocks"; else bad "event mismatch should exit 2 (code=$RUN_CODE err=$RUN_ERR)"; fi

# 7. Missing interpreter blocks before policy execution.
root="$(make_root missing-interpreter)"
printf '#!/usr/bin/env bash\nexit 0\n' > "$root/scripts/enforcement/unit.sh"
run_gate "$root" PreToolUse Bash "$pre_event" EOS_HOOK_GATE_PYTHON=definitely-missing-python
if [ "$RUN_CODE" -eq 2 ] && printf '%s' "$RUN_ERR" | grep -qi 'interpreter'; then ok "missing interpreter blocks"; else bad "missing interpreter should exit 2 (code=$RUN_CODE err=$RUN_ERR)"; fi

# 8. Missing required nested validator blocks.
root="$(make_root missing-nested)"
printf '#!/usr/bin/env bash\nexit 0\n' > "$root/scripts/enforcement/unit.sh"
cat >> "$root/scripts/enforcement/hook-criticality.tsv" <<'EOF_REG'
PreToolUse	Bash	scripts/enforcement/nested.sh	hard	fail_closed	nested	scripts/enforcement/unit.sh	both	-	pretool_json
EOF_REG
run_gate "$root" PreToolUse Bash "$pre_event"
if [ "$RUN_CODE" -eq 2 ] && printf '%s' "$RUN_ERR" | grep -qi 'nested.sh'; then ok "missing required nested validator blocks"; else bad "missing nested validator should exit 2 (code=$RUN_CODE err=$RUN_ERR)"; fi

# 9. Required nested validator failure propagates as deny through the parent.
root="$(make_root nested-failure)"
cat > "$root/scripts/enforcement/nested.sh" <<'EOF_NEST'
#!/usr/bin/env bash
echo 'nested validation failed' >&2
exit 1
EOF_NEST
cat >> "$root/scripts/enforcement/hook-criticality.tsv" <<'EOF_REG'
PreToolUse	Bash	scripts/enforcement/nested.sh	hard	fail_closed	nested	scripts/enforcement/unit.sh	both	-	pretool_json
EOF_REG
cat > "$root/scripts/enforcement/unit.sh" <<'EOF_UNIT'
#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$DIR/nested.sh"
EOF_UNIT
run_gate "$root" PreToolUse Bash "$pre_event"
if [ "$RUN_CODE" -eq 0 ] && printf '%s' "$RUN_OUT" | grep -q 'nested validation failed' && [ "$(printf '%s' "$RUN_OUT" | json_field hookSpecificOutput.permissionDecision)" = deny ]; then ok "nested validator failure blocks"; else bad "nested failure should deny (code=$RUN_CODE out=$RUN_OUT err=$RUN_ERR)"; fi

# 10-11. Missing/malformed registry blocks.
root="$(make_root missing-registry)"
printf '#!/usr/bin/env bash\nexit 0\n' > "$root/scripts/enforcement/unit.sh"
rm "$root/scripts/enforcement/hook-criticality.tsv"
run_gate "$root" PreToolUse Bash "$pre_event"
if [ "$RUN_CODE" -eq 2 ] && printf '%s' "$RUN_ERR" | grep -qi 'registry'; then ok "missing registry blocks"; else bad "missing registry should exit 2 (code=$RUN_CODE err=$RUN_ERR)"; fi
root="$(make_root malformed-registry)"
printf '#!/usr/bin/env bash\nexit 0\n' > "$root/scripts/enforcement/unit.sh"
printf 'bad\trow\n' > "$root/scripts/enforcement/hook-criticality.tsv"
run_gate "$root" PreToolUse Bash "$pre_event"
if [ "$RUN_CODE" -eq 2 ] && printf '%s' "$RUN_ERR" | grep -qi 'malformed'; then ok "malformed registry blocks"; else bad "malformed registry should exit 2 (code=$RUN_CODE err=$RUN_ERR)"; fi

# 12. Missing dependency blocks.
root="$(make_root missing-dependency)"
printf '#!/usr/bin/env bash\nexit 0\n' > "$root/scripts/enforcement/unit.sh"
sed -i 's/\t-\tpretool_json$/\tscripts\/enforcement\/required-lib.sh\tpretool_json/' "$root/scripts/enforcement/hook-criticality.tsv"
run_gate "$root" PreToolUse Bash "$pre_event"
if [ "$RUN_CODE" -eq 2 ] && printf '%s' "$RUN_ERR" | grep -qi 'required-lib.sh'; then ok "missing dependency blocks"; else bad "missing dependency should exit 2 (code=$RUN_CODE err=$RUN_ERR)"; fi

# 13. Converter failure falls back to blocking exit 2.
root="$(make_root converter-failure)"
printf '#!/usr/bin/env bash\necho denied >&2\nexit 1\n' > "$root/scripts/enforcement/unit.sh"
run_gate "$root" PreToolUse Bash "$pre_event" EOS_HOOK_GATE_CONVERTER=false
if [ "$RUN_CODE" -eq 2 ] && printf '%s' "$RUN_ERR" | grep -qi 'conversion failed'; then ok "deny converter failure falls back to exit 2"; else bad "converter failure should exit 2 (code=$RUN_CODE out=$RUN_OUT err=$RUN_ERR)"; fi

# 14. Unexpected exit code blocks.
root="$(make_root unexpected-exit)"
printf '#!/usr/bin/env bash\necho strange >&2\nexit 7\n' > "$root/scripts/enforcement/unit.sh"
run_gate "$root" PreToolUse Bash "$pre_event"
if [ "$RUN_CODE" -eq 0 ] && printf '%s' "$RUN_OUT" | grep -q 'unexpected exit code 7' && [ "$(printf '%s' "$RUN_OUT" | json_field hookSpecificOutput.permissionDecision)" = deny ]; then ok "unexpected subprocess exit blocks"; else bad "unexpected exit should deny (code=$RUN_CODE out=$RUN_OUT err=$RUN_ERR)"; fi

# 15. Signal termination blocks.
root="$(make_root signal)"
printf '#!/usr/bin/env bash\nkill -TERM $$\n' > "$root/scripts/enforcement/unit.sh"
run_gate "$root" PreToolUse Bash "$pre_event"
if [ "$RUN_CODE" -eq 0 ] && printf '%s' "$RUN_OUT" | grep -qi 'signal 15' && [ "$(printf '%s' "$RUN_OUT" | json_field hookSpecificOutput.permissionDecision)" = deny ]; then ok "subprocess signal termination blocks"; else bad "signal should deny (code=$RUN_CODE out=$RUN_OUT err=$RUN_ERR)"; fi

# 16. Valid native deny is forwarded exactly once.
root="$(make_root native-deny)"
cat > "$root/scripts/enforcement/unit.sh" <<'EOF_UNIT'
#!/usr/bin/env bash
cat >/dev/null
printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"native denial"}}'
EOF_UNIT
run_gate "$root" PreToolUse Bash "$pre_event"
if [ "$RUN_CODE" -eq 0 ] && [ "$(printf '%s' "$RUN_OUT" | grep -c 'hookSpecificOutput')" -eq 1 ] && printf '%s' "$RUN_OUT" | grep -q 'native denial'; then ok "valid native deny is forwarded once"; else bad "native deny should be forwarded (code=$RUN_CODE out=$RUN_OUT err=$RUN_ERR)"; fi

# 17. Malformed JSON-looking success output blocks as ambiguous.
root="$(make_root malformed-output)"
printf '#!/usr/bin/env bash\necho "{bad"\nexit 0\n' > "$root/scripts/enforcement/unit.sh"
run_gate "$root" PreToolUse Bash "$pre_event"
if [ "$RUN_CODE" -eq 2 ] && printf '%s' "$RUN_ERR" | grep -qi 'malformed JSON'; then ok "ambiguous malformed hook result blocks"; else bad "malformed output should exit 2 (code=$RUN_CODE out=$RUN_OUT err=$RUN_ERR)"; fi

# 18. Plain success text is converted to valid context JSON, not leaked as invalid stdout.
root="$(make_root success-context)"
printf '#!/usr/bin/env bash\necho "validated successfully"\nexit 0\n' > "$root/scripts/enforcement/unit.sh"
run_gate "$root" PreToolUse Bash "$pre_event"
if [ "$RUN_CODE" -eq 0 ] && [ "$(printf '%s' "$RUN_OUT" | json_field hookSpecificOutput.additionalContext)" = 'validated successfully' ]; then ok "plain success output is converted to valid context JSON"; else bad "plain success should become context JSON (code=$RUN_CODE out=$RUN_OUT err=$RUN_ERR)"; fi

# 19. Stop hard failures use the current top-level decision=block schema.
root="$(make_root stop-deny Stop '*' stop_json)"
printf '#!/usr/bin/env bash\necho "runtime evidence missing" >&2\nexit 1\n' > "$root/scripts/enforcement/unit.sh"
run_gate "$root" Stop '*' "$stop_event"
if [ "$RUN_CODE" -eq 0 ] && [ "$(printf '%s' "$RUN_OUT" | json_field decision)" = block ] && printf '%s' "$RUN_OUT" | grep -q 'runtime evidence missing'; then ok "Stop hard failure uses decision=block"; else bad "Stop failure should block (code=$RUN_CODE out=$RUN_OUT err=$RUN_ERR)"; fi

# 20. A missing sibling sharing event/matcher must not contaminate the requested unit.
root="$(make_root sibling-isolation)"
printf '#!/usr/bin/env bash\ncat >/dev/null\nexit 0\n' > "$root/scripts/enforcement/unit.sh"
printf 'PreToolUse\tBash\tscripts/enforcement/missing-sibling.sh\thard\tfail_closed\tdirect\t-\tboth\t-\tpretool_json\n' >> "$root/scripts/enforcement/hook-criticality.tsv"
run_gate "$root" PreToolUse Bash "$pre_event"
if [ "$RUN_CODE" -eq 0 ] && [ -z "$RUN_OUT" ]; then ok "missing sibling does not block a healthy requested unit"; else bad "missing sibling contaminated healthy unit (code=$RUN_CODE out=$RUN_OUT err=$RUN_ERR)"; fi

printf '\nhook-gate: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
