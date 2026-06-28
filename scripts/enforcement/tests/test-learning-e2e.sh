#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
USE_IN_PROJECT="$ROOT/scripts/use-in-project.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
TARGET="$TMP/learning-target"
mkdir -p "$TARGET"

git init "$TARGET" >/dev/null
git -C "$TARGET" config user.email test@example.com
git -C "$TARGET" config user.name test

echo "# target" > "$TARGET/README.md"
git -C "$TARGET" add README.md
git -C "$TARGET" commit --no-verify -m "init" >/dev/null

(
  cd "$TARGET"
  EOS_CONTRACT_TEST=1 ENGINEERING_OS_HOME="$ROOT" bash "$USE_IN_PROJECT" >/dev/null
)

test -x "$TARGET/.git/hooks/pre-commit"
test -f "$TARGET/.engineering-os/REFERENCE.md"
test -f "$TARGET/.claude/settings.json"

git -C "$TARGET" add -A
git -C "$TARGET" commit --no-verify -m "install engineering os" >/dev/null

run_precommit() {
  (cd "$TARGET" && .git/hooks/pre-commit) >/tmp/eos-learning-precommit.log 2>&1
}

cleanup_case() {
  git -C "$TARGET" reset -q >/dev/null 2>&1 || true
  git -C "$TARGET" clean -fdq >/dev/null 2>&1 || true
}

expect_blocked_precommit() {
  local name="$1"
  if run_precommit; then
    echo "  ❌ expected pre-commit to block: $name"
    cat /tmp/eos-learning-precommit.log
    exit 1
  fi
  echo "  ✅ blocked: $name"
  cleanup_case
}

expect_allowed_precommit() {
  local name="$1"
  if run_precommit; then
    echo "  ✅ allowed: $name"
  else
    echo "  ❌ expected pre-commit to allow: $name"
    cat /tmp/eos-learning-precommit.log
    exit 1
  fi
}

mkdir -p "$TARGET/lessons-learned/bugs" "$TARGET/failed-solutions"

cat > "$TARGET/lessons-learned/bugs/missing-evidence.md" <<'LESSON'
# Bug: missing evidence

## מה קרה
A repeated production-like symptom appeared.

## שורש הבעיה
The claimed root cause is not supported.

## רמת ביטחון
Medium

## איך מונעים בעתיד
Add a gate.

## טסט רגרסיה
tests/repro.test.ts

## סטטוס הבשלה
Verified Lesson

## Prevented Future Issues: 0
LESSON
git -C "$TARGET" add lessons-learned/bugs/missing-evidence.md
expect_blocked_precommit "bad lesson is blocked"

mkdir -p "$TARGET/lessons-learned/bugs"
cat > "$TARGET/lessons-learned/bugs/verified-root-cause.md" <<'LESSON'
# Bug: verified root cause

## מה קרה
A simulated target project had a recurring failure.

## שורש הבעיה
The failing behavior was caused by a missing required guard.

## השערות שנבדקו
- Wrong environment variable — rejected because the reproduction did not read env.
- Missing guard — verified by the failing regression fixture.

## ראיה
The E2E simulation reproduced the failure before accepting this lesson.

## רמת ביטחון
Medium

## איך מזהים מוקדם
Run the regression fixture before changing the affected area.

## איך מונעים בעתיד
Keep the pre-commit learning schema gate enabled.

## טסט רגרסיה
scripts/enforcement/tests/test-learning-e2e.sh

## סטטוס הבשלה
Verified Lesson

## Prevented Future Issues: 0
LESSON
git -C "$TARGET" add lessons-learned/bugs/verified-root-cause.md
expect_allowed_precommit "valid lesson is allowed"
grep -q 'Prevented Future Issues: 0' "$TARGET/lessons-learned/bugs/verified-root-cause.md"
cleanup_case

mkdir -p "$TARGET/failed-solutions"
cat > "$TARGET/failed-solutions/no-alternative.md" <<'FAILSOL'
# Failed solution: no alternative

## מה ניסיתי
Tried a broad workaround.

## למה לא עבד
It did not address the verified root cause.
FAILSOL
git -C "$TARGET" add failed-solutions/no-alternative.md
expect_blocked_precommit "bad failed-solution is blocked"

mkdir -p "$TARGET/failed-solutions"
cat > "$TARGET/failed-solutions/with-alternative.md" <<'FAILSOL'
# Failed solution: with alternative

## מה ניסיתי
Tried a broad workaround.

## למה לא עבד
It did not address the verified root cause.

## מה לבדוק במקום
Check the guard that would have prevented the failure.
FAILSOL
git -C "$TARGET" add failed-solutions/with-alternative.md
expect_allowed_precommit "valid failed-solution is allowed"
cleanup_case

# Important boundary: today's deterministic loop proves capture/enforcement of verified
# knowledge structure. It does not yet enforce that an agent read a relevant lesson before
# touching a matching future area, nor does it auto-increment Prevented Future Issues.
echo "learning loop E2E simulation passed"
