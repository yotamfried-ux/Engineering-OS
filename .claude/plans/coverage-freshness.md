# Route Plan - coverage freshness

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Target paths | scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/tests/test-simulation-coverage.sh, scripts/enforcement/simulation-coverage.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | existing simulation coverage fixture style |
| External systems/connectors | GitHub |
| Skills | none |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy, plan-policy, pr-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- GitHub: inspected `scripts/enforcement/check-simulation-coverage.sh`, `scripts/enforcement/tests/test-simulation-coverage.sh`, `scripts/enforcement/simulation-coverage.tsv`, and `docs/operations/operational-readiness-audit.md` before implementation.

## Connector Usage Evidence

- GitHub: source `scripts/enforcement/check-simulation-coverage.sh`, `scripts/enforcement/tests/test-simulation-coverage.sh`, `scripts/enforcement/simulation-coverage.tsv`, and `docs/operations/operational-readiness-audit.md`; action checked coverage row freshness; result identified stale row-text risk; decision updated the checker, fixture, manifest, and audit; target `scripts/enforcement/check-simulation-coverage.sh`, `scripts/enforcement/tests/test-simulation-coverage.sh`, `scripts/enforcement/simulation-coverage.tsv`, `docs/operations/operational-readiness-audit.md`.
- source: GitHub files `scripts/enforcement/check-simulation-coverage.sh`, `scripts/enforcement/tests/test-simulation-coverage.sh`, `scripts/enforcement/simulation-coverage.tsv`, and `docs/operations/operational-readiness-audit.md`.
- action: checked simulation coverage row freshness against current checker, test, manifest, and audit behavior.
- result: coverage rows could keep stale wording even after direct fixture coverage existed.
- decision: added checker validation, a negative test fixture, manifest row alignment, and readiness audit text for the target files.
- target: scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/tests/test-simulation-coverage.sh, scripts/enforcement/simulation-coverage.tsv, docs/operations/operational-readiness-audit.md

## Documentation Asset Evidence

- internal: `scripts/enforcement/check-simulation-coverage.sh`, `scripts/enforcement/tests/test-simulation-coverage.sh`, `scripts/enforcement/simulation-coverage.tsv`, and `docs/operations/operational-readiness-audit.md` were read.
- context7: not required because this is an internal policy, test, and audit change.
- decision: use enforcement tests and manifest validation as the source of truth for this policy change.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| core/workflow.md | checked |
| scripts/enforcement/check-simulation-coverage.sh | checked |
| scripts/enforcement/tests/test-simulation-coverage.sh | checked |
| scripts/enforcement/simulation-coverage.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Progress Lifecycle Evidence

- start: plan committed before modifying checker, tests, manifest, or audit files.
- mid: checker update recorded after implementation began.
- pre-merge: tests, manifest, and audit updates recorded after implementation.
- pre-merge: final branch review recorded after all non-plan file changes.
- pre-merge: PR #177 opened and failing evidence-policy checks were inspected; connector and documentation evidence were repaired with concrete target-file references.
- pre-merge: connector evidence was expanded with an explicit GitHub source-action-result-decision-target record.

## Claude Run Trace

- goal: harden simulation coverage freshness.
- hypothesis: row text validation keeps the manifest aligned with fixtures.
- connectors: GitHub used for source inspection, branch updates, PR creation, and CI failure analysis.
- steps: inspect checker, tests, manifest, and audit; create this plan; update checker, tests, manifest, and audit; review final branch diff; open PR #177; repair evidence fields after CI feedback.
- evidence: checker, test fixture, manifest, and audit were updated on this branch; PR #177 runs validate the policy gates.
- result: implementation complete; CI rerun pending after evidence repair.
- follow-up: run CI, address review, and merge after green checks.

## DoD

- [x] Route Plan committed before code/test/doc changes.
- [x] Checker validates coverage row text.
- [x] Test fixture covers the freshness rule.
- [x] Manifest row uses existing fixture token.
- [x] Audit records the freshness check.
- [x] PR opened; CI remains the merge gate.
