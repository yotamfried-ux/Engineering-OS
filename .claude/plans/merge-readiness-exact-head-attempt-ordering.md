# Route Plan — Exact-Head Merge Readiness and Attempt Ordering

## Route Plan

| Field | Decision |
|---|---|
| Task type | governance enforcement / GitHub workflow-run reconciliation / merge evidence hardening |
| Task class | `engineering_os_governance` |
| Domain tags | governance, GitHub REST API, CI, merge safety, security, testing, observability |
| Plan Scope | standard |
| Planning Mode | user-authorized implementation; merge and gap closure remain owner-gated |
| Target paths | `.claude/plans/merge-readiness-exact-head-attempt-ordering.md`; `scripts/enforcement/check-merge-readiness.sh`; `scripts/enforcement/tests/test-operational-readiness-gates.sh`; `docs/operations/merge-readiness-checklist.md` |
| Task-router evidence | `core/task-router.md` routes Engineering OS governance and infra/CI work through canonical workflow, Git, quality, security, testing, and observability owners. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, `core/documentation-policy.md`, and `core/hooks-policy.md` require plan-first writes, root-cause reproduction, focused negative/positive fixtures, wider validation, exact-head review, owner approval, and post-merge proof. |
| Templates | waiver — this extends an existing canonical Bash/Python validator and its existing fixture suite; no project scaffold owns the change |
| Architecture guides | `docs/operations/merge-readiness-checklist.md`; `docs/operations/main-required-checks.md`; `docs/operations/operational-readiness-audit.md` |
| Patterns | `patterns/testing/README.md`; `patterns/security/README.md`; `patterns/observability/README.md`; infrastructure pattern consulted but no provisioning pattern applies |
| External systems/connectors | GitHub connector; official GitHub Actions REST documentation; official `actions/github-script` repository |
| Skills | `writing-plans`; `verification-before-completion`; `security-review` |
| Validation gates | focused operational-readiness fixtures; required-workflows contract; known-gaps/readiness suites; all enforcement groups and `run-all-tests.sh`; exact-head policy workflows; live review threads; Operational Work History |
| Evidence to check | PR #256 live head `fa52f62894c97bd4173830a0b5581705676352f9`; `scripts/enforcement/check-known-gaps-live-state.py`; `scripts/enforcement/check-merge-readiness.sh`; `scripts/enforcement/tests/test-operational-readiness-gates.sh`; `.github/workflows/pr-policy.yml`; `.github/workflows/enforcement-tests.yml`; GitHub REST workflow-run response fields `head_sha`, `run_started_at`, `updated_at`, `created_at`, `run_attempt`, and `id` |
| User decisions required | no merge to `main`; no closure claim until explicit Yotam approval, merge with expected-head protection, and post-merge validation |

## Goal

Make the machine evidence presented before a merge trustworthy. The checker must reject workflow evidence that is stale, belongs to another head, lacks required identity or chronology metadata, or hides a later failed or pending attempt behind an older success. Human approval remains a separate mandatory decision.

## Affected Surfaces

- CLI contract and selection logic in `scripts/enforcement/check-merge-readiness.sh`.
- Deterministic fixtures in `scripts/enforcement/tests/test-operational-readiness-gates.sh`.
- Operator instructions in `docs/operations/merge-readiness-checklist.md`.
- No Project 8 file, provider state, secret, deployment, branch protection rule, database, or telemetry bundle changes.

## Non-Negotiable Behavior

1. `--expected-head-sha` is mandatory and must be a lowercase 40-character commit SHA.
2. Every required workflow is evaluated only from runs whose `head_sha` exactly matches the expected head.
3. A required-workflow entry with missing head metadata fails closed instead of being silently ignored.
4. Exact-head candidates require valid chronology and deterministic identity metadata.
5. Latest selection reuses the canonical live-state precedence: `run_started_at`, else `updated_at`, else `created_at`; then `run_attempt`; then run `id`.
6. Input order never affects the selected result or diagnostic ordering.
7. Only the selected latest exact-head attempt may satisfy a required workflow.
8. A selected run must be terminal `completed` with `conclusion=success`.
9. Duplicate workflow names are expected input, not a reason to accept the first occurrence.
10. This checker does not grant human approval and does not merge.

## Experiment / Reproduction

1. Add isolated fixtures that model the registered failure classes while the current checker still uses first occurrence and no expected-head argument.
2. Open a ready-for-review stacked PR against `fix/documentation-runtime-state-drift` and capture the exact focused CI failure on the test-only head.
3. Distinguish expected reproduction failures from unrelated policy failures before implementation.

## Implementation Plan

1. Extend argument parsing and usage with required `--expected-head-sha`.
2. Validate input shape, SHA, required run identity, timestamps, attempts, and IDs fail-closed.
3. Filter by exact head and select deterministically using the existing live-state chronology contract.
4. Produce stable diagnostics naming workflow, selected run ID, attempt, head, status, and conclusion.
5. Update the merge-readiness runbook with the exact invocation and metadata contract.

## Validation Plan

- Positive: unordered input with an older failure and newer success on the expected head passes.
- Negative: older success plus newer failure fails.
- Negative: success on another head fails.
- Negative: required workflow entry missing `head_sha` fails.
- Negative: attempt 2 failure after attempt 1 success fails.
- Negative: latest run pending fails.
- Determinism: duplicate names and reversed input produce the same decision and diagnostic output.
- Compatibility: required workflow set remains synchronized with `docs/operations/main-required-checks.md`.
- Wider: focused test, known-gaps/readiness tests, all enforcement groups, `run-all-tests.sh`, exact-head Actions, review reconciliation, and Operational Work History.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `CLAUDE.md` | read | Verify mutable state and use canonical policy owners before action. |
| `core/task-router.md` | read | Routed as `engineering_os_governance`; infra/CI patterns and security/testing apply. |
| `core/workflow.md` | read | Plan-first Experiment → Fix → Experiment and review lifecycle apply. |
| `core/quality-gates.md` | read | Fresh objective tests and edge cases are mandatory; tests must not be weakened. |
| `core/git-policy.md` | read | Exact-head required workflows and explicit owner approval govern merge; no merge is authorized. |
| `core/documentation-policy.md` | read | CLI behavior and operator documentation must change together without a second policy owner. |
| `core/hooks-policy.md` | read | Deterministic safety rules belong in executable gates rather than prose only. |
| `core/connector-policy.md` | read | Repository owners and official vendor documentation precede implementation. |
| `core/skill-orchestration-policy.md` | read | Planning, verification, and security review ordering applies. |
| `core/capability-registry.yaml` | read | Governance changes require plan, GitHub evidence, validator coverage, Actions, and review evidence. |
| `core/learning-loop.md` | read | Reproduce root cause and preserve regression evidence before claiming correction. |
| `docs/operations/known-gaps.tsv` | checked | P0 closure contract names exact-head filtering, chronology, attempt ordering, deterministic fixtures, live wiring, review, merge, and post-merge proof. |
| `docs/operations/operational-readiness-audit.md` | checked | This is Phase 0 item 1 and precedes later readiness decisions. |
| `scripts/enforcement/check-merge-readiness.sh` | checked | Current implementation accepts the first occurrence and does not require head identity. |
| `scripts/enforcement/tests/test-operational-readiness-gates.sh` | checked | Current fixtures omit head, timestamp, run-attempt, run-ID, duplicates, and unordered input. |
| `scripts/enforcement/check-known-gaps-live-state.py` | checked | Existing canonical ordering uses `run_started_at`, then `updated_at`, then `created_at`, with `run_attempt` and run ID tie-breakers. |
| `.github/workflows/pr-policy.yml` | read | Live PR policy already captures exact head and CI history but does not replace the pre-merge checker. |
| `.github/workflows/enforcement-tests.yml` | read | Focused fixture file runs in group M-R and again in the complete suite. |
| `docs/operations/main-required-checks.md` | checked | Checker remains canonical owner of the required workflow set. |
| GitHub REST workflow-runs documentation | read | Official response objects expose head SHA, timestamps, run attempt, run ID, status, and conclusion. |
| `actions/github-script/README.md` | read | Official action exposes authenticated Octokit REST and pagination; API list order is not a correctness contract. |

## Official Documentation Evidence

- `https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2026-03-10`
- `https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api?apiVersion=2026-03-10`
- `https://docs.github.com/en/rest/guides/scripting-with-the-rest-api-and-javascript?apiVersion=2026-03-10`
- `https://github.com/actions/github-script/blob/main/README.md`

## Alternatives

- Trust API order or the first matching name — rejected because pagination, duplicate names, and reruns make order an unsafe implicit contract.
- Trust the PR-body expected SHA — rejected because prose does not bind each workflow-run object to that head.
- Use only `run_number` — rejected because reruns retain workflow identity while `run_attempt` and execution timestamps change.
- Accept any exact-head success — rejected because a later failed or pending attempt invalidates stale green evidence.
- Add a second required-workflow registry — rejected because the checker already owns the canonical set.
- Automate human approval — rejected because merge approval is Manual by design.

## Data / State Impact

The change reads metadata-only workflow-run JSON and emits deterministic pass/fail diagnostics. It creates no persistent runtime state and processes no prompts, responses, raw telemetry, secrets, or user data.

## Integration Impact

The CLI becomes stricter: callers must provide the expected head SHA and complete GitHub workflow-run metadata. Existing callers that provide only `name`, `status`, and `conclusion` must update their captured fixture or invocation. The required workflow list and human approval boundary do not change.

## Branch and PR Boundary

PR #256 remains open and owner-gated. The user explicitly requested continued work on the next independent gap without merging #256 and also requested separate focused PRs. To avoid mixing implementation into #256, this branch is stacked from its exact head and the new PR targets `fix/documentation-runtime-state-drift`. This is a narrow, documented exception to the normal sequential one-branch cadence; it does not authorize another merge to `main`, delete a branch, or alter #256.

## Capability Evidence

- `routing.task-router-read` — task routed as `engineering_os_governance`.
- `workflow.workflow-read` — plan-first result loop, validation, review, and owner-gated merge applied.
- `plan.route-plan-before-write` — this file is the first write on the dedicated branch.
- `source.github-repo-read` — live main, PR #256, exact files, workflow attempts, and review threads were inspected.
- `validation.policy-change-has-validator` — the implementation is blocked on isolated positive, negative, and deterministic fixtures.
- `validation.actions-checked` — exact-head Actions will be re-fetched after every implementation update.
- `validation.coderabbit-policy` — live review is required; structured fallback is used only if unavailability is proven.

## Skill Evidence

- `writing-plans` — target paths, alternatives, sources, validation, and external gates are defined before code.
- `verification-before-completion` — reproduction, focused correction, wider CI, review, merge, and post-merge claims remain separate.
- `security-review` — fail-closed parsing, untrusted JSON, metadata completeness, deterministic output, and no-secret boundaries are in scope.

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Re-fetched `main`, PR #256, exact head, diff paths, all workflow runs/attempts, job details, ten review threads, canonical files, and official repositories before planning. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS` plus official GitHub documentation and `actions/github-script`.
- action: verified live PR #256/main state; inspected the merge checker, fixtures, workflow consumers, audit contract, and existing chronological selector; created a dedicated stacked branch from exact head `fa52f62894c97bd4173830a0b5581705676352f9`.
- result: the root cause is confirmed in `scripts/enforcement/check-merge-readiness.sh`: the first occurrence wins, with no exact-head or chronology validation; the required official metadata exists and the repository already has a canonical ordering precedent.
- decision: reuse the established live-state ordering contract, make metadata fail closed, preserve the required-workflow owner, and keep human approval separate.
- target: `.claude/plans/merge-readiness-exact-head-attempt-ordering.md`; `scripts/enforcement/check-merge-readiness.sh`; `scripts/enforcement/tests/test-operational-readiness-gates.sh`; `docs/operations/merge-readiness-checklist.md`.

## Claude Run Trace

- goal: prevent stale or wrong-head workflow evidence from authorizing a merge decision.
- hypothesis: mandatory exact-head identity plus deterministic chronology/attempt/ID selection will reject stale green evidence regardless of API order.
- connectors: GitHub; official GitHub Actions REST and `actions/github-script` sources.
- steps: verify live state; read canonical owners; reproduce code-level root cause; align with the existing live-state ordering contract; plan isolated CI fixtures before implementation.
- evidence: Engineering OS `main` `0ee2dbee7a9ab58e86a11726021c30baca0faa22`; PR #256 head `fa52f62894c97bd4173830a0b5581705676352f9`; latest `pr-policy` run 1640 success after run 1639 failure; current checker and fixture content.
- rejected: list-order trust, prose-only head binding, run-number-only ordering, any-success acceptance, duplicate registry, and automated owner approval.
- result: planning and evidence pass complete; test-only reproduction is next and no implementation or closure claim exists yet.

## Definition of Done

- [x] Live main, PR #256, exact head, workflows/latest attempts, and review threads re-fetched.
- [x] Canonical audit, gap row, policies, checker, tests, workflows, patterns, and official sources read.
- [x] Root cause identified in current code and ordering precedent identified in canonical code.
- [x] Route Plan committed before code or test writes.
- [ ] Test-only reproduction fails for the intended missing exact-head/latest-attempt behavior.
- [ ] Minimal implementation makes every isolated fixture pass without weakening unrelated gates.
- [ ] Focused, required-workflow contract, known-gaps/readiness, and full enforcement suites pass.
- [ ] Exact-head non-self workflows pass and latest attempts are verified.
- [ ] All live review threads are reconciled and resolved.
- [ ] Operational Work History and PR body match the exact current head.

## Live External Gates Before Closure

The gap remains `open`. A ready-for-review stacked PR, successful exact-head CI, clean review, and complete implementation are not enough to close it. Explicit Yotam approval, merge with expected-head protection after its base dependency is reconciled, post-merge validation on canonical `main`, and matching audit/live-state evidence are still required.

## Progress Lifecycle Evidence

- start: this plan commit records scope, sources, root cause, alternatives, validation, branch boundary, and external gates before any code or test change.
