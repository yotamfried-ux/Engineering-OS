# Route Plan: capability evidence gate

Branch: `capability-evidence-gate`

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / runtime evidence gate |
| Task class | engineering_os_maintenance |
| Domain tags | capabilities, task-class, evidence, waiver, hooks, CI |
| Task-router evidence | `core/task-router.md` requires Route Plan output and capability selection before work. |
| Workflow evidence | Plan committed before adding validator/hook/CI wiring. |
| Templates | Not required; this is OS enforcement infrastructure. |
| Patterns | Not required; no reusable app implementation pattern. |
| External systems/connectors | GitHub connector only. |
| Skills | None. |
| Validation gates | GitHub Actions, enforcement-tests, manual review fallback, user-approved merge workflow. |

## Capability Evidence

- `github` — connector used to inspect and update repository files, create PR, and check validation results.
- `capability-verify.sh` — previous capability report foundation is used as the source for the next enforcement step.
- `validate-capability-evidence.sh` — new validator that blocks changed plans without task class/capability evidence.
- `capability-evidence-policy.yml` — new PR workflow that runs the validator on changed Engineering OS plans.

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| `core/capability-registry.yaml` | Canonical task classes and capability requirements. | Read as registry owner |
| `core/task-router.md` | Route Plan requirements and task class selection. | Updated |
| `scripts/enforcement/` | Runtime/CI validators and tests. | Updated |
| `.github/workflows/enforcement-tests.yml` | CI coverage for enforcement behavior. | Updated |
| `scripts/install-policy-gates.sh` | Target-project workflow installation. | Updated |

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
- Wire the validator into CI through a PR workflow and enforcement tests.
- Document the gate as the first bridge from capability verification to runtime enforcement.

## Non-goals

- No automatic selection of task class from natural language yet.
- No MCP auto-install.
- No OAuth automation.
- No managed settings lockdown.
- No SaaS/new-project hard gate beyond plan evidence yet.

## Definition of Done

- [x] Validator exists and blocks changed plans missing task class/capability evidence.
- [x] Tests cover pass/fail/waiver cases.
- [x] CI runs the validator through a dedicated PR workflow.
- [x] Target installs copy the new workflow.
- [x] Documentation/runbook explains the evidence format.
- [x] GitHub Actions pass before merge.
- [x] Manual review before merge.
