# Remote Claude Telemetry Handoff

Date: 2026-07-13
Base branch: `main`
Working branch: `docs/project8-real-run-evidence-transition`
Status: implementation in validation; merge requires separate explicit owner approval

## Route Plan

| Field | Value |
|---|---|
| Task type | bug / observability / CI / Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | observability, workflow, governance, testing, security |
| Plan Scope | standard |
| Planning Mode | approved |
| Templates | Not required — this extends the existing telemetry runtime and installed policy workflow |
| Architecture guides | `docs/operations/runtime-telemetry-archive-plan.md`; `docs/operations/operational-work-history.md` |
| Patterns | Not required — existing metadata-only telemetry and OWH contracts are the implementation source of truth |
| External systems / connectors | GitHub connector; official Claude Code hooks documentation; official GitHub refs/token documentation |
| Skills | Not required |
| Validation gates | enforcement-tests; project8 telemetry readiness; telemetry archive tests; installer coverage; pr-policy workflow wiring; live review threads; plan-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; documentation-asset-policy; semantic-cleanup-policy; import-cleanup-policy |
| Evidence to check | `scripts/monitoring/eos-telemetry-session-start.sh`; `scripts/monitoring/record-and-sync-telemetry.sh`; `scripts/monitoring/sync-telemetry-run.py`; `scripts/monitoring/select-pr-telemetry.py`; `scripts/monitoring/export-telemetry-run.py`; `.github/workflows/pr-policy.yml`; `scripts/enforcement/check-live-review-threads.py`; `scripts/install-policy-gates.sh`; `scripts/enforcement/policy-gate-dependencies.tsv`; Project 8 PR #6 OWH artifact |
| User decisions required | none for implementation; explicit merge approval remains required after exact-head evidence |
| Target paths | `scripts/monitoring/`; `.github/workflows/pr-policy.yml`; `scripts/enforcement/check-live-review-threads.py`; `scripts/enforcement/tests/`; `scripts/install-policy-gates.sh`; `scripts/enforcement/policy-gate-dependencies.tsv`; `docs/operations/` |

## Capability Evidence

- `routing.task-router-read` — `core/task-router.md` was read; task classified as Engineering OS observability/governance maintenance.
- `workflow.workflow-read` — `core/workflow.md` was read; plan commit `e530ecc3dcea93458ba38b865ab617a9e185e19c` preceded implementation.
- `plan.route-plan-before-write` — this file was the first implementation-series commit.
- `source.github-repo-read` — Engineering OS `main`, PR #245, Project 8 PR #6, CI, OWH artifact, and live review threads were inspected through GitHub.
- `validation.policy-change-has-validator` — remote persistence, exact-head selection, privacy/checksum rejection, installer wiring, OWH correlation, and live-thread state have fixtures.
- `validation.coderabbit-policy` — work remains isolated in PR #245; exact-head Actions and automated review remain merge gates.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `scripts/monitoring/eos-telemetry-event.sh` | read | events were local-only in the remote Claude workspace |
| `scripts/monitoring/collect-pr-work-history.py` | read | clean CI checkout sees telemetry only when an explicit telemetry file is supplied |
| `.github/workflows/pr-policy.yml` | read | previous workflow had no remote handoff checkout and trusted body text for thread state |
| `scripts/monitoring/export-telemetry-run.py` | read | previous export was manual and preserved raw branch metadata |
| `scripts/monitoring/require-telemetry-session.sh` | read | previous preflight proved local recording but not durable delivery |
| `scripts/enforcement/tests/test-project8-telemetry-readiness.sh` | read | previous tests did not simulate a separate CI workspace |
| Project 8 PR #6 OWH artifact | validated | full CI history was retained, but telemetry was unavailable with zero events |

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

## Definition of Done

- [x] Bare-remote simulation proves a fresh session creates a durable telemetry branch and non-empty bundle.
- [x] Required preflight fails when durable handoff state is absent.
- [x] Stop refreshes the durable bundle without modifying the product branch.
- [x] CI selector rejects wrong PR, wrong branch hash, stale head SHA, and checksum mismatch.
- [x] OWH receives non-zero telemetry from a separate checkout fixture.
- [x] Installed workflow wiring retrieves, selects, supplies, and uploads the matched bundle.
- [x] Installer manifest includes new runtime and CI dependencies.
- [x] Live thread fixture rejects unresolved current and outdated threads.
- [ ] Full telemetry archive and enforcement suites pass on the exact final head.
- [ ] Automated review findings are resolved or disproved with evidence.

## Claude Run Trace

1. Verified Project 8 PR #6 and downloaded its OWH artifact.
2. Reproduced the clean-checkout boundary that caused zero session events.
3. Confirmed two unresolved review threads remained after merge.
4. Committed the Route Plan before implementation.
5. Implemented a dedicated-branch handoff, exact PR/head selector, sequential boundary hooks, fail-closed preflight, CI artifact wiring, and live-thread gate.
6. Ran a local bare-Git simulation proving remote persistence, sanitized selection, OWH correlation, mismatch rejection, and missing-state blocking.

## Progress Lifecycle Evidence

- start: verified the merged Project 8 run, OWH artifact, local telemetry runtime, clean CI workflow, installer manifest, and live review-thread state before implementation; durable-handoff and live-thread gaps were reproduced from real evidence.
- mid: after implementation began, a local bare-remote run created `engineering-os-telemetry`, selected a non-empty exact-head bundle from a separate checkout, supplied it to OWH, rejected mismatches/checksum tampering, and blocked preflight after deleting handoff state; CI validation is now running on the committed implementation.
- pre-merge: not recorded yet.
