#!/usr/bin/env bash
# Verify canonical hook classification, hard wiring, and false-evidence-safe recorders.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SETTINGS="$ROOT/.claude/settings.json"
REGISTRY="$ROOT/scripts/enforcement/hook-criticality.tsv"
CHECK="$ROOT/scripts/enforcement/check-hard-hook-contract.py"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { printf '  ✅ %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf '  ❌ %s\n' "$1"; fail=$((fail + 1)); }

command_for() {
  local event="$1" matcher="$2" needle="$3"
  python3 - "$SETTINGS" "$event" "$matcher" "$needle" <<'PY'
import json,sys
p,event,matcher,needle=sys.argv[1:]
d=json.load(open(p))
for block in d.get('hooks',{}).get(event,[]):
    actual=block.get('matcher','*')
    if actual != matcher:
        continue
    for hook in block.get('hooks',[]):
        cmd=hook.get('command','') if isinstance(hook,dict) else ''
        if needle in cmd:
            print(cmd)
            raise SystemExit(0)
raise SystemExit(1)
PY
}

run_hook() {
  local name="$1" command="$2" input="$3"
  local dir="$WORK/$name"
  mkdir -p "$dir"
  set +e
  (cd "$dir" && printf '%s' "$input" | ENGINEERING_OS_HOME="$ROOT" bash -c "$command") >"$dir/out" 2>"$dir/err"
  local code=$?
  set -e
  printf '%s' "$code" >"$dir/code"
}

assert_no_evidence() {
  local name="$1" dir="$WORK/$1"
  if [ "$(cat "$dir/code")" -eq 0 ] && [ ! -s "$dir/.claude/.evidence/ledger" ]; then
    ok "$name does not fabricate evidence on malformed input"
  else
    bad "$name fabricated evidence or failed open incorrectly (code=$(cat "$dir/code"), out=$(cat "$dir/out"), err=$(cat "$dir/err"))"
  fi
}

context7_cmd="$(command_for PostToolUse 'mcp__Context7__.*' 'evidence_record context7')"
run_hook context7 "$context7_cmd" '{bad-json'
assert_no_evidence context7

read_cmd="$(command_for PostToolUse Read 'read_pattern_lifecycle')"
run_hook read "$read_cmd" '{"tool_name":"Read","tool_input":{}}'
assert_no_evidence read

notion_cmd="$(command_for PostToolUse 'mcp__Notion__.*' 'notion_spec_created')"
run_hook notion "$notion_cmd" '{"tool_name":"mcp__Notion__create-a-page","tool_response":"not-an-object"}'
assert_no_evidence notion

post_bash_cmd="$(command_for PostToolUse Bash 'post-tool-use-bash.sh')"
run_hook post_bash "$post_bash_cmd" '{bad-json'
assert_no_evidence post_bash

post_mcp_cmd="$(command_for PostToolUse 'mcp__.*' 'post-tool-use-mcp.sh')"
run_hook post_mcp "$post_mcp_cmd" '{bad-json'
assert_no_evidence post_mcp

post_read_cmd="$(command_for PostToolUse Read 'post-tool-use-read-evidence.sh')"
run_hook post_read "$post_read_cmd" '{bad-json'
assert_no_evidence post_read

if python3 "$CHECK" --root "$ROOT" --settings "$SETTINGS" --surface source >"$WORK/contract.out" 2>"$WORK/contract.err"; then
  ok "canonical source hard-hook contract passes"
else
  bad "canonical source hard-hook contract failed: $(cat "$WORK/contract.err")"
fi

if awk -F '\t' '
  BEGIN { bad=0; rows=0 }
  /^[[:space:]]*#/ || NF==0 { next }
  NF != 10 { bad=1; next }
  {
    rows++
    if ($4=="hard" && $5!="fail_closed") bad=1
    if ($4=="advisory" && $5!="soft_guidance_only") bad=1
    if ($4=="recorder" && $5!="false_evidence_safe") bad=1
    if ($6=="nested" && $7=="-") bad=1
  }
  END { exit (bad || rows==0) ? 1 : 0 }
' "$REGISTRY"; then
  ok "criticality registry has strict ten-column class semantics"
else
  bad "criticality registry class/shape validation failed"
fi

if grep -q $'PreToolUse\t.*\tscripts/enforcement/pre-tool-use-json-guard.sh\thard\tfail_closed\tdirect' "$REGISTRY" \
   && grep -q $'Stop\t\*\tscripts/enforcement/post-stop-hook.sh\thard\tfail_closed\tdirect' "$REGISTRY" \
   && grep -q $'scripts/enforcement/check-runtime-evidence.sh\thard\tfail_closed\tnested\tscripts/enforcement/post-stop-hook.sh' "$REGISTRY"; then
  ok "direct and nested hard units are represented canonically"
else
  bad "criticality registry is missing required direct/nested ownership"
fi

if grep -q 'soft-hook-gate.sh' "$SETTINGS" && grep -q 'hook-errors.log' "$ROOT/scripts/enforcement/lib/soft-hook-gate.sh"; then
  ok "recorder failures are explicit, observable, and fail-open"
else
  bad "soft recorder observability wiring is missing"
fi

printf '\nhook classification: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
