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
| Target paths | `.claude/plans/close-merge-readiness-exact-head-gap.md`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/live-state-claims.json` |
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

This branch changes status and evidence metadata only. It does not modify the checker, test fixtures, workflow registry, approval policy, or Project 8.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `docs/operations/known-gaps.tsv` | checked | The gap remains `open` until merge and post-merge evidence are synchronized. |
| `docs/operations/operational-readiness-audit.md` | checked | The freshness ledger, matrix, dependency plan, and mandatory checklist still describe the gap as unresolved. |
| `docs/operations/live-state-claims.json` | checked | Versioned claims bind closed gaps to exact PR, head, merge, pull-request workflows, push workflows, and check runs. |
| `scripts/enforcement/check-known-gaps-live-state.py` | read | The live validator fails closed on stale, missing, unmerged, wrong-head, failed-attempt, missing-workflow, and base-containment evidence. |
| `scripts/enforcement/tests/test-known-gaps-live-state.sh` | read | Offline fixtures own the claim schema and negative cases. |
| `docs/operations/merge-readiness-checklist.md` | checked | Human approval and post-merge validation remain separate from machine CI evidence. |
| GitHub PR #257 and commit `efb36cca413602cde3cd20aa17d32b3379f9eb53` | validated | PR #257 merged after expected-head protection; `main` compares identical to the merge commit. |

## Documentation Asset Evidence

- internal: `docs/operations/operational-readiness-audit.md`, `docs/operations/known-gaps.tsv`, `docs/operations/live-state-claims.json`, `docs/operations/merge-readiness-checklist.md`, and `scripts/enforcement/check-known-gaps-live-state.py` define the exact closure schema and source hierarchy.
- context7: Context7 is not required because no external library behavior is being implemented; the external trust boundary is current GitHub REST state already consumed by the repository's canonical live-state workflow.
- decision: extend the existing versioned claim registry and synchronize every audit representation instead of treating the merged PR body or this conversation as closure evidence.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Live PR #257 state, exact reviewed head, latest workflow attempts, review threads, approval comment, merge result, merge commit, and `main` identity were re-fetched. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, PR #257, approval comment `5060947961`, reviewed head `fedf8d069a8634085c650ea6381c1c0dabfdc368`, and merge `efb36cca413602cde3cd20aa17d32b3379f9eb53`.
- action: verified that the PR was mergeable before merge, the latest required attempt was green, both review threads were resolved, the owner approval was recorded, the merge used expected-head protection, and canonical `main` is identical to the merge commit.
- result: the implementation and merge portions of the closure bar are evidenced by PR #257 and merge `efb36cca413602cde3cd20aa17d32b3379f9eb53`; the new live claim must independently verify required push workflows before closure is accepted.
- decision: selected a separate closure PR and fail-closed live claim rather than editing `main` directly or declaring the gap closed from chat memory.
- target: `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/live-state-claims.json`.

## Skill Evidence

- `writing-plans` — this plan commit precedes all canonical status changes.
- `verification-before-completion` — implementation, merge, post-merge proof, canonical claim validation, closure PR review, and closure PR merge remain separate assertions.

## Closure Mapping

- Registry: change the gap status to `closed` and record PR #257, reviewed head, merge commit, and live claim as evidence.
- Audit ledger: change the gap status to `closed`.
- Status matrix: change exact-head/latest-attempt merge safety to `Enforced` and remove the non-closed gap reference.
- Dependency plan: move the gap from active Phase 0 work into completed foundation evidence while leaving `documentation-runtime-state-drift` as the remaining Phase 0 item.
- Mandatory checklist: mark every verified item complete and name the exact PR, runs, approval, merge, and post-merge claim.
- Live claims: add one versioned claim for PR #257 with the exact required pull-request and push workflows.

## Validation Plan

1. Commit the Route Plan before status changes.
2. Update all four canonical representations together.
3. Open a focused ready-for-review PR.
4. Require registry, audit, live-state, and full enforcement CI on the exact closure-PR head.
5. Inspect the generated live-state artifact and every review thread.
6. Keep the gap effectively unclosed until this closure PR is reviewed, explicitly approved, merged, and post-merge validation confirms the synchronized canonical state.
