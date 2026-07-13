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
- `validation.coderabbit-policy` — CodeRabbit and Codex reviews were inspected; all valid findings are resolved or disproved with evidence.

## Connector Evidence

- GitHub provided Project 8 PR #4, Engineering OS PR #244, exact SHAs, workflow metadata, missing target settings, and artifact `operational-work-history-4-29178357323`.

## Connector Usage Evidence

- source: GitHub repositories `yotamfried-ux/Engineering-OS` and `yotamfried-ux/project-8`.
- action: inspected PRs #4, #244 and #245, merged SHAs, OWH data, current audit/gaps/checklist, stale operational references, CI runs, reviews, threads, and Project 8 `.claude/settings.json` state.
- result: `docs/operations/project8-first-real-run-findings.md` plus reconciled audit/gap/checklist sources and `.github/workflows/pr-policy.yml` entered exact-head validation with the durable handoff work.
- decision: updated the Project 8 gap from blocked to open, kept monitoring open, corrected stale references, and kept the combined PR gated by telemetry and live review evidence.
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
- post-review implementation head `4fe3c408254f0fc0c7dfdd2510a0c8347d3ca47c` passed all 26 enforcement steps and both named telemetry-handoff jobs;
- capability, connector, workflow, documentation-asset, semantic-cleanup, and import-cleanup policies passed for the post-review code;
- all existing inline review threads are resolved.

## Definition of Done

- [x] Plan commit precedes documentation changes.
- [x] Findings report records exact merge and artifact facts.
- [x] Project 8 evidence gap is open.
- [x] Monitoring sufficiency remains open.
- [x] Audit separates OWH from missing telemetry.
- [x] Telemetry completion boxes remain unchecked.
- [x] Next-run preflight boundary is explicit.
- [x] Application and telemetry implementation pass all named validation gates.
- [x] Automated reviews and all existing inline threads are inspected and resolved.

## Claude Run Trace

1. Merged verified Project 8 PR #4.
2. Re-centered work on Engineering OS.
3. Read audit, gaps, checklist, preflight and PR #244.
4. Inspected Project 8 OWH and missing target telemetry.
5. Reconciled stale evidence sources without claiming telemetry completion.
6. Added durable remote handoff and live-thread enforcement under a separate plan.
7. Applied Codex findings for provisional PR binding and stale concurrent sync.
8. Verified all enforcement and named handoff suites.

## Progress Lifecycle Evidence

- start: audit, gaps, checklist, preflight, Project 8 evidence, missing target settings, and merged PR #244 were verified before writes.
- mid: after Codex identified provisional PR binding and stale concurrent overwrite risks, commits `6718669befa4184e8e2e96d8bbd6591feb39227e`, `5d9cfdfdefd5cd05c41227d18458f873f1ed16ef`, and `10601c49f901e187cfd584de7208a70ffc895be3` added exact-head provisional selection, PR rebinding, monotonic remote progress protection, and regression coverage.
- pre-merge: post-review head `4fe3c408254f0fc0c7dfdd2510a0c8347d3ca47c` passed all 26 enforcement steps and both named telemetry-handoff jobs; both Codex findings are implemented and their live review threads are resolved. Monitoring closure remains unclaimed; exact-head evidence-only checks and owner approval remain external merge gates.

## Merge Gate

Merge remains blocked until all workflows pass on the exact final evidence head and the owner gives separate explicit approval.
