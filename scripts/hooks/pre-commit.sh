#!/bin/bash
# Engineering OS — portable pre-commit hook
# Drop into <project>/.git/hooks/pre-commit and chmod +x
# Blocks commits if linter or tests fail.
# Install: cp scripts/hooks/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

set -e

STAGED=$(git diff --cached --name-only)
[ -z "$STAGED" ] && exit 0

if [ -f "package.json" ]; then
  npm run lint --if-present && npm test --if-present
elif [ -f "pyproject.toml" ]; then
  ruff check . && pytest --tb=short -q
elif [ -f "Makefile" ]; then
  make lint test
fi
