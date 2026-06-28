# Route Plan: learning reuse E2E gate

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
| Target paths | scripts/enforcement, scripts/enforcement/tests, .claude/plans |

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
| `scripts/enforcement/pre-tool-use-runtime-evidence.sh` | Read |
| `scripts/enforcement/tests/test-learning-e2e.sh` | Read |
| `scripts/enforcement/enforce-learning.sh` | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for repo inspection, branch, commits, PR, and workflow checks. |

## Scope

Add deterministic learning reuse simulations and enforcement so a future task touching a learned area must cite/read the relevant lesson and can record a prevented future issue.

## Definition of Done

- [x] Current learning loop gap is inspected.
- [x] A lesson reuse gate is added.
- [x] The runtime write gate calls the lesson reuse gate.
- [x] E2E tests cover: relevant lesson requires reuse, plan reuse allows write, prevented counter increments, and full bug-to-future-prevention loop.
- [x] CI is checked before merge.
