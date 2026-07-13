# Remote Claude Telemetry Handoff

Date: 2026-07-13
Base branch: `main`
Working branch: `docs/project8-real-run-evidence-transition`
Status: implementation authorized; merge requires separate explicit owner approval

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
| Patterns | Not required — the existing metadata-only telemetry and OWH contracts are the implementation source of truth |
| External systems / connectors | GitHub connector; official Claude Code hooks documentation; official GitHub refs/token documentation |
| Skills | Not required |
| Validation gates | enforcement-tests; project8 telemetry readiness; telemetry archive tests; installer coverage; pr-policy workflow wiring; PR review evidence; plan-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; documentation-asset-policy; semantic-cleanup-policy; import-cleanup-policy |
| Evidence to check | `scripts/monitoring/eos-telemetry-event.sh`; `scripts/monitoring/eos-telemetry-session-start.sh`; `scripts/monitoring/require-telemetry-session.sh`; `scripts/monitoring/export-telemetry-run.py`; `scripts/monitoring/collect-pr-work-history.py`; `.github/workflows/pr-policy.yml`; `scripts/enforcement/check-pr-review-evidence.sh`; `scripts/install-policy-gates.sh`; `scripts/enforcement/policy-gate-dependencies.tsv`; Project 8 PR #6 OWH artifact |
| User decisions required | none for implementation; explicit merge approval remains required after exact-head evidence |
| Target paths | `scripts/monitoring/`; `.github/workflows/pr-policy.yml`; `scripts/enforcement/check-pr-review-evidence.sh`; `scripts/enforcement/tests/`; `scripts/install-policy-gates.sh`; `scripts/enforcement/policy-gate-dependencies.tsv`; `docs/operations/` |

## Capability Evidence

- `routing.task-router-read` — `core/task-router.md` was read; this is Engineering OS observability/governance maintenance with a production-facing Git transport boundary.
- `workflow.workflow-read` — `core/workflow.md` was read; this plan is committed before the new implementation changes.
- `plan.route-plan-before-write` — this file is the first commit for the telemetry-handoff implementation.
- `source.github-repo-read` — Engineering OS `main`, open PR #245, Project 8 PR #6, its final CI and OWH artifact were inspected through GitHub.
- `validation.policy-change-has-validator` — positive and negative fixtures are required for remote persistence, exact-head selection, privacy, installer coverage, and unresolved review threads.
- `validation.coderabbit-policy` — work remains isolated in PR #245; Actions and automated review are required before requesting merge approval.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `scripts/monitoring/eos-telemetry-event.sh` | read | hook events are written only to the target workspace local JSONL file |
| `scripts/monitoring/collect-pr-work-history.py` | read | CI reads only `.engineering-os/telemetry/events.jsonl` from its clean checkout unless `--telemetry-file` is supplied |
| `.github/workflows/pr-policy.yml` | read | the workflow never retrieves telemetry from the remote Claude workspace and therefore reports zero events |
| `scripts/monitoring/export-telemetry-run.py` | read | export exists but is manual and copies the local bundle only after the session |
| `scripts/monitoring/require-telemetry-session.sh` | read | preflight proves local recording but does not prove durable remote handoff |
| `scripts/enforcement/check-pr-review-evidence.sh` | read | the gate validates a free-text `threads:` field but does not inspect live GitHub review-thread state |
| `scripts/enforcement/tests/test-project8-telemetry-readiness.sh` | read | tests prove local recording/session isolation but do not simulate a separate CI checkout |
| Project 8 PR #6 OWH artifact | validated | 38 CI runs and 15 historical failures were retained, but `telemetry_available=false` and `telemetry_events_count=0` |

## Root Cause

Claude Code on the web writes metadata-only events into a gitignored file inside its remote workspace. GitHub Actions later checks out the repository into a separate clean workspace. No durable transport connects those workspaces, so local preflight can pass while OWH sees zero events. A SessionEnd/webhook lifecycle confirmation does not carry the telemetry bundle.

A second independent gap allowed PR #6 to merge with two live unresolved review threads because the gate trusted PR-body prose instead of GitHub thread metadata.

## Implementation Contract

1. Persist each active telemetry run to a dedicated GitHub branch without modifying the product branch or `main`.
2. Perform the first persistence during `SessionStart`; required-mode preflight must block all tools until that push succeeds.
3. Refresh the same run after every `Stop`, `StopFailure`, and `SessionEnd` so phone/remote sessions do not depend on a manual final command.
4. Export only metadata-safe events; hash the source branch name before remote persistence.
5. Match CI telemetry by PR number, branch hash, and exact PR head SHA; stale or unrelated bundles must fail in required mode.
6. Feed the selected remote bundle into OWH and upload it as a separate Actions artifact for later archive import.
7. Collect live GitHub review threads and block readiness while any thread is unresolved.
8. Keep `monitoring-metrics-sufficiency` and `project-8-real-run-evidence` open until a new non-empty run is imported and analyzed.

## Definition of Done

- [ ] A local bare-remote simulation proves SessionStart creates a durable telemetry branch and matching non-empty bundle.
- [ ] Required preflight fails when the remote handoff is absent, failed, stale, or for another run.
- [ ] Stop/SessionEnd refresh the durable bundle without touching the product branch.
- [ ] CI selection rejects wrong PR, wrong branch hash, stale head SHA, zero-event, checksum-mismatched, and privacy-invalid bundles.
- [ ] OWH receives non-zero telemetry from a separate checkout fixture.
- [ ] Installed target workflows retrieve and upload the matched bundle.
- [ ] Installer coverage includes every new runtime and CI dependency.
- [ ] PR review evidence fails with a live unresolved thread and passes when all threads are resolved.
- [ ] Existing telemetry archive export/import/analyze tests remain green.
- [ ] Full enforcement suite and all policy workflows pass on the exact final head.
- [ ] Automated review findings are resolved or disproved with evidence.

## Claude Run Trace

1. Verified Project 8 PR #6 merged successfully and materially improved the Postgres foundation.
2. Downloaded and inspected its CI-generated OWH artifact.
3. Confirmed the OWH retained full CI friction but reported no session telemetry.
4. Compared the local recorder/preflight contract with the clean-checkout OWH workflow.
5. Identified the missing durable workspace-to-CI transport as the root cause.
6. Confirmed PR #6 also retained two unresolved GitHub review threads after merge.
7. Read official Claude Code hook lifecycle documentation and GitHub refs/token documentation before selecting the transport design.

## Progress Lifecycle Evidence

- start: verified the merged Project 8 run, OWH artifact, local telemetry runtime, clean CI workflow, installer manifest, and live review-thread state before implementation; the durable-handoff and live-thread gaps are reproduced from real evidence.
- mid: not recorded yet.
- pre-merge: not recorded yet.
