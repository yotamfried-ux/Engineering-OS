# Remote Claude Telemetry Handoff

Date: 2026-07-13
Base branch: `main`
Working branch: `docs/project8-real-run-evidence-transition`
Status: implementation complete; merge requires exact-head validation, final review inspection, and separate owner approval

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
| Validation gates | enforcement-tests; telemetry-handoff-tests; project8 telemetry readiness; telemetry archive tests; installer coverage; pr-policy workflow wiring; live review threads; plan-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; documentation-asset-policy; semantic-cleanup-policy; import-cleanup-policy |
| Evidence to check | `scripts/monitoring/eos-telemetry-session-start.sh`; `scripts/monitoring/record-and-sync-telemetry.sh`; `scripts/monitoring/sync-telemetry-run.py`; `scripts/monitoring/select-pr-telemetry.py`; `scripts/monitoring/export-telemetry-run.py`; `.github/workflows/pr-policy.yml`; `.github/workflows/telemetry-handoff-tests.yml`; `scripts/enforcement/check-live-review-threads.py`; `scripts/install-policy-gates.sh`; `scripts/enforcement/policy-gate-dependencies.tsv`; `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` |
| User decisions required | none for implementation; explicit merge approval remains required after exact-head evidence |
| Task-router evidence | `core/task-router.md` read; task classified as Engineering OS observability/governance maintenance |
| Workflow evidence | `core/workflow.md` read; plan commit `e530ecc3dcea93458ba38b865ab617a9e185e19c` preceded implementation |
| Target paths | `scripts/monitoring/`; `.github/workflows/pr-policy.yml`; `.github/workflows/telemetry-handoff-tests.yml`; `.github/workflows/workflow-evidence-policy.yml`; `scripts/enforcement/check-live-review-threads.py`; `scripts/enforcement/tests/`; `scripts/install-policy-gates.sh`; `scripts/enforcement/policy-gate-dependencies.tsv`; `docs/operations/project8-telemetry-preflight.md`; `docs/operations/runtime-telemetry-archive-audit-checklist.md`; `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` |

## Template Gap Waiver

No project template is relevant to a repair of the existing Engineering OS telemetry runtime and policy workflows. The task extends already-installed governance infrastructure rather than scaffolding a new project type.

## Skill Evidence

No external skill is required. The implementation is validated by repository-native telemetry, installer, workflow, privacy, and review-thread regression suites.

## Capability Evidence

- `routing.task-router-read` — task router read before planning.
- `workflow.workflow-read` — workflow read and plan-first ordering used.
- `plan.route-plan-before-write` — plan commit preceded implementation.
- `source.github-repo-read` — Engineering OS `main`, PR #245, Project 8 PR #6, CI, OWH artifact, and live review threads were inspected through GitHub.
- `validation.policy-change-has-validator` — remote persistence, exact-head selection, privacy/checksum rejection, installer wiring, OWH correlation, and live-thread state have positive and negative fixtures.
- `validation.actions-checked` — all modified workflows are validated by static wiring fixtures or live Actions runs.
- `validation.coderabbit-policy` — work remained isolated in PR #245; all existing inline review threads were resolved or disproved with evidence, CodeRabbit's final line review was rate-limited, and a focused Codex review was requested for the implementation head.

## Connector Evidence

- GitHub — required to inspect Project 8 PR #6, its CI/OWH artifact and live review threads; also the durable transport and CI source of truth for the fix.

## Connector Usage Evidence

- source: GitHub repositories `yotamfried-ux/Engineering-OS` and `yotamfried-ux/project-8`.
- action: inspected PR #6 merge `b6dd9a662a31e7ef1bad8c7e420450ab80c9ef26`, OWH artifact `operational-work-history-6-29245891365`, current telemetry runtime/workflows, and two unresolved PR #6 review threads.
- result: `scripts/monitoring/sync-telemetry-run.py`, `scripts/monitoring/select-pr-telemetry.py`, `.github/workflows/pr-policy.yml`, `.github/workflows/telemetry-handoff-tests.yml`, and `scripts/enforcement/check-live-review-threads.py` now implement and validate durable handoff and live-state readiness.
- decision: selected an isolated same-repository branch with exact PR/head matching instead of product-branch commits or manual export.
- target: `scripts/monitoring/`; `.github/workflows/pr-policy.yml`; `.github/workflows/telemetry-handoff-tests.yml`; `scripts/enforcement/check-live-review-threads.py`; `scripts/enforcement/tests/`.

## Documentation Asset Evidence

- internal: `docs/operations/runtime-telemetry-archive-plan.md`; `docs/operations/operational-work-history.md`; `docs/operations/project8-telemetry-preflight.md`.
- official: Claude Code hooks lifecycle documentation and GitHub refs/token documentation were consulted for session boundaries, parallel hook behavior, Git transport, and workflow authentication.
- decision: boundary recording and sync are sequential inside one handler; CI accepts only exact matched metadata-only bundles.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `scripts/monitoring/eos-telemetry-event.sh` | read | events were local-only in the remote Claude workspace |
| `scripts/monitoring/collect-pr-work-history.py` | read | clean CI checkout sees telemetry only when an explicit telemetry file is supplied |
| `.github/workflows/pr-policy.yml` | read | previous workflow had no remote handoff checkout and trusted body text for thread state |
| `scripts/monitoring/export-telemetry-run.py` | read | previous export was manual and preserved raw branch metadata |
| `scripts/monitoring/require-telemetry-session.sh` | read | previous preflight proved local recording but not durable delivery |
| `scripts/enforcement/tests/test-project8-telemetry-readiness.sh` | read | previous tests did not simulate a separate CI workspace |
| `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` | validated | records the PR #6 artifact facts, zero-event failure, workspace boundary, root cause, prevention, and regression tests |

## Root Cause

Claude Code web wrote telemetry to a gitignored file in its remote workspace, while GitHub Actions used a clean independent checkout. No durable channel connected them. Separately, merge readiness trusted a free-text `threads:` assertion instead of live GitHub review-thread metadata.

## Implementation

1. SessionStart creates a metadata-only bundle and pushes it to the isolated `engineering-os-telemetry` branch.
2. Stop, StopFailure, and SessionEnd record then refresh the same run sequentially.
3. Required-mode preflight blocks tools until the current run has a successful durable handoff.
4. Export hashes the source branch, rejects raw/sensitive fields, and regenerates the summary from sanitized events.
5. PR policy selects only a non-empty bundle matching repository, PR number, branch hash, and exact head SHA.
6. The selected bundle feeds OWH and is uploaded as a separate Actions artifact.
7. The remote sync dispatches `pr-policy` after a PR exists, avoiding dependence on a manual final export.
8. PR policy fetches live review threads and blocks every unresolved current or outdated thread.
9. The installer preserves a trackable telemetry policy while ignoring local runtime and generated evidence directories.
10. Repository identity is derived from the active workspace remote and passed explicitly to the handoff, avoiding contamination from unrelated CI environment variables.
11. Workflow-evidence failures are preserved as short diagnostic artifacts, avoiding repeated guesses when lifecycle ordering fails.

## Definition of Done

- [x] Bare-remote simulation proves a fresh session creates a durable telemetry branch and non-empty bundle.
- [x] Required preflight fails when durable handoff state is absent.
- [x] Stop refreshes the durable bundle without modifying the product branch.
- [x] CI selector rejects wrong PR, wrong branch hash, stale head SHA, zero events, checksum mismatch, and privacy-invalid data.
- [x] OWH receives non-zero telemetry from a separate checkout fixture.
- [x] Installed workflow wiring retrieves, selects, supplies, and uploads the matched bundle.
- [x] Installer manifest includes new runtime and CI dependencies and ignores local generated evidence without hiding the policy.
- [x] Live thread fixture rejects unresolved current and outdated threads.
- [x] Full enforcement suite passed on implementation head `e7af77a01109a84e8e1899b577be47bb132c8250`.
- [x] Named `telemetry-handoff-tests` passed both remote handoff and live review-thread jobs on implementation head `e7af77a01109a84e8e1899b577be47bb132c8250`.
- [x] Existing automated review findings are resolved or disproved with evidence; final-head review state remains an external merge gate.
- [x] Durable root cause and prevention are captured in `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md`.

## Claude Run Trace

1. Verified Project 8 PR #6 and downloaded its OWH artifact.
2. Reproduced the clean-checkout boundary that caused zero session events.
3. Confirmed two unresolved review threads remained after merge.
4. Committed the Route Plan before implementation.
5. Implemented a dedicated-branch handoff, exact PR/head selector, sequential boundary hooks, fail-closed preflight, CI artifact wiring, and live-thread gate.
6. Added separate-workspace positive tests and wrong-PR, wrong-branch, stale-head, empty, checksum, privacy, and unresolved-thread negative tests.
7. Used an uploaded CI test log to identify repository identity contamination from `GITHUB_REPOSITORY`, then bound handoff identity to the target workspace remote.
8. Verified the full enforcement sweep and both named telemetry-handoff jobs on implementation head `e7af77a01109a84e8e1899b577be47bb132c8250`.
9. Added workflow-evidence diagnostic artifacts, then used the exact output to identify lifecycle ordering and source-reference issues in the cumulative plan files.

## Progress Lifecycle Evidence

- start: verified the merged Project 8 run, OWH artifact, local telemetry runtime, clean CI workflow, installer manifest, and live review-thread state before implementation; durable-handoff and live-thread gaps were reproduced from real evidence.
- mid: after implementation began, a local bare-remote run created `engineering-os-telemetry`, selected a non-empty exact-head bundle from a separate checkout, supplied it to OWH, rejected mismatches/checksum tampering, and blocked preflight after deleting handoff state; first CI feedback then drove explicit simulation registration, repository identity binding, connector/capability evidence, privacy negatives, and diagnostic artifact coverage.
- pre-merge: after the last implementation change, `enforcement-tests` passed all 26 steps on `e7af77a01109a84e8e1899b577be47bb132c8250`; named `telemetry-handoff-tests` passed both jobs; capability, connector, documentation, semantic-cleanup, and import-cleanup policies were green. This evidence-only checkpoint intentionally precedes a final exact-head rerun and separate owner approval.

## Merge Gate

Merge remains blocked until every workflow passes on this evidence head, the requested final Codex review and live thread state are inspected, and the owner gives separate explicit approval.
