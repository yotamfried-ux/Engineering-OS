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

# Code change without a Route Plan must fail; otherwise connector use can bypass review.
git checkout -q -b code-without-plan "$BASE"
echo 'print("hello")' > src/app.py
git add src/app.py
git commit -qm code-without-plan
expect_fail code-without-plan "$(git rev-parse HEAD)"

# A changed Route Plan must explicitly declare External systems/connectors.
git checkout -q -b plan-missing-external-field "$BASE"
mkdir -p .claude/plans
cat > .claude/plans/task.md <<'PLAN'
# Task

## Route Plan

| Field | Value |
|---|---|
| Task type | Documentation |

## Connector Evidence

- [x] Not required.
PLAN
git add .claude/plans/task.md
git commit -qm plan-missing-external-field
expect_fail plan-missing-external-field "$(git rev-parse HEAD)"

# A code change with an explicit no-connector plan should pass.
git checkout -q -b code-with-none-plan "$BASE"
mkdir -p .claude/plans src
cat > .claude/plans/task.md <<'PLAN'
# Task

## Route Plan

| Field | Value |
|---|---|
| External systems/connectors | none |

## Connector Evidence

- [x] External systems/connectors: none.
PLAN
echo 'print("hello")' > src/app.py
git add .claude/plans/task.md src/app.py
git commit -qm code-with-none-plan
expect_pass code-with-none-plan "$(git rev-parse HEAD)"

# A connector declaration without real evidence must fail.
git checkout -q -b connector-without-evidence "$BASE"
mkdir -p .claude/plans
cat > .claude/plans/task.md <<'PLAN'
# Task

## Route Plan

| Field | Value |
|---|---|
| External systems/connectors | GitHub REST API v3 |

## Goal

Do work.
PLAN
git add .claude/plans/task.md
git commit -qm connector-without-evidence
expect_fail connector-without-evidence "$(git rev-parse HEAD)"

# A loose mention must not satisfy the required heading.
git checkout -q -b loose-mention "$BASE"
mkdir -p .claude/plans
cat > .claude/plans/task.md <<'PLAN'
# Task

## Route Plan

| Field | Value |
|---|---|
| External systems/connectors | GitHub REST API v3 |

TODO: add Connector Evidence later.
PLAN
git add .claude/plans/task.md
git commit -qm loose-mention
expect_fail loose-mention "$(git rev-parse HEAD)"

# Connector Evidence alone is no longer enough; usage influence is required.
git checkout -q -b connector-evidence-without-usage "$BASE"
mkdir -p .claude/plans
cat > .claude/plans/task.md <<'PLAN'
# Task

## Route Plan

| Field | Value |
|---|---|
| External systems/connectors | GitHub REST API v3 |

## Connector Evidence

- [x] Connector: GitHub REST API v3.
- [x] Purpose: planning-only validation.
PLAN
git add .claude/plans/task.md
git commit -qm connector-evidence-without-usage
expect_fail connector-evidence-without-usage "$(git rev-parse HEAD)"

# A loose usage heading with no source/action/result wording must fail.
git checkout -q -b connector-usage-too-vague "$BASE"
mkdir -p .claude/plans
cat > .claude/plans/task.md <<'PLAN'
# Task

## Route Plan

| Field | Value |
|---|---|
| External systems/connectors | GitHub REST API v3 |

## Connector Evidence

- [x] Connector: GitHub REST API v3.

## Connector Usage Evidence

- GitHub.
PLAN
git add .claude/plans/task.md
git commit -qm connector-usage-too-vague
expect_fail connector-usage-too-vague "$(git rev-parse HEAD)"

# A connector declaration with evidence and usage influence should pass.
git checkout -q -b connector-with-evidence "$BASE"
mkdir -p .claude/plans
cat > .claude/plans/task.md <<'PLAN'
# Task

## Route Plan

| Field | Value |
|---|---|
| External systems/connectors | GitHub REST API v3 |

## Connector Evidence

- [x] Connector: GitHub REST API v3.
- [x] Purpose: planning-only validation.
- [x] Scope: no secrets or runtime calls.

## Connector Usage Evidence

- GitHub REST API v3: checked repository source state and used the result to choose the implementation path.
PLAN
git add .claude/plans/task.md
git commit -qm connector-with-evidence
expect_pass connector-with-evidence "$(git rev-parse HEAD)"

echo "connector route plan checker tests passed"
