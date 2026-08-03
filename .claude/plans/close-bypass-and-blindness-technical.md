# Route Plan — Close Bypass and Project 8 Blindness Technical Gaps

## Goal

Reconcile the canonical readiness registry and audit with the owner decision that `bypass-approval-provenance` and `project8-experiment-blindness` are technically complete after their reviewed, tested, owner-approved merges. Their behavioral effectiveness remains an observation for the future behavioral experiment and is not a pre-experiment blocker.

## Scope

- `docs/operations/known-gaps.tsv`
- `docs/operations/operational-readiness-audit.md`
- readiness/audit validation only if the canonical synchronization checks require it

No runtime implementation, Project 8 product code, telemetry implementation, pattern implementation, or future workload prompt changes.

## Source of Truth Checks

- Engineering OS `main` and merged PR #264 for bypass provenance implementation.
- Project 8 `main` and merged PR #9 for the product-only experiment-blindness boundary.
- `docs/operations/known-gaps.tsv` for canonical gap status.
- `docs/operations/operational-readiness-audit.md` for readiness classification and experiment-start semantics.

## Owner Decision

For both gaps:

> Technical implementation: closed. Behavioral effectiveness remains an experiment observation, not a pre-experiment blocker.

This decision does not claim full operational readiness and does not close telemetry, hook-parity, archive-integrity, real-run, or monitoring-sufficiency gaps.

## Validation

- Registry and audit statuses remain synchronized.
- Both matrix rows describe the implemented enforcement as active rather than missing.
- Checklists distinguish completed technical work from future experiment observation.
- No future workload content is copied into Project 8.
- Normal readiness validation must remain honest about remaining open gaps.

## Definition of Done

- [ ] `bypass-approval-provenance` is canonical `closed` with merged PR #264 evidence and experiment-observation note.
- [ ] `project8-experiment-blindness` is canonical `closed` with merged PR #9 evidence and experiment-observation note.
- [ ] The audit ledger, matrix, dependency plan, checklists, ROI order, experiment-start wording, and current scope are internally consistent.
- [ ] Remaining pre-experiment blockers are not accidentally closed or weakened.
- [ ] Exact-head CI/review is reconciled before merge.
