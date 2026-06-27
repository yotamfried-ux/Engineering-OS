# Route Plan: required capability evidence enforcement

Branch: `capability-required-evidence`
PR: #102

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / capability registry enforcement |
| Task class | engineering_os_governance |
| Domain tags | capabilities, registry, task-class, evidence, waiver, CI |
| Task-router evidence | `core/task-router.md` requires task class selection and capability evidence before work. |
| Workflow evidence | Plan committed before validator/test/runbook changes. |
| Templates | Not required; this is OS enforcement infrastructure. |
| Patterns | Not required; no reusable app implementation pattern. |
| External systems/connectors | GitHub connector only. |
| Skills | None. |
| Validation gates | GitHub Actions, enforcement-tests, manual review fallback, user-approved merge workflow. |

## Capability Evidence

- `routing.task-router-read` — task routing policy was checked before implementation.
- `workflow.workflow-read` — plan-first workflow is followed by committing this plan before changes.
- `plan.route-plan-before-write` — this plan file is committed before validator changes.
- `source.github-repo-read` — GitHub connector is used to inspect and update repository files.
- `validation.policy-change-has-validator` — this PR updates the capability validator and tests.
- `validation.coderabbit-policy` — manual review fallback is used under the user-approved no-CodeRabbit workflow.

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| `core/capability-registry.yaml` | Canonical task classes and required capabilities. | Read |
| `scripts/enforcement/validate-capability-evidence.sh` | Existing evidence-format validator to harden. | Read and updated |
| `scripts/enforcement/tests/test-capability-evidence.sh` | Existing test suite to expand. | Read and updated |
| `docs/operations/capability-evidence-gate.md` | Runbook for this gate. | Updated |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used to create branch, inspect policy/enforcement files, commit validator/tests, open PR, check Actions, and merge after manual review. |

## Template Gap Waiver

No template is required because this is enforcement infrastructure inside Engineering OS, not a project scaffold.

## Scope

- Parse `Task class` from changed plans.
- Read the task class `required_capabilities` from `core/capability-registry.yaml`.
- Require every required capability ID to appear in `Capability Evidence` or `Capability Waiver`.
- Allow `unclassified` or unknown task classes only when a waiver explains why no registry class applies.
- Add tests for exact-required capability pass/fail/waiver/unknown-class behavior.

## Non-goals

- No natural-language task class inference.
- No runtime tool-call blocking yet.
- No MCP auto-install.
- No OAuth automation.
- No managed settings lockdown.

## Definition of Done

- [x] Validator compares selected task class to registry `required_capabilities`.
- [x] Missing required capability blocks unless explicitly waived.
- [x] Unknown/unclassified task class requires a waiver.
- [x] Tests cover pass, missing required capability, focused waiver, and unknown-class waiver.
- [x] Documentation explains required-capability matching.
- [x] Manual review before merge.

## External Validation Before Merge

GitHub Actions must pass on the final commit before merge.
