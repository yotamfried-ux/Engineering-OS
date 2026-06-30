#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-workflow-evidence.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

make_repo() {
  local name="$1"
  local plan_body="$2"
  mkdir -p "$TMP/$name"
  cd "$TMP/$name"
  git init -q
  git config user.email test@example.com
  git config user.name test
  mkdir -p .claude/plans scripts/enforcement
  echo base > README.md
  git add .
  git commit -q -m base
  base="$(git rev-parse HEAD)"
  printf '%s
' "$plan_body" > .claude/plans/plan.md
  git add .claude/plans/plan.md
  git commit -q -m plan
  echo changed > scripts/enforcement/example.sh
  git add scripts/enforcement/example.sh
  git commit -q -m change
  head="$(git rev-parse HEAD)"
}

assert_fail() {
  local label="$1"
  local plan="$2"
  local expected="$3"
  make_repo "$label" "$plan"
  if bash "$CHECK" "$base" "$head" >"$TMP/$label.out" 2>&1; then
    echo "expected failure: $label"
    exit 1
  fi
  grep -qi "$expected" "$TMP/$label.out"
}

assert_pass() {
  local label="$1"
  local plan="$2"
  make_repo "$label" "$plan"
  bash "$CHECK" "$base" "$head"
}

BASE_PLAN='| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | governance, workflow, tests |
| Target paths | scripts/enforcement/example.sh |
| Templates | not required |
| Patterns | shell test pattern |
| Skills | superpowers |
| Validation gates | enforcement-tests |

## Template Gap Waiver
reason: no template applies.

## Skill Evidence
- superpowers

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| core/workflow.md | checked |

## Claude Run Trace
- goal: test progress lifecycle.
'

NO_PROGRESS="# Plan

$BASE_PLAN"

MISSING_MID="# Plan

$BASE_PLAN
## Progress Lifecycle Evidence

- start: plan created before code.
- pre-merge: final checks verified.
"

GOOD="# Plan

$BASE_PLAN
## Progress Lifecycle Evidence

- start: plan created before code.
- mid: CI/simulation loop validated.
- pre-merge: final checks verified.
"

assert_fail no-progress "$NO_PROGRESS" "progress lifecycle"
assert_fail missing-mid "$MISSING_MID" "mid checkpoint"
assert_pass good-progress "$GOOD"

echo "progress lifecycle checks passed"
