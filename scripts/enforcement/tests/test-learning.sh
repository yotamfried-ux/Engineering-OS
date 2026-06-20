#!/usr/bin/env bash
# test-learning.sh — regression tests for the learning-loop.md enforcer.
# Run: bash scripts/enforcement/tests/test-learning.sh
set -u

ENFORCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENFORCER="$ENFORCE_DIR/enforce-learning.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; }
expect() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected exit $2, got $3)"; fi; }

REPO="$(mktemp -d)"; trap 'rm -rf "$REPO" 2>/dev/null' EXIT
cd "$REPO" || exit 1
git init -q 2>/dev/null; git config user.email t@t.t; git config user.name t

# Full conformant lesson body (all 8 required sections).
LESSON_OK="$(cat <<'EOF'
# Bug: דוגמה
## מה קרה
תסמין
## שורש הבעיה
שורש
## ראיה
לוג
## רמת ביטחון
Medium
## איך מונעים בעתיד
hook
## טסט רגרסיה
path
## סטטוס הבשלה
Verified Lesson
## Prevented Future Issues: 0
EOF
)"
# Same but missing "## ראיה".
LESSON_NO_EVIDENCE="$(cat <<'EOF'
# Bug: דוגמה
## מה קרה
תסמין
## שורש הבעיה
שורש
## רמת ביטחון
Medium
## איך מונעים בעתיד
hook
## טסט רגרסיה
path
## סטטוס הבשלה
Verified Lesson
## Prevented Future Issues: 0
EOF
)"
# Same but missing the Prevented counter line.
LESSON_NO_PREVENTED="$(cat <<'EOF'
# Bug: דוגמה
## מה קרה
תסמין
## שורש הבעיה
שורש
## ראיה
לוג
## רמת ביטחון
Medium
## איך מונעים בעתיד
hook
## טסט רגרסיה
path
## סטטוס הבשלה
Verified Lesson
EOF
)"

FAILSOL_OK="$(cat <<'EOF'
# ניסיון: דוגמה
## מה ניסיתי
גישה
## למה לא עבד
שגיאה
## מה לבדוק במקום
חלופה
EOF
)"
FAILSOL_NO_ALT="$(cat <<'EOF'
# ניסיון: דוגמה
## מה ניסיתי
גישה
## למה לא עבד
שגיאה
EOF
)"

# stage_run <path> <content> — stage a file, run enforcer, echo exit, reset index.
stage_run() {
  local f="$1"; mkdir -p "$(dirname "$f")" 2>/dev/null
  printf '%s\n' "$2" > "$f"; git add -f "$f" 2>/dev/null
  bash "$ENFORCER" >/dev/null 2>&1; local rc=$?
  git reset -q 2>/dev/null; rm -f "$f" 2>/dev/null
  echo "$rc"
}

echo "── L1: lesson schema (lessons-learned/bugs/) ──"
expect "conformant lesson allowed"        0 "$(stage_run lessons-learned/bugs/x.md "$LESSON_OK")"
expect "missing ## ראיה blocked"          1 "$(stage_run lessons-learned/bugs/x.md "$LESSON_NO_EVIDENCE")"
expect "missing Prevented counter blocked" 1 "$(stage_run lessons-learned/bugs/x.md "$LESSON_NO_PREVENTED")"
expect "README.md skipped"                0 "$(stage_run lessons-learned/bugs/README.md '# index')"
expect "_TEMPLATE.md skipped"             0 "$(stage_run lessons-learned/bugs/_TEMPLATE.md '# tpl')"
expect "EOS_BYPASS_LESSON skips L1"       0 "$(EOS_BYPASS_LESSON=1 stage_run lessons-learned/bugs/x.md "$LESSON_NO_EVIDENCE")"

echo "── L2: failed-solutions schema ──"
expect "conformant failed-solution allowed" 0 "$(stage_run failed-solutions/x.md "$FAILSOL_OK")"
expect "missing 'מה לבדוק במקום' blocked"   1 "$(stage_run failed-solutions/x.md "$FAILSOL_NO_ALT")"
expect "EOS_BYPASS_FAILSOL skips L2"        0 "$(EOS_BYPASS_FAILSOL=1 stage_run failed-solutions/x.md "$FAILSOL_NO_ALT")"

echo "── excluded paths & general ──"
expect "prevention-strategies/ skipped"   0 "$(stage_run lessons-learned/prevention-strategies/p.md '# strat')"
expect "postmortems/ skipped"             0 "$(stage_run lessons-learned/postmortems/p.md '# pm')"
expect "file outside lesson dirs skipped" 0 "$(stage_run src/x.md '# code doc')"
expect "EOS_BYPASS_LEARNING (master)"     0 "$(EOS_BYPASS_LEARNING=1 stage_run lessons-learned/bugs/x.md "$LESSON_NO_EVIDENCE")"
expect "no staged files → pass"           0 "$(bash "$ENFORCER" >/dev/null 2>&1; echo $?)"

echo
echo "════════ $PASS passed, $FAIL failed ════════"
[ "$FAIL" -eq 0 ]
