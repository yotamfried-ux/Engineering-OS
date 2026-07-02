#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-workflow-evidence.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PROGRESS_START='## Progress Lifecycle Evidence

- start: plan created before code.
'
PROGRESS_MID='## Progress Lifecycle Evidence

- start: plan created before code.
- mid: validation ran after code began.
'
PROGRESS_FULL='## Progress Lifecycle Evidence

- start: plan created before code.
- mid: validation ran after code began.
- pre-merge: final checks verified after code changes.
'

make_repo() {
  local name="$1" plan_body="$2"
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
' "${plan_body//\$PROGRESS/$PROGRESS_START}" > .claude/plans/plan.md
  git add .claude/plans/plan.md
  git commit -q -m plan-start
  echo changed > scripts/enforcement/example.sh
  git add scripts/enforcement/example.sh
  git commit -q -m change
  printf '%s
' "${plan_body//\$PROGRESS/$PROGRESS_MID}" > .claude/plans/plan.md
  git add .claude/plans/plan.md
  git commit -q -m plan-mid
  printf '%s
' "${plan_body//\$PROGRESS/$PROGRESS_FULL}" > .claude/plans/plan.md
  git add .claude/plans/plan.md
  git commit -q -m plan-pre-merge
  head="$(git rev-parse HEAD)"
}

assert_fail() {
  local label="$1" plan="$2" expected="$3"
  make_repo "$label" "$plan"
  if bash "$CHECK" "$base" "$head" >"$TMP/$label.out" 2>&1; then
    echo "expected failure: $label"
    exit 1
  fi
  grep -qi "$expected" "$TMP/$label.out"
}

assert_pass() {
  local label="$1" plan="$2"
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

$PROGRESS
## Claude Run Trace
- goal: test semantic source relevance.
'

BAD="# Plan

$BASE_PLAN
## DoD

- [x] fixture verified by this suite checker run.

## Source of Truth Checks

| Source | Status |
|---|---|
| docs/operations/other.md | checked |
| docs/README.md | checked |
"

GOOD_TARGET="# Plan

$BASE_PLAN
## DoD

- [x] fixture verified by this suite checker run.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/example.sh | checked |
"

CANONICAL_ONLY="# Plan

$BASE_PLAN
## DoD

- [x] fixture verified by this suite checker run.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| core/workflow.md | checked |
"

assert_fail bad-generic-sources "$BAD" "target paths"
assert_pass good-target-source "$GOOD_TARGET"
assert_fail canonical-only-sources-fail "$CANONICAL_ONLY" "target paths"

echo "plan semantic quality checks passed"
