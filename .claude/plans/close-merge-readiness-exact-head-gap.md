# Route Plan — Close Exact-Head Merge Readiness Gap

## Route Plan

| Field | Decision |
|---|---|
| Task type | operational-readiness closure reconciliation |
| Task class | `engineering_os_governance` |
| Domain tags | governance, audit, GitHub Actions, merge safety, live-state evidence |
| Plan Scope | focused |
| Planning Mode | post-merge evidence reconciliation; this branch does not alter runtime enforcement |
| Task-router evidence | `core/task-router.md` routes canonical audit and gap closure work through Engineering OS governance and merge-governance owners. |
| Workflow evidence | `core/workflow.md`, `core/git-policy.md`, `core/quality-gates.md`, and the audit closure standard require verified implementation, exact-head CI, review, owner-approved merge, post-merge proof, then canonical status synchronization. |
| Target paths | `.claude/plans/close-merge-readiness-exact-head-gap.md`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/live-state-claims.json`; temporary `.github/workflows/temporary-audit-reconciliation.yml` used only to apply validated exact replacements and delete itself before the final diff |
| Templates | waiver — this is a focused canonical-state reconciliation using existing registry and claim schemas |
| Architecture guides | `docs/operations/operational-readiness-audit.md`; `docs/operations/merge-readiness-checklist.md`; `docs/operations/live-state-claims.json` |
| Patterns | none — no implementation pattern is needed for a metadata-only closure claim |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion` |
| Validation gates | known-gaps registry; readiness audit; live-state claim validation; PR policy; exact-head CI; review reconciliation |
| Evidence to check | PR #257 reviewed head `fedf8d069a8634085c650ea6381c1c0dabfdc368`; merge commit `efb36cca413602cde3cd20aa17d32b3379f9eb53`; latest PR workflow attempts; owner approval comment `5060947961`; merge/base containment; post-merge workflows on canonical `main` |
| User decisions required | no merge of this closure PR without a new explicit owner approval |

## Goal

Close `merge-readiness-exact-head-and-attempt-ordering` only if the canonical live-state validator independently proves that PR #257 satisfied the entire closure bar: deterministic fixtures, real merge-decision wiring, exact-head latest-attempt CI, resolved review, explicit owner approval, expected-head protected merge, and post-merge validation on `main`.

## Scope

The final branch diff changes status and evidence metadata only. It does not modify the checker, test fixtures, workflow registry, approval policy, or Project 8. A temporary branch-only workflow applied exact audited replacements to the large canonical audit, failed unless every expected source text matched exactly once, deleted itself in the generated commit, and is absent from the final diff.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `docs/operations/known-gaps.tsv` | checked | The gap closure row records the exact implementation PR, reviewed head, approval, merge, and live claim. |
| `docs/operations/operational-readiness-audit.md` | checked | The freshness ledger, matrix, dependency plan, mandatory checklist, ROI order, and current scope now agree with the registry. |
| `docs/operations/live-state-claims.json` | checked | The new versioned claim binds PR #257 to its exact head, merge, pull-request workflows, push workflows, and check run. |
| `scripts/enforcement/check-known-gaps-live-state.py` | read | The live validator fails closed on stale, missing, unmerged, wrong-head, failed-attempt, missing-workflow, and base-containment evidence. |
| `scripts/enforcement/tests/test-known-gaps-live-state.sh` | read | Offline fixtures own the claim schema and negative cases. |
| `docs/operations/merge-readiness-checklist.md` | checked | Human approval and post-merge validation remain separate from machine CI evidence. |
| `https://github.com/yotamfried-ux/Engineering-OS/pull/257` | validated | PR #257 merged after expected-head protection; canonical `main` compares identical to merge commit `efb36cca413602cde3cd20aa17d32b3379f9eb53`. |

## Documentation Asset Evidence

- internal: `docs/operations/operational-readiness-audit.md`, `docs/operations/known-gaps.tsv`, `docs/operations/live-state-claims.json`, `docs/operations/merge-readiness-checklist.md`, and `scripts/enforcement/check-known-gaps-live-state.py` define the exact closure schema and source hierarchy.
- context7: Context7 is not required because no external library behavior is being implemented; the external trust boundary is current GitHub REST state already consumed by the repository's canonical live-state workflow.
- decision: extend the existing versioned claim registry and synchronize every audit representation instead of treating the merged PR body or this conversation as closure evidence.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Live PR #257 state, exact reviewed head, latest workflow attempts, review threads, approval comment, merge result, merge commit, canonical `main` identity, PR #259 workflows, and final branch diff were re-fetched. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, PR #257, approval comment `5060947961`, reviewed head `fedf8d069a8634085c650ea6381c1c0dabfdc368`, merge `efb36cca413602cde3cd20aa17d32b3379f9eb53`, and PR #259 live-state run 30.
- action: verified the implementation PR, latest attempts, resolved review threads, explicit approval, expected-head merge, canonical-main identity, closure branch diff, and the live claim against current GitHub state.
- result: `known-gaps-live-state` run 30 succeeded on PR #259 head `b8c1602f140cf55bccf0c8e8d46fde9a4eb23c86`, proving the PR #257 claim could resolve its required pull-request and post-merge evidence; the final diff contains four canonical files and no temporary workflow.
- decision: selected a separate closure PR and fail-closed live claim rather than editing `main` directly or declaring the gap closed from chat memory; selected an exact-replacement self-deleting workflow rather than manually rewriting a large canonical audit through a truncated connector response.
- target: `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/live-state-claims.json`; temporary `.github/workflows/temporary-audit-reconciliation.yml`.

## Capability Evidence

- `routing.task-router-read` — the canonical audit dependency order selected this gap and the separate closure workflow.
- `workflow.workflow-read` — implementation, merge, post-merge proof, canonical closure, closure review, and closure merge remain distinct lifecycle states.
- `plan.route-plan-before-write` — commit `a6f90b27916c84ac7e7462384c642946c0b20c37` preceded registry, claim, audit, and temporary-workflow writes; the temporary mechanism was added to the plan before creation.
- `source.github-repo-read` — PR #257, PR #259, commits, workflow attempts, threads, artifacts, files, and compare results were read from GitHub.
- `validation.policy-change-has-validator` — `known-gaps-live-state` run 30 and the existing known-gaps/readiness suites validate the closure metadata; no new validator is needed for this metadata-only claim extension.
- `validation.coderabbit-policy` — PR #257 review findings were corrected and resolved; PR #259 retains independent live review as a blocking gate and structured fallback evidence only when external review is unavailable.

## Skill Evidence

- `writing-plans` — the original plan commit preceded all canonical status changes, the scope update preceded the temporary workflow, and this checkpoint follows the final audit replacement.
- `verification-before-completion` — implementation, merge, post-merge proof, canonical claim validation, closure PR review, closure PR merge, and closure post-merge validation remain separate assertions.

## Closure Mapping

- Registry: the gap status is `closed` with PR #257, reviewed head, merge commit, and live claim evidence.
- Audit ledger: the gap status is `closed`.
- Status matrix: exact-head/latest-attempt merge safety is `Enforced` without a non-closed gap reference.
- Dependency plan: the gap is in completed foundation evidence; `documentation-runtime-state-drift` remains the only active Phase 0 item.
- Mandatory checklist: every implementation and PR #257 lifecycle item is checked with exact evidence.
- Live claims: the PR #257 claim requires exact pull-request and post-merge push workflows.

## Definition of Done — Closure Candidate

- [x] The Route Plan preceded every canonical-state and temporary-workflow write.
- [x] The registry, audit ledger, matrix, dependency order, checklist, ROI order, current scope, and live claim are synchronized.
- [x] The final compare against merge `efb36cca413602cde3cd20aa17d32b3379f9eb53` contains only the four declared canonical paths.
- [x] `known-gaps-live-state` run 30 independently validated the PR #257 claim on the closure branch.
- [x] Capability, connector, documentation-asset, exact-source, lifecycle, and review evidence are recorded in this plan and PR body.

## Current Completion State

The canonical closure candidate and its live claim are complete. PR #259 exact-head full CI, independent review, a new owner approval, closure merge, and closure post-merge validation remain external gates. The Project 8 experiment remains blocked by the other non-closed gaps.

## Progress Lifecycle Evidence

- start: commit `a6f90b27916c84ac7e7462384c642946c0b20c37` recorded the closure scope before canonical state changes.
- mid: commits `e4ea6e35f596430eb1503b2fd140a598b2cd3068` and `da7f17181ace1e65586764bab3772fc6da42b293` synchronized the registry row and added the fail-closed live-state claim; commit `5cc0b98dbeee8acd387cd37ec68f79df480d0888` documented the exact audit-reconciliation mechanism before its workflow was created.
- pre-merge: after the self-deleting workflow committed the audited replacements, the final compare contained exactly four canonical paths and no temporary workflow; `known-gaps-live-state` run 30 succeeded on head `b8c1602f140cf55bccf0c8e8d46fde9a4eb23c86`; this checkpoint corrects the concrete-source and capability-evidence findings without changing runtime enforcement or closure identifiers.

## Validation Plan

1. Require all canonical workflows on the new exact PR #259 head created by this checkpoint.
2. Inspect the fresh `known-gaps-live-state` artifact, full enforcement result, PR policy, and review threads.
3. Synchronize the PR body to the exact head and final latest-attempt outcomes.
4. Do not merge without a new explicit owner approval.
5. After an approved expected-head merge, verify canonical `main`, the live claim, and post-merge workflows before treating the gap as durably closed.
