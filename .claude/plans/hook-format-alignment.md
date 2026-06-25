# Hook Format Alignment Plan

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / governance |
| Domain tags | governance, workflow, hooks, evidence, testing |
| Templates | Not required |
| Architecture guides | `docs/research/official-patterns-adoption-audit.md`; Claude Code Hooks reference |
| Patterns | Existing hook scripts and enforcement tests |
| External systems / connectors | GitHub connector; Web official docs |
| Skills | None |
| Validation gates | GitHub PR, GitHub Actions, CodeRabbit review, explicit approval before merge |
| Task-router evidence | Read `core/task-router.md` during this rollout sequence. |
| Workflow evidence | Read `core/workflow.md` during this rollout sequence. |

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| Claude Code Hooks reference | Confirms official hook output shape | Read |
| `core/capability-registry.yaml` | Confirms next-step scope | Read |
| `docs/research/official-patterns-adoption-audit.md` | Confirms PR sequence and anti-overfitting constraints | Read |
| `scripts/enforcement/pre-tool-use-runtime-evidence.sh` | Confirms current pre-write guard behavior | Read |
| `scripts/enforcement/post-stop-hook.sh` | Confirms current stop-time behavior | Read |
| `scripts/enforcement/tests/test-runtime-evidence.sh` | Confirms regression test surface | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for repository files and PR workflow. |
| Web | Used for official Claude Code Hooks reference. |

## Skill Evidence

No skill is required for this focused change.

## Template Gap Waiver

This is a focused update to existing scripts and tests, not a new scaffold.

## Scope

Keep the change minimal: align the existing pre-tool output shape with the official Claude Code hook response shape and update tests for that behavior. Do not add managed settings, broad MCP access, or new skills.

## Completed Work

- [x] Read official Claude Code Hooks reference.
- [x] Read capability registry and adoption audit.
- [x] Read existing hook scripts and tests.

## Remaining Validation Outside This Plan

GitHub Actions, CodeRabbit review, response to review comments, and merge approval are tracked in the PR checklist.
