# Project 8 Real-Run Evidence Transition

Date: 2026-07-12
Base: `c2572b03f296703d1ff6c84cfbf4e0796b62f588`
Status: implementation approved; merge requires separate owner approval

## Route Plan

| Field | Value |
|---|---|
| Task type | Engineering OS docs/governance maintenance |
| Task class | engineering_os_governance |
| Domain tags | observability, workflow, governance, testing |
| Plan Scope | focused |
| Planning Mode | approved |
| Templates | none required |
| Architecture guides | `docs/operations/runtime-telemetry-archive-plan.md`; `docs/operations/operational-work-history-rollout.md` |
| Patterns | evidence separation; fail-closed telemetry preflight; metadata-only observability; audit freshness |
| Connectors | GitHub for Project 8 PR, CI, artifact and exact-SHA evidence |
| Skills | none required |
| Validation gates | enforcement-tests; plan-policy; pr-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; documentation-asset-policy; semantic-cleanup-policy; import-cleanup-policy |
| Evidence | Project 8 PR #4 and OWH artifact; Engineering OS PR #244; audit, gaps, checklist and preflight docs |
| User decisions | none for implementation; merge approval remains required |
| Target paths | `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/runtime-telemetry-archive-audit-checklist.md`; `docs/operations/project8-first-real-run-findings.md` |

## Capability Evidence

- `routing.task-router-read`: `core/task-router.md` read; task classified as Engineering OS governance.
- `workflow.workflow-read`: `core/workflow.md` read; plan precedes documentation changes.
- `plan.route-plan-before-write`: this is the first branch change.
- `source.github-repo-read`: both repositories, PRs, CI and the OWH artifact were inspected through GitHub.
- `validation.policy-change-has-validator`: existing audit and known-gap freshness gates cover this status reconciliation.

## Verified facts

- Project 8 PR #4 merged as `2d26b3cde2c68ff260c9f91a87700a953c6e29c8`.
- Its OWH artifact records 33 changed files, 49 commits, 14 checks, zero current failures, one review, a valid `booking-system` result-loop contract, 25 repeated-cycle commits, `telemetry_available=false`, and zero telemetry events.
- Engineering OS PR #244 merged as `c2572b03f296703d1ff6c84cfbf4e0796b62f588` and fixes installation, session isolation, preflight and historical CI aggregation.
- Project 8 `main` still has no `.claude/settings.json`; PR #4 cannot be retroactively treated as session telemetry.

## Decision

PR #4 is a real Engineering OS target-project run with valid Operational Work History and real Project 8 improvements. It is not a valid telemetry archive run. The technical blocker is removed by PR #244, so `project-8-real-run-evidence` should move from `blocked` to `open`, while all telemetry export/import/findings requirements remain incomplete.

## Scope

1. Add a first-run findings report separating OWH, session telemetry and Project 8 outcomes.
2. Change the Project 8 gap from blocked to open without closing it.
3. Reconcile the readiness audit with the real run and PR #244.
4. Add preliminary evidence to the telemetry checklist while leaving real run/export/import/findings boxes unchecked.
5. Require the next experiment to use the exact Project 8 workspace, current Engineering OS installation, a new Claude session, positive preflight, a meaningful Project 8 task and non-empty export/import/analyze evidence.

## Non-goals

- No telemetry run is claimed.
- No Project 8 code or provider migration is changed.
- No monitoring gap is closed.
- OWH is not relabeled as session telemetry.
- No merge without final CI, review verification and owner approval.

## Definition of Done

- [ ] Plan commit precedes documentation changes.
- [ ] Findings report cites exact merge and artifact facts.
- [ ] Project 8 evidence gap is open, not blocked or closed.
- [ ] Monitoring sufficiency remains open.
- [ ] Audit separates OWH evidence from missing session telemetry.
- [ ] Real telemetry run/export/import/findings boxes remain unchecked.
- [ ] Next-run preflight boundary is explicit.
- [ ] Exact-head CI passes and review threads are checked.
- [ ] Owner approves merge separately.

## Progress Lifecycle Evidence

- start: current audit/gaps/checklist/preflight, Project 8 PR #4, its OWH artifact, missing Project 8 settings, and merged Engineering OS PR #244 were verified before writes.
- mid: pending documentation reconciliation.
- pre-merge: pending exact-head checks, review and owner approval.
