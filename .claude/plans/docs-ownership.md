# Route Plan: docs ownership

## Route Plan

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | `core/task-router.md` read. |
| Workflow evidence | `core/workflow.md` read. |
| Templates | Not required. |
| Patterns | Not required. |
| External systems/connectors | GitHub |
| Skills | None |
| Validation gates | enforcement-tests, workflow evidence, connector evidence, capability evidence, plan policy, PR policy, review |

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
| `core/documentation-policy.md` | Read |
| `external-skills/README.md` | Read |
| `external-systems/README.md` | Read |
| `scripts/enforcement/tests/` | Read |

## Scope

Add ownership boundaries for documentation files and add tests for those boundaries.

## Definition of Done

- [x] Documentation ownership is defined.
- [x] External inventory files state their role.
- [x] Tests cover the boundaries.
