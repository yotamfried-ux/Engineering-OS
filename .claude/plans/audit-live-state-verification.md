# Route Plan — Live Readiness State Verification

## Route Plan

| Field | Decision |
|---|---|
| Task type | governance enforcement / GitHub live-state reconciliation / audit lifecycle update |
| Task class | `engineering_os_governance` |
| Domain tags | governance, GitHub REST API, CI, security, testing, documentation, operational readiness |
| Plan Scope | standard |
| Planning Mode | user-authorized implementation after merged PR #254; this PR remains owner-gated |
| Target paths | `.claude/plans/audit-live-state-verification.md`; `.github/workflows/known-gaps-live-state.yml`; `docs/operations/live-state-claims.json`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `scripts/enforcement/check-known-gaps-live-state.py`; `scripts/enforcement/fetch-known-gaps-live-state.py`; `scripts/enforcement/check-known-gaps.sh`; `scripts/enforcement/tests/test-known-gaps-live-state.sh` |
| Task-router evidence | `core/task-router.md` routes readiness truth, canonical validators, and CI governance as `engineering_os_governance`. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, and `core/coderabbit-policy.md` require plan-first writes, exact-head evidence, negative tests, review reconciliation, and explicit owner approval. |
| Templates | waiver — no project scaffold owns an extension of the canonical known-gaps validator |
| Architecture guides | `docs/architecture-guides/api/rest.md`; `docs/operations/post-merge-incident-checklist.md`; `docs/operations/main-required-checks.md` |
| Patterns | `patterns/api/README.md`; `patterns/security/README.md`; `patterns/testing/README.md`; `patterns/observability/README.md` |
| External systems/connectors | GitHub |
| Skills | `security-review`; `verification-before-completion`; `writing-plans` |
| Validation gates | focused live-state fixtures; known-gaps and readiness suites; enforcement-tests; known-gaps-live-state; pr-policy; workflow, connector, capability, documentation, cleanup, and telemetry policies; live review threads |
| Evidence to check | PR #254 exact head `f74a26d65f6cebf06f29df1d803c192c3efb9694`; merge `c7d32a0b67a836811689d3a2bf80a63d727e1470`; canonical registry/audit/checkers; official GitHub documentation and official `actions/github-script`, `octokit/rest.js`, and `github/rest-api-description` repositories |
| User decisions required | no Project 8 behavioral experiment or prompt until every gap closes; no merge of PR #255 without a separate explicit Yotam approval after final evidence |

## Goal

Prevent a synchronized registry and audit from asserting closure when live GitHub state disagrees. A versioned claim binds a closed gap to its repository, pull request, reviewed head, merge commit, base branch, required pull-request workflows, required push workflows, and exact-SHA checks. A fail-closed REST fetcher creates a metadata-only snapshot; one deterministic validator checks both offline fixtures and live CI data.

PR #254 is the first real claim. `audit-self-contained-contract` is closed through its exact merged evidence. `audit-live-state-verification` remains open until PR #255 itself is owner-approved, merged, and validated on `main`.

## Non-negotiable behavior

1. `docs/operations/known-gaps.tsv` remains the sole gap registry.
2. Authentication, network, API schema, pagination, permission, or normalization failure fails closed in live CI.
3. Local regression tests remain offline and deterministic.
4. Snapshots exclude tokens, secret values, source content, logs, prompts, responses, and conversation text.
5. Unmerged, stale-head, merge mismatch, base divergence, skipped/neutral/failed evidence, and self-only `pr-policy` evidence fail.
6. Workflow selection uses actual execution chronology, so a late rerun of an older run number can invalidate an earlier green result.
7. Gap status changes require exact implementation, tests, review, merge, and post-merge proof.

## Plan

1. Register a minimal versioned claim for merged PR #254.
2. Fetch documented pull, workflow-run, check-run, and compare-commit metadata with read-only permissions.
3. Normalize only safe documented fields.
4. Validate exact identifiers, base containment, latest chronological workflow attempts, accepted conclusions, and non-self evidence.
5. Invoke live validation through the canonical known-gaps checker only when a snapshot is explicitly supplied.
6. Cover every failure mode with offline positive and negative fixtures.
7. Run one dedicated live workflow and inspect its artifact.
8. Synchronize the registry and audit without prematurely closing the implementation gap.
9. Complete exact-head CI, review reconciliation, self-review, and owner-gated merge/post-merge validation.

## Alternatives

- Parse free-form PR prose — rejected as ambiguous and non-versioned.
- Call GitHub from every local test — rejected as nondeterministic and rate-limit dependent.
- Accept any historical green run — rejected because a later rerun may fail.
- Sort workflow evidence only by `run_number` — rejected because reruns retain their original run number while execution time changes.
- Trust only `merged=true` — rejected because head, merge SHA, base containment, and named checks are independent claims.
- Create a second live-gap registry — rejected because it would duplicate canonical ownership.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `core/task-router.md` | read | The task is Engineering OS governance. |
| `core/workflow.md` | read | Plan-first result loops and post-merge evidence apply. |
| `core/quality-gates.md` | read | Exact tool evidence and negative tests are required. |
| `core/git-policy.md` | read | Expected head, named checks, threads, and owner approval govern merge safety. |
| `docs/operations/known-gaps.tsv` | checked | The P0 gap requires deterministic negative fixtures and a real merged-PR reconciliation. |
| `docs/operations/operational-readiness-audit.md` | checked | Phase 0 requires live-state truth before later readiness work. |
| `scripts/enforcement/check-known-gaps.sh` | checked | Existing synchronization was local-only. |
| `scripts/enforcement/tests/test-known-gaps.sh` | checked | Existing fixtures lacked PR/SHA/workflow/base drift. |
| `.github/workflows/enforcement-tests.yml` | read | Offline suites stay deterministic. |
| `.github/workflows/post-merge-validation.yml` | read | Push-to-main validation supplies a post-merge signal. |
| `actions/github-script/README.md` | read | The official action demonstrates authenticated Octokit REST access, environment-safe inputs, and retries. |
| `octokit/rest.js/README.md` | read | The official client demonstrates explicit endpoint calls and response handling. |
| `github/rest-api-description/README.md` | read | Official OpenAPI descriptions power request validation and contract tests. |

## Official Documentation Evidence

- `https://docs.github.com/en/rest/pulls/pulls` — reviewed head and squash merge SHA are separate exact identifiers.
- `https://docs.github.com/en/rest/checks/runs` — exact-ref check runs distinguish success from failure, neutral, skipped, cancellation, and timeout.
- `https://docs.github.com/en/rest/actions/workflow-runs` — runs expose event, head SHA, status, conclusion, run number, attempt, and execution timestamps.
- `https://docs.github.com/en/rest/commits/commits#compare-two-commits` — compare status and merge base prove base-branch containment.
- `https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions` — use minimal permissions and keep untrusted values outside executable interpolation.

## Official Repository Evidence

- `https://github.com/actions/github-script` — authenticated REST and retry examples shaped live acquisition.
- `https://github.com/octokit/rest.js` — endpoint-method and response examples shaped normalization.
- `https://github.com/github/rest-api-description` — stable API contracts shaped the versioned snapshot boundary.

## Documentation Asset Evidence

- internal: `core/task-router.md`, `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-known-gaps.sh`, `scripts/enforcement/tests/test-known-gaps.sh`, `.github/workflows/enforcement-tests.yml`, and `.github/workflows/post-merge-validation.yml`.
- context7: `https://docs.github.com/en/rest/pulls/pulls`, `https://docs.github.com/en/rest/checks/runs`, `https://docs.github.com/en/rest/actions/workflow-runs`, `https://docs.github.com/en/rest/commits/commits`, `https://github.com/actions/github-script`, `https://github.com/octokit/rest.js`, and `https://github.com/github/rest-api-description` were read directly; no third-party SDK was added.
- decision: separate live acquisition from deterministic validation, preserve execution timestamps, choose workflow attempts chronologically, require base containment and successful non-self evidence, and store only normalized metadata.

## Template Gap Waiver

reason: this focused change extends an existing canonical governance validator and GitHub Actions policy; no application template owns the change.

## Capability Evidence

- `routing.task-router-read` — routed as `engineering_os_governance`.
- `workflow.workflow-read` — plan-first result loops and post-merge evidence applied.
- `plan.route-plan-before-write` — `f6a1dcb81ca6851a0bdaa62db90d034dd6e2bfd1` preceded implementation writes.
- `source.github-repo-read` — exact canonical files, PR #254, workflows, documentation, and official repositories were inspected.
- `validation.policy-change-has-validator` — each live-state requirement has a positive or negative fixture.
- `validation.actions-checked` — the dedicated live workflow and exact-head policy workflows are completion gates.
- `validation.coderabbit-policy` — the valid workflow-rerun review finding was implemented with a regression fixture.

## Skill Evidence

- `security-review` — covered token scope, untrusted inputs, transport/API failure, pagination, privacy, and artifact contents.
- `verification-before-completion` — implementation, local tests, live PR validation, merge, post-merge, and closure remain distinct.
- `writing-plans` — targets, alternatives, official evidence, and validation were recorded before code.

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Verified PR #254 merge truth, read canonical and official repositories, created PR #255, and supplied exact workflow/review evidence. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, `actions/github-script`, `octokit/rest.js`, and `github/rest-api-description`.
- action: merged PR #254 with expected-head protection; implemented claims, fetcher, validator, fixtures, workflow, registry, and audit; inspected run 1 and artifact `8518500199`; read and fixed both review findings.
- result: live run 1 validated PR #254 successfully; the artifact contained approved metadata only; commit `051c0e88613949840dc8aca32d2b14816b0181fc` added chronological rerun selection and the late-rerun regression fixture.
- decision: implemented chronological GitHub workflow-attempt selection, kept strict failure conclusions, blocked premature P0 closure, and added exact owner-gated post-merge proof.
- target: `.claude/plans/audit-live-state-verification.md`; `.github/workflows/known-gaps-live-state.yml`; `docs/operations/live-state-claims.json`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `scripts/enforcement/check-known-gaps-live-state.py`; `scripts/enforcement/fetch-known-gaps-live-state.py`; `scripts/enforcement/check-known-gaps.sh`; `scripts/enforcement/tests/test-known-gaps-live-state.sh`.

## Template/Pattern Rating Evidence

- asset: `patterns/api/README.md`
- rating: 5
- confidence: high
- outcome: stable request/response contracts shaped snapshot normalization.
- decision: retain for GitHub REST boundaries.
- asset: `patterns/security/README.md`
- rating: 5
- confidence: high
- outcome: least privilege, metadata-only artifacts, and fail-closed behavior shaped CI.
- decision: retain for token and privacy controls.
- asset: `patterns/testing/README.md`
- rating: 5
- confidence: high
- outcome: one validator now covers offline fixtures and live snapshots, including the rerun chronology regression.
- decision: retain for deterministic result loops.
- asset: `patterns/observability/README.md`
- rating: 4
- confidence: high
- outcome: exact identifiers and timestamps provide diagnostic evidence without sensitive content.
- decision: retain for live evidence design.

## Data / State Impact

Adds one metadata-only claim and ephemeral snapshots. It changes no Project 8 code, secret, provider resource, deployment, DNS, database, or production state. Only the already merged self-contained audit gap is closed; the live-state implementation gap remains open.

## Integration Impact

- A read-only workflow fetches and validates live GitHub state.
- Local known-gaps tests remain offline by default.
- Closure claims now bind exact PR/head/merge/base/workflow/check evidence.
- A late rerun of an older workflow run number can invalidate stale green evidence.
- The Project 8 experiment and prompt remain blocked.

## Validation Plan

- Python compilation of both new modules.
- `bash scripts/enforcement/tests/test-known-gaps-live-state.sh`.
- canonical known-gaps and readiness suites.
- complete enforcement and policy workflows on one exact final head.
- live snapshot artifact inspection and review-thread reconciliation.
- structured self-review, then separately authorized merge and push-to-main validation.

## Claude Run Trace

- goal: stop stale synchronized readiness claims from contradicting live GitHub truth.
- hypothesis: normalized metadata and one validator catch PR/head/merge/base/workflow drift without network-bound local tests.
- connectors: GitHub; official GitHub documentation and official GitHub/Octokit repositories.
- steps: merge PR #254; inspect `main`; research contracts; plan first; implement; run offline/live result loops; inspect artifact; fix evidence wording; fix chronological rerun selection and add regression coverage.
- evidence: PR #254 head/merge; `known-gaps-live-state` run 1; artifact `8518500199`; review threads; local full fixture output; commits through `051c0e88613949840dc8aca32d2b14816b0181fc`.
- rejected: prose parsing, network-bound local tests, run-number-only ordering, historical-green acceptance, self-only evidence, secret snapshots, and premature gap closure.
- result: implementation and local regression validation are complete; a new exact-head CI/review cycle is active and merge remains owner-gated.

## Definition of Done

- [x] Versioned minimal claim schema tied to canonical closed gaps.
- [x] Fail-closed paginated fetcher with minimal permissions and metadata-only output.
- [x] Validator for exact PR, head, merge, base containment, chronological workflow attempts, checks, and non-self evidence.
- [x] `scripts/enforcement/tests/test-known-gaps-live-state.sh` passed locally and covers merged state, stale identifiers, base divergence, failed/skipped/neutral/missing evidence, open-gap/self-only claims, malformed snapshots, and later reruns of older run numbers.
- [x] Canonical checker integration remains optional and deterministic locally.
- [x] Live run 1 succeeded and artifact `8518500199` was inspected as metadata-only.
- [x] PR #254 reconciled and `audit-self-contained-contract` synchronized as closed.
- [x] `audit-live-state-verification` remains open for its own merge/post-merge proof.
- [x] No merge API call was made for PR #255.

## Live External Gates Before Merge

PR #255 is not merge-ready until one final exact head passes all named non-self checks, every current and outdated review finding is reconciled, all threads are resolved, structured self-review is clean, the PR body identifies the exact head and runs, and Yotam gives separate explicit merge approval. After an authorized merge, the live-state workflow and post-merge validation on `main` determine whether `audit-live-state-verification` can close.

## Progress Lifecycle Evidence

- start: `f6a1dcb81ca6851a0bdaa62db90d034dd6e2bfd1` recorded scope, official research, and validation design before implementation.
- mid: commits through `c2693b2940e8d9d6e8047fbeae6381f4fdc0a9d6` implemented the claim, fetcher, validator, fixtures, workflow, canonical integration, registry, and audit; local fixtures passed.
- pre-merge: commit `051c0e88613949840dc8aca32d2b14816b0181fc` completed the workflow-rerun chronology fix and its late-rerun regression fixture after review; Python compilation and all focused local fixtures succeeded, and exact-head workflow run cycle `29892605106`–`29892605183` was triggered for validation.
