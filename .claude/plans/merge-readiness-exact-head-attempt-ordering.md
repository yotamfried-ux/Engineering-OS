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
| Templates | waiver — focused extension of an existing validator and fixture suite |
| Architecture guides | `docs/operations/merge-readiness-checklist.md`; `docs/operations/main-required-checks.md`; `docs/operations/operational-readiness-audit.md` |
| Patterns | `patterns/testing/README.md`; `patterns/security/README.md`; `patterns/observability/README.md`; infrastructure pattern consulted but no provisioning pattern applies |
| External systems / connectors | GitHub connector; official GitHub Actions REST docs; official `actions/github-script` repository |
| Skills | `writing-plans`; `verification-before-completion`; `security-review` |
| Validation gates | focused operational-readiness fixtures; required-workflows contract; known-gaps/readiness suites; all enforcement suites; exact-head policy workflows; live review threads; Operational Work History |
| Evidence to check | PR #256 head `fa52f62894c97bd4173830a0b5581705676352f9`; current checker/tests; live-state workflow ordering; workflow consumers; official workflow-run metadata |
| User decisions required | no merge; no gap closure before explicit Yotam approval, expected-head merge protection, and post-merge validation |

## Goal

Make pre-merge machine evidence trustworthy. The checker must reject stale, wrong-head, incomplete, failed, or pending workflow evidence even when an older success appears first. Human approval remains separate and mandatory.

## Affected Surfaces

- CLI parsing and workflow-run selection in `scripts/enforcement/check-merge-readiness.sh`.
- Positive, negative, and deterministic fixtures in `scripts/enforcement/tests/test-operational-readiness-gates.sh`.
- Exact invocation and metadata contract in `docs/operations/merge-readiness-checklist.md`.
- No Project 8, provider, secret, deployment, branch-protection, database, or telemetry changes.

## Non-Negotiable Behavior

1. Require `--expected-head-sha` as a lowercase 40-character SHA.
2. Evaluate required workflows only on that exact `head_sha`.
3. Fail closed when a required-workflow entry lacks head identity.
4. Require valid chronology and deterministic identity metadata on exact-head candidates.
5. Reuse canonical ordering: `run_started_at`, else `updated_at`, else `created_at`; then `run_attempt`; then run `id`.
6. Ignore input order and select only the latest exact-head attempt.
7. Require selected status `completed` and conclusion `success`.
8. Emit stable diagnostics in required-workflow order.
9. Preserve the canonical required-workflow set.
10. Never substitute machine evidence for owner approval.

## Experiment / Reproduction

- Commit `54a30ddc6938284032fbd272908d564aa6b9e9b5` adds an isolated old-success/new-failure fixture before implementation.
- The current checker treats the first occurrence as latest, so this fixture is expected to make the focused suite fail.
- The ready-for-review stacked PR will capture the exact test-only failure before the fix is written.

## Implementation Plan

1. Require and validate the expected head argument.
2. Validate workflow-run object shape, head identity, timestamp, attempt, and ID fail closed.
3. Filter exact-head candidates and choose the deterministic latest run.
4. Report the selected run metadata and terminal result consistently.
5. Update the operator runbook and add every registered fixture.

## Validation Plan

- old success + new failure → fail;
- old failure + new success → pass;
- success on another head → fail;
- missing head metadata → fail;
- attempt 2 failure after attempt 1 success → fail;
- latest run pending → fail;
- duplicate workflow names and unordered input → deterministic decision and output;
- missing or malformed chronology/attempt/ID → fail closed;
- required-workflow contract, known-gaps/readiness, all enforcement suites, exact-head Actions, review, and Operational Work History remain required.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `CLAUDE.md` | read | Mutable claims require tool evidence. |
| `core/task-router.md` | read | Routed as Engineering OS governance and infra/CI work. |
| `core/workflow.md` | read | Plan-first Experiment → Fix → Experiment lifecycle applies. |
| `core/quality-gates.md` | read | Fresh focused and edge-case tests are mandatory. |
| `core/git-policy.md` | read | Exact-head workflows and explicit approval govern merge. |
| `core/documentation-policy.md` | read | CLI behavior and runbook update together. |
| `core/hooks-policy.md` | read | Safety claims require executable enforcement. |
| `core/connector-policy.md` | read | Repository owners and official docs precede implementation. |
| `core/skill-orchestration-policy.md` | read | Planning, verification, and security review ordering applies. |
| `core/capability-registry.yaml` | read | Governance requires plan, GitHub state, validator, Actions, and review evidence. |
| `core/learning-loop.md` | read | Root cause and regression evidence precede closure. |
| `docs/operations/known-gaps.tsv` | checked | P0 gap requires exact-head filtering, latest attempts, fixtures, CI, review, merge, and post-merge proof. |
| `docs/operations/operational-readiness-audit.md` | checked | This is Phase 0 item 1. |
| `scripts/enforcement/check-merge-readiness.sh` | checked | Current first-occurrence logic has no head or chronology validation. |
| `scripts/enforcement/tests/test-operational-readiness-gates.sh` | checked | Existing suite lacked head/timestamp/attempt/ID ordering fixtures. |
| `scripts/enforcement/check-known-gaps-live-state.py` | checked | Canonical timestamp/attempt/ID precedence already exists. |
| `.github/workflows/pr-policy.yml` | read | Captures live PR head and CI history; it does not replace the pre-merge checker. |
| `.github/workflows/enforcement-tests.yml` | read | Focused test runs in group M-R and the complete suite. |
| `docs/operations/main-required-checks.md` | checked | Checker remains owner of the required workflow set. |
| GitHub REST workflow-runs docs | read | Official objects expose head SHA, timestamps, attempt, run ID, status, and conclusion. |
| `actions/github-script/README.md` | read | Official Octokit access and pagination are available; list order is not a correctness contract. |

## Official Documentation Evidence

- `https://docs.github.com/en/rest/actions/workflow-runs?apiVersion=2026-03-10`
- `https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api?apiVersion=2026-03-10`
- `https://docs.github.com/en/rest/guides/scripting-with-the-rest-api-and-javascript?apiVersion=2026-03-10`
- `https://github.com/actions/github-script/blob/main/README.md`

## Alternatives

- Trust the first API occurrence — rejected because reruns and pagination make order unsafe.
- Trust a PR-body SHA — rejected because it does not bind each run object.
- Use only `run_number` — rejected because reruns require attempt and execution chronology.
- Accept any exact-head success — rejected because later failure/pending invalidates stale green evidence.
- Add another workflow registry — rejected because the checker already owns the set.
- Automate human approval — rejected because approval is Manual by design.

## Data / State Impact

Metadata-only JSON is read and deterministic diagnostics are emitted. No persistent runtime state, raw telemetry, prompts, responses, secrets, or user data are created or changed.

## Integration Impact

Callers must pass `--expected-head-sha` and complete GitHub run metadata. The required workflow list and human approval boundary remain unchanged.

## Branch and PR Boundary

PR #256 stays open and owner-gated. The user directed continued work on this independent gap without merging #256 and requested focused PRs. This branch is therefore stacked from exact head `fa52f62894c97bd4173830a0b5581705676352f9` and targets `fix/documentation-runtime-state-drift`. This narrow exception avoids contaminating #256 and authorizes no merge, deletion, or direct `main` write.

## Capability Evidence

- `routing.task-router-read` — selected `engineering_os_governance`.
- `workflow.workflow-read` — result loop and owner-gated merge applied.
- `plan.route-plan-before-write` — plan commit `404c5d8330619052eb362b9812dd8d8aa4584411` preceded the test write.
- `source.github-repo-read` — live main, PR, files, attempts, and threads inspected.
- `validation.policy-change-has-validator` — isolated regression fixture exists before implementation.
- `validation.actions-checked` — exact-head Actions will be refreshed after every update.
- `validation.coderabbit-policy` — live review required; fallback only on proven unavailability.

## Skill Evidence

- `writing-plans` — scope, sources, alternatives, validation, and boundaries recorded before code.
- `verification-before-completion` — reproduction, implementation, CI, review, merge, and closure remain distinct.
- `security-review` — untrusted JSON, fail-closed metadata, deterministic output, and no-secret boundary included.

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, official GitHub docs, and `actions/github-script`.
- action: verified main/PR #256; read the checker, tests, consumers, audit, policies, patterns, and canonical ordering; created a stacked branch from the exact head.
- result: root cause confirmed as first-occurrence selection without exact-head or chronology validation; official fields and an internal ordering precedent exist.
- decision: reuse the canonical precedence, fail closed on missing metadata, preserve the required-workflow owner, and keep approval separate.
- target: the four target paths listed above.

## Claude Run Trace

- goal: prevent stale or wrong-head workflow evidence from supporting a merge.
- hypothesis: exact-head filtering plus deterministic chronology/attempt/ID ordering rejects stale green evidence regardless of input order.
- connectors: GitHub and official GitHub sources.
- steps: verify live state; read owners; plan; add isolated reproduction; next capture CI failure, then implement and retest.
- evidence: main `0ee2dbee7a9ab58e86a11726021c30baca0faa22`; PR #256 head `fa52f62894c97bd4173830a0b5581705676352f9`; `pr-policy` run 1640 succeeded after run 1639 failed; plan commit `404c5d8330619052eb362b9812dd8d8aa4584411`; reproduction commit `54a30ddc6938284032fbd272908d564aa6b9e9b5`.
- rejected: implicit list order, prose-only binding, any-success acceptance, duplicate registry, and automated approval.
- result: plan and test-only reproduction are recorded; no implementation or closure claim exists yet.

## Definition of Done — Completed Before PR Open

- [x] Live main, PR #256, exact head, workflows/latest attempts, and review threads re-fetched.
- [x] Audit, gap row, policies, checker, tests, workflows, patterns, and official sources read.
- [x] Root cause and canonical ordering precedent identified.
- [x] Route Plan committed before test or code changes.
- [x] Isolated test-only reproduction committed before implementation.

## Current Completion State

Implementation, focused/wider CI, exact-head workflow reconciliation, live review, PR-body/Operational Work History synchronization, owner approval, merge, post-merge validation, and canonical gap closure are still pending. They are external lifecycle states, not falsely completed checklist items.

## Live External Gates Before Closure

The gap remains `open`. Even a green ready-for-review PR cannot close it without explicit Yotam approval, expected-head merge protection after the stacked base is reconciled, post-merge validation on canonical `main`, and matching audit/live-state evidence.

## Progress Lifecycle Evidence

- start: commit `404c5d8330619052eb362b9812dd8d8aa4584411` recorded scope, sources, root cause, alternatives, validation, and branch boundary before tests or code.
- reproduction prepared: commit `54a30ddc6938284032fbd272908d564aa6b9e9b5` added only the isolated old-success/new-failure fixture; no implementation exists yet.
