# Route Plan: use-in-project runtime path hardening

Branch: `fix/use-in-project-runtime-path`

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / installer + enforcement test |
| Domain tags | installer, target-project, hooks, settings, runtime-path, clean-install |
| Task-router evidence | `core/task-router.md` routes Engineering OS script/hook changes through plan-first governance workflow. |
| Workflow evidence | Plan committed before changing installer scripts/tests. |
| Templates | Not required; this changes the installer contract, not a project scaffold. |
| Patterns | Not required; no reusable app implementation pattern. |
| External systems/connectors | GitHub connector only. |
| Skills | None. |
| Validation gates | GitHub Actions, enforcement-tests, manual review fallback, user-approved merge workflow. |

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| `scripts/use-in-project.sh` | Installs Engineering OS into target projects. | To inspect/update |
| `.claude/settings.json` | Source settings copied/rendered into target projects. | To inspect |
| `scripts/enforcement/tests/` | Location for deterministic regression tests. | To inspect/update |
| `core/hooks-policy.md` | Hook ownership and behavior boundary. | Reference |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used to create branch, inspect installer/settings/tests, commit fixes, open PR, check Actions, and merge after manual review. |

## Template Gap Waiver

No template is required because this is installer/runtime-path hardening, not a new target project scaffold.

## Scope

- Ensure target project `.claude/settings.json` resolves hook commands to the Engineering OS reference path instead of the target repo when `ENGINEERING_OS_HOME` is not exported by the session.
- Preserve the existing behavior of not overwriting a customized target `.claude/settings.json`.
- Add a clean-install contract test proving the rendered target settings no longer contain `$(pwd)` fallback for Engineering OS hooks and do include the expected reference path.

## Non-goals

- No Notion/Sentry/Nemotron auto-install in this PR.
- No managed settings lockdown.
- No MCP auto-install.
- No SaaS/new-project gate.
- No capability-registry runtime enforcement.

## Definition of Done

- [ ] Installer renders or installs target settings with stable Engineering OS reference path.
- [ ] Target install test proves hook path resolution does not depend on target `pwd`.
- [ ] Existing installer output contract remains valid.
- [ ] GitHub Actions pass.
- [ ] Manual review finds no blockers.
