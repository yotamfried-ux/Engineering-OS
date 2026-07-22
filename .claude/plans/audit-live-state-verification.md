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
| Task-router evidence | `core/task-router.md` routes changes to canonical readiness truth, deterministic validators, CI policy, and cross-repository evidence as `engineering_os_governance`. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, and `core/coderabbit-policy.md` require plan-first work, exact live evidence, focused negative tests, wider regression suites, ready-for-review PRs, resolved findings, and owner approval before merge. |
| Templates | waiver — no project scaffold owns a focused extension of the existing known-gaps/audit enforcement path |
| Architecture guides | `docs/architecture-guides/api/rest.md`; `docs/operations/post-merge-incident-checklist.md`; `docs/operations/main-required-checks.md` |
| Patterns | `patterns/api/README.md`; `patterns/security/README.md`; `patterns/testing/README.md`; `patterns/observability/README.md` |
| External systems/connectors | GitHub |
| Skills | `security-review`; `verification-before-completion`; `writing-plans` |
| Validation gates | focused live-state fixtures; known-gaps suite; readiness-audit suite; enforcement-tests; pr-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; documentation-asset-policy; semantic-cleanup-policy; import-cleanup-policy; telemetry-handoff-tests; live review-thread inspection |
| Evidence to check | `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `scripts/enforcement/check-known-gaps.sh`; `scripts/enforcement/tests/test-known-gaps.sh`; `.github/workflows/enforcement-tests.yml`; `.github/workflows/post-merge-validation.yml`; Engineering OS PR #254 head `f74a26d65f6cebf06f29df1d803c192c3efb9694`; merge commit `c7d32a0b67a836811689d3a2bf80a63d727e1470`; official GitHub REST documentation; `actions/github-script`; `octokit/rest.js`; `github/rest-api-description` |
| User decisions required | keep the Project 8 behavioral experiment and its prompt blocked until every registered gap is closed; update the canonical audit during implementation; do not merge this implementation PR without a later explicit owner decision |

## Goal

Close the trust gap where `known-gaps.tsv` and the readiness audit can agree with each other while both contradict live GitHub state. Extend the canonical known-gaps path so a closure claim can be validated against exact pull-request metadata, exact head and merge SHAs, successful named workflow runs, and proof that the merge commit is contained by the declared base branch. Preserve deterministic offline tests by separating live metadata acquisition from snapshot validation.

The first real reconciliation target is merged Engineering OS PR #254. Its successful reconciliation provides the missing post-merge evidence needed to close `gap:audit-self-contained-contract`. This implementation gap, `gap:audit-live-state-verification`, must remain non-closed until its own implementation is merged and post-merge validated.

## Non-negotiable behavior

1. The canonical gap registry remains `docs/operations/known-gaps.tsv`; no parallel status registry is introduced.
2. Live API acquisition fails closed in CI. Authentication, network, schema, pagination, or permission failure cannot be converted into success.
3. Offline regression tests never require network access. They validate explicit JSON fixtures through the same semantic validator used for live snapshots.
4. Evidence is metadata-only: repository, PR number, branch, SHA, workflow/check identifiers, status, conclusion, timestamps, and safe URLs. Tokens, secret values, conversation text, logs, and source contents are excluded.
5. A stale head, unmerged PR, mismatched merge SHA, base branch that does not contain the merge, skipped/neutral/failed latest required workflow, or self-only `pr-policy` evidence must fail.
6. When multiple attempts or old runs exist, the validator selects the newest matching workflow attempt deterministically and requires it to be completed successfully.
7. A gap status moves only when implementation, exact evidence, review, merge, and post-merge requirements in its canonical checklist are actually satisfied.

## Plan

1. Define a small versioned claim schema for exact GitHub closure evidence.
2. Implement a safe GitHub REST fetcher that emits a normalized snapshot for each claim.
3. Implement a deterministic validator that consumes claims plus a snapshot and reports every mismatch.
4. Wire the canonical `check-known-gaps.sh` path to run live-state validation only when an explicit snapshot is supplied.
5. Add offline positive and negative fixtures for merged state, head SHA, merge SHA, base ancestry, latest workflow attempt, skipped/neutral/failure conclusions, missing non-self checks, malformed snapshots, and unknown claims.
6. Add a dedicated named GitHub Actions workflow that fetches live state with read-only permissions, validates it, and stores only the safe normalized snapshot as an artifact.
7. Reconcile PR #254 against live GitHub metadata and its push-to-main workflows.
8. Update `known-gaps.tsv` and the readiness audit in the same PR: close `audit-self-contained-contract` only if its complete merged/post-merge evidence exists; keep or advance `audit-live-state-verification` honestly according to its own closure bar.
9. Run focused tests, all enforcement tests, exact-head CI, external review, and structured self-review. Do not merge without a separate explicit owner decision.

## Alternatives

- Parse free-form PR descriptions for URLs and SHAs — rejected because prose is ambiguous and difficult to validate safely.
- Make every local known-gaps test call GitHub — rejected because network and rate limits would make deterministic development tests unreliable.
- Accept legacy commit statuses only — rejected because GitHub Actions publishes check runs/workflow runs and a successful status list can be empty while Actions checks exist.
- Trust any historical successful run — rejected because a newer failed or skipped attempt must not be hidden by an older green run.
- Use only the PR `merged` boolean — rejected because exact head, merge SHA, base containment, and required workflow outcomes are separate closure claims.
- Create a second live-gap registry — rejected because it would duplicate canonical ownership and drift from `known-gaps.tsv`.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `core/task-router.md` | read | The task changes Engineering OS governance, audit truth, CI, and deterministic validation, so the task class is `engineering_os_governance`. |
| `core/workflow.md` | read | Result loops, exact evidence, and post-merge validation are required; status updates cannot precede evidence. |
| `core/quality-gates.md` | read | Live claims require tool evidence and focused negative tests; valid failures must not be weakened. |
| `core/git-policy.md` | read | Exact expected head, named checks, review threads, and owner approval govern merge readiness. |
| `docs/operations/known-gaps.tsv` | checked | `audit-live-state-verification` is open/P0 and explicitly requires a negative fixture plus one real merged-PR reconciliation. |
| `docs/operations/operational-readiness-audit.md` | checked | Phase 0 orders self-contained audit evidence before live-state verification and requires live GitHub truth immediately before readiness claims. |
| `scripts/enforcement/check-known-gaps.sh` | checked | Current validation synchronizes the TSV and audit locally but has no live GitHub reconciliation. |
| `scripts/enforcement/tests/test-known-gaps.sh` | checked | Current fixtures cover local schema and audit drift but no PR, SHA, workflow, or base-ancestry drift. |
| `.github/workflows/enforcement-tests.yml` | read | The known-gaps suite is currently deterministic and runs repeatedly; live acquisition should remain a separate named CI boundary. |
| `.github/workflows/post-merge-validation.yml` | read | Pushes to `main` already run the full post-merge suite, giving a named push-event signal for closure claims. |
| `actions/github-script/README.md` | read | GitHub's official action exposes a pre-authenticated Octokit client, uses `github.rest.*`, recommends environment variables for untrusted values, and supports retries. |
| `octokit/rest.js/README.md` | read | The official REST client demonstrates typed endpoint-method calls and response handling. |
| `github/rest-api-description/README.md` | read | GitHub's OpenAPI descriptions are stable machine-readable API contracts used to validate requests and power contract tests. |

## Official Documentation Evidence

- Pull requests: `https://docs.github.com/en/rest/pulls/pulls`
  - After a squash merge, `merge_commit_sha` is the squashed commit on the base branch.
  - Decision: claims must bind both the reviewed PR head SHA and the resulting merge commit SHA.
- Check runs: `https://docs.github.com/en/rest/checks/runs`
  - `GET /repos/{owner}/{repo}/commits/{ref}/check-runs` reads checks for an exact SHA; completed conclusions include success, failure, neutral, skipped, cancelled, and timed out.
  - Decision: only an explicitly accepted successful conclusion can satisfy a required exact-SHA check.
- Workflow runs: `https://docs.github.com/en/rest/actions/workflow-runs`
  - Workflow runs expose `head_sha`, event, status, conclusion, run number, and attempt and can be filtered by exact head SHA.
  - Decision: the snapshot records exact event/SHA and the validator chooses the newest matching attempt.
- Commit comparison: `https://docs.github.com/en/rest/commits/commits#compare-two-commits`
  - The compare endpoint determines the relationship between a merge commit and the current base branch.
  - Decision: `identical` or base-branch `ahead` with no backward divergence proves the declared base contains the merge commit.
- GitHub Actions security hardening: `https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions`
  - Decision: no untrusted expression is interpolated into executable code, permissions are read-only and minimal, and snapshots exclude secrets.

## Official Repository Evidence

- `actions/github-script`
  - Example: its README injects an authenticated `github` client and demonstrates `github.rest.issues.*`, environment-based inputs, and retry configuration.
  - Applied decision: use the same authenticated REST semantics and avoid direct interpolation of repository-controlled strings into commands.
- `octokit/rest.js`
  - Example: `octokit.rest.repos.listForOrg({...}).then(({ data }) => ...)` demonstrates endpoint method calls and explicit response handling.
  - Applied decision: normalize only documented response fields before validation.
- `github/rest-api-description`
  - Example: GitHub publishes bundled OpenAPI descriptions and states they power request validation and contract tests.
  - Applied decision: keep the fetcher close to documented REST resources and keep the validator independent of undocumented payload fields.

## Documentation Asset Evidence

- internal: `core/task-router.md`, `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-known-gaps.sh`, `scripts/enforcement/tests/test-known-gaps.sh`, `.github/workflows/enforcement-tests.yml`, and `.github/workflows/post-merge-validation.yml`.
- context7: primary official GitHub documentation and official source repositories were read directly: `https://docs.github.com/en/rest/pulls/pulls`, `https://docs.github.com/en/rest/checks/runs`, `https://docs.github.com/en/rest/actions/workflow-runs`, `https://docs.github.com/en/rest/commits/commits`, `actions/github-script`, `octokit/rest.js`, and `github/rest-api-description`; no third-party SDK is introduced.
- decision: separate live acquisition from deterministic validation, bind claims to exact PR/head/merge/workflow data, require base-branch containment and newest successful non-self workflow evidence, and store only normalized metadata.

## Template Gap Waiver

reason: this task extends an existing canonical governance validator and GitHub Actions policy; no application or service template owns the change.

## Capability Evidence

- `routing.task-router-read` — routed as `engineering_os_governance`.
- `workflow.workflow-read` — plan-first result loops and post-merge evidence govern implementation.
- `plan.route-plan-before-write` — this Route Plan is the first branch commit before validator, workflow, registry, or audit changes.
- `source.github-repo-read` — live repository files, merged PR #254, exact SHAs, Actions policy, and official GitHub repositories were inspected.
- `validation.policy-change-has-validator` — every new live-state rule receives positive and negative deterministic fixtures.
- `validation.actions-checked` — exact-head workflows and the dedicated live-state workflow will be inspected before completion.
- `validation.coderabbit-policy` — every valid external-review finding remains a completion gate.

## Skill Evidence

- `security-review` — applied to GitHub token scope, untrusted input, API failures, snapshot privacy, artifact content, and fail-closed behavior.
- `verification-before-completion` — implementation, PR CI, live reconciliation, merge, post-merge validation, and gap closure remain separate claims.
- `writing-plans` — exact files, evidence, alternatives, tests, and owner decisions are recorded before code changes.

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Read canonical repository files, PR #254 merge state, exact head/merge SHAs, workflow policies, official GitHub/Octokit repositories, and later exact-head CI/review state. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, `actions/github-script`, `octokit/rest.js`, and `github/rest-api-description`.
- action: verified PR #254 at exact head, merged it with expected-head protection, confirmed merge commit `c7d32a0b67a836811689d3a2bf80a63d727e1470` and canonical audit presence on `main`, inspected the local known-gaps enforcement path and official implementation examples.
- result: local audit/registry synchronization is deterministic but cannot detect live PR/SHA/workflow drift; official API contracts expose every required metadata field while allowing safe normalized snapshots.
- decision: implement a versioned claim file, a fail-closed metadata fetcher, one deterministic snapshot validator, optional invocation through the canonical checker, and a dedicated read-only CI workflow.
- target: `.claude/plans/audit-live-state-verification.md`, `docs/operations/live-state-claims.json`, `scripts/enforcement/fetch-known-gaps-live-state.py`, `scripts/enforcement/check-known-gaps-live-state.py`, `scripts/enforcement/check-known-gaps.sh`, `scripts/enforcement/tests/test-known-gaps-live-state.sh`, `.github/workflows/known-gaps-live-state.yml`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.

## Template/Pattern Rating Evidence

- asset: `patterns/api/README.md`; rating: 5; confidence: high; outcome: explicit request/response contracts and stable schemas shape the normalized snapshot boundary; decision: retain.
- asset: `patterns/security/README.md`; rating: 5; confidence: high; outcome: least-privilege token use, fail-closed errors, safe artifacts, and untrusted-input separation are mandatory; decision: retain.
- asset: `patterns/testing/README.md`; rating: 5; confidence: high; outcome: offline fixtures cover every live mismatch while CI supplies one real reconciliation; decision: retain.
- asset: `patterns/observability/README.md`; rating: 4; confidence: high; outcome: the snapshot records exact identifiers and outcomes needed to diagnose drift without collecting sensitive content; decision: retain.

## Data / State Impact

Adds a versioned metadata-only claim file and ephemeral/generated live snapshots. No application data, secret value, provider resource, Project 8 product code, deployment, DNS, database, or production state is changed. The only durable status mutations are synchronized updates to the canonical known-gaps registry and readiness audit after exact evidence exists.

## Integration Impact

- GitHub Actions receives a new named read-only live-state check.
- `check-known-gaps.sh` remains deterministic by default and validates live state only when explicitly given a snapshot.
- Closed-gap evidence can no longer rely solely on matching Markdown/TSV prose.
- PR #254 becomes the first real positive reconciliation fixture.
- The Project 8 behavioral experiment remains blocked; this work only increases readiness-truth reliability.

## Validation Plan

- `python3 scripts/enforcement/check-known-gaps-live-state.py --claims <fixture> --snapshot <fixture>` for focused positive and negative fixtures.
- `bash scripts/enforcement/tests/test-known-gaps-live-state.sh`.
- `bash scripts/enforcement/tests/test-known-gaps.sh`.
- `bash scripts/enforcement/check-known-gaps.sh`.
- `bash scripts/enforcement/check-readiness-audit.sh`.
- `bash scripts/enforcement/tests/test-readiness-audit.sh`.
- `bash scripts/enforcement/run-all-tests.sh`.
- dedicated `known-gaps-live-state` workflow against the exact PR head.
- exact-head non-self policy checks, review-thread reconciliation, and structured self-review.
- after any authorized merge: push-to-main live-state and post-merge validation before closing `audit-live-state-verification`.

## Claude Run Trace

- goal: prevent a synchronized but stale readiness audit from asserting closure contrary to live GitHub truth.
- hypothesis: normalized live metadata plus one shared deterministic validator will catch stale PR/head/merge/workflow claims without making local tests network-dependent.
- connectors: GitHub; primary official GitHub documentation; official GitHub and Octokit source repositories.
- steps: merge validated PR #254; confirm canonical files on main; inspect known-gaps and post-merge paths; research official APIs/repos; create this plan; implement claims/fetcher/validator/workflow; run offline and live result loops; update audit and registry only from evidence.
- evidence: PR #254 head `f74a26d65f6cebf06f29df1d803c192c3efb9694`, merge commit `c7d32a0b67a836811689d3a2bf80a63d727e1470`, exact main files, official endpoint contracts, and official repository examples named above.
- rejected: chat-only tracking, free-form evidence parsing, network-bound local tests, legacy-status-only checks, historical-green selection, self-only PR policy evidence, secret-bearing snapshots, and status closure before merge/post-merge proof.
- result: implementation has not started; the exact branch scope and evidence contract are now committed first.

## Definition of Done

- [ ] Claim schema is versioned, minimal, and tied to canonical gap IDs.
- [ ] Fetcher paginates required endpoints, fails closed, uses minimal read permissions, and emits no secrets or content.
- [ ] Validator checks repository, PR number, merged/state, head SHA, merge SHA, base branch containment, newest required workflow attempts, and at least one successful non-self workflow.
- [ ] Offline fixtures cover every required positive and negative case.
- [ ] Canonical `check-known-gaps.sh` invokes the same validator when a snapshot is explicitly supplied.
- [ ] Dedicated exact-head CI live check succeeds and preserves only a safe snapshot artifact.
- [ ] PR #254 is reconciled against live metadata and push-to-main workflows.
- [ ] `audit-self-contained-contract` is closed only after complete merged/post-merge evidence; registry and audit remain synchronized.
- [ ] `audit-live-state-verification` status reflects its own implementation/merge/post-merge truth without premature closure.
- [ ] All named CI checks pass on the final exact head, all review threads are resolved, and structured self-review finds no remaining correctness, security, or scope defect.
- [ ] No merge occurs without a later explicit owner approval.

## Progress Lifecycle Evidence

- start: merged PR #254 only after exact-head CI and seven resolved threads, confirmed merge commit `c7d32a0b67a836811689d3a2bf80a63d727e1470` and audit presence on `main`, inspected the canonical local enforcement path, researched official GitHub REST contracts plus `actions/github-script`, `octokit/rest.js`, and `github/rest-api-description`, created branch `feat/audit-live-state-verification`, and committed this Route Plan before implementation changes.
