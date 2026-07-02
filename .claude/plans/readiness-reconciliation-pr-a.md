# Readiness Reconciliation PR A

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task type | governance |
| Domain tags | readiness, enforcement |
| Task-router evidence | core/task-router.md checked |
| Workflow evidence | core/workflow.md checked |
| Target paths | docs/operations/operational-readiness-audit.md, docs/operations/known-gaps.tsv, .github/workflows/enforcement-tests.yml, scripts/enforcement/check-readiness-audit.sh, scripts/enforcement/check-known-gaps.sh, scripts/enforcement/tests/test-readiness-audit.sh, scripts/enforcement/tests/test-known-gaps.sh, scripts/enforcement/simulation-coverage.tsv |
| Templates | not required |
| Patterns | not required |
| Skills | none |
| External systems/connectors | github |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, documentation-asset-policy, capability-evidence-policy, plan-policy, pr-policy, semantic-cleanup-policy, import-cleanup-policy |

## Scope

PR A turns the readiness audit into a checked contract. It extracts the audit validator, links partial rows to known gaps, adds checklist checks for manual-by-design rows, restores open gap tracking, and tests the behavior.

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: repository files, pull request state, CI state, and review feedback were checked.

## Connector Selection Waiver

The plan-file fallback carries the governance spec and progress evidence for this session.

## Connector Usage Evidence

- source: github files `docs/operations/operational-readiness-audit.md`, `docs/operations/known-gaps.tsv`, `.github/workflows/enforcement-tests.yml`, `scripts/enforcement/check-readiness-audit.sh`, `scripts/enforcement/check-known-gaps.sh`, and `scripts/enforcement/tests/test-readiness-audit.sh`.
- action: checked readiness audit classification, known-gap status handling, CI results, and review feedback.
- result: partial rows lacked required non-closed gap linkage, and accepted-manual status needed audit visibility coverage.
- decision: updated the readiness validator, known-gap register contract, checklist docs, fixture tests, and accepted-manual audit visibility handling.
- target: scripts/enforcement/check-readiness-audit.sh, scripts/enforcement/tests/test-readiness-audit.sh, scripts/enforcement/check-known-gaps.sh, docs/operations/operational-readiness-audit.md, docs/operations/known-gaps.tsv, .github/workflows/enforcement-tests.yml

## Documentation Asset Evidence

- internal: `docs/operations/operational-readiness-audit.md`, `docs/operations/known-gaps.tsv`, `core/task-router.md`, `core/workflow.md`, `core/hooks-policy.md`, `scripts/enforcement/simulation-coverage.tsv`, and `scripts/enforcement/MANIFEST.tsv`.
- context7: not required for internal governance scripts and docs.
- decision: follow existing check-script plus fixture-test conventions.

## Graphify Usage Evidence

- source: graphify-out/graph.json.
- action: checked enforcement graph structure.
- result: validators and fixture tests belong under scripts/enforcement.
- decision: extracted the audit validator into scripts/enforcement with sibling tests.
- target: scripts/enforcement/check-readiness-audit.sh, scripts/enforcement/tests/test-readiness-audit.sh, .github/workflows/enforcement-tests.yml

## Template Gap Waiver

No template applies to internal governance enforcement.

## Source of Truth Checks

| Source | Status |
|---|---|
| docs/operations/operational-readiness-audit.md | checked |
| docs/operations/known-gaps.tsv | checked |
| scripts/enforcement/check-known-gaps.sh | checked |
| scripts/enforcement/check-readiness-audit.sh | checked |
| scripts/enforcement/tests/test-readiness-audit.sh | checked |
| scripts/enforcement/tests/test-known-gaps.sh | checked |
| scripts/enforcement/simulation-coverage.tsv | checked |
| .github/workflows/enforcement-tests.yml | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/hooks-policy.md | checked |

## Claude Run Trace

- goal: make readiness rows deterministically classified or gap-linked.
- hypothesis: a reusable validator enables fixture coverage for audit classification rules.
- connectors: GitHub used for file inspection, CI checks, and review feedback.
- steps: checked sources; created plan; extracted validator; rewrote audit and gaps; added checklists and fixtures; repaired accepted-manual handling after review feedback.
- evidence: validator, tests, audit, known-gaps register, checklist docs, and workflow call site changed in this branch.
- rejected: inline-only validation, unlinked partial rows, and closed-like accepted-manual handling.
- result: PR A classification contract is implemented.
- follow-up: PRs B-E handle the re-registered gaps.

## Progress Lifecycle Evidence

- start: plan committed before validator, audit, gaps, checklist, or test edits.
- mid: validator extraction, audit rewrite, gaps registration, checklists, and fixtures were recorded after implementation began.
- pre-merge: verification evidence was recorded after implementation.
- pre-merge: accepted-manual validator and fixture changes were recorded after review feedback.
- pre-merge: concrete Source of Truth table repair was recorded after CI feedback.

## DoD

- [x] Readiness validator extracted.
- [x] Audit rows classified or gap-linked.
- [x] Manual-by-design checklists added.
- [x] Known-gaps closure artifact rule added.
- [x] Accepted-manual audit visibility behavior covered by tests.
- [x] CI and review gates are the final validation record.
