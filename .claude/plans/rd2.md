# Route Plan

## Route Plan

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Templates | none |
| Patterns | none |
| External systems/connectors | GitHub |
| Skills | none |
| Validation gates | enforcement-tests, workflow evidence, connector evidence, capability evidence, plan policy, PR policy, review |

## Capability Evidence

- routing.task-router-read
- workflow.workflow-read
- plan.route-plan-before-write
- source.github-repo-read
- validation.policy-change-has-validator
- validation.coderabbit-policy

## Source of Truth Checks

| Source | Status |
|---|---|
| core/git-policy.md | Read |
| scripts/enforcement/tests/ | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used |

## Definition of Done

Completed.
