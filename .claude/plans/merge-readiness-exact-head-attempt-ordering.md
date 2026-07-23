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
| Patterns | `patterns/testing/README.md`; `patterns/security/README.md`; `patterns/observability/README.md`; infrastructure consulted, no provisioning pattern applies |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion`; `security-review` |
| Validation gates | focused operational-readiness fixtures; clean-install suite; required-workflows contract; known-gaps/readiness suites; all enforcement suites; exact-head workflows; live review; Operational Work History |
| Evidence to check | PR #256 merge `4ca1fd5a58fc96275ae69a1d2e573b7712d9055d`; PR #257 live head; checker and every `--runs-json` consumer; live-state ordering; merge policy wiring; official workflow-run and attempt metadata; byte identity of squash-history-only paths |
| User decisions required | no merge; no gap closure before explicit Yotam approval, expected-head merge protection, and post-merge validation |

## Goal

Reject stale, wrong-head, incomplete, failed, or pending required-workflow evidence even when an older success appears first. Preserve the human approval boundary and the existing live merge-decision wiring in `core/git-policy.md`.

## Required Behavior

1. Require `--expected-head-sha` as a lowercase 40-character SHA.
2. Evaluate required workflows only on matching `head_sha`.
3. Fail closed on missing head identity or malformed exact-head metadata.
4. Select latest by `run_started_at`, else `updated_at`, else `created_at`; then `run_attempt`; then run `id`.
5. Make input order irrelevant and diagnostics deterministic.
6. Require selected status `completed` and conclusion `success`.
7. Preserve the canonical required-workflow set and human approval boundary.
8. Keep repository and clean-install callers synchronized with the stricter contract.

## Result Loop

- Plan commit `404c5d8330619052eb362b9812dd8d8aa4584411` preceded tests and implementation.
- Reproduction commit `54a30ddc6938284032fbd272908d564aa6b9e9b5` added old success followed by newer failure while the old checker still accepted the first occurrence.
- Enforcement run 1365 failed in group M–R after all earlier suites passed, proving stale-success acceptance before implementation.
- Checker commit `4123adb3c4a19dea6d2bd9d04d7f7f031ff1d03e` added exact-head, chronology, attempt, ID, terminal-state, and fail-closed metadata validation.
- Fixture commit `1b95ac486ce5938010449228a3cc9501f04f8e51` added positive, negative, malformed-input, tie-breaker, and deterministic-output coverage.
- Runbook commit `3f350b8d0432f9a068261b039d97b50653d4670f` documented exact invocation and merge boundaries.
- Enforcement run 1370 failed in group A–F because `scripts/enforcement/tests/test-clean-install-and-usage.sh` still used legacy evidence and omitted the expected-head argument.
- Consumer commit `ca737eaa56a7a5a9cde6daa9ddf7726957f23820` synchronized clean-install evidence and invocation after scope expansion commit `0510b39927f89812d805cd50d7eb3c4394079858`.
- Enforcement run 1373 passed A–L, then exposed a fixture defect in M–R: the uppercase-SHA test used digits only, so uppercasing did not change its value.
- Fixture correction commit `7fc3d886824d1a5891491b45008ee4e11ae4a3e6` changed only test SHA values; run 1374 then passed all dedicated suites, groups A–Z, every `scripts/enforcement/tests/test-*.sh`, and all remaining contracts.
- Self-review found that the runbook listed all three timestamp fields as mandatory although runtime requires at least one by precedence. Commit `14356ebd259e691f4b289c1041453c8285426d9c` aligned the prose.
- Mid-checkpoint commit `419060be0ce73ebaca09150060a97792e5a01dc5` started exact-head revalidation after the final documentation correction.
- Enforcement run 1376 on `419060be0ce73ebaca09150060a97792e5a01dc5` passed every dedicated suite, groups A–Z, the loop over every enforcement test file, and all remaining contracts.
- CodeRabbit review produced two actionable threads: the timestamp wording and the missing post-consumer pre-merge checkpoint. The timestamp finding is fixed by `14356ebd259e691f4b289c1041453c8285426d9c`; commit `375e97c2b17dce6a0845b3db82a7877f6e57baa7` recorded the required later pre-merge checkpoint. Both threads were replied to and explicitly resolved.
- Enforcement run 1377 and pr-policy runs 1664–1666 succeeded on exact head `375e97c2b17dce6a0845b3db82a7877f6e57baa7` before this base-reconciliation checkpoint.
- PR #256 then merged by squash as `4ca1fd5a58fc96275ae69a1d2e573b7712d9055d`; PR #257 was retargeted to `main`. All nine PR #256-only paths were verified byte-identical between `main` and the PR #257 head, proving that the effective scope remains the five target paths.
- This plan-only base-reconciliation commit intentionally creates a new exact head so every required workflow can rerun against the current `main` base. Historical green runs are not treated as final evidence for the new head.

## Validation Matrix

- old success + new failure → fail;
- old failure + new success → pass;
- other-head success → fail;
- missing head → fail;
- attempt 2 failure after attempt 1 success → fail;
- latest pending → fail;
- duplicate names and reversed input → identical decision/output;
- malformed timestamp/attempt/ID/input → fail closed;
- clean-install target simulation passes exact-head green evidence and blocks pending evidence;
- all dedicated suites, A–Z, every enforcement test file, required policy workflows, live review, and Operational Work History must pass on the final exact head.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `CLAUDE.md` | read | Mutable claims require live evidence. |
| `core/task-router.md` | read | Governance and infra/CI route selected. |
| `core/workflow.md` | read | Plan-first Experiment → Fix → Experiment applies. |
| `core/quality-gates.md` | read | Fresh focused, negative, wider, and installed-target evidence is mandatory. |
| `core/git-policy.md` | read | Merge policy already requires running and documenting this checker on the exact PR head before a merge API call; explicit owner approval remains separate. |
| `core/documentation-policy.md` | read | CLI and operator runbook update together. |
| `core/hooks-policy.md` | read | Deterministic safety claims require executable validation. |
| `core/connector-policy.md` | read | Repository owners and official provider sources precede changes. |
| `core/skill-orchestration-policy.md` | read | Planning, verification, and security review apply. |
| `core/capability-registry.yaml` | read | Governance requires plan, GitHub, validator, Actions, and review evidence. |
| `core/learning-loop.md` | read | Root cause and regression proof precede closure. |
| `docs/operations/known-gaps.tsv` | checked | P0 closure requires exact head, latest attempt, fixtures, live wiring, CI, review, approved merge, and post-merge proof. |
| `docs/operations/operational-readiness-audit.md` | checked | This is Phase 0 item 1. |
| `scripts/enforcement/check-merge-readiness.sh` | checked | Old first-occurrence logic lacked head and chronology validation; the new implementation fails closed. |
| `scripts/enforcement/tests/test-operational-readiness-gates.sh` | checked | Focused owner contains ordering, metadata, malformed-input, and determinism fixtures. |
| `scripts/enforcement/tests/test-clean-install-and-usage.sh` | checked | Consumer supplies complete exact-head run objects and mandatory CLI argument. |
| `scripts/enforcement/check-known-gaps-live-state.py` | checked | Canonical timestamp/attempt/ID precedence is reused. |
| `.github/workflows/enforcement-tests.yml` | checked | Dedicated groups and the loop over every enforcement test file are live; no standalone `run-all-tests.sh` exists on the exact head. |
| `docs/operations/main-required-checks.md` | checked | Checker remains required-workflow owner. |
| `https://docs.github.com/en/rest/actions/workflow-runs` | read | Official API supports exact `head_sha` filtering and returns workflow-run status/conclusion metadata. |
| `https://docs.github.com/en/rest/actions/workflow-jobs` | read | Official API exposes jobs for a specific workflow-run attempt, proving reruns are separate evidence. |
| `https://github.com/actions/github-script/blob/main/README.md` | read | Official Octokit and pagination support are available. |
| `https://github.com/octokit/rest.js` | read | Official REST client examples and endpoint bindings support authenticated provider metadata retrieval. |

## Documentation Asset Evidence

- internal: `docs/operations/merge-readiness-checklist.md`, `core/git-policy.md`, `docs/operations/main-required-checks.md`, `scripts/enforcement/check-known-gaps-live-state.py`, and the two fixture suites define operator, merge-decision, ordering, and consumer contracts.
- context7: Context7 was not required because the trust boundary is GitHub REST metadata; official GitHub Actions REST, `actions/github-script`, and `octokit/rest.js` sources were checked directly.
- decision: selected exact-head filtering plus timestamp, `run_attempt`, and run-ID ordering, and updated the runbook to state the precise at-least-one timestamp contract.

## Template/Pattern Rating Evidence

- asset: `patterns/testing/README.md`
- asset: `patterns/security/README.md`
- asset: `patterns/observability/README.md`
- rating: useful — fixture isolation, trust-boundary validation, and structured diagnostic guidance constrained implementation and tests.
- outcome: adopted isolated fixtures, fail-closed metadata handling, deterministic selected-run output, and clean-install parity.
- decision: kept these patterns as task guidance without promoting maturity or inventing real-use evidence.
- confidence: high for local applicability; no lifecycle maturity claim.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Live main, PRs #256/#257, commits, Actions runs/jobs/logs/artifacts, comments, review threads, repository files, blob SHAs, and official GitHub repositories were inspected. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, PRs #256/#257, Actions runs 1363–1377 and pr-policy 1661–1666, exact file diffs, CodeRabbit comments, review threads, and main/head blob identities.
- action: verified live state; read policies, checker, every known caller, workflows, audit, patterns, official sources, CI diagnostics, diff, comments, and review threads; implemented and corrected the full result loop; retargeted to current `main`; proved squash-history-only paths are byte-identical; created a truthful new checkpoint to rerun all required workflows on the new base.
- result: the effective diff remains five merge-readiness paths; latest historical exact-head enforcement run 1377 and pr-policy run 1666 succeeded before this new checkpoint; fresh exact-head workflows are now required.
- decision: updated the actual consumers, fixtures, runbook, lifecycle evidence, and base reconciliation rather than weakening the checker, trusting list order, rewriting history, duplicating PR #256, or adding a compatibility bypass.
- target: `scripts/enforcement/check-merge-readiness.sh`; `scripts/enforcement/tests/test-operational-readiness-gates.sh`; `scripts/enforcement/tests/test-clean-install-and-usage.sh`; `docs/operations/merge-readiness-checklist.md`; `.claude/plans/merge-readiness-exact-head-attempt-ordering.md`.

## Alternatives

- Preserve legacy invocation — rejected because it reintroduces headless evidence.
- Trust API order or first occurrence — rejected because reruns and pagination make order unsafe.
- Trust PR-body SHA alone — rejected because it does not bind each workflow-run object.
- Accept any exact-head success — rejected because later failure or pending state invalidates stale green.
- Reuse pre-retarget workflow runs as final evidence — rejected because base-sensitive checks must rerun on the current PR base.
- Rewrite branch history or duplicate PR #256 — rejected because the nine inherited paths are already byte-identical to `main`.
- Add another workflow registry or automate approval — rejected because canonical ownership and Manual-by-design approval remain required.
- Add a new merge hook — rejected because `core/git-policy.md` already wires the checker into the human merge decision while authorization must remain human.

## Data / Integration Impact

The checker reads metadata-only JSON and emits deterministic diagnostics. Repository and clean-install callers pass exact head and complete workflow-run metadata. No persistent runtime state, prompt/response content, secret, user data, required-workflow registry, or merge authorization changes.

## Branch and PR Boundary

PR #256 is merged to `main` as `4ca1fd5a58fc96275ae69a1d2e573b7712d9055d`. PR #257 now targets current `main`; its nine PR #256-only displayed paths are byte-identical to `main`, while the effective change remains the five merge-readiness paths. No merge, branch deletion, or direct `main` write is authorized.

## Capability Evidence

- `routing.task-router-read` — `engineering_os_governance` selected.
- `workflow.workflow-read` — result loop and owner-gated merge applied.
- `plan.route-plan-before-write` — initial plan preceded implementation; every discovered consumer expansion preceded its edit; this base-reconciliation checkpoint precedes fresh current-base validation.
- `source.github-repo-read` — live state, callers, runs, jobs, logs, artifacts, comments, diffs, threads, and blob identities inspected.
- `validation.policy-change-has-validator` — focused and clean-install fixtures own the behavior.
- `validation.actions-checked` — exact-head Actions must refresh on this new plan-only head before completion.
- `validation.coderabbit-policy` — manual review was triggered after the stacked-base auto-review skip; both findings were verified against current code, corrected, replied to, and resolved.

## Skill Evidence

- `writing-plans` — scope and corrections were recorded before each newly discovered edit.
- `verification-before-completion` — reproduction, implementation, focused CI, full CI, review, base reconciliation, merge, and closure remain separate.
- `security-review` — untrusted JSON, missing identity, incomplete chronology, stale success, and nondeterministic input fail closed without a bypass.

## Claude Run Trace

- goal: prevent stale or wrong-head workflow evidence from supporting a merge.
- hypothesis: exact-head filtering and deterministic chronology/attempt/ID ordering reject stale green only when every caller supplies provider identity metadata and every base-sensitive policy reruns after base reconciliation.
- connectors: GitHub and official GitHub sources.
- steps: verify; plan; reproduce; implement; expand fixtures; run CI; correct clean-install consumer; rerun; correct fixture defect; run all enforcement; inspect diff; trigger manual CodeRabbit; align runbook wording; revalidate exact head; resolve threads; merge PR #256 with owner approval; retarget PR #257; verify byte identity; create a current-base validation checkpoint.
- evidence: reproduction run 1365; consumer failure run 1370; fixture failure run 1373; full successes runs 1374, 1376, and 1377; pr-policy 1666; review findings and implementation/correction commits; PR #256 merge `4ca1fd5a58fc96275ae69a1d2e573b7712d9055d`; nine matching blob SHAs.
- rejected: implicit list order, optional expected head, compatibility fallback, duplicate registry, automated approval, merge-hook scope expansion, validator weakening, stale-base CI reuse, and branch-history rewriting.
- result: implementation, consumers, focused/wider regression evidence, documentation, review corrections, and base reconciliation are complete; fresh exact-head current-base workflow evidence remains active.

## Definition of Done — Pre-Merge Evidence Checkpoint

- [x] Live stale-success failure reproduced before implementation.
- [x] Exact-head latest-attempt checker committed.
- [x] Positive, negative, malformed-input, attempt, tie-breaker, and determinism fixtures committed.
- [x] Clean-install consumer synchronized after a live failure.
- [x] Operator runbook aligned with runtime metadata semantics.
- [x] Dedicated suites, groups A–Z, every enforcement test file, and all remaining contracts passed on historical exact head `375e97c2b17dce6a0845b3db82a7877f6e57baa7` in run 1377.
- [x] CodeRabbit findings verified, corrected, replied to, and resolved.
- [x] PR #256 merged with owner approval and PR #257 retargeted to current `main`.
- [x] All nine squash-history-only paths verified byte-identical between `main` and PR #257.
- [ ] Every required workflow passes on this new exact head and current `main` base.
- [ ] Explicit owner approval to merge PR #257 is recorded.
- [ ] Expected-head protected merge and post-merge validation complete.

## Current Completion State

Implementation, review correction, and base reconciliation are complete. Fresh required workflows must pass on this new plan-only exact head. Explicit owner approval, merge, post-merge validation, and canonical gap closure remain incomplete.

## Live External Gates Before Closure

The gap remains `open`. Even a green ready-for-review PR cannot close it without explicit Yotam approval, expected-head merge protection after base reconciliation, post-merge validation on canonical `main`, and matching audit/live-state evidence.

## Progress Lifecycle Evidence

- start: commit `404c5d8330619052eb362b9812dd8d8aa4584411` recorded initial scope before tests or code.
- mid: commit `54a30ddc6938284032fbd272908d564aa6b9e9b5` introduced the stale-success reproduction; runs 1363–1365 isolated evidence friction and the intended failure.
- pre-merge: the test-only stage recorded reproduction readiness and an explicit merge prohibition before implementation.
- mid: commits `4123adb3c4a19dea6d2bd9d04d7f7f031ff1d03e`, `1b95ac486ce5938010449228a3cc9501f04f8e51`, and `3f350b8d0432f9a068261b039d97b50653d4670f` implemented the checker, focused fixtures, and runbook.
- mid: run 1370 exposed clean-install consumer drift; plan commit `0510b39927f89812d805cd50d7eb3c4394079858` expanded scope before consumer commit `ca737eaa56a7a5a9cde6daa9ddf7726957f23820`.
- mid: run 1373 exposed the case-insensitive fixture error; commit `7fc3d886824d1a5891491b45008ee4e11ae4a3e6` corrected only the fixture and run 1374 passed the full workflow.
- mid: self-review produced documentation-only commit `14356ebd259e691f4b289c1041453c8285426d9c`; commit `419060be0ce73ebaca09150060a97792e5a01dc5` started exact-head revalidation.
- pre-merge: run 1376 passed the complete enforcement workflow on `419060be0ce73ebaca09150060a97792e5a01dc5`; commit `375e97c2b17dce6a0845b3db82a7877f6e57baa7` recorded the later reviewed checkpoint and run 1377 passed the full workflow.
- base-reconciliation: after PR #256 merged, PR #257 was retargeted to `main`, nine inherited paths were proven byte-identical, and this separate plan commit starts fresh current-base exact-head validation without claiming approval, merge, post-merge proof, or gap closure.
