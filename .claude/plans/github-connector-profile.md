# Official GitHub Connector Profile Plan

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / governance |
| Domain tags | governance, connectors, GitHub, source-of-truth, MCP, testing |
| Templates | Not required |
| Architecture guides | `docs/research/official-patterns-adoption-audit.md`; official Claude Code MCP docs; official `github/github-mcp-server` README |
| Patterns | Existing capability registry and enforcement test workflow |
| External systems / connectors | GitHub connector; Web official docs |
| Skills | None |
| Validation gates | GitHub PR, GitHub Actions, CodeRabbit review, explicit approval before merge |
| Task-router evidence | Read `core/task-router.md` during this rollout sequence. |
| Workflow evidence | Read `core/workflow.md` during this rollout sequence. |

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| `docs/research/official-patterns-adoption-audit.md` | Confirms this step is the narrow GitHub connector profile | Read |
| `core/capability-registry.yaml` | Confirms connectors should start narrow and read-oriented | Read |
| Claude Code MCP docs | Confirms project-scoped `.mcp.json` and environment expansion behavior | Read |
| `github/github-mcp-server` README | Confirms official server image, toolsets, and read-only mode | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for repository files and PR workflow. |
| Web | Used for official Claude Code and GitHub MCP references. |

## Skill Evidence

No skill is required for this focused connector profile change.

## Template Gap Waiver

This PR adds a reusable connector profile template and validator. No application scaffold is needed.

## Scope

Add a read-oriented GitHub connector profile template and validation only. Do not enable it as project runtime `.mcp.json`, do not add write profiles, and do not add managed settings lockdown.

## Completed Work

- [x] Read adoption audit.
- [x] Read capability registry.
- [x] Read official Claude Code MCP docs.
- [x] Read official GitHub MCP Server README.

## Remaining Validation Outside This Plan

GitHub Actions, CodeRabbit review, response to review comments, and merge approval are tracked in the PR checklist.
