# Managed Settings Deployment Proof Plan

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / governance |
| Domain tags | governance, managed-settings, deployment, validation, operations |
| Templates | Not required |
| Architecture guides | `docs/research/official-patterns-adoption-audit.md` |
| Patterns | Existing enforcement test pattern under `scripts/enforcement/tests/` |
| External systems / connectors | GitHub |
| Skills | `engineering-route` package available, but no runtime package invocation is required for this docs/test PR |
| Validation gates | GitHub Actions, CodeRabbit review, unresolved review thread check, explicit approval before merge |
| Task-router evidence | Read `core/task-router.md` |
| Workflow evidence | Read `core/workflow.md` |

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| `core/task-router.md` | Confirms this is governance / deployment work and needs a route plan before writing | Read |
| `core/workflow.md` | Confirms plan-first workflow and validation requirements | Read |
| `templates/settings/claude-managed-lockdown.json` | Current managed settings template that must not be expanded in this PR | Read |
| `external-systems/claude-managed-settings-rollout.md` | Current conservative rollout decision and deferred permission-rule lockdown | Read |
| `.github/workflows/enforcement-tests.yml` | Confirms test suites are auto-discovered by `scripts/enforcement/tests/test-*.sh` | Read |
| `scripts/enforcement/tests/test-managed-settings-template.sh` | Existing validator that this proof must complement, not replace | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used to read repository policies and create the implementation branch/files/PR. |

## Skill Evidence

No additional runtime skill is required. This PR is a documentation and validator proof. The newly merged `engineering-route` package is relevant as policy context, but this task is executed through the existing repository governance workflow.

## Template Gap Waiver

No application scaffold or project template is needed. This is an operations proof for an existing policy template.

## Scope

Add a deployment proof runbook and a CI validator only.

Do not:

- Change `templates/settings/claude-managed-lockdown.json` policy semantics.
- Add `allowManagedPermissionRulesOnly`.
- Lock skills, agents, or permission rules.
- Copy managed settings into `.claude/settings.json`.
- Enable managed settings in `use-in-project.sh`.
- Add MDM, Jamf, Kandji, Intune, GPO, or server-managed org rollout automation.
- Add new MCP servers.

## Completed Work

- [x] Read task router.
- [x] Read workflow.
- [x] Read managed settings template.
- [x] Read managed settings rollout doc.
- [x] Read enforcement-tests workflow.
- [x] Read existing managed settings template validator.
- [x] Added safety preflight that blocks active deployment while managed hook replacements are absent.
- [x] Added backup/restore instructions for pre-existing managed settings files.
- [x] Updated the validator to enforce the safety preflight and backup/restore requirements.

## Remaining Validation Outside This Plan

- GitHub Actions must pass.
- CodeRabbit must complete review.
- Review comments must be handled or explicitly resolved.
- Merge requires explicit user approval.
