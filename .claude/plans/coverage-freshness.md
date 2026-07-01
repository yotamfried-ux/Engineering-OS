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

- GitHub: inspected simulation coverage checker, tests, manifest, and readiness audit before implementation.

## Connector Usage Evidence

- source: GitHub files `scripts/enforcement/check-simulation-coverage.sh`, `scripts/enforcement/tests/test-simulation-coverage.sh`, `scripts/enforcement/simulation-coverage.tsv`, and `docs/operations/operational-readiness-audit.md`.
- action: checked the simulation coverage freshness hardening target.
- result: coverage rows can retain deferred-language after a direct fixture already exists.
- decision: added a freshness check, negative fixture, manifest alignment, and audit update.
- target: scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/tests/test-simulation-coverage.sh, scripts/enforcement/simulation-coverage.tsv, docs/operations/operational-readiness-audit.md

## Documentation Asset Evidence

- internal: `scripts/enforcement/check-simulation-coverage.sh`, `scripts/enforcement/tests/test-simulation-coverage.sh`, `scripts/enforcement/simulation-coverage.tsv`, and `docs/operations/operational-readiness-audit.md` were read.
- context7: not required because this is an internal policy, test, and audit change.
- decision: keep simulation coverage notes aligned with actual fixtures.

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
- pre-merge: PR opening evidence recorded after implementation and before CI merge decision.

## Claude Run Trace

- goal: harden simulation coverage freshness.
- hypothesis: detecting stale deferred-language in coverage rows will keep the manifest aligned with actual fixtures.
- connectors: GitHub used for source inspection and branch updates.
- steps: inspect checker, tests, manifest, and audit; create this plan; update checker, tests, manifest, and audit; prepare PR validation evidence.
- evidence: checker, test fixture, manifest, and audit were updated on this branch.
- rejected: claiming all qualitative simulation depth is solved is rejected; this loop targets row freshness only.
- result: implementation complete.
- follow-up: open PR, run CI, address review, and merge.

## DoD

- [x] Route Plan committed before code/test/doc changes.
- [x] Checker validates deferred-language coverage rows.
- [x] Test fixture covers the freshness rule.
- [x] Manifest row uses existing fixture token.
- [x] Audit records the freshness check.
- [x] PR opening evidence will be validated by PR policy and CI before merge.
