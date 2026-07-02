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

## DoD

- [x] fixture verified by this suite checker run.

## Source of Truth Checks
| Source | Status |
|---|---|
| CLAUDE.md | checked |

\$PROGRESS
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

## DoD

- [x] fixture verified by this suite checker run.

## Source of Truth Checks
| Source | Status |
|---|---|
| CLAUDE.md | checked |
| core/workflow.md | checked |

\$PROGRESS
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

## DoD

- [x] fixture verified by this suite checker run.

## Source of Truth Checks
| Source | Status |
|---|---|
| CLAUDE.md | checked |
| core/workflow.md | checked |

\$PROGRESS
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

## DoD

- [x] fixture verified by this suite checker run.

## Source of Truth Checks
| Source | Status |
|---|---|
| CLAUDE.md | checked |
| core/workflow.md | checked |

\$PROGRESS
## Claude Run Trace
- goal: test
"

assert_fail bad-source "$BAD_SOURCE" "source of truth"
assert_fail bad-skill "$BAD_SKILL" "security-review"
assert_fail bad-trace "$BAD_TRACE" "run trace"
assert_pass good "$GOOD"

# DoD quality schema: vague items, missing verification signal, and a missing
# section all fail; the GOOD fixture above is the passing shape.
DOD_BLOCK="## DoD

- [x] fixture verified by this suite checker run."
DOD_VAGUE="${GOOD/"$DOD_BLOCK"/"## DoD

- [x] done"}"
DOD_NO_SIGNAL="${GOOD/"$DOD_BLOCK"/"## DoD

- [x] everything works correctly and the change is complete now."}"
DOD_MISSING="${GOOD/"$DOD_BLOCK"/"## Notes

- [x] fixture note without any completion section."}"

assert_fail dod-vague-item "$DOD_VAGUE" "vague or placeholder"
assert_fail dod-no-verification-signal "$DOD_NO_SIGNAL" "verification signal"
assert_fail dod-section-missing "$DOD_MISSING" "definition of done"

echo "plan quality checks passed"
