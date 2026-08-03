# Route Plan — Close Bypass and Project 8 Blindness Technical Gaps

## Route Plan

| Field | Decision |
|---|---|
| Task type | operational-readiness canonical status reconciliation |
| Task class | `engineering_os_governance` |
| Domain tags | governance, readiness, documentation, experiment-boundary, security |
| Plan Scope | focused |
| Planning Mode | owner-approved semantic reconciliation of two already-merged technical implementations; no runtime implementation changes |
| Target paths | `.claude/plans/close-bypass-and-blindness-technical.md`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md` |
| Task-router evidence | `core/task-router.md` was read; it routes docs/governance/Engineering OS maintenance through the canonical governance workflow and requires an explicit registry task class plus knowledge/tool selection before writes. |
| Workflow evidence | `core/workflow.md`, `core/git-policy.md`, `core/quality-gates.md`, and `docs/operations/merge-readiness-checklist.md` were checked; they require plan-first work, validated canonical evidence, exact-head CI/review, explicit owner approval, protected merge, and post-merge separation. |
| Templates | waiver — focused canonical-state reconciliation reuses the existing `known-gaps.tsv` and readiness-audit schemas; no project/template scaffold is applicable. |
| Architecture guides | `docs/operations/operational-readiness-audit.md`; `docs/operations/known-gaps.tsv`; `docs/operations/merge-readiness-checklist.md` |
| Patterns | none — this is metadata-only canonical-state reconciliation; no implementation pattern is required. |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion` |
| Validation gates | `known-gaps-live-state`; `enforcement-tests`; `workflow-evidence-policy`; `connector-evidence-policy`; `capability-evidence-policy`; `documentation-asset-policy`; `plan-policy`; `semantic-cleanup-policy`; `import-cleanup-policy`; `telemetry-handoff-tests`; `pr-policy`; review reconciliation |
| Evidence to check | Engineering OS PR #264 reviewed head `335bd0ba1b92c60e02f0a18a6197587b4c940c0a` and merge `f9449e708f9cfaff89458419baea2b96a3af8210`; Project 8 PR #9 reviewed head `8591d2569fb7fcd2481670fe814c5ec46becb8aa` and merge `3ca98089045df7256755bacd4a9a1b8500624874`; current canonical registry/audit; final PR #265 exact-head CI/reviews |
| User decisions required | the owner decision changing these two gaps to technical closure has been supplied; a separate explicit owner approval for PR #265 final exact head is still required before merge. |

## Goal

Reconcile the canonical readiness registry and audit with the owner decision that `bypass-approval-provenance` and `project8-experiment-blindness` are technically complete after their reviewed, tested, owner-approved merges. Their behavioral effectiveness remains an observation for the future behavioral experiment and is not a pre-experiment blocker.

## Scope

- `docs/operations/known-gaps.tsv`
- `docs/operations/operational-readiness-audit.md`
- this Route Plan

No runtime implementation, Project 8 product code, telemetry implementation, pattern implementation, provider state, future workload prompt, or permanent workflow changes.

## Template Gap Waiver

No reusable project template applies to this focused canonical-state reconciliation. The change reuses the existing `docs/operations/known-gaps.tsv` registry schema and `docs/operations/operational-readiness-audit.md` readiness schema; introducing or modifying a template would create unrelated reusable-asset scope.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `core/task-router.md` | read | This is `engineering_os_governance`; the canonical governance evidence contract applies. |
| `core/workflow.md` | read | Plan-first work, exact-head validation/review, explicit owner approval, merge, and later lifecycle claims remain distinct. |
| `docs/operations/merge-readiness-checklist.md` | read | Canonical status changes still require exact-head CI/review and a separate owner merge decision. |
| `docs/operations/known-gaps.tsv` | read | Both target rows were still `open` because their prior closure text included behavioral/live observation that the owner has now reclassified as experiment observation. |
| `docs/operations/operational-readiness-audit.md` | read | Ledger, matrix, phase ordering, checklists, ROI order, and current-scope wording all required synchronized updates for the two status changes. |
| `scripts/enforcement/lib/evidence.sh` | checked | Engineering OS `main` includes the canonical request-only bypass path merged by PR #264; reviewed head `335bd0ba1b92c60e02f0a18a6197587b4c940c0a` and merge `f9449e708f9cfaff89458419baea2b96a3af8210` supply the exact implementation identity. |
| `scripts/enforcement/validate-bypass-approval.py` | checked | Provider-backed approval validation and exact-scope/fail-closed semantics from PR #264 are present on canonical Engineering OS `main`. |
| `scripts/enforcement/check-product-boundary.py` in `yotamfried-ux/project-8` | checked | Project 8 `main` includes the deterministic product-only boundary merged by PR #9; reviewed head `8591d2569fb7fcd2481670fe814c5ec46becb8aa` and merge `3ca98089045df7256755bacd4a9a1b8500624874` supply the exact implementation identity. |
| `.claude/settings.json` in `yotamfried-ux/project-8` | checked | The merged target settings retain machine-readable telemetry/runtime hooks while model-visible Engineering OS coaching was removed. |

## Documentation Asset Evidence

- internal: `core/task-router.md`; `core/workflow.md`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/merge-readiness-checklist.md`; `scripts/enforcement/lib/evidence.sh`; Project 8 `scripts/enforcement/check-product-boundary.py`; Project 8 `.claude/settings.json`.
- context7: not required — this PR changes repository-owned readiness classification only and does not alter a vendor/API/runtime contract.
- decision: reuse the canonical registry/audit and distinguish technical closure from later behavioral observation instead of creating a second status registry.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Re-fetched Engineering OS PR #264, merge `f9449e708f9cfaff89458419baea2b96a3af8210`, `scripts/enforcement/lib/evidence.sh`, and canonical `main`; re-fetched Project 8 PR #9, merge `3ca98089045df7256755bacd4a9a1b8500624874`, `scripts/enforcement/check-product-boundary.py`, `.claude/settings.json`, and Project 8 `main`; then checked the canonical registry/audit before changing status. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS` PR #264 and `yotamfried-ux/project-8` PR #9 plus their exact merged files and canonical branches.
- action: re-fetched merge state, exact reviewed heads, compare state, CI/review evidence, `scripts/enforcement/lib/evidence.sh`, Project 8 `scripts/enforcement/check-product-boundary.py`, Project 8 `.claude/settings.json`, and current canonical gap/audit wording before changing status.
- result: Engineering OS PR #264 merge `f9449e708f9cfaff89458419baea2b96a3af8210` is canonical `main` and owns `scripts/enforcement/lib/evidence.sh`; Project 8 PR #9 merge `3ca98089045df7256755bacd4a9a1b8500624874` is canonical Project 8 `main` and owns `scripts/enforcement/check-product-boundary.py` plus telemetry-only `.claude/settings.json`. These exact identifiers show the two previously missing technical implementations now exist on canonical branches.
- decision: updated only `gap:bypass-approval-provenance` and `gap:project8-experiment-blindness` to `closed` because those exact merged paths satisfy the technical closure contracts; kept behavioral effectiveness as experiment observation and kept telemetry integrity, hook parity, real-run, monitoring sufficiency, pattern, longitudinal, and full-readiness gaps unchanged.
- target: `docs/operations/known-gaps.tsv` and `docs/operations/operational-readiness-audit.md`.

## Capability Evidence

- `routing.task-router-read` — `core/task-router.md` was read before this canonical reconciliation.
- `workflow.workflow-read` — governance lifecycle and evidence separation were checked before writes.
- `plan.route-plan-before-write` — plan-only commit `89567827de51041cc0ee84dccbe1b76b307ba47e` preceded canonical registry/audit writes.
- `source.github-repo-read` — exact PR, merge, compare, workflow, review, registry, audit, and implementation-file state was read from GitHub.
- `validation.policy-change-has-validator` — existing known-gaps, readiness-audit, documentation, workflow, connector, capability, and full enforcement validators own this focused metadata change.
- `validation.actions-checked` — exact-head workflows are required and re-run after every head change.
- `validation.coderabbit-policy` — CodeRabbit/Codex findings and live review threads must be reconciled on the final exact head before merge approval.

## Skill Evidence

- `writing-plans` — scope, sources, owner decision, lifecycle evidence, and validation were recorded before and after canonical writes.
- `verification-before-completion` — technical implementation closure, experiment observation, experiment readiness, full operational readiness, PR merge, and post-merge evidence remain separate claims.

## Owner Decision

For both gaps:

> Technical implementation: closed. Behavioral effectiveness remains an experiment observation, not a pre-experiment blocker.

This decision does not claim full operational readiness and does not close telemetry, hook-parity, archive-integrity, real-run, monitoring-sufficiency, longitudinal, or pattern gaps.

## Validation

- Registry and audit statuses remain synchronized.
- Both matrix rows describe the implemented enforcement as active rather than missing.
- Checklists distinguish completed technical work from future experiment observation.
- No future workload content is copied into Project 8.
- Normal readiness validation remains honest about remaining open gaps.
- Exact-head CI and review must be re-collected after this plan correction before merge approval is requested.

## Progress Lifecycle Evidence

- start: plan-only commit `89567827de51041cc0ee84dccbe1b76b307ba47e` recorded scope and the owner decision before canonical audit writes.
- mid: the canonical patch updated exactly two registry rows and the corresponding audit ledger, matrix, dependency, checklist, ROI, and current-scope statements; a temporary branch-only sync workflow was used only to apply the large-file patch and was removed before PR scope.
- pre-review: commit `457b44986cf6832fa6818e02a1146cc31d576bf0` proved every non-self evidence gate except the connector decision-impact keyword, while `enforcement-tests` and the latest `pr-policy` were still running. This correction changes only the connector decision verb required by the deterministic checker.

## Definition of Done

- [x] `bypass-approval-provenance` is candidate canonical `closed` with merged PR #264 evidence and experiment-observation note.
- [x] `project8-experiment-blindness` is candidate canonical `closed` with merged PR #9 evidence and experiment-observation note.
- [x] The audit ledger, matrix, dependency plan, checklists, ROI order, and current scope are internally reconciled for these two closures.
- [x] Remaining pre-experiment and full-readiness gaps were not accidentally closed or weakened.
- [x] Final compare excludes the temporary patch workflow and contains only the Route Plan plus the two canonical readiness files.

External merge gate: exact-head CI/review must be green/reconciled and a new explicit owner approval for PR #265 final exact head is required before merge.
