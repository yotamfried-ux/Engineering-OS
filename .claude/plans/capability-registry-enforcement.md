# Capability Registry Enforcement Plan

Branch: `enforce-capability-registry`
PR: #93

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / governance |
| Domain tags | governance, capability-registry, connectors, skills, validation |
| Task-router evidence | `core/task-router.md` is the canonical routing owner; this PR only updates registry coverage. |
| Workflow evidence | Plan-first workflow applied before registry/test/runbook edits. |
| Templates | Not required; this is registry governance, not a project scaffold. |
| Patterns | Existing enforcement-test pattern under `scripts/enforcement/tests/`. |
| External systems / connectors | GitHub only. |
| Skills | None required for this scoped registry cleanup. |
| Validation gates | GitHub Actions, CodeRabbit/review threads, explicit user approval before merge. |

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| `core/capability-registry.yaml` | Canonical capability decision source being promoted from skeleton to inventory-backed. | Read |
| `external-systems/README.md` | Current connector inventory source; not changed by this PR. | Read |
| `external-skills/README.md` | Current skill inventory source; not changed by this PR. | Read |
| `scripts/enforcement/tests/` | Existing validator location and style. | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used to read current repo files, reset this PR branch to current `main`, and update only the scoped PR files. |

## Skill Evidence

No runtime skill was required for this focused registry/test/runbook change. The task is governed by the existing Engineering OS workflow and validated by repository checks.

## Scope

Keep PR #93 limited to capability registry hardening:

- Expand `core/capability-registry.yaml` from skeleton to inventory-backed / non-runtime.
- Add a validator under `scripts/enforcement/tests/`.
- Add an operations runbook under `docs/operations/`.

## Non-goals

- Do not change `CLAUDE.md` navigation/ownership; PR #97 owns that.
- Do not reclassify Nemotron in `external-skills/README.md`; PR #96 owns that.
- Do not change `external-systems/README.md` inventory.
- Do not enable runtime hook enforcement yet.
- Do not add managed settings activation.
- Do not auto-install MCP config into target projects.
- Do not add elevated connector defaults or broad MCP toolsets.

## Completed Work

- [x] Reset PR branch to current `main` so the plan is committed before implementation changes.
- [ ] Update `core/capability-registry.yaml` only.
- [ ] Add `scripts/enforcement/tests/test-capability-registry.sh`.
- [ ] Add `docs/operations/capability-registry-enforcement.md`.

## Remaining Validation Outside This Plan

- GitHub Actions must pass.
- Review threads must be checked.
- Merge requires explicit user approval.
