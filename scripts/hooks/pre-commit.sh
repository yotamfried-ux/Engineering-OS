#!/bin/bash
# Engineering OS — portable pre-commit hook
# Drop into <project>/.git/hooks/pre-commit and chmod +x
# Blocks commits if linter, tests, or physical test-file scan fails.
# Install: cp scripts/hooks/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

set -e

STAGED=$(git diff --cached --name-only)
[ -z "$STAGED" ] && exit 0

# Block accidental deletion of CLAUDE.md — it is the Engineering OS entry point
if echo "$STAGED" | grep -q "^CLAUDE\.md$"; then
  if ! git show ":CLAUDE.md" > /dev/null 2>&1; then
    echo "❌ BLOCKED: Cannot delete CLAUDE.md — it is the Engineering OS entry point."
    echo "   If intentional, bypass with: SKIP_CLAUDE_CHECK=1 git commit"
    [ "${SKIP_CLAUDE_CHECK:-}" = "1" ] || exit 1
  fi
fi

if [ -f "package.json" ]; then
  npm run lint --if-present && npm test --if-present
elif [ -f "pyproject.toml" ]; then
  ruff check . && pytest --tb=short -q
elif [ -f "Makefile" ]; then
  make lint test
fi

# ── Physical test file enforcement ────────────────────────────────────────────
# Blocks commits when: >2 code files are staged AND the entire project has 0 test files.
# This is a filesystem scan — not a text check of the commit message.
# Note: checks project-wide test existence (not per-change coverage).
#       A project with any test files passes. A project with ZERO tests is blocked on large commits.

STAGED_CODE=$(git diff --cached --name-only 2>/dev/null \
  | grep -E '\.(ts|tsx|js|jsx|py|go|rs)$' \
  | grep -vE '(\.(test|spec)\.(ts|tsx|js|jsx|py)|__tests__|/tests/)' \
  | wc -l | tr -d ' ')

if [ "${STAGED_CODE:-0}" -gt 2 ]; then
  # Exempt chore/docs/style/ci/build commits
  COMMIT_TYPE=$(git log --format=%s -1 HEAD 2>/dev/null | grep -oE '^[a-z]+' || echo "")
  case "$COMMIT_TYPE" in chore|docs|style|ci|build) exit 0 ;; esac

  PROJECT_TESTS=$(find . \
    \( -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.test.js" -o -name "*.test.jsx" \
       -o -name "*.spec.ts" -o -name "*.spec.js" \
       -o -name "*.test.py" -o -name "*.spec.py" \
       -o -name "*.test.go" \) \
    -not -path "*/node_modules/*" \
    -not -path "*/.git/*" \
    2>/dev/null | wc -l | tr -d ' ')

  if [ "${PROJECT_TESTS:-0}" -eq 0 ]; then
    echo "❌ COMMIT BLOCKED: $STAGED_CODE code files staged, 0 test files found in project."
    echo "   (This check fires only when the ENTIRE project has no tests — not per-file coverage)"
    echo "   Write at least one test file anywhere in the project, then commit."
    echo "   Exempt commit types: chore, docs, style, ci, build"
    exit 1
  fi
fi
