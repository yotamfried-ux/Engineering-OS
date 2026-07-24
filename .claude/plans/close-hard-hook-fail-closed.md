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
| Target paths | `.claude/plans/close-hard-hook-fail-closed.md`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/live-state-claims.json` |
| Templates | waiver — focused canonical-state reconciliation using the existing registry, audit, and live-claim schemas |
| Architecture guides | `docs/operations/operational-readiness-audit.md`; `docs/operations/known-gaps.tsv`; `docs/operations/live-state-claims.json`; `docs/operations/merge-readiness-checklist.md` |
| Patterns | none — no implementation pattern is needed for metadata-only closure |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion`; `security-review` |
| Validation gates | known-gaps registry; readiness audit; live-state claim; documentation hygiene; full enforcement; PR policy; exact-head CI; review reconciliation |
| Evidence to check | PR #262 reviewed head `5ee5d9fe51ddd8b9b490fe60424be4ea37cad9b3`; ten exact-head workflows including `pr-policy` 1770 / ID `30115981865` and `enforcement-tests` 1463 / ID `30115055846`; 11 resolved review threads; owner approval record comment `5074786377`; expected-head protected squash merge `e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6`; canonical `main` identity; required post-merge push workflows |
| User decisions required | no merge of PR #263 without a new explicit owner approval for its final exact head |

## Goal

Close `hard-hook-fail-closed` only if live GitHub evidence proves that PR #262 implemented the complete hard-hook failure contract, passed exact-head CI and review, merged with explicit owner approval and expected-head protection, and passed the required post-merge workflows on canonical `main`.

## Scope

This closure branch changes canonical status and evidence metadata only. It does not alter hook runtime behavior, settings wiring, the criticality registry, validators, installers, Project 8, bypass provenance, or repository-boundary parity. The one-time reconciliation workflow and helper applied exact source-matched replacements and deleted themselves; the final compare contains only the four declared canonical paths.

## Documentation Asset Evidence

- internal: `docs/operations/operational-readiness-audit.md`; `docs/operations/known-gaps.tsv`; `docs/operations/live-state-claims.json`; `docs/operations/merge-readiness-checklist.md`; `.github/workflows/known-gaps-live-state.yml`; `scripts/enforcement/check-known-gaps-live-state.py`.
- context7: the official vendor source `https://code.claude.com/docs/en/hooks` remains the basis for hook deny semantics; this metadata-only closure does not reinterpret or modify the merged implementation.
- decision: reuse the existing canonical registry, audit, live-claim schema, fetcher, and validator; do not create a parallel closure document or infer push success from unavailable conversational connector output.

## Claude Run Trace

- trace_source: GitHub connector reads/writes, PR #262 and #263 metadata, exact commits, workflow records, review threads, approval provenance, compare state, and canonical repository files.
- exact_token_usage_available: no.
- trace_boundary: no independent Claude Code session trace is claimed; repository and provider evidence are the auditable surrogate.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| PR #262 and merge `e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6` | verified | The implementation PR is merged and closed; `main` compares identical to the merge commit. |
| `docs/operations/known-gaps.tsv` | synchronized | The candidate row is `closed` and names exact PR #262 head, workflow, review, approval, merge, and live-claim evidence. |
| `docs/operations/operational-readiness-audit.md` | synchronized | Ledger, matrix, completed foundation, Phase 1 order, checklist, ROI order, snapshot, and current scope agree with the registry. |
| `docs/operations/live-state-claims.json` | synchronized | The versioned claim binds PR #262 exact head and merge to ten PR workflows, two push workflows, and the required check run. |
| `scripts/enforcement/check-known-gaps-live-state.py` | read | The validator requires the referenced gap to be `closed`, selects the latest exact-head PR and push runs, and fails closed on missing, stale, unsuccessful, or wrong-identity evidence. |
| `.github/workflows/known-gaps-live-state.yml` | read | PR #263 touches canonical state and therefore triggers a read-only GitHub fetch and deterministic reconciliation. |
| `core/git-policy.md` and `docs/operations/merge-readiness-checklist.md` | validated | The exact-head, explicit-approval, expected-head merge lifecycle was applied to PR #262; approval provenance is comment `5074786377`. |

## Capability Evidence

- `routing.task-router-read` — the audit dependency order selected canonical gap closure work.
- `workflow.workflow-read` — implementation, merge, post-merge proof, canonical closure, review, closure approval, and closure merge remain separate lifecycle states.
- `plan.route-plan-before-write` — commit `447d5950b4cdcf890d6ecd13c660c195e8c930f7` preceded registry, claim, audit, workflow, and helper writes.
- `source.github-repo-read` — PR #262 metadata, workflows, threads, approval record, merge result, repository files, validator, workflow, and `main` identity were read from GitHub.
- `validation.policy-change-has-validator` — the existing known-gaps, audit, documentation-hygiene, live-state, and full enforcement validators own this metadata-only closure.
- `validation.coderabbit-policy` — the implementation PR reconciled 11 live review threads; PR #263 requires independent review as a blocking gate.

## Skill Evidence

- `writing-plans` — scope, exact evidence, canonical targets, lifecycle separation, and external gates were recorded before writes.
- `verification-before-completion` — implementation completion, exact-head CI, review, owner approval, expected-head merge, canonical-main identity, live post-merge validation, closure metadata, closure review, closure merge, and closure post-merge proof remain separate assertions.
- `security-review` — the closure does not weaken hook semantics, substitute absence of a repair issue for positive proof, or claim post-merge success without provider evidence.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Re-fetched PR #262 exact head, exact-head workflow records, 11 resolved review threads, owner approval record `5074786377`, merge commit `e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6`, canonical `main`, closure schemas, PR #263, and the clean four-file compare. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, PR #262, PR #263, exact heads, workflows, review threads, approval record, merge result, repository files, canonical `main`, live-state workflow, and validator.
- action: verified the merge lifecycle, recorded durable approval provenance, created the plan-first closure branch, applied exact canonical replacements, removed one-time reconciliation files, and prepared a fail-closed live claim rather than inferring push success.
- result: PR #262 merged as `e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6`; reconciliation commit `95795c73756a3e14fc530943757adb2e1063e3ae` produced a clean PR #263 compare with exactly the plan, registry, audit, and live claim; closure remains contingent on exact-head CI, live-state validation, review, new owner approval, closure merge, and closure post-merge proof.
- decision: selected a separate closure PR and the existing GitHub-backed live-state validator rather than treating PR prose, absence of a repair issue, or chat memory as canonical closure.
- target: `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/live-state-claims.json`.

## Definition of Done — Closure Candidate

- [x] Route Plan committed before canonical writes.
- [x] Added a PR #262 live-state claim with exact reviewed head, merge commit, required PR workflows, required push workflows, and required check run.
- [x] Changed the registry row to `closed` with exact evidence.
- [x] Synchronized audit ledger, matrix, dependency plan, checklist, ROI order, snapshot, and current scope.
- [x] Removed every temporary reconciliation file from the final compare.

External gates remaining before durable closure:

- focused known-gaps, audit, documentation-hygiene, and live-state validation on the exact PR #263 head;
- full exact-head CI and independent review on PR #263;
- a new explicit owner approval before merging PR #263;
- PR #263 merge and post-merge workflow verification before the closure is treated as durable.

## Progress Lifecycle Evidence

- start: commit `447d5950b4cdcf890d6ecd13c660c195e8c930f7` recorded scope, exact implementation evidence, canonical sources, and external gates before every closure-state write.
- mid: the one-time exact-source reconciliation generated commit `95795c73756a3e14fc530943757adb2e1063e3ae`, synchronized the three canonical closure files, and removed both temporary files.
- pre-merge: the compare against `main` at `e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6` contains exactly four paths and no temporary workflow or helper; this plan-only checkpoint triggers clean exact-head CI and live review for PR #263.

## Validation Plan

1. Require focused and full exact-head CI on the clean PR #263 head.
2. Require `known-gaps-live-state` to independently verify PR #262 pull-request and post-merge push evidence.
3. Inspect the fresh Operational Work History artifact and every live review thread.
4. Reconcile valid findings and document any rejected finding with exact source evidence.
5. Do not merge without a new explicit approval for PR #263.
6. After merge, verify canonical `main` and post-merge workflows before claiming durable closure.
