# Readiness Reconciliation — PR A (audit truth + validator hardening)

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task type | docs / governance / Engineering OS maintenance |
| Domain tags | governance, readiness, enforcement |
| Task-router evidence | core/task-router.md read; routed via routing_matrix section 7 (Engineering OS maintenance / governance) |
| Workflow evidence | core/workflow.md read; stages 1-4 completed before writing; plan-file fallback used because Notion is unavailable |
| Target paths | docs/operations/operational-readiness-audit.md, docs/operations/known-gaps.tsv, docs/operations/memory-context-checklist.md, docs/operations/merge-readiness-checklist.md, docs/operations/post-merge-incident-checklist.md, docs/operations/documentation-ownership.tsv, .github/workflows/enforcement-tests.yml, scripts/enforcement/check-readiness-audit.sh, scripts/enforcement/check-known-gaps.sh, scripts/enforcement/simulation-coverage.tsv, scripts/enforcement/tests/test-readiness-audit.sh, scripts/enforcement/tests/test-known-gaps.sh, scripts/enforcement, .github/workflows, docs/operations |
| Templates | not required |
| Patterns | not required |
| Skills | none |
| External systems/connectors | github |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, documentation-asset-policy, capability-evidence-policy, plan-policy, pr-policy, semantic-cleanup-policy, import-cleanup-policy |

## Scope

Make the operational-readiness audit incapable of holding an unclassified partial row:

1. Extract the inline readiness-audit validator from `.github/workflows/enforcement-tests.yml` into `scripts/enforcement/check-readiness-audit.sh` (behavior-preserving, then strengthened) so it is fixture-testable.
2. Strengthen it: add `Manual by design` status; `Partially enforced` / `Missing enforcement` matrix rows must carry `gap:<gap_id>` cross-checked against a non-closed row in `docs/operations/known-gaps.tsv`; `Manual by design` rows must name an existing `Checklist:` doc; ban deferred tokens (todo, tbd, pending, not yet, future loop) in matrix rows without a gap link; plain `Manual` becomes invalid inside the matrix.
3. Reclassify all 31 audit rows: enforced rows get explicit by-design residual wording; partial rows get gap links; memory/context and merge safety become `Manual by design` with new checklist docs.
4. Re-add 13 official open gaps to `docs/operations/known-gaps.tsv` and mirror them in the audit freshness ledger.
5. Strengthen `check-known-gaps.sh`: a `closed` gap requires concrete test and evidence artifacts (not NONE).
6. New checklist docs: memory-context, merge-readiness, post-merge-incident; register them in `docs/operations/documentation-ownership.tsv`.
7. New `tests/test-readiness-audit.sh` fixtures (positive, missing gap link, closed-gap link, plain Manual, missing checklist, deferred token, missing required row); extend `tests/test-known-gaps.sh` with closed-gap artifact negatives; point the `readiness-audit` simulation-coverage row at the new script/test.

## Alternatives

- Extend the inline workflow python instead of extracting a script — rejected: inline CI python cannot be fixture-tested, so negative classification cases would stay unproven.
- Reclassify rows without re-registering gaps — rejected: partial rows would again be terminal free-text states, which is the exact failure PR A removes.
- Edit core/documentation-policy.md for the contradiction-review bullet — rejected for PR A: MANIFEST md-sync requires a same-commit enforcer change; the review guidance lives in the audit row text instead.
- Ban all judgment wording in the audit — rejected: only deterministic deferred tokens are banned; review-based-by-design wording stays legitimate.

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read this session before any write.
- `workflow.workflow-read` — core/workflow.md read this session before any write.
- `plan.route-plan-before-write` — this plan is committed before the first code/config/test change.
- `source.github-repo-read` — GitHub MCP get_me + list_pull_requests run against yotamfried-ux/Engineering-OS (no open PRs for this branch).
- `validation.policy-change-has-validator` — the audit-classification policy gains a dedicated validator (`check-readiness-audit.sh`) plus fixture tests in this same PR.
- `validation.coderabbit-policy` — change ships as a PR from a dedicated branch per core/coderabbit-policy.md; review evidence recorded in the PR body; merge only on explicit user approval.

## Connector Evidence

- github: read repository state via GitHub MCP (get_me, list_pull_requests for yotamfried-ux/Engineering-OS) and repository files for the audit, gaps register, validators, and workflows.

## Connector Selection Waiver

Notion is required for governance-class work by connector policy, but the Notion MCP connector is unavailable in this remote session environment; the approved fallback from core/workflow.md stage 1 applies — this plan file under .claude/plans/ carries the spec and progress validation instead.

## Connector Usage Evidence

- source: github repository yotamfried-ux/Engineering-OS — docs/operations/operational-readiness-audit.md, docs/operations/known-gaps.tsv, .github/workflows/enforcement-tests.yml, scripts/enforcement/check-known-gaps.sh.
- action: github state read via MCP get_me and list_pull_requests (confirmed zero open PRs so PR A is not superseding an open PR), plus repository file inspection of the audit validator and gaps register.
- result: github inspection found the validator at .github/workflows/enforcement-tests.yml accepts Partially enforced rows with no gap linkage, and docs/operations/known-gaps.tsv holds 12 closed rows with no open tracking for the remaining partial areas.
- decision: github findings selected the PR A shape — extracted validator scripts/enforcement/check-readiness-audit.sh with gap-link enforcement, 13 re-added open gaps, and strengthened closed-gap artifact checks in scripts/enforcement/check-known-gaps.sh.
- target: docs/operations/operational-readiness-audit.md, docs/operations/known-gaps.tsv, scripts/enforcement/check-readiness-audit.sh, scripts/enforcement/check-known-gaps.sh, scripts/enforcement/tests/test-readiness-audit.sh, .github/workflows/enforcement-tests.yml.

## Documentation Asset Evidence

- internal: docs/operations/operational-readiness-audit.md, docs/operations/known-gaps.tsv, core/task-router.md, core/workflow.md, core/hooks-policy.md, scripts/enforcement/coverage-required-gates.tsv, scripts/enforcement/simulation-coverage.tsv, scripts/enforcement/MANIFEST.tsv.
- context7: not required because this change edits internal Engineering OS governance enforcement (bash/python validators and markdown/TSV registers) and does not implement or integrate any external library, framework, SDK, or API.
- decision: the audit's own readiness definition and the existing validator conventions (check-*.sh plus tests/test-*.sh fixtures, TSV manifests) fixed the implementation shape: extract-then-strengthen the audit validator instead of extending inline workflow python, and reuse the known-gaps ledger cross-check pattern for gap links.

## Graphify Usage Evidence

- source: graphify query over graphify-out/graph.json for the enforcement gate wiring (check/enforce scripts, tests, coverage manifests).
- action: graphify query "enforcement gates and coverage manifests" oriented the dependency map before file reads.
- result: the graph surfaced enforce-tests.sh and the tests community as the callers/owners of the gate wiring, confirming validators live in scripts/enforcement with sibling fixture tests rather than inline CI python.
- decision: graph finding selected the extract-to-script approach for the readiness validator and informed which test files the new fixtures join; it scoped the write set to scripts/enforcement, its tests, the workflows dir, and docs/operations.
- target: scripts/enforcement, scripts/enforcement/tests, .github/workflows, docs/operations

## Template Gap Waiver

No project template applies: this is internal governance/enforcement maintenance inside Engineering OS itself, not a scaffolded project type; templates/ entries cover application project scaffolds and are out of scope for audit-register and validator edits.

## Source of Truth Checks

| Source | Status |
|---|---|
| docs/operations/operational-readiness-audit.md | checked |
| docs/operations/known-gaps.tsv | checked |
| scripts/enforcement/check-known-gaps.sh | checked |
| .github/workflows/enforcement-tests.yml | checked |
| scripts/enforcement/simulation-coverage.tsv | checked |
| scripts/enforcement/tests/test-known-gaps.sh | checked |
| scripts/enforcement/tests/test-readiness-coverage-map.sh | checked |
| docs/operations/documentation-ownership.tsv | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/hooks-policy.md | checked |

## Claude Run Trace

- goal: make every operational-readiness audit row deterministically classified — Enforced, Manual by design with checklist, Waiver-gated, or gap-linked — with a validator that fails CI on unclassified partial rows.
- hypothesis: extracting the inline workflow validator into a parameterized script allows fixture tests for gap-link and checklist rules without weakening any existing check.
- connectors: github via MCP (get_me, list_pull_requests) confirmed repo state and zero open PRs before branching work.
- steps: graphify orientation, gate-by-gate inspection of check/enforce scripts and manifests, reconciliation table for all 31 rows, then validator extraction, audit rewrite, gaps re-registration, checklist docs, fixtures.
- evidence: enforcement-tests.yml lines 139-161 accept Partially enforced without gap linkage; known-gaps.tsv has 12 closed rows and no open rows; 10 waived simulation cells inventoried.
- rejected: editing core/documentation-policy.md for the contradiction-review bullet was rejected in PR A because MANIFEST md-sync would force a same-commit enforcer change; the review guidance lives in the audit row text instead. Also rejected: banning all judgment wording — only deterministic deferred tokens are banned.
- result: PR A ships the classification contract; selection-coverage, trace/simulation, governance, and install-depth hardening follow in PRs B-E per the approved reconciliation plan.
- follow-up: PRs B-E close the 13 re-registered gaps; each flips its audit rows and gap statuses with closure artifacts.

## Progress Lifecycle Evidence

- start: plan committed on claude/engineering-os-readiness-audit-xt362m before any validator, audit, gaps, checklist, or test edits.
- mid: validator extraction, audit reclassification, 13 re-registered gaps, checklists, and fixtures landed in commit 535140a; targeted gates re-ran green after implementation began.

## DoD

- check-readiness-audit.sh extracted and strengthened; enforcement-tests.yml calls it.
- Audit matrix reclassified: no plain Manual rows; partial rows gap-linked; Manual by design rows name existing checklists.
- known-gaps.tsv carries 13 open gaps mirrored in the audit ledger; check-known-gaps.sh requires artifacts for closed gaps.
- New fixtures pass: test-readiness-audit.sh (positive plus six negatives), test-known-gaps.sh closed-gap negatives.
- Full local enforcement test suite passes with no existing test weakened or removed.
- Draft PR opened with review evidence; merge deferred to explicit user approval.

## Completed Work

- Reconciliation table for all 31 audit rows produced and approved (see repository plan for PR A scope).

## Remaining Validation Outside This Plan

- PRs B-E implement selection-coverage, trace/simulation/test-contract, manual-by-design governance evidence, and install-depth hardening; each carries its own route plan and closes its registered gaps.
