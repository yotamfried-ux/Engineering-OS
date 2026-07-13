# Project 8 Real-Run Evidence Transition

Date: 2026-07-12
Base: `c2572b03f296703d1ff6c84cfbf4e0796b62f588`
Status: implementation evidence complete; merge remains externally gated

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
| Validation gates | enforcement-tests; plan-policy; pr-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; documentation-asset-policy; semantic-cleanup-policy; import-cleanup-policy |
| Evidence to check | Project 8 PR #4 and OWH artifact; Engineering OS PR #244; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/runtime-telemetry-archive-audit-checklist.md`; `docs/operations/project8-telemetry-preflight.md`; `docs/operations/operational-work-history.md`; `docs/operations/result-loop-contract-audit-checklist.md` |
| User decisions required | No implementation decision; owner merge approval is required after exact-head evidence |
| Task-router evidence | `core/task-router.md` read; selected Engineering OS governance |
| Workflow evidence | `core/workflow.md` read; plan commit `7fab9bc23118f942f86d9b1afeb8af8d023f6d97` preceded documentation changes |
| Target paths | `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/runtime-telemetry-archive-audit-checklist.md`; `docs/operations/project8-first-real-run-findings.md`; `docs/operations/operational-work-history.md`; `docs/operations/result-loop-contract-audit-checklist.md` |

## Capability Evidence

- `routing.task-router-read` — task router read before planning.
- `workflow.workflow-read` — workflow read and plan-first ordering used.
- `plan.route-plan-before-write` — plan commit preceded all documentation changes.
- `source.github-repo-read` — both repositories, PRs, CI, exact SHAs and the OWH artifact were inspected through GitHub.
- `validation.policy-change-has-validator` — existing audit, known-gap and plan validators cover this evidence/status reconciliation; no new validator is required.
- `validation.coderabbit-policy` — CodeRabbit and Codex reviews were inspected; both CodeRabbit threads and the Codex stale-reference thread are resolved.

## Connector Evidence

- GitHub provided Project 8 PR #4, Engineering OS PR #244, exact SHAs, workflow metadata, missing target settings, and artifact `operational-work-history-4-29178357323`.

## Connector Usage Evidence

- source: GitHub repositories `yotamfried-ux/Engineering-OS` and `yotamfried-ux/project-8`.
- action: inspected PRs #4, #244 and #245, merged SHAs, OWH data, current audit/gaps/checklist, stale operational references, CI runs, reviews, threads, and Project 8 `.claude/settings.json` state.
- result: `docs/operations/project8-first-real-run-findings.md` plus reconciled `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `docs/operations/runtime-telemetry-archive-audit-checklist.md`, `docs/operations/operational-work-history.md`, `docs/operations/result-loop-contract-audit-checklist.md`, and the combined PR workflow `.github/workflows/pr-policy.yml` passed or entered exact-head validation.
- decision: updated the Project 8 gap from blocked to open, kept monitoring open, corrected stale blocked references, and kept the combined PR blocked until telemetry handoff and live-thread enforcement pass.
- target: `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/runtime-telemetry-archive-audit-checklist.md`; `docs/operations/project8-first-real-run-findings.md`; `docs/operations/operational-work-history.md`; `docs/operations/result-loop-contract-audit-checklist.md`; `.github/workflows/pr-policy.yml`.

## Documentation Asset Evidence

- internal: `docs/operations/runtime-telemetry-archive-plan.md`; `docs/operations/operational-work-history-rollout.md`; `docs/operations/project8-telemetry-preflight.md`.
- context7: not required because the original evidence reconciliation introduced no external API, SDK, or runtime implementation decisions.
- decision: internal archive and preflight contracts require OWH and session telemetry to remain separate.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `docs/operations/known-gaps.tsv` | read | Project 8 status was blocked and assumed no real target evidence |
| `docs/operations/operational-readiness-audit.md` | read | audit said the Project 8 run was not performed |
| `docs/operations/runtime-telemetry-archive-audit-checklist.md` | read | telemetry export/import/findings items remained incomplete |
| `docs/operations/project8-telemetry-preflight.md` | read | next valid run requires exact workspace, fresh session and positive preflight |
| `docs/operations/operational-work-history.md` | read | a non-historical note still called Project 8 evidence blocked |
| `docs/operations/result-loop-contract-audit-checklist.md` | read | reconciliation and real-run sections still called the gap blocked |
| `docs/operations/project8-first-real-run-findings.md` | validated | exact PR #4 and OWH facts are recorded without calling OWH telemetry |

## Decision

Project 8 PR #4 is a real target run with valid OWH and real product improvements, but it had zero session events. PR #244 removed the installation blocker, so the gap moves from blocked to open while telemetry closure remains incomplete.

## Validation Evidence

- original documentation evidence head `025223911c100e96816eb93944f980009a9b08cd` passed enforcement-tests and every independent evidence gate;
- the cumulative PR was later extended by the separate remote-telemetry plan;
- cumulative implementation head `e7af77a01109a84e8e1899b577be47bb132c8250` passed all 26 enforcement steps and both named telemetry-handoff jobs;
- capability, connector, documentation-asset, semantic-cleanup, and import-cleanup policies passed on that implementation head;
- every existing inline review thread is resolved.

## Definition of Done

- [x] Plan commit precedes documentation changes.
- [x] Findings report records exact merge and artifact facts.
- [x] Project 8 evidence gap is open.
- [x] Monitoring sufficiency remains open.
- [x] Audit separates OWH from missing telemetry.
- [x] Telemetry completion boxes remain unchecked.
- [x] Next-run preflight boundary is explicit.
- [x] Application/content head passes enforcement-tests and every independent evidence gate.
- [x] Automated reviews and all existing inline threads are inspected and resolved.

## Claude Run Trace

1. Merged verified Project 8 PR #4.
2. Re-centered work on Engineering OS.
3. Read audit, gaps, checklist, preflight and PR #244.
4. Inspected the Project 8 OWH artifact and missing target settings.
5. Committed the plan before documentation updates.
6. Opened PR #245 and used first-run CI to identify Route Plan evidence omissions.
7. CodeRabbit confirmed the initial Route Plan findings were addressed; Codex found two remaining stale blocked-status references.
8. Reconciled both stale documents and recorded the first real result-loop run without marking telemetry complete.
9. Verified enforcement-tests and all independent policy gates on application/content head `025223911c100e96816eb93944f980009a9b08cd`.
10. Resolved all three original inline review threads and added a separate evidence checkpoint.
11. PR #245 was later extended with `remote-telemetry-handoff.md`; this plan's GitHub target was linked to the cumulative workflow diff.
12. Refreshed this plan after the later code work so its lifecycle evidence reflects the cumulative PR rather than the earlier docs-only head.

## Progress Lifecycle Evidence

- start: audit, gaps, checklist, preflight, Project 8 PR #4, its OWH artifact, missing target settings and merged PR #244 were verified before writes.
- mid: after Codex identified provisional PR binding and stale concurrent overwrite risks, cumulative code commits `6718669befa4184e8e2e96d8bbd6591feb39227e`, `5d9cfdfdefd5cd05c41227d18458f873f1ed16ef`, and `10601c49f901e187cfd584de7208a70ffc895be3` added provisional exact-head selection, exact rebinding, monotonic remote progress protection, and regression coverage without changing the audit closure claims.
- pre-merge: implementation head `e7af77a01109a84e8e1899b577be47bb132c8250` passed all enforcement steps and both named telemetry-handoff jobs; workflow diagnostic artifact `workflow-evidence-log-29289025034` identified the cumulative lifecycle/source mismatches, commits `dcfd0bc97e2086eac002ba31191bb0af672f53d4` and `27235a4cddd1bfd90b1dae57c16269b47ba31a16` separated the earlier mid evidence, and all existing review threads are resolved. Exact-head checks and owner approval remain external merge gates.

## Merge Gate

Merge remains blocked until all workflows pass on the exact final evidence head and the owner gives separate explicit approval.
