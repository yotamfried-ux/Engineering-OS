#!/usr/bin/env bash
# test-resource.sh — regression tests for the resource-management.md enforcer.
# Run: bash scripts/enforcement/tests/test-resource.sh
set -u

ENFORCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENFORCER="$ENFORCE_DIR/enforce-resource.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; }
expect() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected exit $2, got $3)"; fi; }

REPO="$(mktemp -d)"; trap 'rm -rf "$REPO" 2>/dev/null' EXIT
cd "$REPO" || exit 1
git init -q 2>/dev/null
git config user.email t@t.t; git config user.name t
M="$REPO/M"

echo "── R1: .claudeignore must exist (precommit) ──"
rm -f .claudeignore
bash "$ENFORCER" precommit >/dev/null 2>&1; expect "missing .claudeignore blocked" 1 $?
touch .claudeignore
bash "$ENFORCER" precommit >/dev/null 2>&1; expect "present .claudeignore allowed" 0 $?
rm -f .claudeignore
EOS_BYPASS_CLAUDEIGNORE=1 bash "$ENFORCER" precommit >/dev/null 2>&1; expect "EOS_BYPASS_CLAUDEIGNORE skips R1" 0 $?
EOS_BYPASS_RESOURCE=1    bash "$ENFORCER" precommit >/dev/null 2>&1; expect "EOS_BYPASS_RESOURCE (master) skips R1" 0 $?

echo "── R2: no model identifier in commit message (commit-msg) ──"
printf 'fix: bump to claude-opus-4-8\n'        > "$M"; bash "$ENFORCER" commit-msg "$M" >/dev/null 2>&1; expect "opus model id blocked"   1 $?
printf 'feat: default to claude-sonnet-4-6\n'  > "$M"; bash "$ENFORCER" commit-msg "$M" >/dev/null 2>&1; expect "sonnet model id blocked" 1 $?
printf 'feat: add new endpoint\n'              > "$M"; bash "$ENFORCER" commit-msg "$M" >/dev/null 2>&1; expect "clean message allowed"    0 $?
printf 'feat: x\n\nCo-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>\n' > "$M"
bash "$ENFORCER" commit-msg "$M" >/dev/null 2>&1; expect "standard Co-Authored-By trailer allowed" 0 $?
printf 'fix: bump to claude-opus-4-8\n' > "$M"
EOS_BYPASS_MODELID=1  bash "$ENFORCER" commit-msg "$M" >/dev/null 2>&1; expect "EOS_BYPASS_MODELID skips R2" 0 $?
EOS_BYPASS_RESOURCE=1 bash "$ENFORCER" commit-msg "$M" >/dev/null 2>&1; expect "EOS_BYPASS_RESOURCE (master) skips R2" 0 $?

echo
echo "════════ $PASS passed, $FAIL failed ════════"
[ "$FAIL" -eq 0 ]
