# Route Plan: operational readiness finalization

Branch: `operational-readiness-final`

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / operational readiness finalization |
| Task class | engineering_os_governance |
| Domain tags | runtime-evidence, registry, target-install, PR-hygiene, CI |
| Task-router evidence | `core/task-router.md` requires task class selection and required capability evidence. |
| Workflow evidence | Plan committed before runtime enforcement, registry, test, and PR-cleanup changes. |
| Templates | Not required; this hardens Engineering OS itself. |
| Patterns | Not required; no reusable app implementation pattern. |
| External systems/connectors | GitHub connector only. |
| Skills | None. |
| Validation gates | GitHub Actions, enforcement-tests, manual review fallback, user-approved merge workflow. |

## Capability Evidence

- `routing.task-router-read` — task routing policy was already used to classify this as Engineering OS governance.
- `workflow.workflow-read` — plan-first workflow is followed by committing this plan before changes.
- `plan.route-plan-before-write` — this plan is committed before implementation.
- `source.github-repo-read` — GitHub connector is used to inspect/update files, check PRs, and validate Actions.
- `validation.policy-change-has-validator` — this PR updates runtime evidence validation and target-install tests.
- `validation.coderabbit-policy` — manual review fallback is used; CodeRabbit is intentionally excluded from this task per user instruction.

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| `core/capability-registry.yaml` | Runtime status and task-class capability requirements. | To update |
| `scripts/enforcement/pre-tool-use-runtime-evidence.sh` | Live write-time evidence gate. | To update |
| `scripts/enforcement/lib/evidence.sh` | Shared live evidence ledger. | To inspect/update if needed |
| `scripts/enforcement/tests/` | Deterministic validator tests. | To update |
| `.github/workflows/enforcement-tests.yml` | CI clean-install and runtime evidence coverage. | To update |
| `scripts/use-in-project.sh` | Target project install contract. | To validate through tests |
| Open PRs | Branch/PR hygiene. | To close stale superseded PRs |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used to create branch, inspect files and open PRs, update enforcement/tests, close stale PRs, check Actions, and merge after manual review. |

## Template Gap Waiver

No template is required because this is Engineering OS runtime/enforcement hardening, not a target project scaffold.

## Scope

- Add live write-time registry validation to the runtime evidence gate.
- Enable the registry runtime status only after tests prove the gate path.
- Add/strengthen tests for live evidence gate and clean target install smoke behavior.
- Close stale open PRs that are superseded by the merged enforcement stack.
- Do not touch CodeRabbit policy or require CodeRabbit review in this step.

## Non-goals

- No CodeRabbit retry/review work in this step.
- No OAuth automation.
- No MCP auto-install.
- No managed settings lockdown.

## Definition of Done

- [ ] Runtime write gate validates the selected Route Plan against required capabilities.
- [ ] Registry runtime status reflects the new enforcement level.
- [ ] Tests cover live evidence and target install smoke behavior.
- [ ] Stale open PRs are closed or documented as superseded.
- [ ] GitHub Actions pass.
- [ ] Manual review finds no blockers.
