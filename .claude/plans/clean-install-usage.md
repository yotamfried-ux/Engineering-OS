# Route Plan: clean install and usage experiments

## Route Plan

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | `core/task-router.md` used for Engineering OS governance/testing work. |
| Workflow evidence | `core/workflow.md` used for experiment -> fix -> verify loop. |
| Templates | Not required. |
| Patterns | Not required. |
| External systems/connectors | GitHub |
| Skills | None |
| Validation gates | enforcement-tests, workflow evidence, connector evidence, capability evidence, plan policy, PR policy, review |

## Capability Evidence

- `routing.task-router-read` — routed as Engineering OS governance.
- `workflow.workflow-read` — plan-first loop used.
- `plan.route-plan-before-write` — this plan exists before test changes.
- `source.github-repo-read` — GitHub connector used to inspect `use-in-project.sh` and current enforcement tests.
- `validation.policy-change-has-validator` — this branch adds regression tests.
- `validation.coderabbit-policy` — PR review required before merge.

## Source of Truth Checks

| Source | Status |
|---|---|
| `scripts/use-in-project.sh` | Read |
| `scripts/enforcement/tests/` | Read |
| `.claude/settings.json` | Used through clean install assertions |
| `scripts/enforcement/pre-tool-use-runtime-evidence.sh` | Used through usage simulation |
| `scripts/enforcement/enforce-workflow.sh` | Used through usage simulation |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for branch, source inspection, commits, PR, workflows. |

## Definition of Done

- [x] Clean target repo install is tested.
- [x] Re-running install is tested for idempotency.
- [x] Target install includes settings, commands, hooks, policy workflows, setup and capability report.
- [x] Usage simulation blocks write without plan.
- [x] Usage simulation blocks write with plan but without evidence.
- [x] Usage simulation allows write only after required route/workflow evidence.
- [x] Usage simulation blocks merge-readiness when workflow runs are not all green.
- [x] Usage simulation allows merge-readiness when workflow runs are green.
