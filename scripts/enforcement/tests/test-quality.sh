#!/usr/bin/env bash
# test-quality.sh — regression tests for the quality-gates.md cleanup enforcer.
# Run: bash scripts/enforcement/tests/test-quality.sh
set -u

ENFORCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENFORCER="$ENFORCE_DIR/enforce-quality.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; }
expect() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected exit $2, got $3)"; fi; }

REPO="$(mktemp -d)"; trap 'rm -rf "$REPO" 2>/dev/null' EXIT
cd "$REPO" || exit 1
git init -q 2>/dev/null
git config user.email t@t.t; git config user.name t

# check <desc> <expected_exit> <filename> <line...>: stage ONLY this file, run enforcer.
check() {
  local desc="$1" exp="$2" f="$3"; shift 3
  git reset -q 2>/dev/null
  printf '%s\n' "$@" > "$f"
  git add "$f" 2>/dev/null
  bash "$ENFORCER" >/dev/null 2>&1
  expect "$desc" "$exp" $?
}

echo "── blocking: interactive debuggers ──"
check "JS debugger blocked"          1 app.js   "const x = 1;" "debugger;"
check "PY breakpoint() blocked"      1 app.py   "x = 1" "breakpoint()"
check "PY pdb.set_trace() blocked"   1 dbg.py   "import pdb; pdb.set_trace()"
check "PY import pdb blocked"        1 imp.py   "import pdb"
check "PY import ipdb blocked"       1 imp2.py  "import ipdb"
check "RB binding.pry blocked"       1 app.rb   "binding.pry"
check "RB byebug blocked"            1 dbg.rb   "byebug"

echo "── blocking: merge-conflict markers ──"
check "conflict marker <<<<<<< blocked" 1 conf.js  "<<<<<<< HEAD"
check "conflict marker >>>>>>> blocked" 1 conf2.js ">>>>>>> branch-name"

echo "── allowed ──"
check "clean code passes"            0 clean.ts "export const sum = (a:number,b:number) => a + b;"
check "non-code file (.md) not scanned" 0 notes.md "here is a debugger; and pdb.set_trace() in prose"
check "debugger inside identifier not matched" 0 ok.js "const debugger_flag = true;"

echo "── advisory (non-blocking) ──"
check "console.log does not block"   0 log.js   "console.log(x)"
check "print() does not block"       0 p.py     "print(x)"
git reset -q 2>/dev/null
printf '%s\n' "console.log(x)" > w.js; git add w.js 2>/dev/null
out="$(bash "$ENFORCER" 2>&1)"; code=$?
{ [ "$code" = 0 ] && printf '%s' "$out" | grep -q 'console.log/print'; } \
  && ok "console.log emits a warning" || bad "console.log emits a warning"

echo "── bypasses ──"
git reset -q 2>/dev/null; printf '%s\n' "debugger;" > b.js; git add b.js 2>/dev/null
EOS_BYPASS_CLEANUP=1 bash "$ENFORCER" >/dev/null 2>&1; expect "EOS_BYPASS_CLEANUP skips gate" 0 $?
EOS_BYPASS_QUALITY=1 bash "$ENFORCER" >/dev/null 2>&1; expect "EOS_BYPASS_QUALITY (master) skips gate" 0 $?

echo "── only added lines count ──"
git reset -q 2>/dev/null
printf '%s\n' "const x = 1;" "debugger;" > del.js
git add del.js 2>/dev/null; git commit -qm "seed with debugger" 2>/dev/null
printf '%s\n' "const x = 1;" > del.js   # remove the debugger line
git add del.js 2>/dev/null
bash "$ENFORCER" >/dev/null 2>&1; expect "removing a debugger line passes" 0 $?

echo
echo "════════ $PASS passed, $FAIL failed ════════"
[ "$FAIL" -eq 0 ]
