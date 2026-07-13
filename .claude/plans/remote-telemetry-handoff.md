# Remote Claude Telemetry Handoff

Date: 2026-07-13
Status: implementation complete; merge externally gated

## Route Plan

| Field | Value |
|---|---|
| Task type | bug / observability / CI |
| Task class | engineering_os_governance |
| Domain tags | observability, governance, testing, security |
| Plan Scope | standard |
| Planning Mode | approved |
| Templates | Not required |
| Architecture guides | `docs/operations/runtime-telemetry-archive-plan.md`; `docs/operations/operational-work-history.md` |
| Patterns | Not required |
| External systems/connectors | GitHub |
| Skills | Not required |
| Validation gates | enforcement-tests; telemetry-handoff-tests; pr-policy; plan-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy |
| Evidence to check | `scripts/monitoring/sync-telemetry-run.py`; `scripts/monitoring/select-pr-telemetry.py`; `.github/workflows/pr-policy.yml`; `scripts/enforcement/check-live-review-threads.py`; `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` |
| User decisions required | explicit owner merge approval |
| Task-router evidence | `core/task-router.md` read; Engineering OS governance selected |
| Workflow evidence | `core/workflow.md` read; plan commit `e530ecc3dcea93458ba38b865ab617a9e185e19c` preceded implementation |
| Target paths | `scripts/monitoring/`; `.github/workflows/`; `scripts/enforcement/`; `docs/operations/`; `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` |

## Template Gap Waiver

No template applies to repair of the existing telemetry runtime and policy workflows.

## Skill Evidence

No external skill is required; repository-native regression suites validate the change.

## Capability Evidence

- `routing.task-router-read` — routing source read.
- `workflow.workflow-read` — workflow source read.
- `plan.route-plan-before-write` — plan preceded implementation.
- `source.github-repo-read` — Project 8 PR #6, CI, OWH, and review threads inspected through GitHub.
- `validation.policy-change-has-validator` — positive and negative fixtures cover delivery, matching, privacy, OWH, and live threads.
- `validation.actions-checked` — modified workflows validated in live Actions.
- `validation.coderabbit-policy` — existing findings resolved or disproved; final Codex review requested.

## Connector Evidence

- GitHub — source of truth for PR #6, OWH, workflow state, review threads, transport, and CI selection.

## Connector Usage Evidence

- source: GitHub repositories `yotamfried-ux/Engineering-OS` and `yotamfried-ux/project-8`.
- action: inspected merge `b6dd9a662a31e7ef1bad8c7e420450ab80c9ef26`, artifact `operational-work-history-6-29245891365`, runtime workflows, and unresolved review threads.
- result: `scripts/monitoring/sync-telemetry-run.py`, `scripts/monitoring/select-pr-telemetry.py`, `.github/workflows/pr-policy.yml`, and `scripts/enforcement/check-live-review-threads.py` implement durable delivery and live-state validation.
- decision: selected an isolated same-repository telemetry branch with exact repository, PR, branch-hash, and head matching.
- target: `scripts/monitoring/`; `.github/workflows/pr-policy.yml`; `scripts/enforcement/check-live-review-threads.py`.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `scripts/monitoring/eos-telemetry-event.sh` | read | previous events stayed in the remote Claude workspace |
| `.github/workflows/pr-policy.yml` | read | previous CI never retrieved session events and trusted body text for thread state |
| `scripts/monitoring/require-telemetry-session.sh` | read | previous preflight proved local recording, not durable delivery |
| `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` | validated | records the root cause and regression evidence |

## Definition of Done

- [x] Separate-workspace simulation produces non-empty telemetry.
- [x] Exact selector rejects wrong, stale, empty, tampered, and privacy-invalid bundles.
- [x] OWH consumes non-zero events from a clean checkout.
- [x] Required preflight rejects missing durable state.
- [x] Live unresolved threads fail.
- [x] All 26 enforcement steps and both named handoff jobs passed on `e7af77a01109a84e8e1899b577be47bb132c8250`.
- [x] Verified lesson captures prevention and tests.

## Claude Run Trace

1. Inspected PR #6 and its zero-event OWH.
2. Reproduced the remote-workspace/clean-CI boundary.
3. Implemented isolated-branch delivery, exact selection, sequential hooks, and live-thread blocking.
4. Added positive and negative regression tests.
5. Used CI artifacts to correct repository identity and lifecycle evidence.
6. Verified the enforcement and named handoff suites.

## Progress Lifecycle Evidence

- start: PR #6 evidence, telemetry runtime, CI workflow, installer, and live threads were inspected before implementation; both false-green paths were reproduced.
- mid: a bare-remote simulation delivered exact non-empty telemetry to a separate checkout; OWH consumed it, invalid bundles failed, and CI feedback drove repository binding, privacy, coverage, and diagnostics.
- pre-merge: implementation head `e7af77a01109a84e8e1899b577be47bb132c8250` passed enforcement and named handoff jobs; diagnostic artifact `workflow-evidence-log-29289025034` isolated lifecycle/source failures, and the mid checkpoints were committed in `dcfd0bc97e2086eac002ba31191bb0af672f53d4` and `27235a4cddd1bfd90b1dae57c16269b47ba31a16`. Existing threads are resolved; exact-head checks and owner approval remain external merge gates.

## Merge Gate

Merge remains blocked until exact-head workflows pass, final review state is inspected, and the owner gives explicit approval.
