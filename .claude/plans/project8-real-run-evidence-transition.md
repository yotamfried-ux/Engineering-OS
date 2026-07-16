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
| Evidence to check | Project 8 PR #4 and OWH artifact; Project 8 PR #6 and OWH artifact; Engineering OS PR #244; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/runtime-telemetry-archive-audit-checklist.md`; `docs/operations/project8-telemetry-preflight.md`; `docs/operations/operational-work-history.md`; `docs/operations/result-loop-contract-audit-checklist.md` |
| User decisions required | No implementation decision; owner merge approval is required after exact-head evidence |
| Task-router evidence | `core/task-router.md` read; selected Engineering OS governance |
| Workflow evidence | `core/workflow.md` read; plan commit `7fab9bc23118f942f86d9b1afeb8af8d023f6d97` preceded documentation changes |
| Target paths | `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/runtime-telemetry-archive-audit-checklist.md`; `docs/operations/project8-first-real-run-findings.md`; `docs/operations/operational-work-history.md`; `docs/operations/result-loop-contract-audit-checklist.md`; `.github/workflows/pr-policy.yml`; `scripts/monitoring/`; `scripts/enforcement/` |

## Capability Evidence

- `routing.task-router-read` — task router read before planning.
- `workflow.workflow-read` — workflow read and plan-first ordering used.
- `plan.route-plan-before-write` — plan commit preceded all documentation changes.
- `source.github-repo-read` — both repositories, PRs, CI, exact SHAs and OWH artifacts were inspected through GitHub.
- `validation.policy-change-has-validator` — audit, known-gap, telemetry, workflow, installer, privacy, live-thread, and plan validators cover the change.
- `validation.coderabbit-policy` — CodeRabbit and Codex findings were inspected against current code; valid findings were fixed and tested.

## Connector Evidence

- GitHub provided Project 8 PRs #4 and #6, Engineering OS PRs #244 and #245, exact SHAs, workflow metadata, missing target telemetry, and OWH artifacts `operational-work-history-4-29178357323` and `operational-work-history-6-29245891365`.

## Connector Usage Evidence

- source: GitHub repositories `yotamfried-ux/Engineering-OS` and `yotamfried-ux/project-8`.
- action: inspected PRs #4, #6, #244 and #245, merged SHAs, OWH data, current audit/gaps/checklist, CI runs, reviews, threads, runtime workflows, and Project 8 telemetry installation state.
- result: readiness sources keep OWH and session telemetry separate while the remote handoff and live-thread gate entered exact-head validation.
- decision: kept both monitoring gaps open, fixed the transport capability required for a valid later run, and kept Project 8 product work outside this PR.
- target: `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/runtime-telemetry-archive-audit-checklist.md`; `docs/operations/project8-first-real-run-findings.md`; `docs/operations/operational-work-history.md`; `docs/operations/result-loop-contract-audit-checklist.md`; `.github/workflows/pr-policy.yml`; `scripts/monitoring/`; `scripts/enforcement/`.

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
| `docs/operations/project8-telemetry-preflight.md` | validated | next valid run requires exact workspace, fresh session, positive local event count, and ready remote handoff |
| `docs/operations/operational-work-history.md` | validated | OWH can exist without session telemetry and cannot substitute for it |
| `docs/operations/result-loop-contract-audit-checklist.md` | validated | first real target evidence exists while telemetry and comparison-run criteria remain incomplete |
| `docs/operations/project8-first-real-run-findings.md` | validated | Project 8 PR #4 is classified as OWH-only rather than valid telemetry evidence |
| `operational-work-history-6-29245891365` | validated | PR #6 retained CI history but reported `telemetry_available=false` and zero events |

## Decision

Project 8 has real OWH and product evidence, but neither completed run supplied session telemetry to CI. This PR repairs the measurement transport and review-state gate; it does not count as the next valid Project 8 experiment.

## Validation Evidence

- application/content head `a02085a53928fece09181ef536e3f4d31967aeb8` passed all 26 steps in `enforcement-tests` run `29463304115`;
- the same head passed both named jobs in `telemetry-handoff-tests` run `29463304133`;
- plan-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy, semantic-cleanup-policy, and import-cleanup-policy passed on the application head;
- workflow-evidence-policy and pr-policy were intentionally left to re-evaluate the exact evidence head after lifecycle and PR-body evidence were updated;
- every existing inline review thread was resolved before the evidence commit.

## Definition of Done

- [x] Plan commit precedes documentation changes.
- [x] Findings reports record exact merge and artifact facts without treating OWH as telemetry.
- [x] Project 8 evidence gap remains open.
- [x] Monitoring sufficiency remains open.
- [x] Audit separates OWH from missing telemetry.
- [x] Telemetry completion boxes remain unchecked.
- [x] Next-run preflight boundary is explicit.
- [x] Application and telemetry implementation passed complete enforcement and named handoff validation.
- [x] Automated reviews and all existing inline threads were inspected; valid findings were fixed or documented as non-blocking.

## Claude Run Trace

1. Merged and inspected verified Project 8 target work.
2. Re-centered work on Engineering OS measurement validity.
3. Read audit, gaps, archive checklist, preflight, OWH, workflow, task router, and learning-loop sources.
4. Traced zero-event OWH to the remote-workspace/clean-CI boundary.
5. Implemented durable isolated-branch handoff, exact selection, trusted policy resolution, and live-thread enforcement.
6. Added focused positive, mismatch, tampering, privacy, concurrency, installer, and workflow-wiring regressions.
7. Isolated named CI failures rather than polling a truncated aggregate log.
8. Verified the application/content head through complete enforcement and named telemetry workflows.

## Progress Lifecycle Evidence

- start: audit, gaps, archive checklist, preflight, Project 8 evidence, missing target telemetry, and merged Engineering OS foundations were verified before writes.
- mid: durable handoff, exact matching, trusted-base policy, sequential lifecycle hooks, monotonic sync, privacy validation, OWH ingestion, live-thread checks, and named CI isolation were implemented and corrected from review findings.
- pre-merge: application/content head `a02085a53928fece09181ef536e3f4d31967aeb8` passed all 26 enforcement steps and both named telemetry-handoff jobs; all existing live review threads were resolved, and the two monitoring gaps stayed open. Final evidence-head policy execution and separate owner approval were left outside the application commit.

## Merge Gate

Merge is blocked unless every workflow passes on the exact evidence head, final live review state has no unresolved thread, and the owner gives separate explicit approval.
