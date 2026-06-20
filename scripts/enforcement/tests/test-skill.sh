#!/usr/bin/env bash
# test-skill.sh — regression tests for the skill-orchestration-policy.md enforcer.
# Run: bash scripts/enforcement/tests/test-skill.sh
set -u

ENFORCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENFORCER="$ENFORCE_DIR/enforce-skill.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; }
expect() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected exit $2, got $3)"; fi; }

REPO="$(mktemp -d)"; trap 'rm -rf "$REPO" 2>/dev/null' EXIT
cd "$REPO" || exit 1
git init -q 2>/dev/null; git config user.email t@t.t; git config user.name t

# Registry baseline (committed) — uses the real registry link form [name](./name/)
# so the enforcer's exact match is exercised.
mkdir -p external-skills
{
  echo '# Registry'
  echo
  echo '| **[goodskill](./goodskill/)** | desc |'
  echo '| **[nopolicy](./nopolicy/)** | desc |'
  echo '| **[noact](./noact/)** | desc |'
} > external-skills/README.md
git add external-skills/README.md; git commit -qm init 2>/dev/null

ALL4="README.md integration.md policy.md activation.md"

# mkskill <name> <files...> — create a skill dir with the given files, stage it,
# run the enforcer, echo exit code, then reset/clean.
mkskill() {
  local name="$1"; shift
  local d="external-skills/$name"; mkdir -p "$d"
  local f; for f in "$@"; do echo "x" > "$d/$f"; done
  git add "$d" 2>/dev/null
  bash "$ENFORCER" >/dev/null 2>&1; local rc=$?
  git reset -q 2>/dev/null; rm -rf "$d" 2>/dev/null
  echo "$rc"
}

echo "── S1: four contract files ──"
expect "complete + registered skill allowed" 0 "$(mkskill goodskill $ALL4)"
expect "missing policy.md blocked"            1 "$(mkskill nopolicy README.md integration.md activation.md)"
expect "missing activation.md blocked"        1 "$(mkskill noact README.md integration.md policy.md)"
expect "EOS_BYPASS_SKILLDOC skips S1"         0 "$(EOS_BYPASS_SKILLDOC=1 mkskill nopolicy README.md integration.md activation.md)"

echo "── S2: registry registration ──"
expect "unregistered skill blocked"           1 "$(mkskill ghostskill $ALL4)"
expect "partial-name (substring of registered) blocked" 1 "$(mkskill good $ALL4)"
expect "EOS_BYPASS_SKILLREG skips S2"         0 "$(EOS_BYPASS_SKILLREG=1 mkskill ghostskill $ALL4)"

echo "── excluded paths & general ──"
# Editing the top-level registry itself is not a skill dir → pass.
printf '\n- extra\n' >> external-skills/README.md; git add external-skills/README.md
expect "editing registry README allowed"      0 "$(bash "$ENFORCER" >/dev/null 2>&1; echo $?)"
git reset -q; git checkout -q -- external-skills/README.md
expect "file outside external-skills allowed" 0 "$(mkdir -p src; echo x > src/x.md; git add src/x.md; bash "$ENFORCER" >/dev/null 2>&1; rc=$?; git reset -q; rm -rf src; echo $rc)"
expect "EOS_BYPASS_SKILL (master) skips all"  0 "$(EOS_BYPASS_SKILL=1 mkskill ghostskill README.md)"
expect "no staged files → pass"               0 "$(bash "$ENFORCER" >/dev/null 2>&1; echo $?)"

echo
echo "════════ $PASS passed, $FAIL failed ════════"
[ "$FAIL" -eq 0 ]
