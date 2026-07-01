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

- GitHub: inspected target files before implementation.

## Connector Usage Evidence

- source: GitHub files for checker, test, manifest, and audit.
- action: checked coverage hardening target.
- result: coverage rows needed stronger validation.
- decision: added checker, tests, manifest alignment, and audit update.
- target: scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/tests/test-simulation-coverage.sh, scripts/enforcement/simulation-coverage.tsv, docs/operations/operational-readiness-audit.md

## Documentation Asset Evidence

- internal: target files were read.
- context7: not required for an internal policy change.
- decision: use enforcement tests as validation source.

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

- start: plan committed before implementation files changed.
- mid: checker update recorded after implementation began.
- pre-merge: test, manifest, audit, and branch review were recorded after implementation.

## Claude Run Trace

- goal: harden simulation coverage freshness.
- hypothesis: row text validation keeps the manifest aligned with fixtures.
- connectors: GitHub used for source inspection and branch updates.
- steps: inspect targets; create plan; update checker, tests, manifest, and audit; review branch.
- evidence: checker, test fixture, manifest, and audit were updated.
- result: implementation complete.
- follow-up: open PR, run CI, address review, and merge.

## DoD

- [x] Route Plan committed before code/test/doc changes.
- [x] Checker validates coverage row text.
- [x] Test fixture covers the freshness rule.
- [x] Manifest row uses existing fixture token.
- [x] Audit records the freshness check.
- [x] PR policy will validate review evidence before merge.
