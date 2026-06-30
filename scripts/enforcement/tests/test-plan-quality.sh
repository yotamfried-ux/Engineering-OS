#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-workflow-evidence.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

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
' "$plan_body" > .claude/plans/plan.md
  git add .claude/plans/plan.md
  git commit -q -m plan
  echo changed > scripts/enforcement/example.sh
  git add scripts/enforcement/example.sh
  git commit -q -m change
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

PROGRESS='## Progress Lifecycle Evidence

- start: plan created before code.
- mid: validation ran.
- pre-merge: final checks verified.
'

BAD_SOURCE="# Plan

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
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
| CLAUDE.md | checked |

$PROGRESS
## Claude Run Trace
- goal: test
"

BAD_SKILL="# Plan

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Templates | not required |
| Patterns | shell test pattern |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests |

## Template Gap Waiver
reason: no template applies.

## Skill Evidence
- superpowers

## Source of Truth Checks
| Source | Status |
|---|---|
| CLAUDE.md | checked |
| core/workflow.md | checked |

$PROGRESS
## Claude Run Trace
- goal: test
"

BAD_TRACE="# Plan

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
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
| CLAUDE.md | checked |
| core/workflow.md | checked |

$PROGRESS
"

GOOD="# Plan

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Templates | not required |
| Patterns | shell test pattern |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests |

## Template Gap Waiver
reason: no template applies.

## Skill Evidence
- superpowers
- security-review

## Source of Truth Checks
| Source | Status |
|---|---|
| CLAUDE.md | checked |
| core/workflow.md | checked |

$PROGRESS
## Claude Run Trace
- goal: test
"

assert_fail bad-source "$BAD_SOURCE" "source of truth"
assert_fail bad-skill "$BAD_SKILL" "security-review"
assert_fail bad-trace "$BAD_TRACE" "run trace"
assert_pass good "$GOOD"

echo "plan quality checks passed"
