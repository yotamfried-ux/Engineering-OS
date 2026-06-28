# Route Plan: learning loop E2E simulation

## Route Plan

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | `core/task-router.md` read. |
| Workflow evidence | `core/workflow.md` read. |
| Templates | Not required |
| Patterns | Not required |
| External systems/connectors | GitHub |
| Skills | None |
| Validation gates | enforcement-tests, workflow evidence, connector evidence, capability evidence, plan policy, PR policy, review |
| Target paths | scripts/enforcement/tests, .claude/plans |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Source of Truth Checks

| Source | Status |
|---|---|
| `core/learning-loop.md` | Read |
| `scripts/enforcement/enforce-learning.sh` | Read |
| `scripts/hooks/pre-commit.sh` | Read |
| `scripts/enforcement/tests/test-learning.sh` | Read |
| `scripts/use-in-project.sh` | To be exercised by test |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used to inspect repo files, create branch, and prepare PR workflow. |

## Scope

Add an E2E simulation test for learning-loop behavior in a temporary target project.

## Definition of Done

- [x] Current learning-loop implementation is inspected.
- [x] E2E simulation test is added.
- [x] Test proves install + pre-commit + lesson/failed-solution enforcement.
- [x] Test documents the remaining semantic gap: prevention/reuse is not yet deterministically enforced.
- [x] CI is checked before merge.
