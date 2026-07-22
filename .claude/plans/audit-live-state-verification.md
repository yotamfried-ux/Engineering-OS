# Route Plan — Live Readiness State Verification

## Route Plan

| Field | Decision |
|---|---|
| Task type | governance enforcement / GitHub live-state reconciliation / audit lifecycle update |
| Task class | `engineering_os_governance` |
| Domain tags | governance, GitHub API, CI, security, testing, documentation, operational readiness |
| Plan Scope | standard |
| Planning Mode | user-authorized gap implementation after merged PR #254; any later merge still requires exact-head validation, reconciled review, and explicit owner approval |
| Target paths | `.claude/plans/audit-live-state-verification.md`; `docs/operations/live-state-claims.json`; `scripts/enforcement/fetch-known-gaps-live-state.py`; `scripts/enforcement/check-known-gaps-live-state.py`; `scripts/enforcement/check-known-gaps.sh`; `scripts/enforcement/tests/test-known-gaps-live-state.sh`; `.github/workflows/known-gaps-live-state.yml`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md` |
| Task-router evidence | `core/task-router.md` routes canonical readiness truth, deterministic validators, CI policy, and cross-repository evidence as `engineering_os_governance`. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, and `core/coderabbit-policy.md` require plan-first work, exact live evidence, negative tests, wider suites, ready-for-review PRs, resolved review, and owner approval. |
| Templates | waiver — no project scaffold owns a focused extension of the existing known-gaps/audit enforcement path |
| Architecture guides | `docs/architecture-guides/api/rest.md`; `docs/operations/post-merge-incident-checklist.md`; `docs/operations/main-required-checks.md` |
| Patterns | `patterns/api/README.md`; `patterns/security/README.md`; `patterns/testing/README.md`; `patterns/observability/README.md` |
| External systems/connectors | GitHub |
| Skills | `security-review`; `verification-before-completion`; `writing-plans` |
| Validation gates | live-state fixtures; known-gaps suite; readiness-audit suite; enforcement-tests; known-gaps-live-state; pr-policy; workflow/connector/capability/documentation policies; cleanup policies; telemetry-handoff-tests; live review-thread inspection |
| Evidence to check | `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `scripts/enforcement/check-known-gaps.sh`; `scripts/enforcement/tests/test-known-gaps.sh`; `.github/workflows/enforcement-tests.yml`; `.github/workflows/post-merge-validation.yml`; PR #254 head `f74a26d65f6cebf06f29df1d803c192c3efb9694`; merge `c7d32a0b67a836811689d3a2bf80a63d727e1470`; official GitHub REST docs; `actions/github-script`; `octokit/rest.js`; `github/rest-api-description` |
| User decisions required | keep the Project 8 behavioral experiment and prompt blocked until every gap closes; update the canonical audit during progress; do not merge this implementation PR without a later explicit owner decision |

## Goal

Prevent `known-gaps.tsv` and the readiness audit from agreeing with each other while contradicting live GitHub state. The canonical known-gaps path validates exact PR metadata, reviewed head, merge commit, base containment, newest named workflow attempts, and exact-SHA check runs. Offline tests remain deterministic because live acquisition and snapshot validation are separate.

PR #254 is the first real reconciliation target. Its claim supports closure of `gap:audit-self-contained-contract`; `gap:audit-live-state-verification` remains open until this implementation is merged and validated on `main`.

## Non-negotiable behavior

1. `docs/operations/known-gaps.tsv` remains the only gap registry.
2. Authentication, network, API schema, pagination, permission, or normalization failures fail closed in live CI.
3. Offline regression tests use explicit fixtures and never require network access.
4. Snapshots contain metadata only: repository, PR, branch, SHAs, workflow/check identifiers, status, conclusion, timestamps, and safe URLs.
5. Stale head, unmerged PR, merge mismatch, missing base containment, skipped/neutral/failed newest run, or self-only `pr-policy` evidence fails.
6. The newest matching workflow attempt is selected deterministically.
7. Status changes require implementation, test, exact evidence, review, merge, and post-merge proof.

## Plan

1. Define a versioned claim schema.
2. Fetch and normalize documented GitHub REST resources with minimal permissions.
3. Validate claims and snapshots through one deterministic validator.
4. Invoke the validator from `check-known-gaps.sh` only when an explicit snapshot is supplied.
5. Cover positive and negative merged/head/merge/base/workflow/check/schema/status cases offline.
6. Run a named read-only workflow and preserve only a metadata snapshot.
7. Reconcile PR #254 and synchronize the registry/audit.
8. Run exact-head result loops and review; keep the implementation gap open until its own post-merge proof.

## Alternatives

- Parse free-form PR prose — rejected as ambiguous.
- Make local tests call GitHub — rejected as nondeterministic.
- Accept legacy statuses or any historical green run — rejected because Actions check/workflow attempts are exact-SHA and newer failures matter.
- Trust only `merged=true` — rejected because reviewed head, merge SHA, base containment, and named workflows are independent claims.
- Create a parallel live registry — rejected because it would drift from the canonical TSV.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `core/task-router.md` | read | This is Engineering OS governance and readiness enforcement. |
| `core/workflow.md` | read | Result loops, exact evidence, and post-merge validation apply. |
| `core/quality-gates.md` | read | Live claims require tool evidence and focused negative tests. |
| `core/git-policy.md` | read | Exact expected head, named checks, threads, and owner approval govern merge readiness. |
| `docs/operations/known-gaps.tsv` | checked | `audit-live-state-verification` is open/P0 and requires real reconciliation. |
| `docs/operations/operational-readiness-audit.md` | checked | Phase 0 requires live truth before readiness claims. |
| `scripts/enforcement/check-known-gaps.sh` | checked | Local TSV/audit synchronization lacked live GitHub reconciliation. |
| `scripts/enforcement/tests/test-known-gaps.sh` | checked | Existing fixtures did not cover PR/SHA/workflow/base drift. |
| `.github/workflows/enforcement-tests.yml` | read | Offline enforcement remains deterministic; the new live workflow is separate. |
| `.github/workflows/post-merge-validation.yml` | read | Push-to-main validation supplies a named post-merge signal. |
| `actions/github-script/README.md` | read | Official authenticated Octokit examples use `github.rest.*`, environment inputs, and retries. |
| `octokit/rest.js/README.md` | read | Official endpoint-method examples normalize documented response data. |
| `github/rest-api-description/README.md` | read | GitHub's stable OpenAPI descriptions power request validation and contract tests. |

## Official Documentation Evidence

- `https://docs.github.com/en/rest/pulls/pulls` — squash `merge_commit_sha` identifies the base-branch squash commit; bind reviewed head and merge SHA.
- `https://docs.github.com/en/rest/checks/runs` — exact-ref check runs distinguish `success`, `failure`, `neutral`, `skipped`, cancellation, and timeout.
- `https://docs.github.com/en/rest/actions/workflow-runs` — workflow runs expose exact head SHA, event, status, conclusion, run number, and attempt.
- `https://docs.github.com/en/rest/commits/commits#compare-two-commits` — compare status and merge base prove the base contains the merge.
- `https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions` — permissions are minimal and repository-controlled strings are not interpolated into executable code.

## Official Repository Evidence

- `actions/github-script` — authenticated REST client, environment-safe inputs, and retry examples informed API access.
- `octokit/rest.js` — explicit REST endpoint calls and response handling informed normalization.
- `github/rest-api-description` — stable bundled OpenAPI contracts informed field selection and validation boundaries.

## Documentation Asset Evidence

- internal: `core/task-router.md`, `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-known-gaps.sh`, `scripts/enforcement/tests/test-known-gaps.sh`, `.github/workflows/enforcement-tests.yml`, `.github/workflows/post-merge-validation.yml`.
- context7: primary official GitHub documentation and official repositories were read directly; no third-party SDK is introduced.
- decision: separate live acquisition from deterministic validation, bind exact identifiers, require base containment and newest successful non-self evidence, and store only normalized metadata.

## Template Gap Waiver

reason: this task extends an existing canonical governance validator and Actions policy; no application scaffold owns the change.

## Capability Evidence

- `routing.task-router-read` — routed as `engineering_os_governance`.
- `workflow.workflow-read` — plan-first result loops and post-merge proof applied.
- `plan.route-plan-before-write` — commit `f6a1dcb81ca6851a0bdaa62db90d034dd6e2bfd1` preceded implementation writes.
- `source.github-repo-read` — canonical files, PR #254, exact SHAs, workflows, and official repositories were inspected.
- `validation.policy-change-has-validator` — every live-state rule has positive and negative fixtures.
- `validation.actions-checked` — exact-head and dedicated live workflows remain completion gates.
- `validation.coderabbit-policy` — every valid review finding remains a completion gate.

## Skill Evidence

- `security-review` — applied to token scope, untrusted inputs, transport/API failure, privacy, artifacts, and fail-closed behavior.
- `verification-before-completion` — implementation, PR CI, live reconciliation, merge, post-merge, and closure remain separate claims.
- `writing-plans` — exact targets, alternatives, validators, and decisions were recorded first.

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Canonical files, PR #254 exact merge state, Actions policies, official GitHub/Octokit repositories, and exact-head CI/review state. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, `actions/github-script`, `octokit/rest.js`, and `github/rest-api-description`.
- action: verified and merged PR #254 with expected-head protection; inspected canonical enforcement; researched official contracts/examples; created claims, fetcher, validator, fixtures, workflow, and synchronized audit/registry updates.
- result: the branch now detects live PR/head/merge/base/workflow/check drift while local tests remain offline and deterministic.
- decision: retain the canonical TSV, metadata-only snapshot, read-only workflow, and open implementation status until this PR's own merge/post-merge proof.
- target: all Route Plan target paths listed above.

## Template/Pattern Rating Evidence

- asset: `patterns/api/README.md`; rating: 5; confidence: high; outcome: explicit request/response contracts shaped snapshot normalization; decision: retain.
- asset: `patterns/security/README.md`; rating: 5; confidence: high; outcome: least privilege, safe artifacts, and fail-closed failures shaped the workflow; decision: retain.
- asset: `patterns/testing/README.md`; rating: 5; confidence: high; outcome: one validator serves offline mismatch fixtures and live snapshots; decision: retain.
- asset: `patterns/observability/README.md`; rating: 4; confidence: high; outcome: exact identifiers provide diagnostic evidence without sensitive content; decision: retain.

## Data / State Impact

Adds one metadata-only claim file and ephemeral live snapshots. No application data, secret value, Project 8 product code, provider resource, deployment, DNS, database, or production state changes. The registry closes only the already merged self-contained audit gap; live-state verification stays open.

## Integration Impact

- A new named read-only workflow fetches and validates live GitHub state.
- `check-known-gaps.sh` stays deterministic unless an explicit snapshot is provided.
- Closed-gap evidence cannot rely only on matching Markdown/TSV prose.
- PR #254 is the first real claim.
- The Project 8 behavioral experiment remains blocked.

## Validation Plan

- `bash scripts/enforcement/tests/test-known-gaps-live-state.sh`.
- `bash scripts/enforcement/tests/test-known-gaps.sh` and `bash scripts/enforcement/check-known-gaps.sh`.
- `bash scripts/enforcement/tests/test-readiness-audit.sh` and normal readiness validation.
- full enforcement suites and named `known-gaps-live-state` workflow.
- exact-head policy checks, review-thread reconciliation, structured self-review, and post-merge validation after any separately authorized merge.

## Claude Run Trace

- goal: prevent a synchronized but stale readiness audit from asserting closure contrary to live GitHub truth.
- hypothesis: normalized live metadata plus one deterministic validator catches stale PR/head/merge/workflow claims without network-bound local tests.
- connectors: GitHub; official GitHub docs; official GitHub and Octokit repositories.
- steps: merge PR #254; verify main; research official contracts; plan first; implement claims/fetcher/validator/workflow; run local fixtures; update audit and registry.
- evidence: PR #254 head `f74a26d65f6cebf06f29df1d803c192c3efb9694`, merge `c7d32a0b67a836811689d3a2bf80a63d727e1470`, implementation commits, offline fixture output, and official sources above.
- rejected: chat tracking, prose parsing, network-bound local tests, historical-green selection, self-only evidence, secret snapshots, and premature closure.
- result: implementation and local fixture validation are complete; exact-head live CI, external review, and owner-gated merge/post-merge proof remain separate gates.

## Definition of Done

- [x] Claim schema is versioned, minimal, and tied to canonical closed gap IDs.
- [x] Fetcher paginates documented endpoints, fails closed, uses minimal read permissions, and emits metadata only.
- [x] Validator checks repository, PR, merged state, head, merge, base containment, newest workflow attempts, checks, and successful non-self evidence.
- [x] Offline fixtures cover every required positive and negative case.
- [x] Canonical `check-known-gaps.sh` invokes the validator when a snapshot is explicitly supplied.
- [ ] Dedicated exact-head live CI succeeds and its safe artifact is inspected.
- [ ] PR #254 is reconciled against live metadata and push-to-main workflows.
- [x] Registry and audit close `audit-self-contained-contract` through the exact PR #254 claim.
- [x] `audit-live-state-verification` remains open pending its own merge/post-merge proof.
- [ ] All named CI checks and review threads are reconciled and structured self-review is clean.
- [x] No merge is attempted without a later explicit owner approval.

## Progress Lifecycle Evidence

- start: commit `f6a1dcb81ca6851a0bdaa62db90d034dd6e2bfd1` recorded exact scope, official research, and validation design before implementation.
- mid: commits through `c2693b2940e8d9d6e8047fbeae6381f4fdc0a9d6` implemented the versioned claim, fail-closed fetcher, deterministic validator, offline fixtures, canonical checker integration, read-only live workflow, and synchronized registry/audit progress; all local positive and negative fixtures passed.
