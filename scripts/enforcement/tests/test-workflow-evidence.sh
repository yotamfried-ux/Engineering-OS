#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECKER="$ROOT/scripts/enforcement/check-workflow-evidence.sh"
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

expect_pass() {
  local name="$1"
  local head="$2"
  if ! "$CHECKER" "$BASE" "$head"; then
    echo "expected $name to pass"
    exit 1
  fi
}

expect_fail() {
  local name="$1"
  local head="$2"
  if "$CHECKER" "$BASE" "$head"; then
    echo "expected $name to fail"
    exit 1
  fi
}

write_good_plan() {
  local path="$1"
  cat > "$path" <<'PLAN'
# Route Plan

| Field | Value |
|---|---|
| Task type | Feature implementation |
| Domain tags | api, testing |
| Templates | templates/api-service/README.md checked and reused |
| Patterns | patterns/api/README.md, patterns/testing/README.md |
| External systems/connectors | none |
| Skills | superpowers-verify |
| Validation gates | npm test, PR CI |
| Task-router evidence | core/task-router.md routing matrix consulted |
| Workflow evidence | core/workflow.md steps consulted before coding |

## Source of Truth Checks

| Need | Source checked | Result |
|---|---|---|
| Existing API pattern | patterns/api/README.md | request/response shape selected |

## Skill Evidence

- [x] DoD check planned and captured.
PLAN
}

# Code without plan fails.
git checkout -q -b code-without-plan "$BASE"
echo 'console.log("hello")' > src/app.js
git add src/app.js
git commit -qm code-without-plan
expect_fail code-without-plan "$(git rev-parse HEAD)"

# Plan and code in same commit fails because order is not proven.
git checkout -q -b plan-and-code-same-commit "$BASE"
write_good_plan .claude/plans/task.md
echo 'console.log("hello")' > src/app.js
git add .claude/plans/task.md src/app.js
git commit -qm plan-and-code-same-commit
expect_fail plan-and-code-same-commit "$(git rev-parse HEAD)"

# Plan before code passes.
git checkout -q -b plan-before-code "$BASE"
write_good_plan .claude/plans/task.md
git add .claude/plans/task.md
git commit -qm plan-first
echo 'console.log("hello")' > src/app.js
git add src/app.js
git commit -qm code-second
expect_pass plan-before-code "$(git rev-parse HEAD)"

# Missing task-router evidence fails.
git checkout -q -b missing-router-evidence "$BASE"
write_good_plan .claude/plans/task.md
python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/task.md')
s=p.read_text()
s=s.replace('| Task-router evidence | core/task-router.md routing matrix consulted |\n','')
p.write_text(s)
PY
git add .claude/plans/task.md
git commit -qm missing-router-evidence
expect_fail missing-router-evidence "$(git rev-parse HEAD)"

# Missing source-of-truth checks fails.
git checkout -q -b missing-source-checks "$BASE"
write_good_plan .claude/plans/task.md
python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/task.md')
s=p.read_text()
s=s.split('## Source of Truth Checks')[0] + '## Skill Evidence\n\n- [x] DoD check planned.\n'
p.write_text(s)
PY
git add .claude/plans/task.md
git commit -qm missing-source-checks
expect_fail missing-source-checks "$(git rev-parse HEAD)"

# Declared skill without evidence fails.
git checkout -q -b missing-skill-evidence "$BASE"
write_good_plan .claude/plans/task.md
python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/task.md')
s=p.read_text().split('## Skill Evidence')[0]
p.write_text(s)
PY
git add .claude/plans/task.md
git commit -qm missing-skill-evidence
expect_fail missing-skill-evidence "$(git rev-parse HEAD)"

# Template gap without waiver or learning/template artifact fails.
git checkout -q -b template-gap-no-waiver "$BASE"
write_good_plan .claude/plans/task.md
python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/task.md')
s=p.read_text()
s=s.replace('templates/api-service/README.md checked and reused','none — no matching template exists')
p.write_text(s)
PY
git add .claude/plans/task.md
git commit -qm template-gap-no-waiver
expect_fail template-gap-no-waiver "$(git rev-parse HEAD)"

# Template gap with waiver passes.
git checkout -q -b template-gap-with-waiver "$BASE"
write_good_plan .claude/plans/task.md
python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/task.md')
s=p.read_text()
s=s.replace('templates/api-service/README.md checked and reused','none — no matching template exists')
s += '\n## Template Gap Waiver\n\nThe task is an internal test fixture; no reusable template should be added.\n'
p.write_text(s)
PY
git add .claude/plans/task.md
git commit -qm template-gap-with-waiver
expect_pass template-gap-with-waiver "$(git rev-parse HEAD)"

echo "workflow evidence checker tests passed"
