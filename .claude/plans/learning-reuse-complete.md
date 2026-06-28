# Route Plan: complete learning reuse loop

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
| Target paths | core/learning-loop.md, scripts/enforcement, scripts/enforcement/tests, .claude/plans |

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
| `scripts/enforcement/tests/test-learning-e2e.sh` | Read |
| `scripts/enforcement/pre-tool-use-runtime-evidence.sh` | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for repo inspection, branch, commits, PR, and workflow checks. |

## Scope

Complete the learning loop by adding deterministic lesson reuse checks, a prevention counter update tool, documentation/schema updates, and E2E simulations.

## Definition of Done

- [x] Existing learning-loop gap is inspected.
- [x] Lesson reuse checker is added.
- [x] Prevention counter update tool is added.
- [x] Documentation explains Applies To Paths, Domain Tags, Lessons Reused, and counter rules.
- [x] Tests cover relevant lesson requires reuse, reuse allows work, counter increment, and full bug-to-future-prevention flow.
- [x] CI is checked before merge.
