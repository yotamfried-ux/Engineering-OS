#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-workflow-evidence.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

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
| core/workflow.md | checked |
| scripts/enforcement/example.sh | checked |

## Claude Run Trace
- goal: test progress lifecycle.
'

START_PROGRESS='## Progress Lifecycle Evidence

- start: route plan committed before implementation work.
'

REAL_PROGRESS='## Progress Lifecycle Evidence

- start: route plan committed before implementation work.
- mid: implementation loop updated after first code change.
- pre-merge: final validation evidence recorded after implementation changes.
'

MID_PROGRESS='## Progress Lifecycle Evidence

- start: route plan committed before implementation work.
- mid: implementation loop updated after first code change.
'

init_repo() {
  local name="$1"
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
}

commit_plan() {
  local body="$1"
  printf '%s
' "# Plan" "" "$BASE_PLAN" "$body" > .claude/plans/plan.md
  git add .claude/plans/plan.md
  git commit -q -m "plan update"
}

commit_code() {
  local label="$1"
  echo "$label" >> scripts/enforcement/example.sh
  git add scripts/enforcement/example.sh
  git commit -q -m "code $label"
}

finish_head() {
  head="$(git rev-parse HEAD)"
}

assert_fail() {
  local label="$1"
  local expected="$2"
  if bash "$CHECK" "$base" "$head" >"$TMP/$label.out" 2>&1; then
    echo "expected failure: $label"
    exit 1
  fi
  grep -qi "$expected" "$TMP/$label.out" || { echo "missing expected error for $label"; cat "$TMP/$label.out"; exit 1; }
  echo "ok: $label"
}

assert_pass() {
  local label="$1"
  bash "$CHECK" "$base" "$head" >"$TMP/$label.out" 2>&1 || { echo "expected pass: $label"; cat "$TMP/$label.out"; exit 1; }
  echo "ok: $label"
}

init_repo no-progress
commit_plan ''
commit_code one
finish_head
assert_fail no-progress "progress lifecycle"

init_repo all-markers-prefilled
commit_plan "$REAL_PROGRESS"
commit_code one
finish_head
assert_fail all-markers-prefilled "mid checkpoint"

init_repo single-final-backfill
commit_plan "$START_PROGRESS"
commit_code one
commit_plan "$REAL_PROGRESS"
finish_head
assert_fail single-final-backfill "single final backfill"

init_repo code-after-premerge
commit_plan "$START_PROGRESS"
commit_code one
commit_plan "$MID_PROGRESS"
commit_plan "$REAL_PROGRESS"
commit_code two
finish_head
assert_fail code-after-premerge "after the last code"

init_repo ordered-progress
commit_plan "$START_PROGRESS"
commit_code one
commit_plan "$MID_PROGRESS"
commit_plan "$REAL_PROGRESS"
finish_head
assert_pass ordered-progress

echo "progress lifecycle checks passed"
