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
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, `core/documentation-policy.md`, and `core/hooks-policy.md` require plan-first reproduction, minimal correction, focused/wider tests, review, exact-head validation, owner approval, and post-merge proof. |
| Target paths | `.claude/plans/merge-readiness-exact-head-attempt-ordering.md`; `scripts/enforcement/check-merge-readiness.sh`; `scripts/enforcement/tests/test-operational-readiness-gates.sh`; `docs/operations/merge-readiness-checklist.md` |
| Templates | waiver — focused extension of an existing validator and fixture suite |
| Architecture guides | `docs/operations/merge-readiness-checklist.md`; `docs/operations/main-required-checks.md`; `docs/operations/operational-readiness-audit.md` |
| Patterns | `patterns/testing/README.md`; `patterns/security/README.md`; `patterns/observability/README.md`; infrastructure consulted, no provisioning pattern applies |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion`; `security-review` |
| Validation gates | focused operational-readiness fixtures; required-workflows contract; known-gaps/readiness suites; all enforcement suites; exact-head workflows; live review; Operational Work History |
| Evidence to check | PR #256 head `fa52f62894c97bd4173830a0b5581705676352f9`; current checker/tests; live-state ordering; workflow consumers; official workflow-run metadata |
| User decisions required | no merge; no gap closure before explicit Yotam approval, expected-head merge protection, and post-merge validation |

## Goal

Reject stale, wrong-head, incomplete, failed, or pending workflow evidence even when an older success appears first. Human approval remains separate and mandatory.

## Affected Surfaces

- `scripts/enforcement/check-merge-readiness.sh`
- `scripts/enforcement/tests/test-operational-readiness-gates.sh`
- `docs/operations/merge-readiness-checklist.md`
- this Route Plan

No Project 8, provider, secret, deployment, branch-protection, database, or raw telemetry change is in scope.

## Required Behavior

1. Require `--expected-head-sha` as a lowercase 40-character SHA.
2. Evaluate required workflows only on matching `head_sha`.
3. Fail closed on missing head identity or malformed exact-head metadata.
4. Select latest by `run_started_at`, else `updated_at`, else `created_at`; then `run_attempt`; then run `id`.
5. Make input order irrelevant and diagnostics deterministic.
6. Require selected status `completed` and conclusion `success`.
7. Preserve the canonical required-workflow set and human approval boundary.

## Experiment and Implementation

- Plan commit `404c5d8330619052eb362b9812dd8d8aa4584411` preceded all tests and code.
- Reproduction commit `54a30ddc6938284032fbd272908d564aa6b9e9b5` added old success followed by newer failure while the checker still accepted the first occurrence.
- PR #257 Actions run 1365 failed in enforcement group M–R after groups A–L and all earlier dedicated suites passed, isolating the changed fixture before implementation.
- Checker commit `4123adb3c4a19dea6d2bd9d04d7f7f031ff1d03e` added mandatory full lowercase head identity, fail-closed input validation, canonical timestamp/attempt/ID selection, and stable selected-run diagnostics.
- Fixture commit `1b95ac486ce5938010449228a3cc9501f04f8e51` added success, failure, wrong-head, missing metadata, rerun, pending, tie-breaker, malformed input, and input-order determinism coverage.
- Runbook commit `3f350b8d0432f9a068261b039d97b50653d4670f` documented the exact invocation, provider fields, selection rules, expected-head merge protection, and post-merge boundary.

## Validation Plan

- old success + new failure → fail;
- old failure + new success → pass;
- other-head success → fail;
- missing head → fail;
- attempt 2 failure after attempt 1 success → fail;
- latest pending → fail;
- duplicate names and reversed input → same decision/output;
- malformed timestamp/attempt/ID → fail closed;
- required-workflow contract, known-gaps/readiness, all enforcement, exact-head Actions, review, and Operational Work History remain required.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `CLAUDE.md` | read | Mutable claims require live evidence. |
| `core/task-router.md` | read | Governance and infra/CI route selected. |
| `core/workflow.md` | read | Plan-first Experiment → Fix → Experiment applies. |
| `core/quality-gates.md` | read | Fresh focused and edge fixtures are mandatory. |
| `core/git-policy.md` | read | Exact-head CI and owner approval govern merge. |
| `core/documentation-policy.md` | read | CLI and operator runbook update together. |
| `core/hooks-policy.md` | read | Safety claims require executable enforcement. |
| `core/connector-policy.md` | read | Repository and official sources precede changes. |
| `core/skill-orchestration-policy.md` | read | Planning, verification, and security review apply. |
| `core/capability-registry.yaml` | read | Governance requires plan, GitHub, validation, Actions, and review evidence. |
| `core/learning-loop.md` | read | Root cause and regression proof precede closure. |
| `docs/operations/known-gaps.tsv` | checked | P0 closure requires exact head, latest attempt, fixtures, CI, review, merge, and post-merge proof. |
| `docs/operations/operational-readiness-audit.md` | checked | This is Phase 0 item 1. |
| `scripts/enforcement/check-merge-readiness.sh` | checked | The old first-occurrence logic lacked head and chronology validation. |
| `scripts/enforcement/tests/test-operational-readiness-gates.sh` | checked | The focused owner now contains the registered positive, negative, and deterministic fixtures. |
| `scripts/enforcement/check-known-gaps-live-state.py` | checked | Canonical timestamp/attempt/ID precedence is reused. |
| `.github/workflows/pr-policy.yml` | read | Live PR head and CI history are captured. |
| `.github/workflows/enforcement-tests.yml` | read | Focused suite runs in group M-R and the full suite. |
| `docs/operations/main-required-checks.md` | checked | Checker remains the required-workflow owner. |
| `https://docs.github.com/en/rest/actions/workflow-runs` | read | Official run objects expose required metadata. |
| `https://github.com/actions/github-script/blob/main/README.md` | read | Official Octokit and pagination support are available. |

## Documentation Asset Evidence

- internal: `docs/operations/merge-readiness-checklist.md`, `docs/operations/main-required-checks.md`, and `scripts/enforcement/check-known-gaps-live-state.py` define the operator contract, workflow owner, and ordering precedent.
- context7: Context7 was not required because the boundary is GitHub REST metadata; official `https://docs.github.com/en/rest/actions/workflow-runs` and `https://github.com/actions/github-script/blob/main/README.md` were checked directly.
- decision: The official fields and internal precedent selected exact-head filtering plus timestamp, `run_attempt`, and run-ID ordering instead of list order.

## Template/Pattern Rating Evidence

- asset: `patterns/testing/README.md`
- asset: `patterns/security/README.md`
- asset: `patterns/observability/README.md`
- rating: useful for this task — fixture isolation, boundary validation, and structured metadata/diagnostic guidance directly constrained the implementation and tests.
- outcome: adopted isolated fixtures, fail-closed input validation, and deterministic selected-run diagnostics; no production observability backend was added.
- decision: keep these three patterns as implementation guidance without promoting their maturity or inventing real-use evidence.
- confidence: high for local applicability; no claim is made about pattern lifecycle maturity.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Live main, PR #256, PR #257, commits, Actions runs/jobs/logs/artifacts, review threads, files, and official GitHub repositories were inspected. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, PR #256, PR #257, Actions runs 1363–1366, workflow evidence artifact 8551390559, and exact repository files.
- action: verified state and read policies, checker, fixtures, workflows, audit, patterns, official sources, CI steps, and uploaded diagnostics; then wrote the minimal checker, test matrix, and runbook.
- result: commits `4123adb3c4a19dea6d2bd9d04d7f7f031ff1d03e`, `1b95ac486ce5938010449228a3cc9501f04f8e51`, and `3f350b8d0432f9a068261b039d97b50653d4670f` implement the three declared target surfaces while preserving the open gap and manual approval boundary.
- decision: selected canonical ordering, complete fail-closed fixtures, and exact-head operator guidance without adding another registry or weakening validators.
- target: `scripts/enforcement/check-merge-readiness.sh`; `scripts/enforcement/tests/test-operational-readiness-gates.sh`; `docs/operations/merge-readiness-checklist.md`.

## Alternatives

- First API occurrence — rejected because reruns and pagination make order unsafe.
- PR-body SHA only — rejected because it does not bind each run.
- `run_number` only — rejected because reruns require attempt and chronology.
- Any exact-head success — rejected because later failure or pending state invalidates stale green.
- Second workflow registry — rejected because the checker owns the set.
- Automated approval — rejected because approval is Manual by design.

## Data / Integration Impact

Metadata-only JSON is read and deterministic diagnostics are emitted. Callers must pass exact head and complete workflow-run metadata. No persistent state, prompts, responses, secrets, user data, or required-workflow ownership changes.

## Branch and PR Boundary

PR #256 remains open and owner-gated. Per the user's direction to continue independently without contaminating #256, PR #257 is stacked from exact head `fa52f62894c97bd4173830a0b5581705676352f9`. This narrow exception authorizes no merge, branch deletion, or direct `main` write.

## Capability Evidence

- `routing.task-router-read` — `engineering_os_governance` selected.
- `workflow.workflow-read` — result loop and owner-gated merge applied.
- `plan.route-plan-before-write` — commit `404c5d8330619052eb362b9812dd8d8aa4584411` preceded test and implementation changes.
- `source.github-repo-read` — live state, files, runs, jobs, logs, artifacts, and threads inspected.
- `validation.policy-change-has-validator` — isolated reproduction preceded the checker and expanded regression matrix.
- `validation.actions-checked` — exact-head Actions are refreshed after each implementation checkpoint.
- `validation.coderabbit-policy` — live review required; fallback only on proven unavailability.

## Skill Evidence

- `writing-plans` — scope, sources, alternatives, validation, and boundaries were recorded before code.
- `verification-before-completion` — reproduction, implementation, CI, review, merge, and closure remain separate.
- `security-review` — untrusted JSON, fail-closed metadata, deterministic output, and no-secret boundary shaped the implementation.

## Claude Run Trace

- goal: prevent stale or wrong-head workflow evidence from supporting a merge.
- hypothesis: exact-head filtering plus deterministic chronology/attempt/ID ordering rejects stale green regardless of input order.
- connectors: GitHub and official GitHub sources.
- steps: verify; route; plan; reproduce; isolate CI failure; implement checker; expand fixtures; update runbook; begin exact-head validation.
- evidence: main `0ee2dbee7a9ab58e86a11726021c30baca0faa22`; PR #256 head `fa52f62894c97bd4173830a0b5581705676352f9`; reproduction run 1365; implementation commits `4123adb3c4a19dea6d2bd9d04d7f7f031ff1d03e`, `1b95ac486ce5938010449228a3cc9501f04f8e51`, and `3f350b8d0432f9a068261b039d97b50653d4670f`.
- rejected: implicit list order, prose-only binding, any-success acceptance, duplicate registry, automated approval, and validator weakening.
- result: implementation and regression coverage are committed; exact-head CI and review evidence are being evaluated separately from completion and closure.

## Definition of Done — Implementation Checkpoint

- [x] Live pre-fix failure isolated in enforcement group M-R.
- [x] Exact-head and latest-attempt checker implementation committed.
- [x] Positive, negative, malformed-input, tie-breaker, and determinism fixtures committed.
- [x] Merge-readiness runbook updated with the exact invocation and provider metadata contract.
- [x] Implementation checkpoint recorded after the final code/test change.

## Current Completion State

Implementation is complete. Exact-head focused and wider CI, current-head external review, PR-body and Operational Work History synchronization, owner approval, merge, post-merge validation, and canonical gap closure remain incomplete.

## Live External Gates Before Closure

The gap remains `open`. Green implementation is insufficient without explicit Yotam approval, expected-head merge protection after base reconciliation, post-merge validation on canonical `main`, and matching audit/live-state evidence.

## Progress Lifecycle Evidence

- start: commit `404c5d8330619052eb362b9812dd8d8aa4584411` recorded scope, sources, root cause, alternatives, validation, and branch boundary before tests or code.
- mid: test-only commit `54a30ddc6938284032fbd272908d564aa6b9e9b5` introduced the stale-success reproduction, and runs 1363–1365 exposed evidence-contract friction before implementation.
- pre-merge: PR #257 test-only stage contained the plan-first fixture, live isolated failure, corrected source/connector/pattern evidence, and explicit merge prohibition; this checkpoint recorded reproduction readiness only.
- mid: commits `4123adb3c4a19dea6d2bd9d04d7f7f031ff1d03e`, `1b95ac486ce5938010449228a3cc9501f04f8e51`, and `3f350b8d0432f9a068261b039d97b50653d4670f` implemented exact-head selection, complete fixtures, and operator guidance after the reproduced failure.
