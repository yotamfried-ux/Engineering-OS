# Route Plan — Close Documentation Runtime State Drift

## Route Plan

| Field | Decision |
|---|---|
| Task type | operational-readiness closure reconciliation |
| Task class | `engineering_os_governance` |
| Domain tags | documentation governance, audit, live-state evidence, GitHub Actions |
| Plan Scope | focused |
| Planning Mode | post-merge evidence reconciliation; no runtime implementation changes |
| Task-router evidence | `core/task-router.md` routes canonical audit and known-gap closure through Engineering OS governance and the relevant docs-governance owner. |
| Workflow evidence | `core/workflow.md`, `core/git-policy.md`, `core/quality-gates.md`, and the audit closure standard require implementation, exact-head CI, review, explicit approval, expected-head merge, post-merge proof, then canonical synchronization. |
| Target paths | `.claude/plans/close-documentation-runtime-state-drift.md`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/live-state-claims.json`; temporary self-deleting audit reconciliation workflow if needed for exact large-file replacements |
| Templates | waiver — focused canonical-state reconciliation using existing registry, audit, and live-claim schemas |
| Architecture guides | `docs/operations/operational-readiness-audit.md`; `docs/operations/known-gaps.tsv`; `docs/operations/live-state-claims.json`; `docs/operations/merge-readiness-checklist.md` |
| Patterns | none — no implementation pattern is needed for metadata-only closure |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion` |
| Validation gates | known-gaps registry; readiness audit; live-state claim; documentation hygiene; full enforcement; PR policy; exact-head CI; review reconciliation |
| Evidence to check | PR #260 reviewed head `e63a27babb09da4a7c4589cbe3e37c112f6b6e79`; latest exact-head workflows including `pr-policy` 1692 and `enforcement-tests` 1391; 7 resolved review threads; owner approval record comment `5063627361`; expected-head squash merge `105ecd0d0dc72aa847d11b193190689dbda0dda8`; canonical `main` identity; post-merge push workflows |
| User decisions required | no merge of the closure PR without a new explicit owner approval for that PR |

## Goal

Close `documentation-runtime-state-drift` only if live GitHub evidence proves that PR #260 completed the remaining implementation checklist, passed exact-head CI and review, merged with explicit owner approval and expected-head protection, and passed the required post-merge workflows on canonical `main`.

## Scope

This closure branch changes canonical status and evidence metadata only. It does not alter the documentation-hygiene implementation, MANIFEST contract, telemetry terminology guard, ownership registry, Project 8, or runtime hooks.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `docs/operations/known-gaps.tsv` | checked | The gap is still `open` and its evidence text predates the PR #260 merge. |
| `docs/operations/operational-readiness-audit.md` | checked | Seven implementation items are checked; the final exact-head/review/merge/post-merge item remains open. |
| `docs/operations/live-state-claims.json` | checked | A new versioned claim is required to bind PR #260 exact head and merge evidence. |
| `scripts/enforcement/check-known-gaps-live-state.py` | read | The validator fails closed when required PR or push workflows are missing, stale, unsuccessful, or associated with the wrong head/merge. |
| PR #260 live state | validated | Exact reviewed head merged as `105ecd0d0dc72aa847d11b193190689dbda0dda8`; `main` compares identical. |

## Capability Evidence

- `routing.task-router-read` — the audit dependency order selected canonical gap closure work.
- `workflow.workflow-read` — implementation, merge, post-merge proof, canonical closure, review, and closure merge remain separate lifecycle states.
- `plan.route-plan-before-write` — this plan commit precedes registry, claim, audit, and temporary-workflow writes.
- `source.github-repo-read` — PR #260 metadata, workflows, threads, merge result, repository files, and `main` identity were read from GitHub.
- `validation.policy-change-has-validator` — the existing known-gaps, audit, documentation-hygiene, live-state, and full enforcement validators own this metadata-only closure.
- `validation.coderabbit-policy` — the implementation PR reconciled seven live review threads; the closure PR retains independent review as a blocking gate.

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, PR #260, exact head, workflows, review threads, approval record, merge result, repository files, and canonical `main` comparison.
- action: re-fetched live merge-readiness evidence, merged with expected-head protection, verified `main`, and prepared a fail-closed live claim and canonical audit synchronization.
- result: PR #260 merged as `105ecd0d0dc72aa847d11b193190689dbda0dda8`; canonical `main` is identical; closure remains contingent on the live-state validator proving the required post-merge workflows.
- decision: use a separate closure PR and existing live-state validator rather than treating PR prose or chat memory as canonical closure.
- target: `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/live-state-claims.json`.

## Definition of Done — Closure Candidate

- [x] Route Plan committed before canonical writes.
- [ ] Add a PR #260 live-state claim with exact reviewed head, merge commit, required PR workflows, required push workflows, and required check run.
- [ ] Change the registry row to `closed` with exact evidence.
- [ ] Synchronize audit ledger, matrix, dependency plan, checklist, ROI order, and current scope.
- [ ] Pass focused known-gaps, audit, documentation-hygiene, and live-state validation.
- [ ] Pass full exact-head CI and independent review on the closure PR.
- [ ] Obtain new explicit owner approval before merging the closure PR.
- [ ] Verify closure-PR post-merge workflows before treating the status as durable.

## Progress Lifecycle Evidence

- start: this plan is the first closure-branch commit and records scope, evidence, and external gates before any canonical state changes.

## Validation Plan

1. Add the versioned live claim and exact source-matched canonical replacements.
2. Let `known-gaps-live-state` independently verify PR #260 pull-request and post-merge push evidence.
3. Run focused and full exact-head CI on the closure PR.
4. Reconcile all live review threads.
5. Do not merge without a new explicit approval for the closure PR.
6. After merge, verify canonical `main` and post-merge workflows before claiming durable closure.
