#!/usr/bin/env bash
# End-to-end source/settings/installed-target proof for hard-hook fail-closed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-hard-hook-contract.py"
REGISTRY="$ROOT/scripts/enforcement/hook-criticality.tsv"
SETTINGS="$ROOT/.claude/settings.json"
SOFT="$ROOT/scripts/enforcement/lib/soft-hook-gate.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { printf '  ✅ %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf '  ❌ %s\n' "$1"; fail=$((fail + 1)); }
expect_fail() {
  local name="$1" pattern="$2"; shift 2
  set +e
  "$@" >"$WORK/out" 2>"$WORK/err"
  local code=$?
  set -e
  if [ "$code" -ne 0 ] && grep -qi "$pattern" "$WORK/err"; then ok "$name"; else bad "$name (code=$code out=$(cat "$WORK/out") err=$(cat "$WORK/err"))"; fi
}

python3 "$CHECK" --root "$ROOT" --settings "$SETTINGS" --surface source >/dev/null && ok "source hard-hook contract passes" || bad "source hard-hook contract should pass"

# Registry row missing: the still-wired hard command must become unregistered and fail.
awk 'index($0,"PreToolUse\tBash\tscripts/enforcement/enforce-git.sh\t")==0' "$REGISTRY" >"$WORK/missing-row.tsv"
expect_fail "required registry row missing is rejected" "not a registered direct hard unit" \
  python3 "$CHECK" --root "$ROOT" --settings "$SETTINGS" --registry "$WORK/missing-row.tsv" --surface source

printf 'bad\trow\n' >"$WORK/malformed.tsv"
expect_fail "malformed registry is rejected" "malformed hook-criticality" \
  python3 "$CHECK" --root "$ROOT" --settings "$SETTINGS" --registry "$WORK/malformed.tsv" --surface source

# Settings command missing.
python3 - "$SETTINGS" "$WORK/missing-command.json" <<'PY'
import json,sys
src,dst=sys.argv[1:]
d=json.load(open(src))
block=next(x for x in d['hooks']['PreToolUse'] if x.get('matcher')=='Bash')
block['hooks']=[h for h in block['hooks'] if 'enforce-git.sh' not in h.get('command','')]
json.dump(d,open(dst,'w'),indent=2)
PY
expect_fail "missing settings command is rejected" "expected exactly one command, found 0" \
  python3 "$CHECK" --root "$ROOT" --settings "$WORK/missing-command.json" --surface source

# Wrong target command.
python3 - "$SETTINGS" "$WORK/wrong-target.json" <<'PY'
import json,sys
src,dst=sys.argv[1:]
d=json.load(open(src))
for block in d['hooks']['PreToolUse']:
    if block.get('matcher')=='Bash':
        for h in block.get('hooks',[]):
            if 'enforce-git.sh' in h.get('command',''):
                h['command']=h['command'].replace('enforce-git.sh','enforce-debugging.sh')
json.dump(d,open(dst,'w'),indent=2)
PY
expect_fail "settings command pointing to wrong target is rejected" "expected exactly one command" \
  python3 "$CHECK" --root "$ROOT" --settings "$WORK/wrong-target.json" --surface source

# Hard command hidden behind soft failure.
python3 - "$SETTINGS" "$WORK/soft-hard.json" <<'PY'
import json,sys
src,dst=sys.argv[1:]
d=json.load(open(src))
for block in d['hooks']['PreToolUse']:
    if block.get('matcher')=='Bash':
        for h in block.get('hooks',[]):
            if 'enforce-git.sh' in h.get('command',''):
                h['command'] += ' || true'
json.dump(d,open(dst,'w'),indent=2)
PY
expect_fail "hard hook wrapped in soft failure is rejected" "soft-wrapped" \
  python3 "$CHECK" --root "$ROOT" --settings "$WORK/soft-hard.json" --surface source

# A missing required dependency in the canonical chain must fail validation.
cp "$REGISTRY" "$WORK/missing-dependency.tsv"
printf 'PreToolUse\tBash\tscripts/enforcement/nonexistent-nested.sh\thard\tfail_closed\tnested\tscripts/enforcement/enforce-git.sh\tboth\t-\tpretool_json\n' >>"$WORK/missing-dependency.tsv"
expect_fail "missing required nested dependency is rejected" "nonexistent-nested.sh" \
  python3 "$CHECK" --root "$ROOT" --settings "$SETTINGS" --registry "$WORK/missing-dependency.tsv" --surface source

# Bootstrap itself must block if the hard wrapper is absent.
hard_cmd="$(python3 - "$SETTINGS" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
block=next(x for x in d['hooks']['PreToolUse'] if x.get('matcher')=='Bash')
print(next(h['command'] for h in block['hooks'] if 'pre-tool-use-json-guard.sh' in h.get('command','')))
PY
)"
missing_cmd="${hard_cmd/hook-gate.sh/missing-hook-gate.sh}"
pre='{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"printf ok"}}'
set +e
printf '%s' "$pre" | ENGINEERING_OS_HOME="$ROOT" bash -c "$missing_cmd" >"$WORK/out" 2>"$WORK/err"
code=$?
set -e
if [ "$code" -eq 2 ] && grep -qi 'wrapper missing' "$WORK/err"; then ok "missing hard wrapper bootstrap blocks"; else bad "missing wrapper should exit 2 (code=$code err=$(cat "$WORK/err"))"; fi

# Advisory remains explicitly fail-open.
advisory_cmd="$(python3 - "$SETTINGS" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
block=next(x for x in d['hooks']['PreToolUse'] if x.get('matcher')=='Bash')
print(next(h['command'] for h in block['hooks'] if 'rtk hook claude' in h.get('command','')))
PY
)"
set +e
PATH=/usr/bin:/bin bash -c "$advisory_cmd" </dev/null >"$WORK/out" 2>"$WORK/err"
code=$?
set -e
if [ "$code" -eq 0 ]; then ok "explicit advisory failure remains fail-open"; else bad "advisory should remain fail-open (code=$code)"; fi

# Recorder failure is observable, returns success, and emits no policy allow/deny JSON.
mkdir -p "$WORK/recorder-target/.git" "$WORK/recorder"
cat >"$WORK/recorder/fail.sh" <<'EOF_REC'
#!/usr/bin/env bash
echo 'internal recorder diagnostic' >&2
exit 9
EOF_REC
(
  cd "$WORK/recorder-target"
  set +e
  printf '{}\n' | bash "$SOFT" --event PostToolUse --unit "$WORK/recorder/fail.sh" >"$WORK/rec.out" 2>"$WORK/rec.err"
  echo $? >"$WORK/rec.code"
  set -e
)
if [ "$(cat "$WORK/rec.code")" -eq 0 ] && grep -q 'failed open' "$WORK/rec.err" && [ -s "$WORK/recorder-target/.engineering-os/hook-errors.log" ] && [ ! -s "$WORK/rec.out" ]; then
  ok "recorder failure is observable without masquerading as policy success"
else
  bad "recorder failure contract failed (code=$(cat "$WORK/rec.code") out=$(cat "$WORK/rec.out") err=$(cat "$WORK/rec.err"))"
fi

# Official clean-target installer must render the same hard contract.
TARGET="$WORK/target"
git init "$TARGET" >/dev/null
(
  cd "$TARGET"
  EOS_CONTRACT_TEST=1 ENGINEERING_OS_HOME="$ROOT" bash "$ROOT/scripts/use-in-project.sh" >"$WORK/install.out"
)
python3 "$CHECK" --root "$ROOT" --settings "$TARGET/.claude/settings.json" --surface installed >/dev/null && ok "clean installed-target contract passes" || bad "installed-target contract should pass"

installed_cmd="$(python3 - "$TARGET/.claude/settings.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
block=next(x for x in d['hooks']['PreToolUse'] if x.get('matcher')=='Bash')
print(next(h['command'] for h in block['hooks'] if 'pre-tool-use-json-guard.sh' in h.get('command','')))
PY
)"
set +e
printf '%s' "$pre" | (cd "$TARGET" && bash -c "$installed_cmd") >"$WORK/out" 2>"$WORK/err"
code=$?
set -e
if [ "$code" -eq 0 ]; then ok "clean installed-target valid request succeeds"; else bad "installed valid request should succeed (code=$code out=$(cat "$WORK/out") err=$(cat "$WORK/err"))"; fi

set +e
printf '{bad' | (cd "$TARGET" && bash -c "$installed_cmd") >"$WORK/out" 2>"$WORK/err"
code=$?
set -e
if [ "$code" -eq 2 ] && grep -qi 'input validation' "$WORK/err"; then ok "clean installed-target malformed input blocks"; else bad "installed malformed input should block (code=$code err=$(cat "$WORK/err"))"; fi

set +e
printf '%s' "$pre" | (cd "$TARGET" && EOS_HOOK_GATE_PYTHON=missing-python bash -c "$installed_cmd") >"$WORK/out" 2>"$WORK/err"
code=$?
set -e
if [ "$code" -eq 2 ] && grep -qi 'interpreter' "$WORK/err"; then ok "clean installed-target interpreter failure blocks"; else bad "installed interpreter failure should block (code=$code err=$(cat "$WORK/err"))"; fi

missing_installed_cmd="${installed_cmd/pre-tool-use-json-guard.sh/missing-enforcer.sh}"
set +e
printf '%s' "$pre" | (cd "$TARGET" && bash -c "$missing_installed_cmd") >"$WORK/out" 2>"$WORK/err"
code=$?
set -e
if [ "$code" -eq 2 ] && grep -qi 'enforcer is missing' "$WORK/err"; then ok "clean installed-target missing enforcer blocks"; else bad "installed missing enforcer should block (code=$code err=$(cat "$WORK/err"))"; fi

printf '\nhard-hook fail-closed: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
