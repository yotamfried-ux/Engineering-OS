# Managed Settings Rollout Plan

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / governance |
| Domain tags | governance, Claude Code, managed settings, lockdown, validation |
| Templates | Not required |
| Architecture guides | `docs/research/official-patterns-adoption-audit.md`; official Claude Code settings docs |
| Patterns | Existing capability registry and enforcement test workflow |
| External systems / connectors | GitHub connector; Web official docs |
| Skills | None |
| Validation gates | GitHub PR, GitHub Actions, CodeRabbit review, explicit approval before merge |
| Task-router evidence | Read `core/task-router.md` during this rollout sequence. |
| Workflow evidence | Read `core/workflow.md` during this rollout sequence. |

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| `docs/research/official-patterns-adoption-audit.md` | Confirms managed settings rollout is the last step and should happen after local hooks/evals/connectors are stable | Read |
| `core/capability-registry.yaml` | Confirms connectors and runtime enforcement must remain small and tested | Read |
| Claude Code settings docs | Confirms managed scope, precedence, managed-only fields, and validation behavior | Read |
| Existing enforcement workflow | Confirms new validator scripts are automatically executed in CI | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for repository files and PR workflow. |
| Web | Used for official Claude Code settings reference. |

## Skill Evidence

No skill is required for this focused settings-template change.

## Template Gap Waiver

This PR adds the managed settings rollout template itself. No application scaffold is needed.

## Scope

Add managed settings guidance and a validator template only. Do not enable managed lockdown in project runtime settings, do not require enterprise deployment, and do not change existing hooks or connector behavior.

## Completed Work

- [x] Read adoption audit.
- [x] Read capability registry.
- [x] Read official Claude Code settings docs.
- [x] Read enforcement workflow.

## Remaining Validation Outside This Plan

GitHub Actions, CodeRabbit review, response to review comments, and merge approval are tracked in the PR checklist.
