# Route Plan: capability verification framework

Branch: `capability-verification`

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / capability verification |
| Domain tags | capabilities, skills, engines, connectors, templates, installer, reporting |
| Task-router evidence | `core/task-router.md` routes Engineering OS governance/script changes through plan-first workflow. |
| Workflow evidence | Plan committed before adding verification framework and installer wiring. |
| Templates | Not required; this is OS verification infrastructure, not a target project scaffold. |
| Patterns | Not required; no reusable app implementation pattern. |
| External systems/connectors | GitHub connector only. |
| Skills | None. |
| Validation gates | GitHub Actions, enforcement-tests, manual review fallback, user-approved merge workflow. |

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| `core/capability-registry.yaml` | Inventory of task classes, skills, engines, connectors, and templates. | To inspect |
| `scripts/skill-bootstrap.sh` | Existing skill/engine detection source. | To inspect/reuse |
| `scripts/use-in-project.sh` | Target install output and setup report generation. | To inspect/update |
| `.github/workflows/enforcement-tests.yml` | Clean-install contract coverage. | To inspect/update |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used to create branch, inspect files, commit framework, open PR, check Actions, and merge after manual review. |

## Template Gap Waiver

No template is required because this is a verification/reporting framework inside Engineering OS.

## Scope

- Add a general capability verification script that covers skills, engines, connectors, and templates.
- Reuse `skill-bootstrap.sh --json` for skill/engine status where possible.
- Read connector/template inventory from `core/capability-registry.yaml` instead of hardcoding only Notion/Sentry/Nemotron.
- Generate a target-project report during `use-in-project.sh`.
- Add tests proving the report covers multiple capabilities and is created during clean install.

## Non-goals

- No MCP auto-install.
- No OAuth automation.
- No managed settings lockdown.
- No runtime gating from capability registry yet.
- No SaaS/new-project task gate yet.

## Definition of Done

- [ ] `scripts/capability-verify.sh` exists and outputs Markdown by default.
- [ ] Verification covers skills, engines, connectors, and templates.
- [ ] `use-in-project.sh` writes `ENGINEERING_OS_CAPABILITIES.md` in target projects.
- [ ] Enforcement tests prove the report is generated and is not limited to Notion/Sentry/Nemotron.
- [ ] GitHub Actions pass.
- [ ] Manual review finds no blockers.
