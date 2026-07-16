# Remote Telemetry Final Merge Checkpoint

Date: 2026-07-16
Status: implementation and application validation complete; exact-head merge gates pending

This checkpoint closes the repository evidence chronology for:

- `.claude/plans/remote-telemetry-handoff.md`
- `.claude/plans/project8-real-run-evidence-transition.md`

## Route Plan

| Field | Value |
|---|---|
| Task type | bug / observability / CI / governance |
| Task class | engineering_os_governance |
| Domain tags | observability, governance, testing, security |
| Plan Scope | standard |
| Planning Mode | approved |
| Templates | Not required |
| Architecture guides | `docs/operations/runtime-telemetry-archive-plan.md`; `docs/operations/operational-work-history.md`; `docs/operations/project8-telemetry-preflight.md` |
| Patterns | metadata-only observability; fail-closed required delivery; partial-order progress; positive export schema; unique atomic state writes |
| External systems/connectors | GitHub |
| Skills | Not required |
| Validation gates | enforcement-tests; telemetry-handoff-tests; pr-policy; plan-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; documentation-asset-policy; semantic-cleanup-policy; import-cleanup-policy |
| Evidence to check | `scripts/monitoring/sync-telemetry-run.py`; `scripts/monitoring/telemetry_handoff.py`; `scripts/monitoring/export-telemetry-run.py`; `.github/workflows/pr-policy.yml`; `.github/workflows/telemetry-handoff-tests.yml`; `scripts/enforcement/tests/test-telemetry-shallow-head-ancestry.sh`; `scripts/enforcement/tests/test-telemetry-invalid-utf8.sh`; `scripts/enforcement/tests/test-telemetry-boundary-validation.sh`; `scripts/enforcement/tests/test-telemetry-state-atomic-write.sh`; `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` |
| User decisions required | owner merge approval received in the instruction to make PR #245 merge-ready and merge it |
| Target paths | `scripts/monitoring/`; `.github/workflows/`; `scripts/enforcement/`; `.claude/plans/`; `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` |
| Task-router evidence | `core/task-router.md` was read; Engineering OS governance maintenance was selected |
| Workflow evidence | `core/workflow.md` was read; both original plans preceded implementation and this checkpoint follows the final runtime and Verified Lesson commits |

## Template Gap Waiver

No repository template applies to a final evidence checkpoint for an existing telemetry runtime and policy workflow repair.

## Skill Evidence

No external skill was required. Repository-native validators, deterministic fixtures, live GitHub Actions, CodeRabbit, Codex, and structured self-review covered the task.

## Capability Evidence

- `routing.task-router-read` — routing source was read before implementation.
- `workflow.workflow-read` — the repository workflow and result-loop contract governed execution.
- `plan.route-plan-before-write` — the two original plans preceded implementation.
- `source.github-repo-read` — exact PR, workflow, review, thread, commit, and artifact state was read through GitHub.
- `validation.policy-change-has-validator` — positive and negative fixtures cover transport, identity, privacy, policy, paths, ancestry, progress, boundary evidence, state concurrency, CI selection, OWH, and live review state.
- `validation.actions-checked` — focused and complete GitHub Actions validation passed after the final runtime correction.
- `validation.coderabbit-policy` — every valid CodeRabbit and Codex finding was reproduced or verified before repair and received focused regression coverage.

## Connector Evidence

- GitHub was the source of truth for PR #245, Project 8 PR #6, exact SHAs, Actions runs, OWH artifacts, reviews, and live review threads.

## Connector Usage Evidence

- source: `yotamfried-ux/Engineering-OS` PR #245 and `yotamfried-ux/project-8` PR #6.
- action: inspected exact heads, workflows, OWH artifacts, review findings, live threads, and CI results; applied fixes only after deterministic reproductions.
- result: application head `4e7f9d1faa0d6018e8d22ead60d0e42bf23230fe` contains bounded shallow-history recovery, strict UTF-8 handling, event-derived boundary validation, unique atomic state temp files, and no temporary helper workflows.
- decision: kept `monitoring-metrics-sufficiency` and `project-8-real-run-evidence` open because a fresh target-project session artifact has not yet been imported and analyzed.
- target: PR #245 merge readiness only; Project 8 product work remained out of scope.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `scripts/monitoring/sync-telemetry-run.py` | validated | missing shallow objects trigger bounded fetch/retry before ancestry classification |
| `scripts/monitoring/telemetry_handoff.py` | validated | invalid UTF-8 fails closed, stored boundary equals recomputed event evidence, and state writers use unique temporary files |
| `scripts/monitoring/export-telemetry-run.py` | validated | custom event and run-id inputs decode strictly and export only the approved schema |
| `.github/workflows/telemetry-handoff-tests.yml` | validated | remote handoff, shallow ancestry, invalid UTF-8, boundary evidence, state concurrency, and live review checks are isolated with explicit timeouts |
| `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` | validated | commit `3c6e7cb22e8a4ec25867f22ecdc1c4227841611e` records the final failure family after the runtime correction |
| `docs/operations/known-gaps.tsv` | validated | `monitoring-metrics-sufficiency` and `project-8-real-run-evidence` remain open |

## Validation Evidence

- helper run `29508718994` applied the final repair, passed seven focused telemetry regressions, removed both temporary helper workflows, and produced application head `4e7f9d1faa0d6018e8d22ead60d0e42bf23230fe`.
- `telemetry-handoff-tests` run `29508908367` passed all six jobs after Verified Lesson commit `3c6e7cb22e8a4ec25867f22ecdc1c4227841611e`.
- `enforcement-tests` run `29508908285` passed every named stage, grouped A-Z suites, the aggregate all-suites execution, and all repository contract checks after the same lesson commit.
- earlier failing run `29503245581` proved shallow ancestry and malformed UTF-8 failures before repair.
- earlier failing runs `29500646182` and `29500578566` proved partial-order progress regression and custom-source export leakage before repair.
- temporary helper workflows are absent from the final PR file list.

## Definition of Done

- [x] Remote workspace telemetry is durably transported and exactly selected by CI.
- [x] Trusted policy, canonical identity, custom paths, and policy modes have positive and negative coverage.
- [x] Remote bundles are validated before progress or PR binding is trusted.
- [x] Product-head ancestry supports bounded shallow-history recovery and rejects stale downgrade or unrelated history.
- [x] Event and lifecycle-boundary progress are independently monotonic.
- [x] Stored lifecycle boundary equals the boundary recomputed from validated events.
- [x] Export uses strict UTF-8 and a positive metadata schema allowlist.
- [x] Concurrent durable-state writers use unique same-directory temporary files.
- [x] Live unresolved current and outdated review threads block readiness.
- [x] Focused telemetry validation passed after the final runtime correction.
- [x] Complete enforcement validation passed after the final runtime correction.
- [x] Verified Lesson was updated after the final runtime correction.
- [x] Both monitoring gaps remain open pending fresh Project 8 evidence.
- [x] Owner merge approval was explicitly received.

## Progress Lifecycle Evidence

- start: Project 8 PR #6 and its zero-event OWH exposed the remote-workspace versus clean-CI transport gap.
- mid: durable transport, exact selection, trusted policy, canonical identity, custom paths, policy modes, complete bundle validation, immutable PR binding, safe head advancement, partial-order progress, export allowlisting, OWH ingestion, bounded CI history, and live-thread enforcement were implemented through repeated result loops.
- pre-merge: application head `4e7f9d1faa0d6018e8d22ead60d0e42bf23230fe` passed focused helper run `29508718994`; Verified Lesson commit `3c6e7cb22e8a4ec25867f22ecdc1c4227841611e` recorded shallow-history recovery, strict UTF-8, event-derived boundary validation, and unique atomic state writes; focused run `29508908367` and complete run `29508908285` passed after that lesson without another runtime change.

## Merge Gate

Merge is permitted only after every required workflow passes on the exact checkpoint head and live GitHub review state contains no unresolved thread.
