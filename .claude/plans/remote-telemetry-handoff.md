# Remote Claude Telemetry Handoff

Date: 2026-07-13
Base: `main`
Status: implementation complete; merge externally gated

## Route Plan

| Field | Value |
|---|---|
| Task type | bug / observability / CI / Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | observability, workflow, governance, testing, security |
| Plan Scope | standard |
| Planning Mode | approved |
| Templates | Not required |
| Architecture guides | `docs/operations/runtime-telemetry-archive-plan.md`; `docs/operations/operational-work-history.md` |
| Patterns | Not required |
| External systems/connectors | GitHub |
| Skills | Not required |
| Validation gates | enforcement-tests; telemetry-handoff-tests; plan-policy; pr-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; documentation-asset-policy; semantic-cleanup-policy; import-cleanup-policy |
| Evidence to check | `scripts/monitoring/sync-telemetry-run.py`; `scripts/monitoring/select-pr-telemetry.py`; `.github/workflows/pr-policy.yml`; `.github/workflows/telemetry-handoff-tests.yml`; `scripts/enforcement/check-live-review-threads.py`; `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` |
| User decisions required | explicit owner approval after exact-head evidence |
| Task-router evidence | `core/task-router.md` read; Engineering OS governance selected |
| Workflow evidence | `core/workflow.md` read; plan commit `e530ecc3dcea93458ba38b865ab617a9e185e19c` preceded implementation |
| Target paths | `scripts/monitoring/`; `.github/workflows/pr-policy.yml`; `.github/workflows/telemetry-handoff-tests.yml`; `.github/workflows/workflow-evidence-policy.yml`; `scripts/enforcement/`; `docs/operations/`; `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` |

## Template Gap Waiver

No template applies to repair of the existing telemetry runtime and governance workflows. No new project type is scaffolded.

## Skill Evidence

No external skill is required. Repository-native telemetry, installer, workflow, privacy, and review-thread suites validate the change.

## Capability Evidence

- `routing.task-router-read` — routing source read before planning.
- `workflow.workflow-read` — workflow source read and plan-first ordering used.
- `plan.route-plan-before-write` — plan commit preceded implementation.
- `source.github-repo-read` — Engineering OS, Project 8 PR #6, CI, OWH, and review threads inspected through GitHub.
- `validation.policy-change-has-validator` — positive and negative fixtures cover persistence, matching, privacy, installer wiring, OWH correlation, and live threads.
- `validation.actions-checked` — modified workflows validated by static fixtures and live Actions.
- `validation.coderabbit-policy` — existing findings resolved or disproved; focused final Codex review requested.

## Connector Evidence

- GitHub — source of truth for PR #6, its OWH artifact, workflow state, review threads, durable transport, and CI selection.

## Connector Usage Evidence

- source: GitHub repositories `yotamfried-ux/Engineering-OS` and `yotamfried-ux/project-8`.
- action: inspected Project 8 merge `b6dd9a662a31e7ef1bad8c7e420450ab80c9ef26`, OWH artifact `operational-work-history-6-29245891365`, runtime/workflow files, and unresolved PR #6 threads.
- result: durable handoff, exact bundle selection, CI upload, OWH ingestion, and live-thread blocking are implemented and tested.
- decision: use an isolated same-repository telemetry branch with exact repo/PR/branch-hash/head matching.
- target: `scripts/monitoring/`; `.github/workflows/pr-policy.yml`; `.github/workflows/telemetry-handoff-tests.yml`; `scripts/enforcement/check-live-review-threads.py`.

## Documentation Asset Evidence

- internal: `docs/operations/runtime-telemetry-archive-plan.md`; `docs/operations/operational-work-history.md`; `docs/operations/project8-telemetry-preflight.md`.
- official: Claude Code hooks lifecycle and GitHub refs/token documentation informed sequencing and authentication decisions.
- decision: record and sync boundaries sequentially; accept only exact metadata-only bundles in CI.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `scripts/monitoring/eos-telemetry-event.sh` | read | previous events stayed inside the remote Claude workspace |
| `.github/workflows/pr-policy.yml` | read | previous CI never retrieved remote session events and trusted body text for thread state |
| `scripts/monitoring/require-telemetry-session.sh` | read | previous preflight proved local recording, not durable delivery |
| `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` | validated | records the real zero-event evidence, root cause, prevention, and regression coverage |

## Root Cause

Claude Code web and GitHub Actions used separate workspaces with no durable telemetry bridge. Review readiness also trusted PR prose rather than live GitHub thread metadata.

## Implementation

1. SessionStart pushes a sanitized bundle to `engineering-os-telemetry`.
2. Stop, StopFailure, and SessionEnd record then refresh the bundle.
3. Required preflight blocks tool use without durable current-run state.
4. Export removes raw branch names and rejects sensitive fields.
5. CI matches repository, PR, branch hash, and exact head SHA.
6. Matched events feed OWH and upload as a separate artifact.
7. Live unresolved review threads block readiness.
8. Installer ignores generated local evidence while keeping the policy trackable.

## Definition of Done

- [x] Separate-workspace simulation produces a non-empty durable bundle.
- [x] Required preflight rejects missing handoff state.
- [x] Selector rejects wrong PR, branch, head, empty, tampered, and privacy-invalid bundles.
- [x] OWH receives non-zero telemetry from a clean checkout fixture.
- [x] Installer and workflow wiring include every dependency.
- [x] Live current and outdated unresolved threads fail.
- [x] All 26 enforcement steps passed on `e7af77a01109a84e8e1899b577be47bb132c8250`.
- [x] Both named telemetry-handoff jobs passed on `e7af77a01109a84e8e1899b577be47bb132c8250`.
- [x] Root cause and prevention captured in a verified lesson.

## Claude Run Trace

1. Inspected Project 8 PR #6 and its OWH artifact.
2. Reproduced the remote-workspace/clean-CI boundary.
3. Implemented isolated-branch handoff, exact selector, sequential hooks, CI artifacts, and live-thread gate.
4. Added positive and negative separate-workspace tests.
5. Used CI artifacts to fix repository identity contamination and lifecycle evidence ordering.
6. Verified the full enforcement sweep and named telemetry jobs.

## Progress Lifecycle Evidence

- start: real PR #6 evidence, telemetry runtime, clean CI workflow, installer, and live thread state were inspected before implementation; both false-green paths were reproduced.
- mid: the bare-remote simulation produced an exact non-empty bundle for a separate checkout, OWH consumed it, invalid bundles failed, and CI feedback drove repository binding, privacy, coverage, and diagnostic improvements.
- pre-merge: implementation head `e7af77a01109a84e8e1899b577be47bb132c8250` passed all enforcement and named handoff jobs; diagnostic artifact `workflow-evidence-log-29289025034` isolated the lifecycle/source failures, concrete source evidence replaced the broad artifact label, and the mid checkpoints were committed earlier in `dcfd0bc97e2086eac002ba31191bb0af672f53d4` and `27235a4cddd1bfd90b1dae57c16269b47ba31a16`. All existing threads are resolved; exact-head checks and owner approval remain external merge gates.

## Merge Gate

Merge remains blocked until exact-head workflows pass, final review state is inspected, and the owner gives separate explicit approval.
