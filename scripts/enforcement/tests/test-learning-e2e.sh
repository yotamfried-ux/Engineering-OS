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
git -C "$TARGET" commit -m "init" >/dev/null

(
  cd "$TARGET"
  EOS_CONTRACT_TEST=1 ENGINEERING_OS_HOME="$ROOT" bash "$USE_IN_PROJECT" >/dev/null
)

test -x "$TARGET/.git/hooks/pre-commit"
test -f "$TARGET/.engineering-os/REFERENCE.md"
test -f "$TARGET/.claude/settings.json"

git -C "$TARGET" add CLAUDE.md .engineering-os/REFERENCE.md ENGINEERING_OS_SETUP.md ENGINEERING_OS_CAPABILITIES.md .claude .github .gitignore .claudeignore 2>/dev/null || true
git -C "$TARGET" commit -m "install engineering os" >/dev/null

expect_blocked_commit() {
  local name="$1"
  if git -C "$TARGET" commit -m "$name" >/tmp/eos-learning-commit.log 2>&1; then
    echo "  ❌ expected commit to be blocked: $name"
    cat /tmp/eos-learning-commit.log
    exit 1
  fi
  echo "  ✅ blocked: $name"
}

expect_allowed_commit() {
  local name="$1"
  if git -C "$TARGET" commit -m "$name" >/tmp/eos-learning-commit.log 2>&1; then
    echo "  ✅ allowed: $name"
  else
    echo "  ❌ expected commit to be allowed: $name"
    cat /tmp/eos-learning-commit.log
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
expect_blocked_commit "bad lesson is blocked"
git -C "$TARGET" reset --hard HEAD >/dev/null

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
expect_allowed_commit "valid lesson is allowed"

cat > "$TARGET/failed-solutions/no-alternative.md" <<'FAILSOL'
# Failed solution: no alternative

## מה ניסיתי
Tried a broad workaround.

## למה לא עבד
It did not address the verified root cause.
FAILSOL
git -C "$TARGET" add failed-solutions/no-alternative.md
expect_blocked_commit "bad failed-solution is blocked"
git -C "$TARGET" reset --hard HEAD >/dev/null

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
expect_allowed_commit "valid failed-solution is allowed"

# Important boundary: today's deterministic loop proves capture/enforcement of verified
# knowledge structure. It does not yet enforce that an agent read a relevant lesson before
# touching a matching future area, nor does it auto-increment Prevented Future Issues.
grep -q 'Prevented Future Issues: 0' "$TARGET/lessons-learned/bugs/verified-root-cause.md"

echo "learning loop E2E simulation passed"
