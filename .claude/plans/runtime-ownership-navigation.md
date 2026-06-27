# Runtime Ownership Navigation Plan

Branch: `docs/runtime-ownership-navigation`

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / documentation governance |
| Domain tags | navigation, ownership, runtime-layers, docs-index |
| Task-router evidence | `core/task-router.md` routes Engineering OS documentation/governance work through plan-first workflow. |
| Workflow evidence | Plan is committed before `CLAUDE.md` / docs navigation changes. |
| Templates | Not required; documentation ownership update only. |
| Patterns | Not required; no runtime code pattern. |
| External systems/connectors | GitHub connector only. |
| Skills | None. |
| Validation gates | GitHub Actions, manual review fallback, explicit merge workflow approved by user. |

## Scope

Add minimal ownership/navigation clarification after PR #95, #93, and #96:

- `CLAUDE.md`: map non-core runtime/documentation layers without duplicating their rules.
- `docs/README.md`: align docs inventory with current folders and remove stale/ambiguous references.
- Keep Nemotron reclassification out of scope because PR #96 already merged it.

## Non-goals

- No runtime hook changes.
- No installer changes.
- No managed settings activation.
- No MCP auto-install.
- No SaaS gate implementation.
- No capability registry runtime enforcement.

## Definition of Done

- [ ] `CLAUDE.md` explains ownership for `.claude/`, hooks/settings/commands/agents, docs, templates, patterns, external systems, external skills, engines/backends, evals, and checkpoints.
- [ ] `docs/README.md` reflects current documentation folders and does not point to removed legacy folders.
- [ ] Diff remains docs-only except this plan.
- [ ] GitHub Actions pass.
- [ ] Manual review finds no blocking issues.
