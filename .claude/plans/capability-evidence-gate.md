# Route Plan: capability evidence gate

Branch: `capability-evidence-gate`

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / runtime evidence gate |
| Domain tags | capabilities, task-class, evidence, waiver, hooks, CI |
| Task-router evidence | `core/task-router.md` requires Route Plan output and capability selection before work. |
| Workflow evidence | Plan committed before adding validator/hook/CI wiring. |
| Templates | Not required; this is OS enforcement infrastructure. |
| Patterns | Not required; no reusable app implementation pattern. |
| External systems/connectors | GitHub connector only. |
| Skills | None. |
| Validation gates | GitHub Actions, enforcement-tests, manual review fallback, user-approved merge workflow. |

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| `core/capability-registry.yaml` | Canonical task classes and capability requirements. | To inspect |
| `core/task-router.md` | Route Plan requirements and task class selection. | To inspect/update if needed |
| `scripts/enforcement/` | Runtime/CI validators and tests. | To inspect/update |
| `.github/workflows/enforcement-tests.yml` | CI coverage for enforcement behavior. | To inspect/update |
| `.claude/settings.json` | Hook wiring for local runtime enforcement. | To inspect/update if needed |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used to create branch, inspect policy/enforcement files, commit validator/tests, open PR, check Actions, and merge after manual review. |

## Template Gap Waiver

No template is required because this is enforcement infrastructure inside Engineering OS.

## Scope

- Add a deterministic capability evidence validator for changed `.claude/plans/*.md` files.
- Require explicit `Task class` evidence and a `Capability Evidence` section in changed plans.
- Allow clear waivers through `Capability Waiver` when a capability is not needed.
- Wire the validator into CI through enforcement tests first.
- Document the gate as the first bridge from capability verification to runtime enforcement.

## Non-goals

- No automatic selection of task class from natural language yet.
- No MCP auto-install.
- No OAuth automation.
- No managed settings lockdown.
- No SaaS/new-project hard gate beyond plan evidence yet.

## Definition of Done

- [ ] Validator exists and blocks changed plans missing task class/capability evidence.
- [ ] Tests cover pass/fail/waiver cases.
- [ ] CI runs the validator.
- [ ] Documentation/runbook explains the evidence format.
- [ ] GitHub Actions pass.
- [ ] Manual review finds no blockers.
