#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECKER="$ROOT/scripts/enforcement/check-connector-evidence.sh"
chmod +x "$CHECKER"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cd "$TMP"
git init -q
git config user.email test@example.com
git config user.name test
mkdir -p .claude/plans src
echo initial > README.md
git add README.md
git commit -qm initial
BASE="$(git rev-parse HEAD)"

cat > .claude/plans/task.md <<'PLAN'
# Task

## Connector Evidence
- [x] Not required: documentation-only task.
PLAN
git add .claude/plans/task.md
git commit -qm with-evidence
HEAD_OK="$(git rev-parse HEAD)"
"$CHECKER" "$BASE" "$HEAD_OK"

git checkout -q -b missing "$BASE"
mkdir -p .claude/plans
cat > .claude/plans/task.md <<'PLAN'
# Task

## Goal
Do work.
PLAN
git add .claude/plans/task.md
git commit -qm missing-evidence
HEAD_BAD="$(git rev-parse HEAD)"
if "$CHECKER" "$BASE" "$HEAD_BAD"; then
  echo "expected missing Connector Evidence to fail"
  exit 1
fi

echo "connector evidence checker tests passed"
