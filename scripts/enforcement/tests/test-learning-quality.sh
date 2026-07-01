#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
GATE="$ROOT/scripts/enforcement/enforce-learning-capture.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG="$TMP/out.log"

passcase() { local name="$1"; shift; "$@" >"$LOG" 2>&1 || { echo "fail: $name"; cat "$LOG"; exit 1; }; echo "ok: $name"; }
blockcase() { local name="$1"; shift; if "$@" >"$LOG" 2>&1; then echo "unexpected pass: $name"; cat "$LOG"; exit 1; else echo "ok: $name"; fi; }

repo() {
  rm -rf "$TMP/repo"
  mkdir -p "$TMP/repo/.claude/plans" "$TMP/repo/src/core" "$TMP/repo/lessons-learned/bugs" "$TMP/repo/failed-solutions"
  cd "$TMP/repo"
  git init >/dev/null
  git config user.email test@example.com
  git config user.name test
  echo base > README.md
  git add README.md
  git commit -m base >/dev/null
  cat > .claude/plans/active.md <<'PLAN'
# Route Plan

| Field | Decision |
|---|---|
| Task class | bug_fix |
| Domain tags | core |
PLAN
}

code() { echo "export const value = $1;" > src/core/item.ts; git add src/core/item.ts; }

shallow_lesson() {
  cat > lessons-learned/bugs/item.md <<'LESSON'
# Item

## מה קרה
A change failed.

## שורש הבעיה
TODO

## השערות שנבדקו
- Unknown.

## ראיה
None.

## רמת ביטחון
Low

## איך מזהים מוקדם
Not sure.

## איך מונעים בעתיד
Later.

## טסט רגרסיה
N/A

## סטטוס הבשלה
Draft

## Prevented Future Issues: 0

## Prevention/Enforcement Update
TODO
LESSON
  git add lessons-learned/bugs/item.md
}

valid_lesson() {
  local link_line="${1:-}"
  cat > lessons-learned/bugs/item.md <<LESSON
# Item

## מה קרה
A state regression occurred.

## שורש הבעיה
The root cause was verified by a failing regression test that reproduced a missing state update.

## השערות שנבדקו
- Cache idea was rejected by logs.
$link_line
- Missing state update was verified by regression test.

## ראיה
The regression test failed before the fix and passed after the fix in the fixture command.

## רמת ביטחון
Medium

## איך מזהים מוקדם
Run the state regression before core state changes.

## איך מונעים בעתיד
Keep the regression test and run the check before touching the state update path.

## טסט רגרסיה
scripts/enforcement/tests/test-learning-quality.sh

## סטטוס הבשלה
Verified Lesson

## Prevented Future Issues: 0

## Prevention/Enforcement Update
Added or kept a regression enforcement check that prevents this class of issue.
LESSON
  git add lessons-learned/bugs/item.md
}

failed_note() {
  cat > failed-solutions/item-cache.md <<'NOTE'
# Attempt note

## מה ניסיתי
Cache refresh.

## למה לא עבד
The root cause was a missing state update.

## מה לבדוק במקום
Verify the state update path.
NOTE
  git add failed-solutions/item-cache.md
}

run_gate() { (cd "$TMP/repo" && bash "$GATE"); }

repo; code 1; shallow_lesson; blockcase shallow_content_blocked run_gate
repo; code 2; valid_lesson; passcase valid_content_allowed run_gate
repo; code 3; failed_note; valid_lesson; blockcase missing_failed_note_link_blocked run_gate
repo; code 4; failed_note; valid_lesson "- failed-solutions/item-cache.md was rejected by logs."; passcase linked_failed_note_allowed run_gate

echo "learning quality simulations passed"
