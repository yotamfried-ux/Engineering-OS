#!/usr/bin/env bash
# test-debugging.sh — regression tests for the debugging-policy.md enforcer.
# Run: bash scripts/enforcement/tests/test-debugging.sh
set -u

ENFORCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENFORCER="$ENFORCE_DIR/enforce-debugging.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; }
expect() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected exit $2, got $3)"; fi; }

# run_pre <command> → enforcer exit code (D1/D3 path)
run_pre() {
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" \
    | bash "$ENFORCER" pretooluse >/dev/null 2>&1
}
# run_pre_out <command> → enforcer stdout (to inspect D3 reminders)
run_pre_out() {
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" \
    | bash "$ENFORCER" pretooluse 2>/dev/null
}

echo "── D1: no-verify bypass is blocked (git commit) ──"
run_pre "git commit --no-verify -m x";  expect "commit --no-verify blocked" 1 $?
run_pre "git commit -m x --no-verify";  expect "commit --no-verify AFTER -m blocked" 1 $?
run_pre "git commit -m --no-verify";    expect "-m value (--no-verify) not misread as flag" 0 $?
run_pre "git commit -n -m x";           expect "commit -n blocked" 1 $?
run_pre "git commit -nm x";             expect "commit -nm (combined) blocked" 1 $?
run_pre "git commit -m x";              expect "normal commit allowed" 0 $?
run_pre "git commit -am x";             expect "commit -am (no n) allowed" 0 $?
run_pre "git log --grep commit -n 5";   expect "git log -n not misread as commit" 0 $?

echo "── D1: no-verify bypass is blocked (git push) ──"
run_pre "git push --no-verify";              expect "push --no-verify blocked" 1 $?
run_pre "git push origin main --no-verify";  expect "push (with remote) --no-verify blocked" 1 $?
run_pre "git push -n";                       expect "push -n (dry-run) allowed" 0 $?
run_pre "git push origin main";              expect "normal push allowed" 0 $?

echo "── D1: bypasses ──"
EOS_BYPASS_NOVERIFY=1 run_pre "git commit --no-verify -m x"; expect "EOS_BYPASS_NOVERIFY skips D1" 0 $?
EOS_BYPASS_DEBUG=1    run_pre "git commit --no-verify -m x"; expect "EOS_BYPASS_DEBUG (master) skips D1" 0 $?
run_pre "ls -la";                                            expect "non-git command allowed" 0 $?

echo "── D3: rollback reminder (non-blocking) ──"
run_pre "git reset --hard HEAD~1"; expect "reset --hard is non-blocking" 0 $?
printf '%s' "$(run_pre_out 'git reset --hard HEAD~1')" | grep -q 'failed-solutions' \
  && ok "reset --hard emits reminder" || bad "reset --hard emits reminder"
printf '%s' "$(run_pre_out 'git revert HEAD')" | grep -q 'failed-solutions' \
  && ok "revert emits reminder" || bad "revert emits reminder"
printf '%s' "$(run_pre_out 'git checkout -- file.txt')" | grep -q 'failed-solutions' \
  && ok "checkout -- emits reminder" || bad "checkout -- emits reminder"
[ -z "$(run_pre_out 'git checkout -b feature')" ] \
  && ok "checkout -b (new branch) is silent" || bad "checkout -b (new branch) is silent"
[ -z "$(run_pre_out 'git status')" ] \
  && ok "git status is silent" || bad "git status is silent"

echo "── D2: a fix: commit must add a regression test ──"
REPO="$(mktemp -d)"; trap 'rm -rf "$REPO" 2>/dev/null' EXIT
cd "$REPO" || exit 1
git init -q 2>/dev/null
git config user.email t@t.t; git config user.name t
MSG="$REPO/MSG"

printf '%s\n' "fix: null deref in parser" > "$MSG"
echo "code" > app.py; git add app.py 2>/dev/null
bash "$ENFORCER" commit-msg "$MSG" >/dev/null 2>&1; expect "fix: without staged test blocked" 1 $?

echo "t" > test_app.py; git add test_app.py 2>/dev/null
bash "$ENFORCER" commit-msg "$MSG" >/dev/null 2>&1; expect "fix: with staged test allowed" 0 $?

git reset -q 2>/dev/null
printf '%s\n' "feat: add new endpoint" > "$MSG"
echo "code2" > app2.py; git add app2.py 2>/dev/null
bash "$ENFORCER" commit-msg "$MSG" >/dev/null 2>&1; expect "feat: without test allowed (not a fix)" 0 $?

git reset -q 2>/dev/null
printf '%s\n' "fix(api): bad status code" > "$MSG"
echo "code3" > app3.py; git add app3.py 2>/dev/null
bash "$ENFORCER" commit-msg "$MSG" >/dev/null 2>&1; expect "fix(scope): without test blocked" 1 $?

EOS_BYPASS_FIXTEST=1 bash "$ENFORCER" commit-msg "$MSG" >/dev/null 2>&1; expect "EOS_BYPASS_FIXTEST skips D2" 0 $?
EOS_BYPASS_DEBUG=1   bash "$ENFORCER" commit-msg "$MSG" >/dev/null 2>&1; expect "EOS_BYPASS_DEBUG (master) skips D2" 0 $?

# Deleting a test file must NOT satisfy D2 (--diff-filter excludes deletions).
git reset -q 2>/dev/null
echo "baseline" > test_seed.py; git add test_seed.py 2>/dev/null
git commit -qm "chore: seed test file" 2>/dev/null
git rm -q test_seed.py 2>/dev/null
printf '%s\n' "fix: drop coverage instead of adding it" > "$MSG"
bash "$ENFORCER" commit-msg "$MSG" >/dev/null 2>&1; expect "fix: deleting a test file is blocked" 1 $?

echo
echo "════════ $PASS passed, $FAIL failed ════════"
[ "$FAIL" -eq 0 ]
