#!/usr/bin/env bash
# commit-msg hook — blocks commits missing required format sections or lying about tests
# Install: cp scripts/hooks/commit-msg.sh .git/hooks/commit-msg && chmod +x .git/hooks/commit-msg
# Governing policy: core/git-policy.md <commit_protocol>

MSG_FILE="$1"
MSG=$(cat "$MSG_FILE")
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Resolve the Engineering OS reference the same way pre-commit.sh does: inside
# the Engineering OS repo this is the repo root; inside a target project
# installed with use-in-project.sh, the shared read-only reference path is
# stored in .engineering-os/REFERENCE.md. Without this, enforce-debugging.sh
# and enforce-resource.sh below would look for themselves inside the TARGET
# repo (which never has them) and silently no-op in every installed project.
EOS_HOME="${ENGINEERING_OS_HOME:-}"
if [ -z "$EOS_HOME" ] && [ -f "$REPO_ROOT/.engineering-os/REFERENCE.md" ]; then
  EOS_HOME="$(sed -n 's/^- Reference location: `\(.*\)`/\1/p' "$REPO_ROOT/.engineering-os/REFERENCE.md" | head -1)"
fi
EOS_HOME="${EOS_HOME:-$REPO_ROOT}"

# Exempt merge/revert commits
case "$MSG" in "Merge "*|"Revert "*) exit 0 ;; esac

has() { echo "$MSG" | grep -q "$1"; }
MISSING=""
has "✅" || MISSING="${MISSING}✅ "
has "❌" || MISSING="${MISSING}❌ "
has "🔄" || MISSING="${MISSING}🔄 "
has "🧪" || MISSING="${MISSING}🧪 "

if [ -n "$MISSING" ]; then
  echo "❌ COMMIT BLOCKED — commit message missing required sections: $MISSING"
  echo "   Format: ✅ עובד / ❌ לא עובד / 🔄 השתנה / 🧪 בדיקות"
  echo "   See: core/git-policy.md <commit_protocol>"
  exit 1
fi

# Block commits that claim "no tests" — forces explicit N/A justification
TEST_CONTENT=$(echo "$MSG" | grep -A3 "🧪" | tail -3)
if echo "$TEST_CONTENT" | grep -iE "^[[:space:]]*(none|no tests?|אין|לא נכתבו)[[:space:]]*$" >/dev/null 2>&1; then
  echo "❌ COMMIT BLOCKED — 🧪 section says 'none'."
  echo "   Either write tests, or document explicitly WHY N/A (e.g., 'chore: no logic changed')."
  echo "   Only Merge/Revert commits are exempt from this check."
  exit 1
fi

# debugging-policy.md — a `fix:` commit must add a regression test (debug_loop step 7).
# Governing policy: core/debugging-policy.md. Bypass: EOS_BYPASS_FIXTEST=1 (or EOS_BYPASS_DEBUG=1).
if [ -f "$EOS_HOME/scripts/enforcement/enforce-debugging.sh" ]; then
  bash "$EOS_HOME/scripts/enforcement/enforce-debugging.sh" commit-msg "$MSG_FILE" || exit 1
else
  echo "warning: enforce-debugging.sh not found under $EOS_HOME/scripts/enforcement (debugging-policy check skipped)" >&2
fi

# resource-management.md <model-selection> — no model identifier in commit messages.
# Governing policy: core/resource-management.md. Bypass: EOS_BYPASS_MODELID=1.
if [ -f "$EOS_HOME/scripts/enforcement/enforce-resource.sh" ]; then
  bash "$EOS_HOME/scripts/enforcement/enforce-resource.sh" commit-msg "$MSG_FILE" || exit 1
else
  echo "warning: enforce-resource.sh not found under $EOS_HOME/scripts/enforcement (model-id check skipped)" >&2
fi

# quality-gates.md — block a large code commit when the project has ZERO test files.
# Lives here (not pre-commit) so the commit TYPE from the message drives exemptions;
# pre-commit doesn't have the commit message yet, so it read the PREVIOUS commit's type.
# Bypass: EOS_BYPASS_TESTFILES=1.
case "${EOS_BYPASS_TESTFILES:-}" in 1|true|TRUE|yes|YES) exit 0 ;; esac
TESTFILE_TYPE=$(printf '%s' "$MSG" | head -1 | grep -oE '^[a-z]+' || true)
case "$TESTFILE_TYPE" in chore|docs|style|ci|build) exit 0 ;; esac

STAGED_CODE=$(git diff --cached --name-only 2>/dev/null \
  | grep -E '\.(ts|tsx|js|jsx|py|go|rs)$' \
  | grep -vE '(\.(test|spec)\.(ts|tsx|js|jsx|py)|__tests__|/tests/|_test\.go$|(^|/)(test_[^/]*|[^/]*_test|tests)\.py$)' \
  | wc -l | tr -d ' ')

if [ "${STAGED_CODE:-0}" -gt 2 ]; then
  PROJECT_TESTS=$(find "$REPO_ROOT" \
    \( -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.go" -o -name "test_*.py" \
       -o -name "*_test.py" -o -name "tests.py" -o -path "*/tests/*" -o -path "*/__tests__/*" \) \
    -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
  if [ "${PROJECT_TESTS:-0}" -eq 0 ]; then
    echo "❌ COMMIT BLOCKED: $STAGED_CODE code files staged, 0 test files found in project."
    echo "   (Project-wide scan — any test file anywhere satisfies this; not per-file coverage.)"
    echo "   Write at least one test, or use type chore/docs/style/ci/build if no logic changed."
    echo "   BYPASS: EOS_BYPASS_TESTFILES=1."
    exit 1
  fi
fi

exit 0
