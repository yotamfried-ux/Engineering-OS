# Route Plan: MCP recorder wiring

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
| `.claude/settings.json` | Read |
| `scripts/enforcement/post-tool-use-mcp.sh` | Read |
| `scripts/enforcement/tests/test-hook-classification.sh` | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for repo inspection, branch, commits, PR, and workflow checks. |

## Scope

Wire the generic MCP recorder into the repository's own PostToolUse hooks and add a regression test.

## Definition of Done

- [x] Current settings gap is verified.
- [x] Generic MCP recorder is wired in `.claude/settings.json`.
- [x] Regression test proves settings include `mcp__.*` with `post-tool-use-mcp.sh`.
- [x] CI is checked before merge.
