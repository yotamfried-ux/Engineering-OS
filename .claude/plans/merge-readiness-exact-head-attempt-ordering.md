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
| Validation gates | focused operational-readiness fixtures; installed-target clean-install suite; required-workflows contract; known-gaps/readiness suites; all enforcement suites; exact-head workflows; live review; Operational Work History |
| Evidence to check | PR #256 head `fa52f62894c97bd4173830a0b5581705676352f9`; checker and all CLI consumers; live-state ordering; workflow wiring; official workflow-run metadata |
| User decisions required | no merge; no gap closure before explicit Yotam approval, expected-head merge protection, and post-merge validation |

## Goal

Reject stale, wrong-head, incomplete, failed, or pending workflow evidence even when an older success appears first, including when the checker is exercised from the clean-install target simulation. Human approval remains separate and mandatory.

## Required Behavior

1. Require `--expected-head-sha` as a lowercase 40-character SHA.
2. Evaluate required workflows only on matching `head_sha`.
3. Fail closed on missing head identity or malformed exact-head metadata.
4. Select latest by `run_started_at`, else `updated_at`, else `created_at`; then `run_attempt`; then run `id`.
5. Make input order irrelevant and diagnostics deterministic.
6. Require selected status `completed` and conclusion `success`.
7. Preserve the canonical required-workflow set and human approval boundary.
8. Keep the clean-install usage simulation synchronized with the stricter CLI and provider metadata contract.

## Result Loop

- Plan commit `404c5d8330619052eb362b9812dd8d8aa4584411` preceded all tests and code.
- Reproduction commit `54a30ddc6938284032fbd272908d564aa6b9e9b5` added old success followed by newer failure while the checker still accepted the first occurrence.
- Run 1365 failed in group M–R after earlier suites passed, proving stale-success acceptance before implementation.
- Checker commit `4123adb3c4a19dea6d2bd9d04d7f7f031ff1d03e` implemented exact-head, chronology, attempt, ID, terminal-state, and fail-closed input validation.
- Fixture commit `1b95ac486ce5938010449228a3cc9501f04f8e51` added registered positive, negative, malformed-input, tie-breaker, and deterministic-output cases.
- Runbook commit `3f350b8d0432f9a068261b039d97b50653d4670f` documented exact invocation and provider metadata.
- Run 1370 failed in group A–F because `scripts/enforcement/tests/test-clean-install-and-usage.sh` still created legacy run objects and omitted `--expected-head-sha`.
- Consumer commit `ca737eaa56a7a5a9cde6daa9ddf7726957f23820` now supplies deterministic run IDs, exact head, timestamp, attempt, real JSON null for pending conclusion, and the mandatory expected-head argument in both pending and green paths.

## Validation Plan

- old success + new failure → fail;
- old failure + new success → pass;
- other-head success → fail;
- missing head → fail;
- attempt 2 failure after attempt 1 success → fail;
- latest pending → fail;
- duplicate names and reversed input → identical decision/output;
- malformed timestamp/attempt/ID/input → fail closed;
- clean-install target simulation passes exact-head green evidence and blocks pending evidence;
- required-workflow contract, known-gaps/readiness, all enforcement, exact-head Actions, review, and Operational Work History remain required.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `CLAUDE.md` | read | Mutable claims require live evidence. |
| `core/task-router.md` | read | Governance and infra/CI route selected. |
| `core/workflow.md` | read | Plan-first Experiment → Fix → Experiment applies. |
| `core/quality-gates.md` | read | Fresh focused and clean-install fixtures are mandatory. |
| `core/git-policy.md` | read | Exact-head CI and owner approval govern merge. |
| `core/documentation-policy.md` | read | CLI and operator runbook update together. |
| `core/hooks-policy.md` | read | Safety claims require executable enforcement. |
| `core/connector-policy.md` | read | Repository and official sources precede changes. |
| `core/skill-orchestration-policy.md` | read | Planning, verification, and security review apply. |
| `core/capability-registry.yaml` | read | Governance requires plan, GitHub, validation, Actions, and review evidence. |
| `core/learning-loop.md` | read | Root cause and regression proof precede closure. |
| `docs/operations/known-gaps.tsv` | checked | P0 closure requires exact head, latest attempt, fixtures, live wiring, CI, review, merge, and post-merge proof. |
| `docs/operations/operational-readiness-audit.md` | checked | This is Phase 0 item 1. |
| `scripts/enforcement/check-merge-readiness.sh` | checked | Old first-occurrence logic lacked head and chronology validation. |
| `scripts/enforcement/tests/test-operational-readiness-gates.sh` | checked | Focused owner contains registered ordering and metadata fixtures. |
| `scripts/enforcement/tests/test-clean-install-and-usage.sh` | checked | Consumer now uses complete exact-head run objects and mandatory CLI argument. |
| `scripts/enforcement/check-known-gaps-live-state.py` | checked | Canonical timestamp/attempt/ID precedence is reused. |
| `.github/workflows/enforcement-tests.yml` | read | Clean-install runs in group A–F; focused suite runs in group M–R and full suite. |
| `docs/operations/main-required-checks.md` | checked | Checker remains required-workflow owner. |
| `https://docs.github.com/en/rest/actions/workflow-runs` | read | Official run objects expose required metadata. |
| `https://github.com/actions/github-script/blob/main/README.md` | read | Official Octokit and pagination support are available. |

## Documentation Asset Evidence

- internal: `docs/operations/merge-readiness-checklist.md`, `docs/operations/main-required-checks.md`, `scripts/enforcement/check-known-gaps-live-state.py`, and `scripts/enforcement/tests/test-clean-install-and-usage.sh` define operator, ordering, and consumer contracts.
- context7: Context7 was not required because the boundary is GitHub REST metadata; official `https://docs.github.com/en/rest/actions/workflow-runs` and `https://github.com/actions/github-script/blob/main/README.md` were checked directly.
- decision: Official fields and internal consumers selected exact-head filtering plus timestamp, `run_attempt`, and run-ID ordering in focused and clean-install tests.

## Template/Pattern Rating Evidence

- asset: `patterns/testing/README.md`
- asset: `patterns/security/README.md`
- asset: `patterns/observability/README.md`
- rating: useful — fixture isolation, trust-boundary validation, and structured diagnostics constrained implementation and tests.
- outcome: adopted isolated fixtures, fail-closed metadata handling, deterministic selected-run output, and clean-install parity.
- decision: retain these patterns as task guidance without promoting maturity or inventing real-use evidence.
- confidence: high for local applicability; no lifecycle maturity claim.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Live main, PRs #256/#257, commits, Actions runs/jobs/logs/artifacts, review threads, repository files, and official GitHub repositories were inspected. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, PRs #256/#257, Actions runs 1363–1370, workflow artifact 8551390559, and exact repository files.
- action: verified state; read policies, checker, focused and clean-install consumers, workflows, audit, patterns, official sources, CI steps, and diagnostics; corrected the discovered consumer.
- result: commit `ca737eaa56a7a5a9cde6daa9ddf7726957f23820` synchronizes `scripts/enforcement/tests/test-clean-install-and-usage.sh` with the exact-head metadata and CLI contract exposed by run 1370.
- decision: corrected the consumer rather than weakening the checker or adding a compatibility fallback.
- target: `scripts/enforcement/check-merge-readiness.sh`; `scripts/enforcement/tests/test-operational-readiness-gates.sh`; `scripts/enforcement/tests/test-clean-install-and-usage.sh`; `docs/operations/merge-readiness-checklist.md`.

## Alternatives

- Preserve legacy invocation as optional compatibility — rejected because it would reintroduce headless evidence.
- First API occurrence — rejected because reruns and pagination make order unsafe.
- PR-body SHA only — rejected because it does not bind each run.
- Any exact-head success — rejected because later failure or pending state invalidates stale green.
- Second workflow registry or automated approval — rejected because canonical ownership and Manual-by-design approval remain required.

## Data / Integration Impact

Metadata-only JSON is read and deterministic diagnostics are emitted. Repository and clean-install simulation callers pass exact head and complete workflow-run metadata. No persistent state, prompts, responses, secrets, user data, or required-workflow ownership changes.

## Branch and PR Boundary

PR #256 remains open and owner-gated. PR #257 is stacked from exact head `fa52f62894c97bd4173830a0b5581705676352f9` per the user's instruction to continue independently without contaminating #256. No merge, branch deletion, or direct `main` write is authorized.

## Capability Evidence

- `routing.task-router-read` — `engineering_os_governance` selected.
- `workflow.workflow-read` — result loop and owner-gated merge applied.
- `plan.route-plan-before-write` — initial plan preceded code; consumer scope expansion preceded its correction.
- `source.github-repo-read` — live state, consumers, runs, jobs, logs, artifacts, and threads inspected.
- `validation.policy-change-has-validator` — focused and clean-install fixtures own the behavior.
- `validation.actions-checked` — exact-head Actions refreshed at each checkpoint.
- `validation.coderabbit-policy` — live review required; fallback only on proven unavailability.

## Skill Evidence

- `writing-plans` — scope and correction were updated before the discovered consumer edit.
- `verification-before-completion` — reproduction, fixes, CI, review, merge, and closure remain separate.
- `security-review` — untrusted JSON and missing identity fail closed without a legacy bypass.

## Claude Run Trace

- goal: prevent stale or wrong-head workflow evidence from supporting a merge in repository and clean-install simulation use.
- hypothesis: exact-head filtering and deterministic ordering reject stale green only if every consumer supplies required provider metadata.
- connectors: GitHub and official GitHub sources.
- steps: verify; reproduce; implement checker and focused fixtures; update runbook; run CI; discover consumer drift; expand scope; correct consumer; start renewed validation.
- evidence: reproduction run 1365; implementation commits `4123adb3c4a19dea6d2bd9d04d7f7f031ff1d03e`, `1b95ac486ce5938010449228a3cc9501f04f8e51`, `3f350b8d0432f9a068261b039d97b50653d4670f`; consumer failure run 1370; consumer fix `ca737eaa56a7a5a9cde6daa9ddf7726957f23820`.
- rejected: implicit list order, optional expected head, compatibility fallback, duplicate registry, automated approval, and validator weakening.
- result: checker, focused fixtures, runbook, and clean-install consumer are synchronized; renewed exact-head validation remains active.

## Definition of Done — Consumer-Correction Checkpoint

- [x] Live stale-success failure reproduced before implementation.
- [x] Exact-head latest-attempt checker and focused fixture matrix committed.
- [x] Operator runbook updated.
- [x] Clean-install consumer failure isolated in Actions run 1370.
- [x] Clean-install consumer added to target scope before edit.
- [x] Clean-install consumer synchronized with exact-head metadata and CLI contract.

## Current Completion State

Implementation and known consumer synchronization are complete. Renewed focused/full CI, current-head review, PR-body and Operational Work History synchronization, owner approval, merge, post-merge validation, and canonical gap closure remain incomplete.

## Live External Gates Before Closure

The gap remains `open`. Green implementation is insufficient without explicit Yotam approval, expected-head merge protection after base reconciliation, post-merge validation on canonical `main`, and matching audit/live-state evidence.

## Progress Lifecycle Evidence

- start: commit `404c5d8330619052eb362b9812dd8d8aa4584411` recorded initial scope before tests or code.
- mid: test commit `54a30ddc6938284032fbd272908d564aa6b9e9b5` introduced the stale-success reproduction and runs 1363–1365 exposed evidence friction.
- pre-merge: the test-only stage recorded reproduction readiness and an explicit merge prohibition before implementation.
- mid: commits `4123adb3c4a19dea6d2bd9d04d7f7f031ff1d03e`, `1b95ac486ce5938010449228a3cc9501f04f8e51`, and `3f350b8d0432f9a068261b039d97b50653d4670f` implemented the checker, focused fixtures, and runbook.
- mid: run 1370 exposed clean-install consumer drift and commit `0510b39927f89812d805cd50d7eb3c4394079858` expanded scope before correction.
- mid: commit `ca737eaa56a7a5a9cde6daa9ddf7726957f23820` synchronized the clean-install consumer with exact-head provider metadata and mandatory CLI invocation.
