# Route Plan: hook gate classification

## Route Plan

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | `core/task-router.md` used to route this as Engineering OS governance / enforcement testing. |
| Workflow evidence | `core/workflow.md` used for experiment -> fix -> verify loop. |
| Templates | Not required. |
| Patterns | Not required. |
| External systems/connectors | GitHub |
| Skills | None |
| Validation gates | enforcement-tests, workflow evidence, connector evidence, capability evidence, plan policy, PR policy, review |

## Capability Evidence

- `routing.task-router-read` — routed as Engineering OS governance.
- `workflow.workflow-read` — plan-first workflow used.
- `plan.route-plan-before-write` — this plan exists before hook policy/test changes.
- `source.github-repo-read` — GitHub connector used to inspect hooks policy, settings, and recorder scripts.
- `validation.policy-change-has-validator` — this branch adds regression tests for hook criticality and recorder behavior.
- `validation.coderabbit-policy` — PR review required before merge.

## Source of Truth Checks

| Source | Status |
|---|---|
| `core/hooks-policy.md` | Read |
| `.claude/settings.json` | Read |
| `scripts/enforcement/post-tool-use-read-evidence.sh` | Read |
| `scripts/enforcement/post-tool-use-mcp.sh` | Read |
| `scripts/enforcement/post-tool-use-bash.sh` | Read |
| `scripts/enforcement/tests/` | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for source inspection, branch, commits, PR, and workflows. |

## Definition of Done

- [x] Hook classes are documented: hard gate, advisory, evidence recorder, lifecycle setup.
- [x] Known KG2 status is updated from broad open gap to scoped resolved/mitigated behavior.
- [x] Tests prove malformed PostToolUse recorder input produces no evidence.
- [x] Tests prove valid PostToolUse recorder input records expected evidence.
- [x] Tests prove PreToolUse hard gate blocks are not wrapped in `|| true` and are preceded by JSON guard where required.
