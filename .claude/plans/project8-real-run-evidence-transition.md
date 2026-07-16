# Project 8 Real-Run Evidence Transition

Date: 2026-07-12
Base: `c2572b03f296703d1ff6c84cfbf4e0796b62f588`
Status: evidence reconciliation and application-head validation complete; merge externally gated

## Route Plan

| Field | Value |
|---|---|
| Task type | Engineering OS docs / governance maintenance |
| Task class | engineering_os_governance |
| Domain tags | observability, workflow, governance, testing |
| Plan Scope | focused |
| Planning Mode | approved |
| Templates | Not required |
| Architecture guides | `docs/operations/runtime-telemetry-archive-plan.md`; `docs/operations/operational-work-history-rollout.md` |
| Patterns | evidence separation; fail-closed telemetry preflight; metadata-only observability; audit freshness |
| External systems/connectors | GitHub |
| Skills | Not required |
| Validation gates | enforcement-tests; telemetry-handoff-tests; plan-policy; pr-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; documentation-asset-policy; semantic-cleanup-policy; import-cleanup-policy |
| Evidence to check | Project 8 PR #4 and OWH artifact; Project 8 PR #6 and OWH artifact; Engineering OS PR #244; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/runtime-telemetry-archive-audit-checklist.md`; `docs/operations/project8-telemetry-preflight.md`; `docs/operations/operational-work-history.md`; `docs/operations/result-loop-contract-audit-checklist.md`; `scripts/enforcement/tests/test-telemetry-policy-and-path-overrides.sh`; `scripts/enforcement/tests/test-telemetry-head-advancement.sh` |
| User decisions required | No implementation decision; owner merge approval is required after exact-head evidence |
| Task-router evidence | `core/task-router.md` read; selected Engineering OS governance |
| Workflow evidence | `core/workflow.md` read; plan commit `7fab9bc23118f942f86d9b1afeb8af8d023f6d97` preceded documentation changes |
| Target paths | `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/runtime-telemetry-archive-audit-checklist.md`; `docs/operations/project8-first-real-run-findings.md`; `docs/operations/operational-work-history.md`; `docs/operations/result-loop-contract-audit-checklist.md`; `.github/workflows/pr-policy.yml`; `.github/workflows/telemetry-handoff-tests.yml`; `scripts/monitoring/`; `scripts/enforcement/` |

## Capability Evidence

- `routing.task-router-read` — task router read before planning.
- `workflow.workflow-read` — workflow read and plan-first ordering used.
- `plan.route-plan-before-write` — plan commit preceded all documentation changes.
- `source.github-repo-read` — both repositories, PRs, CI, exact SHAs and OWH artifacts were inspected through GitHub.
- `validation.policy-change-has-validator` — audit, known-gap, telemetry, workflow, installer, privacy, source-path, policy-mode, product-head ancestry, concurrency, live-thread, CI-history, and plan validators cover the change.
- `validation.coderabbit-policy` — CodeRabbit and Codex findings were inspected against current code; valid findings were fixed and tested.

## Connector Evidence

- GitHub provided Project 8 PRs #4 and #6, Engineering OS PRs #244 and #245, exact SHAs, workflow metadata, missing target telemetry, OWH artifacts `operational-work-history-4-29178357323` and `operational-work-history-6-29245891365`, official workflow-run query constraints, and live review-thread state.

## Connector Usage Evidence

- source: GitHub repositories `yotamfried-ux/Engineering-OS` and `yotamfried-ux/project-8`.
- action: inspected PRs #4, #6, #244 and #245, merged SHAs, OWH data, current audit/gaps/checklist, CI runs, reviews, threads, runtime workflows, Project 8 telemetry installation state, and GitHub's workflow-run search contract.
- result: `.github/workflows/pr-policy.yml`, `.github/workflows/telemetry-handoff-tests.yml`, `scripts/monitoring/sync-telemetry-run.py`, and `scripts/monitoring/select-pr-telemetry.py` passed application-head validation while readiness sources kept OWH and session telemetry separate.
- decision: kept both monitoring gaps open, fixed the transport and evidence-history capabilities required for a valid later run, and kept Project 8 product work outside this PR.
- target: `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/runtime-telemetry-archive-audit-checklist.md`; `docs/operations/project8-first-real-run-findings.md`; `docs/operations/operational-work-history.md`; `docs/operations/result-loop-contract-audit-checklist.md`; `.github/workflows/pr-policy.yml`; `.github/workflows/telemetry-handoff-tests.yml`; `scripts/monitoring/`; `scripts/enforcement/`.

## Documentation Asset Evidence

- internal: `docs/operations/runtime-telemetry-archive-plan.md`; `docs/operations/operational-work-history-rollout.md`; `docs/operations/project8-telemetry-preflight.md`.
- context7: not required because the implementation extends repository-native scripts and workflows whose contracts are validated by source inspection and regression suites.
- decision: internal archive and preflight contracts require OWH and session telemetry to remain separate.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `docs/operations/known-gaps.tsv` | validated | `monitoring-metrics-sufficiency` and `project-8-real-run-evidence` remain open |
| `docs/operations/operational-readiness-audit.md` | validated | OWH evidence is separated from missing session telemetry and neither monitoring gap is closed |
| `docs/operations/runtime-telemetry-archive-audit-checklist.md` | validated | real telemetry export/import/findings items remain incomplete |
| `docs/operations/project8-telemetry-preflight.md` | validated | the next valid run boundary requires exact workspace identity, a fresh session, positive local events, a ready remote handoff, and exact CI selection |
| `docs/operations/operational-work-history.md` | validated | OWH can exist without session telemetry and cannot substitute for it |
| `docs/operations/result-loop-contract-audit-checklist.md` | validated | first real target evidence exists while telemetry and comparison-run criteria remain incomplete |
| `docs/operations/project8-first-real-run-findings.md` | validated | Project 8 PR #4 is classified as OWH-only rather than valid telemetry evidence; Project 8 PR #6 artifact `operational-work-history-6-29245891365` also reported zero session events |
| `scripts/monitoring/sync-telemetry-run.py` | validated | remote bundles are fully validated; exact state converges locally; canonical repository, source-path, policy-mode, PR-binding, progress, and product-head ancestry constraints fail closed |
| `.github/workflows/pr-policy.yml` | validated | trusted policy and exact product checkout are separated; CI history is bounded from PR creation before exact PR-number filtering and OWH enrichment |
| `.github/workflows/telemetry-handoff-tests.yml` | validated | remote handoff, source-path/policy behavior, product-head advancement, and live review-thread behavior are isolated as named timeout-bounded checks |
| `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` | validated | verified lesson records the complete failure family and regression contract |

## Decision

Project 8 has real OWH and product evidence, but neither completed run supplied session telemetry to CI. This PR repairs the measurement transport and review-state gate; it does not count as the next valid Project 8 experiment.

## Validation Evidence

- application/content head `8bc8682aa5719dcba8e4cd89df881fecc7b24aab` passed every stage in `enforcement-tests` run `29498660859`, including the grouped suites, aggregate all-suites pass, and repository contract checks;
- the same head passed `telemetry-handoff-tests` run `29498660824` with named successful stages for remote workspace handoff, policy modes/source overrides, product-head advancement, and live review threads;
- regression evidence proved canonical repository identity, trusted exact-base policy, metadata-only array scanning, consistent custom event/run-id paths, nonblocking `best_effort`, fail-closed `required`, full fetched-bundle validation, immutable exact PR binding, monotonic event/boundary progress, local durable-state convergence, and safe ancestor-to-descendant product-head replacement;
- stale descendant downgrade, unrelated product history, stale local progress, wrong repository/PR/branch/head, tampering, empty telemetry, and unresolved live threads were rejected;
- live `pr-policy` run `29464405759` accepted the bounded CI-history query, generated OWH with 737 PR-associated runs, and then blocked the outstanding review thread as designed;
- every known inline thread was resolved only after its finding received an implementation fix or exact focused evidence;
- verified lesson commit `c3afb8dc7c5893f13f6b5481fc5096d752514235` recorded the complete failure and prevention contract after application validation;
- `monitoring-metrics-sufficiency` and `project-8-real-run-evidence` remained open because no fresh Project 8 session artifact was imported and analyzed.

## Definition of Done

- [x] Plan commit precedes documentation changes.
- [x] Findings reports record exact merge and artifact facts without treating OWH as telemetry.
- [x] Project 8 evidence gap remains open.
- [x] Monitoring sufficiency remains open.
- [x] Audit separates OWH from missing telemetry.
- [x] Telemetry completion boxes remain unchecked.
- [x] Next-run preflight boundary is explicit.
- [x] Stale provisional binding converges local durable state and conflicting PR binding fails closed.
- [x] Custom telemetry paths and `best_effort`/`required` policy semantics have focused coverage.
- [x] Product-head advancement permits a validated ancestor replacement and rejects stale downgrade or unrelated history.
- [x] PR CI history uses a server-side PR-created-at bound and exact local PR filtering.
- [x] Application and telemetry implementation passed complete enforcement and all named focused telemetry stages.
- [x] Automated reviews and all known inline threads were inspected; valid findings were fixed and tested.
- [x] Verified lesson was updated after the last runtime and workflow correction.

## Claude Run Trace

1. Merged and inspected verified Project 8 target work.
2. Re-centered work on Engineering OS measurement validity.
3. Read audit, gaps, archive checklist, preflight, OWH, workflow, task router, and learning-loop sources.
4. Traced zero-event OWH to the remote-workspace/clean-CI boundary.
5. Implemented durable isolated-branch handoff, exact selection, trusted policy resolution, and live-thread enforcement.
6. Added focused positive, mismatch, tampering, privacy, concurrency, installer, and workflow-wiring regressions.
7. Isolated named CI failures rather than polling a truncated aggregate log.
8. Reproduced and fixed stale remote exact/local provisional state divergence.
9. Applied the Codex server-side CI-history bound and verified it in live pr-policy.
10. Added canonical repository validation, complete fetched-bundle validation, custom source-path propagation, and distinct policy-mode behavior.
11. Reproduced the normal-commit strict-head failure and implemented validated same/ancestor/descendant/unrelated product-head handling.
12. Added a named product-head advancement CI stage and passed focused and complete regressions.
13. Resolved all known threads only after evidence and expanded the Verified Lesson.

## Progress Lifecycle Evidence

- start: audit, gaps, archive checklist, preflight, Project 8 evidence, missing target telemetry, and merged Engineering OS foundations were verified before writes.
- mid: durable handoff, exact matching, trusted-base policy, sequential lifecycle hooks, monotonic sync, local-state convergence, privacy validation, canonical identity, source-path consistency, policy-mode semantics, safe product-head ancestry handling, OWH ingestion, bounded CI history, live-thread checks, and named CI isolation were implemented and corrected from review findings.
- pre-merge: application/content head `8bc8682aa5719dcba8e4cd89df881fecc7b24aab` passed complete `enforcement-tests` run `29498660859` and focused `telemetry-handoff-tests` run `29498660824`; exact evidence covered remote transport, trusted policy, privacy, source paths, policy modes, progress ordering, safe product-head advancement, bounded PR-scoped OWH, and live-thread enforcement; all known review threads were resolved after evidence; verified lesson commit `c3afb8dc7c5893f13f6b5481fc5096d752514235` recorded the corrected measurement contract while both monitoring gaps stayed open.

## Merge Gate

Merge is blocked unless every workflow passes on the exact evidence head, final live review state has no unresolved thread, and the owner gives separate explicit approval.
