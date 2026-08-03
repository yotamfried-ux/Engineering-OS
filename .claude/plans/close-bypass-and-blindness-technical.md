# Route Plan — Close Bypass and Project 8 Blindness Technical Gaps

## Route Plan

| Field | Decision |
|---|---|
| Task type | operational-readiness canonical status reconciliation |
| Task class | `engineering_os_governance` |
| Domain tags | governance, readiness, documentation, experiment-boundary, security |
| Plan Scope | focused |
| Planning Mode | owner-approved semantic reconciliation of two already-merged technical implementations; no runtime implementation changes |
| Target paths | `.claude/plans/close-bypass-and-blindness-technical.md`; `docs/operations/known-gaps.tsv`; `docs/operations/live-state-claims.json`; `docs/operations/operational-readiness-audit.md` |
| Task-router evidence | `core/task-router.md` was read; it routes docs/governance/Engineering OS maintenance through the canonical governance workflow and requires an explicit registry task class plus knowledge/tool selection before writes. |
| Workflow evidence | `core/workflow.md`, `core/git-policy.md`, `core/quality-gates.md`, and `docs/operations/merge-readiness-checklist.md` were checked; they require plan-first work, validated canonical evidence, exact-head CI/review, explicit owner approval, protected merge, and post-merge separation. |
| Templates | waiver — focused canonical-state reconciliation reuses the existing known-gap/readiness/live-claim schemas; no project/template scaffold is applicable. |
| Architecture guides | `docs/operations/operational-readiness-audit.md`; `docs/operations/known-gaps.tsv`; `docs/operations/live-state-claims.json`; `docs/operations/merge-readiness-checklist.md` |
| Patterns | none — this is metadata-only canonical-state reconciliation; no implementation pattern is required. |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion` |
| Validation gates | `known-gaps-live-state`; `enforcement-tests`; `workflow-evidence-policy`; `connector-evidence-policy`; `capability-evidence-policy`; `documentation-asset-policy`; `plan-policy`; `semantic-cleanup-policy`; `import-cleanup-policy`; `telemetry-handoff-tests`; `pr-policy`; review reconciliation |
| Evidence to check | Engineering OS PR #264 reviewed head `335bd0ba1b92c60e02f0a18a6197587b4c940c0a` and merge `f9449e708f9cfaff89458419baea2b96a3af8210`; Project 8 PR #9 reviewed head `8591d2569fb7fcd2481670fe814c5ec46becb8aa` and merge `3ca98089045df7256755bacd4a9a1b8500624874`; live-state claims for both closures; final PR #265 exact-head CI/reviews |
| User decisions required | the owner decision changing these two gaps to technical closure has been supplied; a separate explicit owner approval for PR #265 final exact head is still required before merge. |

## Goal

Reconcile the canonical readiness registry and audit with the owner decision that `bypass-approval-provenance` and `project8-experiment-blindness` are technically complete after their reviewed, tested, owner-approved merges. Their behavioral effectiveness remains an observation for the future behavioral experiment and is not a pre-experiment blocker.

## Scope

- `docs/operations/known-gaps.tsv`
- `docs/operations/live-state-claims.json`
- `docs/operations/operational-readiness-audit.md`
- this Route Plan

No runtime implementation, Project 8 product code, telemetry implementation, pattern implementation, provider state, future workload prompt, or permanent workflow changes.

This PR does **not** change the global `Experiment start decision`. The current all-gaps/full-ready rule remains canonical until a separate follow-up explicitly defines a telemetry-based `Experiment Ready` gate with its own checker and fixtures.

## Template Gap Waiver

No reusable project template applies to this focused canonical-state reconciliation. The change reuses the existing `docs/operations/known-gaps.tsv`, `docs/operations/live-state-claims.json`, and `docs/operations/operational-readiness-audit.md` schemas; introducing or modifying a template would create unrelated reusable-asset scope.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `core/task-router.md` | read | This is `engineering_os_governance`; the canonical governance evidence contract applies. |
| `core/workflow.md` | read | Plan-first work, exact-head validation/review, explicit owner approval, merge, and later lifecycle claims remain distinct. |
| `docs/operations/merge-readiness-checklist.md` | read | Canonical status changes still require exact-head CI/review and a separate owner merge decision. |
| `docs/operations/known-gaps.tsv` | read | Both target rows were still `open` because their prior closure text included behavioral/live observation that the owner has now reclassified as experiment observation. |
| `docs/operations/live-state-claims.json` | read and updated | Every canonical `closed` status that depends on mutable GitHub merge evidence should have a fail-closed versioned live claim; claims were added for Engineering OS PR #264 and Project 8 PR #9. |
| `docs/operations/operational-readiness-audit.md` | read and updated | Ledger, matrix, phase/checklist text, current snapshot, and current-scope wording were synchronized with the two technical closures while leaving the global experiment-start rule unchanged. |
| `scripts/enforcement/lib/evidence.sh` | checked | Engineering OS `main` includes the canonical request-only bypass path merged by PR #264; reviewed head `335bd0ba1b92c60e02f0a18a6197587b4c940c0a` and merge `f9449e708f9cfaff89458419baea2b96a3af8210` supply the exact implementation identity. |
| `scripts/enforcement/validate-bypass-approval.py` | checked | Provider-backed approval validation and exact-scope/fail-closed semantics from PR #264 are present on canonical Engineering OS `main`. |
| `scripts/enforcement/check-product-boundary.py` in `yotamfried-ux/project-8` | checked | Project 8 `main` includes the deterministic product-only boundary merged by PR #9; reviewed head `8591d2569fb7fcd2481670fe814c5ec46becb8aa` and merge `3ca98089045df7256755bacd4a9a1b8500624874` supply the exact implementation identity. |
| `.claude/settings.json` in `yotamfried-ux/project-8` | checked | The merged target settings retain machine-readable telemetry/runtime hooks while model-visible Engineering OS coaching was removed. |

## Documentation Asset Evidence

- internal: `core/task-router.md`; `core/workflow.md`; `docs/operations/known-gaps.tsv`; `docs/operations/live-state-claims.json`; `docs/operations/operational-readiness-audit.md`; `docs/operations/merge-readiness-checklist.md`; `scripts/enforcement/lib/evidence.sh`; Project 8 `scripts/enforcement/check-product-boundary.py`; Project 8 `.claude/settings.json`.
- context7: not required — this PR changes repository-owned readiness classification only and does not alter a vendor/API/runtime contract.
- decision: reuse the canonical registry/audit/live-claim mechanism and distinguish technical closure from later behavioral observation instead of creating a second status registry.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Re-fetched Engineering OS PR #264, merge `f9449e708f9cfaff89458419baea2b96a3af8210`, bypass owner files, and canonical `main`; re-fetched Project 8 PR #9, merge `3ca98089045df7256755bacd4a9a1b8500624874`, product-boundary/runtime files, and Project 8 `main`; `known-gaps-live-state` run 60 / `30841282393` then successfully validated the two newly registered cross-repository live claims. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS` PR #264, `yotamfried-ux/project-8` PR #9, PR #265, exact merged files, workflows, review threads, and canonical branches.
- action: re-fetched merge state, exact reviewed heads, compare state, CI/review evidence, bypass/product-boundary implementation paths, current registry/audit/live-claim state, and every PR #265 review finding before changing status and reconciling scope.
- result: Engineering OS PR #264 merge `f9449e708f9cfaff89458419baea2b96a3af8210` is canonical `main`; Project 8 PR #9 merge `3ca98089045df7256755bacd4a9a1b8500624874` is canonical Project 8 `main`; `known-gaps-live-state` run `30841282393` succeeded after adding `engineering-os-pr-264-bypass-approval-provenance` and `project-8-pr-9-experiment-blindness`, proving the claims can be reconciled fail-closed from the Engineering OS workflow.
- decision: updated only `gap:bypass-approval-provenance` and `gap:project8-experiment-blindness` to `closed`; kept behavioral effectiveness as experiment observation; kept the existing global experiment-start rule unchanged in this PR; kept telemetry integrity, hook parity, qualification/monitoring, pattern, longitudinal, and full-readiness gaps unchanged.
- target: `docs/operations/known-gaps.tsv`; `docs/operations/live-state-claims.json`; `docs/operations/operational-readiness-audit.md`.

## Capability Evidence

- `routing.task-router-read` — `core/task-router.md` was read before this canonical reconciliation.
- `workflow.workflow-read` — governance lifecycle and evidence separation were checked before writes.
- `plan.route-plan-before-write` — plan-only commit `89567827de51041cc0ee84dccbe1b76b307ba47e` preceded canonical registry/audit writes.
- `source.github-repo-read` — exact PR, merge, compare, workflow, review, registry, audit, live-claim, and implementation-file state was read from GitHub.
- `validation.policy-change-has-validator` — existing known-gaps, live-state, readiness-audit, documentation, workflow, connector, capability, and full enforcement validators own this focused metadata change.
- `validation.actions-checked` — exact-head workflows are required and re-run after every head change; live-state run `30841282393` already validated the cross-repository claims on the review-corrected branch.
- `validation.coderabbit-policy` — four valid current review findings were verified and corrected: keep experiment prerequisites consistent, register live claims, refresh the audit snapshot, and avoid prematurely changing the experiment authorization rule.

## Skill Evidence

- `writing-plans` — scope, sources, owner decision, lifecycle evidence, review reconciliation, and validation were recorded before and after canonical writes.
- `verification-before-completion` — technical implementation closure, experiment observation, experiment readiness, full operational readiness, PR merge, and post-merge evidence remain separate claims.

## Owner Decision

For both gaps:

> Technical implementation: closed. Behavioral effectiveness remains an experiment observation, not a pre-experiment blocker.

This decision closes the two implementation gaps but does not by itself authorize the behavioral experiment. A separate follow-up will define which remaining telemetry/readiness gaps are pre-experiment blockers and will change the canonical experiment-start rule only with executable validation.

## Validation

- Registry and audit statuses remain synchronized.
- Versioned live-state claims cover both newly closed gaps and are validated cross-repository by the existing fail-closed workflow.
- Both matrix rows describe the implemented enforcement as active rather than missing.
- Checklists distinguish completed technical work from future experiment observation.
- Audit metadata uses the merge state actually relied on for this closure.
- No future workload content is copied into Project 8.
- The current global experiment-start decision remains unchanged, avoiding a partial prose-only readiness-policy change.
- Exact-head CI and review must be re-collected after this final plan checkpoint before merge approval is requested.

## Progress Lifecycle Evidence

- start: plan-only commit `89567827de51041cc0ee84dccbe1b76b307ba47e` recorded scope and the owner decision before canonical audit writes.
- mid: the canonical patch updated exactly two registry rows and the corresponding audit ledger, matrix, dependency, checklist, and current-scope statements; temporary branch-only sync workflows were used only to apply large-file patches and were removed before final PR scope.
- review-result-loop: Codex/CodeRabbit identified four valid current findings: an accidental partial experiment-policy change, missing live-state claims, stale audit snapshot metadata, and contradictory experiment-authorization wording. The branch added both versioned claims, refreshed the snapshot, restored the unchanged global experiment rule, and removed all optional/post-start classifications from this PR.
- pre-review: commit `047d05c68e79b392c06598e0f7c773da0eae1e8e` removed the last temporary review-sync workflow. On that head, all completed non-self evidence workflows were successful, including cross-repository `known-gaps-live-state` run `30841282393`; `enforcement-tests` was still running and `pr-policy` failed only because the four valid review threads had not yet been resolved. This plan checkpoint follows those fixes and is the final documentation change before thread reconciliation.

## Definition of Done

- [x] `bypass-approval-provenance` is candidate canonical `closed` with merged PR #264 evidence and experiment-observation note.
- [x] `project8-experiment-blindness` is candidate canonical `closed` with merged Project 8 PR #9 evidence and experiment-observation note.
- [x] Versioned live-state claims bind both newly closed gaps to exact reviewed heads, merges, PR workflows, and push workflows.
- [x] The audit ledger, matrix, phase/checklist text, snapshot, and current scope are internally reconciled for these two closures.
- [x] The global experiment-start rule was not partially changed in this closure PR.
- [x] Remaining pre-experiment/full-readiness gaps were not accidentally closed or weakened.
- [x] Final compare contains only this Route Plan plus `known-gaps.tsv`, `live-state-claims.json`, and `operational-readiness-audit.md`; no temporary workflow remains.

External merge gate: successor exact-head CI/review must be green/reconciled and a new explicit owner approval for PR #265 final exact head is required before merge.
