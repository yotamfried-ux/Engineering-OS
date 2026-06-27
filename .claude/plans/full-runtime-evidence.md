# Route Plan

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | checked |
| Workflow evidence | checked |
| Templates | none |
| Patterns | none |
| External systems/connectors | GitHub |
| Skills | none |
| Validation gates | enforcement-tests, capability-evidence-policy, workflow-evidence-policy, connector-evidence-policy, target install smoke |

## Capability Evidence

- `routing.task-router-read` — checked.
- `workflow.workflow-read` — checked.
- `plan.route-plan-before-write` — checked.
- `source.github-repo-read` — checked.
- `validation.policy-change-has-validator` — checked.
- `validation.coderabbit-policy` — manual review fallback.

## Source of Truth Checks

Repository files checked.

## Connector Evidence

GitHub connector used.

## Template Gap Waiver

Not required for runtime enforcement work.
