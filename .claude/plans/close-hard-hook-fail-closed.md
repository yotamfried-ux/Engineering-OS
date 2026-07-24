# Route Plan — Close Hard Hook Fail-Closed

## Route Plan

| Field | Decision |
|---|---|
| Task type | operational-readiness closure reconciliation |
| Task class | `engineering_os_governance` |
| Domain tags | hook governance, security, audit, live-state evidence, GitHub Actions |
| Plan Scope | focused |
| Planning Mode | post-merge evidence reconciliation; no runtime implementation changes |
| Task-router evidence | `core/task-router.md` routes canonical audit and known-gap closure through Engineering OS governance and `hooks-governance`. |
| Workflow evidence | `core/workflow.md`, `core/git-policy.md`, `core/quality-gates.md`, and the audit closure standard require implementation, exact-head CI, review, explicit approval, expected-head merge, post-merge proof, then canonical synchronization. |
| Target paths | `.claude/plans/close-hard-hook-fail-closed.md`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/live-state-claims.json`; a temporary self-deleting reconciliation workflow used only to apply exact validated replacements and absent from the final diff |
| Templates | waiver — focused canonical-state reconciliation using the existing registry, audit, and live-claim schemas |
| Architecture guides | `docs/operations/operational-readiness-audit.md`; `docs/operations/known-gaps.tsv`; `docs/operations/live-state-claims.json`; `docs/operations/merge-readiness-checklist.md` |
| Patterns | none — no implementation pattern is needed for metadata-only closure |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion`; `security-review` |
| Validation gates | known-gaps registry; readiness audit; live-state claim; documentation hygiene; full enforcement; PR policy; exact-head CI; review reconciliation |
| Evidence to check | PR #262 reviewed head `5ee5d9fe51ddd8b9b490fe60424be4ea37cad9b3`; ten exact-head workflows including `pr-policy` 1770 / ID `30115981865` and `enforcement-tests` 1463 / ID `30115055846`; 11 resolved review threads; owner approval record comment `5074786377`; expected-head protected squash merge `e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6`; canonical `main` identity; required post-merge push workflows |
| User decisions required | no merge of the closure PR without a new explicit owner approval for its final exact head |

## Goal

Close `hard-hook-fail-closed` only if live GitHub evidence proves that PR #262 implemented the complete hard-hook failure contract, passed exact-head CI and review, merged with explicit owner approval and expected-head protection, and passed the required post-merge workflows on canonical `main`.

## Scope

This closure branch changes canonical status and evidence metadata only. It does not alter hook runtime behavior, settings wiring, the criticality registry, validators, installers, Project 8, bypass provenance, or repository-boundary parity. Any temporary reconciliation workflow must apply exact single-match replacements, delete itself, and be absent from the final compare.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| PR #262 and merge `e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6` | verified | The implementation PR is merged and closed; `main` compares identical to the merge commit. |
| `docs/operations/known-gaps.tsv` | pending synchronization | The gap remains `open` until the live claim proves the required pull-request and post-merge evidence. |
| `docs/operations/operational-readiness-audit.md` | pending synchronization | Ledger, matrix, dependency plan, checklist, ROI order, snapshot, and current scope must agree with the registry. |
| `docs/operations/live-state-claims.json` | pending synchronization | A versioned claim must bind PR #262 exact head and merge to named PR workflows, push workflows, and the required check run. |
| `scripts/enforcement/check-known-gaps-live-state.py` | read | The validator requires the referenced gap to be `closed`, selects the latest exact-head PR and push runs, and fails closed on missing, stale, unsuccessful, or wrong-identity evidence. |
| `.github/workflows/known-gaps-live-state.yml` | read | A closure PR touching canonical state triggers a read-only GitHub fetch and deterministic reconciliation. |
| `core/git-policy.md` and `docs/operations/merge-readiness-checklist.md` | validated | The exact-head, explicit-approval, expected-head merge lifecycle was applied to PR #262; approval provenance is comment `5074786377`. |

## Capability Evidence

- `routing.task-router-read` — the audit dependency order selected canonical gap closure work.
- `workflow.workflow-read` — implementation, merge, post-merge proof, canonical closure, review, closure approval, and closure merge remain separate lifecycle states.
- `plan.route-plan-before-write` — this file is committed before registry, claim, audit, or temporary-reconciliation writes.
- `source.github-repo-read` — PR #262 metadata, workflows, threads, approval record, merge result, repository files, validator, workflow, and `main` identity were read from GitHub.
- `validation.policy-change-has-validator` — the existing known-gaps, audit, documentation-hygiene, live-state, and full enforcement validators own this metadata-only closure.
- `validation.coderabbit-policy` — the implementation PR reconciled 11 live review threads; the closure PR requires independent review as a blocking gate.

## Skill Evidence

- `writing-plans` — scope, exact evidence, canonical targets, lifecycle separation, and external gates are recorded before writes.
- `verification-before-completion` — implementation completion, exact-head CI, review, owner approval, expected-head merge, canonical-main identity, live post-merge validation, closure metadata, closure review, closure merge, and closure post-merge proof remain separate assertions.
- `security-review` — the closure must not weaken hook semantics, substitute absence of a repair issue for positive proof, or claim post-merge success without provider evidence.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Re-fetched PR #262 exact head, exact-head workflow records, 11 resolved review threads, owner approval record `5074786377`, merge commit `e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6`, canonical `main`, closure schemas, and validators. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, PR #262, exact head, workflows, review threads, approval record, merge result, repository files, canonical `main`, live-state workflow, and validator.
- action: verified the merge lifecycle, recorded durable approval provenance, selected the established separate-closure pattern, and prepared a fail-closed live claim rather than inferring push success from unavailable connector output.
- result: PR #262 merged as `e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6`; canonical `main` is identical; the closure remains contingent on `known-gaps-live-state` independently resolving exact PR workflows, required push workflows, and the required check run.
- decision: selected a separate closure PR and the existing GitHub-backed live-state validator rather than treating PR prose, absence of a repair issue, or chat memory as canonical closure.
- target: `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/live-state-claims.json`.

## Definition of Done — Closure Candidate

- [ ] Route Plan committed before canonical writes.
- [ ] Add a PR #262 live-state claim with exact reviewed head, merge commit, required PR workflows, required push workflows, and required check run.
- [ ] Change the registry row to `closed` with exact evidence.
- [ ] Synchronize audit ledger, matrix, dependency plan, checklist, ROI order, snapshot, and current scope.
- [ ] Remove every temporary reconciliation file from the final compare.

External gates remaining before durable closure:

- focused known-gaps, audit, documentation-hygiene, and live-state validation on the exact closure-PR head;
- full exact-head CI and independent review on the closure PR;
- a new explicit owner approval before merging the closure PR;
- closure-PR merge and post-merge workflow verification before the closure is treated as durable.

## Progress Lifecycle Evidence

- start: this plan records scope, exact implementation evidence, canonical sources, and external gates before every closure-state write.

## Validation Plan

1. Apply exact source-matched updates to the three canonical closure files and remove temporary reconciliation machinery.
2. Open a focused closure PR with a final four-file compare.
3. Require `known-gaps-live-state` to independently verify PR #262 pull-request and post-merge push evidence.
4. Run focused and full exact-head CI and inspect the fresh Operational Work History artifact.
5. Reconcile every valid review finding and confirm zero unresolved threads.
6. Do not merge without a new explicit owner approval for the final exact head.
7. After merge, verify canonical `main` and post-merge workflows before claiming durable closure.
