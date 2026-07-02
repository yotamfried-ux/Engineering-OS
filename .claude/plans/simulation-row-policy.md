# Route Plan - simulation row policy

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

- GitHub: inspected the checker, test, manifest, and audit files.

## Connector Usage Evidence

- source: GitHub files for checker, test, manifest, and audit.
- action: GitHub checked the coverage policy files.
- result: GitHub evidence showed the manifest row rule needed stronger validation.
- decision: updated the checker, test, manifest, and audit.
- target: scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/tests/test-simulation-coverage.sh, scripts/enforcement/simulation-coverage.tsv, docs/operations/operational-readiness-audit.md

## Documentation Asset Evidence

- internal: `scripts/enforcement/check-simulation-coverage.sh`, `scripts/enforcement/tests/test-simulation-coverage.sh`, `scripts/enforcement/simulation-coverage.tsv`, and `docs/operations/operational-readiness-audit.md` were read.
- context7: not required because this is an internal policy, test, and audit change.
- decision: use enforcement tests and manifest validation as the source of truth.

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

## Claude Run Trace

- goal: harden simulation coverage row policy.
- hypothesis: row text validation keeps the manifest aligned with fixtures.
- connectors: GitHub used for source inspection and branch updates.
- steps: inspect files; create plan before implementation.
- evidence: implementation pending.
- result: pending implementation.
- follow-up: update checker, tests, manifest, audit, open PR, run CI, and merge after green checks.

## DoD

- [x] Route Plan committed before code/test/doc changes.
- [ ] Checker validates coverage row text.
- [ ] Test fixture covers the rule.
- [ ] Manifest row uses existing fixture token.
- [ ] Audit records the check.
- [ ] PR opened and all checks are green.
