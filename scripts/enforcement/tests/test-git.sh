#!/usr/bin/env bash
# test-git.sh — regression tests for the git-policy.md enforcer (PreToolUse Bash).
# Run: bash scripts/enforcement/tests/test-git.sh
set -u

ENFORCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENFORCER="$ENFORCE_DIR/enforce-git.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; }
expect() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected exit $2, got $3)"; fi; }

# json <command> — emit a Bash tool-call payload for the given command string.
json() { python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$1"; }
# run <command> — pipe the payload through the enforcer, echo its exit code.
# Group-redirect so a SIGPIPE on the producer (when a bypass exits before reading
# stdin) is silenced; the reported code is the enforcer's.
run() { { json "$1" | bash "$ENFORCER" pretooluse; } >/dev/null 2>&1; echo $?; }

echo "── G1: block plain force-push (allow --force-with-lease) ──"
expect "git push --force blocked"             1 "$(run 'git push --force')"
expect "git push -f blocked"                  1 "$(run 'git push -f')"
expect "git push --force origin br blocked"   1 "$(run 'git push --force origin feature')"
expect "git -c ... push --force blocked"      1 "$(run 'git -c user.name=bot push --force origin feature')"
expect "git push --force-with-lease allowed"  0 "$(run 'git push --force-with-lease')"
expect "git push --force-with-lease origin allowed" 0 "$(run 'git push --force-with-lease origin feature')"
expect "plain git push allowed"               0 "$(run 'git push origin feature')"
expect "git push -u origin allowed"           0 "$(run 'git push -u origin feature')"
expect "commit msg mentioning --force allowed" 0 "$(run 'git commit -m "handle --force flag"')"

echo "── G2: block draft PR creation ──"
expect "gh pr create --draft blocked"         1 "$(run 'gh pr create --draft --title x --body y')"
expect "gh pr create -d (short) blocked"      1 "$(run 'gh pr create -d --title x')"
expect "gh --repo ... pr create --draft blocked" 1 "$(run 'gh --repo owner/repo pr create --draft --title x --body y')"
# Non-draft PRs pass G2 but hit G6c (maintenance-routine evidence required). Provision it.
_EV_G6C="$(mktemp -d)"
printf '%s\tread_maintenance_routine\t\n' "$(date +%s)" > "$_EV_G6C/ledger"
expect "gh pr create (ready) allowed"         0 "$(EOS_EVIDENCE_DIR="$_EV_G6C" run 'gh pr create --title x --body y')"
expect "--draft inside --body allowed"        0 "$(EOS_EVIDENCE_DIR="$_EV_G6C" run 'gh pr create --title x --body "we use --draft sparingly"')"
rm -rf "$_EV_G6C"

echo "── bypasses + general ──"
expect "EOS_BYPASS_FORCEPUSH skips G1"  0 "$(EOS_BYPASS_FORCEPUSH=1 run 'git push --force')"
expect "EOS_BYPASS_DRAFTPR skips G2"    0 "$(EOS_BYPASS_DRAFTPR=1 run 'gh pr create --draft')"
expect "EOS_BYPASS_GIT (master) skips all" 0 "$(EOS_BYPASS_GIT=1 run 'git push --force')"
expect "non-git command allowed"       0 "$(run 'echo hello --force --draft')"
expect "empty stdin allowed"           0 "$(printf '' | bash "$ENFORCER" pretooluse >/dev/null 2>&1; echo $?)"

echo
echo "════════ $PASS passed, $FAIL failed ════════"
[ "$FAIL" -eq 0 ]
