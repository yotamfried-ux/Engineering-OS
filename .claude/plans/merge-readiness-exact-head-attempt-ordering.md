# Route Plan — Exact-Head Merge Readiness and Attempt Ordering

## Route Plan

| Field | Decision |
|---|---|
| Task type | governance enforcement / GitHub workflow-run reconciliation / merge evidence hardening |
| Task class | `engineering_os_governance` |
| Domain tags | governance, GitHub REST API, CI, merge safety, security, testing, observability |
| Plan Scope | standard |
| Planning Mode | user-authorized implementation; merge and gap closure remain owner-gated |
| Task-router evidence | `core/task-router.md` routes this as `engineering_os_governance` plus infra/CI work and requires canonical workflow, Git, testing, security, and observability owners. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, `core/documentation-policy.md`, and `core/hooks-policy.md` require plan-first reproduction, minimal correction, focused/wider tests, installed-target validation, review, exact-head validation, owner approval, and post-merge proof. |
| Target paths | `.claude/plans/merge-readiness-exact-head-attempt-ordering.md`; `scripts/enforcement/check-merge-readiness.sh`; `scripts/enforcement/tests/test-operational-readiness-gates.sh`; `scripts/enforcement/tests/test-clean-install-and-usage.sh`; `docs/operations/merge-readiness-checklist.md` |
| Templates | waiver — focused extension of an existing validator and fixture suites |
| Architecture guides | `docs/operations/merge-readiness-checklist.md`; `docs/operations/main-required-checks.md`; `docs/operations/operational-readiness-audit.md` |
| Patterns | `patterns/testing/README.md`; `patterns/security/README.md`; `patterns/observability/README.md` |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion`; `security-review` |
| Validation gates | focused operational-readiness fixtures; clean-install suite; known-gaps/readiness suites; all enforcement suites; exact-head workflows; live review; Operational Work History |
| Evidence to check | PR #256 merge `4ca1fd5a58fc96275ae69a1d2e573b7712d9055d`; PR #257 live head; checker and every `--runs-json` consumer; merge policy wiring; official workflow-run and workflow-attempt metadata |
| User decisions required | explicit Yotam approval before merge; post-merge proof before gap closure |

## Goal

Reject stale, wrong-head, incomplete, failed, or pending required-workflow evidence even when an older success appears first. Preserve the human approval boundary and the existing live merge-decision wiring in `core/git-policy.md`.

## Required Behavior

1. Require `--expected-head-sha` as a full lowercase 40-character SHA.
2. Evaluate required workflows only when `head_sha` equals the expected head.
3. Fail closed on missing identity or malformed exact-head chronology metadata.
4. Select the latest run by `run_started_at`, otherwise `updated_at`, otherwise `created_at`; then `run_attempt`; then run `id`.
5. Make input order irrelevant and diagnostics deterministic.
6. Accept only selected runs with `status=completed` and `conclusion=success`.
7. Keep the required-workflow registry and explicit human approval boundary unchanged.
8. Keep repository and clean-install callers synchronized with the stricter contract.

## Result Loop

- experiment: commit `54a30ddc6938284032fbd272908d564aa6b9e9b5` introduced an old success followed by a newer failure before the checker fix.
- observed failure: enforcement run 1365 failed in group M–R, proving that the old first-occurrence logic accepted stale success.
- root cause: the checker had no expected-head contract and trusted the first workflow-name occurrence.
- core fix: commits `4123adb3c4a19dea6d2bd9d04d7f7f031ff1d03e`, `1b95ac486ce5938010449228a3cc9501f04f8e51`, and `3f350b8d0432f9a068261b039d97b50653d4670f` implemented exact-head filtering, deterministic ordering, fixtures, and operator guidance.
- correction cycle: enforcement run 1370 exposed the legacy clean-install caller; commit `ca737eaa56a7a5a9cde6daa9ddf7726957f23820` synchronized it after scope checkpoint `0510b39927f89812d805cd50d7eb3c4394079858`.
- fixture correction: enforcement run 1373 exposed a digits-only uppercase-SHA fixture; `7fc3d886824d1a5891491b45008ee4e11ae4a3e6` corrected only that fixture.
- successful experiments: enforcement runs 1374, 1376, and 1377 passed the dedicated suites, groups A–Z, every enforcement test file, and the remaining contracts.
- review corrections: `14356ebd259e691f4b289c1041453c8285426d9c` aligned timestamp wording; `375e97c2b17dce6a0845b3db82a7877f6e57baa7` recorded the later checkpoint; both CodeRabbit threads were replied to and resolved.
- base reconciliation: PR #256 merged by squash as `4ca1fd5a58fc96275ae69a1d2e573b7712d9055d`; a clean branch was rebuilt from that exact `main`, with plan commit `33ddb11b25960a633031c6f4144d49bb6a5d8198` before the reconciled implementation commit `97c19316bb3a4285f04901ca95e49695b51ce86e`.
- clean comparison: `main..97c19316bb3a4285f04901ca95e49695b51ce86e` contains two commits and exactly the five declared target paths.

## Validation Matrix

- old success followed by new failure → fail;
- old failure followed by new success → pass;
- success on another head → fail;
- missing or malformed head identity → fail;
- attempt 2 failure after attempt 1 success → fail;
- latest pending run → fail;
- duplicate workflow names and reversed input → identical result and diagnostics;
- malformed timestamp, attempt, ID, or JSON input → fail closed;
- clean-install target simulation accepts exact-head green evidence and blocks pending evidence;
- every required workflow, review state, and Operational Work History artifact is refreshed on the final exact head.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `core/git-policy.md` | read | The checker is required before a merge API call; owner approval remains separate. |
| `docs/operations/known-gaps.tsv` | checked | The P0 closure bar includes exact-head CI, review, approved merge, and post-merge proof. |
| `scripts/enforcement/check-merge-readiness.sh` | checked | The new implementation fails closed and orders exact-head runs deterministically. |
| `scripts/enforcement/tests/test-operational-readiness-gates.sh` | checked | The focused owner covers stale, wrong-head, attempt, pending, malformed, and ordering cases. |
| `scripts/enforcement/tests/test-clean-install-and-usage.sh` | checked | The installed consumer supplies full run identity and the mandatory expected head. |
| `scripts/enforcement/check-known-gaps-live-state.py` | read | Existing provider chronology uses timestamp, attempt, and ID precedence. |
| `https://docs.github.com/en/rest/actions/workflow-runs` | read | GitHub exposes `head_sha`, timestamps, status, conclusion, attempt, and run identity. |
| `https://docs.github.com/en/rest/actions/workflow-jobs` | read | GitHub exposes jobs for a specific workflow-run attempt. |
| `https://github.com/actions/github-script/blob/main/README.md` | read | The official action demonstrates authenticated Octokit REST calls and pagination. |
| `https://github.com/octokit/rest.js` | read | The official client provides typed REST endpoint access used by GitHub tooling. |

## Documentation Asset Evidence

- internal: `docs/operations/merge-readiness-checklist.md`, `docs/operations/main-required-checks.md`, `core/git-policy.md`, and the two test suites define the operator, registry, decision, and installed-consumer contracts.
- context7: Context7 retrieval was unnecessary because this change uses GitHub provider metadata directly; the concrete external sources checked were `https://docs.github.com/en/rest/actions/workflow-runs`, `https://docs.github.com/en/rest/actions/workflow-jobs`, `https://github.com/actions/github-script`, and `https://github.com/octokit/rest.js`.
- decision: reuse GitHub provider identity and the repository's existing ordering precedent instead of inventing a parallel run model.

## Template/Pattern Rating Evidence

- asset: `patterns/testing/README.md`
- asset: `patterns/security/README.md`
- asset: `patterns/observability/README.md`
- rating: useful for isolated fixtures, fail-closed trust boundaries, and deterministic diagnostics.
- outcome: the implementation covers malformed input, stale evidence, wrong-head evidence, attempt ordering, deterministic output, and installed-target parity.
- decision: selected these patterns as task guidance without changing their registry maturity.
- confidence: high for this repository-local use; no cross-project maturity claim is made.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | PRs #256, #257, and #258; commits; workflow runs and jobs; artifacts; review threads; branch refs; file blobs; and official GitHub repositories were inspected. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, PR #257, PR #258, commit `4ca1fd5a58fc96275ae69a1d2e573b7712d9055d`, and the official `actions/github-script` and `octokit/rest.js` repositories.
- action: verified live `main`; reproduced stale-success acceptance; inspected every checker caller; retargeted the PR; compared inherited blobs; rebuilt clean history; and refreshed exact-head workflow evidence.
- result: PR #257 now has clean base `4ca1fd5a58fc96275ae69a1d2e573b7712d9055d`, plan-first commit `33ddb11b25960a633031c6f4144d49bb6a5d8198`, implementation commit `97c19316bb3a4285f04901ca95e49695b51ce86e`, and exactly five changed paths.
- decision: updated the branch history and evidence instead of weakening validators, trusting list order, retaining squash-history noise, or duplicating PR #256 changes.
- target: `.claude/plans/merge-readiness-exact-head-attempt-ordering.md`; `docs/operations/merge-readiness-checklist.md`; `scripts/enforcement/check-merge-readiness.sh`; `scripts/enforcement/tests/test-clean-install-and-usage.sh`; `scripts/enforcement/tests/test-operational-readiness-gates.sh`.

## Alternatives

- Preserve optional expected-head behavior — rejected because it permits headless evidence.
- Trust API order or first occurrence — rejected because reruns and pagination make order unsafe.
- Accept any exact-head success — rejected because a newer failure or pending run invalidates stale green.
- Reuse workflows from the former stacked base — rejected because current-base policy evidence must be refreshed.
- Keep the noisy squash history — rejected because it broke plan-first lifecycle validation and obscured the effective diff.
- Automate approval — rejected because merge authorization remains Manual by design.

## Data / Integration Impact

The checker reads metadata-only JSON and emits deterministic diagnostics. No persistent provider state, prompt or response content, secret, user data, required-workflow registry, or merge authorization changes.

## Branch and PR Boundary

PR #257 targets `main` at `4ca1fd5a58fc96275ae69a1d2e573b7712d9055d`. The branch contains the plan-first commit and one reconciled implementation commit. PR #258 only constructed the temporary clean history and did not change `main`. No merge of PR #257, branch deletion, or gap closure is authorized.

## Capability Evidence

- `routing.task-router-read` — `engineering_os_governance` selected.
- `workflow.workflow-read` — plan-first result loops, ordered lifecycle evidence, exact-head CI, and owner-gated merge applied.
- `plan.route-plan-before-write` — `33ddb11b25960a633031c6f4144d49bb6a5d8198` precedes the clean implementation commit.
- `source.github-repo-read` — live PR, branch, workflow, artifact, review, file, and official-repository evidence inspected.
- `validation.policy-change-has-validator` — focused and clean-install fixtures own the behavior.
- `validation.actions-checked` — current exact-head workflows are refreshed after each evidence checkpoint.
- `validation.coderabbit-policy` — both concrete findings were corrected and resolved; final live review state remains a merge gate.

## Skill Evidence

- `writing-plans` — the clean Route Plan commit precedes the reconciled implementation.
- `verification-before-completion` — reproduction, correction, full CI, review, merge, and post-merge closure remain separate claims.
- `security-review` — untrusted JSON, missing identity, incomplete chronology, stale success, and nondeterministic input fail closed without a compatibility bypass.

## Claude Run Trace

- goal: prevent stale or wrong-head workflow evidence from supporting a merge.
- hypothesis: exact-head filtering and deterministic chronology, attempt, and ID ordering reject stale green only when every caller supplies provider identity metadata.
- connectors: GitHub and official GitHub sources.
- steps: verify; plan; reproduce; implement; expand fixtures; correct the clean-install caller; rerun; correct the fixture; review; merge PR #256 with approval; retarget PR #257; rebuild plan-first clean history; compare the exact diff; refresh current-base gates.
- evidence: enforcement runs 1365, 1370, 1373, 1374, 1376, and 1377; PRs #256–#258; commits `33ddb11b25960a633031c6f4144d49bb6a5d8198`, `97c19316bb3a4285f04901ca95e49695b51ce86e`, `176fee0ce5c092c3589e958e383856affae82524`, and `e81058eac3ea0404d2f9745599f13c2345b8336b`; official GitHub sources above.
- rejected: implicit order, optional expected head, compatibility fallback, stale-base CI reuse, automated approval, validator weakening, and noisy inherited history.
- result: the implementation and clean-history reconciliation are complete; final exact-head workflow, review, approval, merge, and post-merge evidence remain separate external gates.

## Definition of Done — Implementation Evidence

- The checker requires a full lowercase expected head and rejects malformed input.
- Exact-head candidates are selected by timestamp, attempt, and run ID independent of input order.
- Stale success, newer failure, newer pending, wrong-head success, and missing identity fixtures are covered.
- The clean-install consumer passes complete run metadata and the expected-head argument.
- The operator runbook documents exact invocation, provider fields, ordering, expected-head protection, and post-merge limits.
- Full enforcement, evidence policies, live review, and Operational Work History are refreshed on the final exact head before an owner decision.

## Current Completion State

Implementation and clean-history reconciliation are complete. Final current-head workflows, live review reconciliation, explicit owner approval, expected-head protected merge, post-merge validation, and canonical gap closure remain distinct gates.

## Live External Gates Before Closure

The gap remains `open`. A green PR does not authorize merge. Closure requires explicit Yotam approval, expected-head protected merge, validation on canonical `main`, and synchronized audit/live-state evidence.

## Progress Lifecycle Evidence

- start: commit `33ddb11b25960a633031c6f4144d49bb6a5d8198` added this Route Plan on current `main` before any reconciled code, config, or test change.
- mid: commit `97c19316bb3a4285f04901ca95e49695b51ce86e` applied the reviewed checker, fixtures, clean-install caller, and runbook as exactly five changed paths after the clean Route Plan commit.
- pre-merge: historical enforcement run 1377 and resolved review findings establish the implementation baseline; a distinct current-head checkpoint follows the clean-history mid checkpoint.
- pre-merge: commit `176fee0ce5c092c3589e958e383856affae82524` completed the clean-history mid evidence and truthful external-gate separation after the final code and test commit; this distinct checkpoint records the five-path state before exact-head CI.
