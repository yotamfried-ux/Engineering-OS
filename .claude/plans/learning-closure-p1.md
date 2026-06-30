# Learning Closure P1

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | learning, closure |
| Target paths | scripts/enforcement/enforce-learning-capture.sh, scripts/enforcement/tests/test-learning-capture.sh, scripts/enforcement/simulation-coverage.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | governance validator pattern |
| External systems/connectors | github |
| Skills | none |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy, pr-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`

## Connector Evidence

- github: read learning gate, tests, known gaps, and audit before changes.

## Connector Usage Evidence

- source: github learning capture gate and learning test fixtures.
- action: inspected current validator and fixtures.
- result: github showed the gate checks headings but allows weak reusable content.
- decision: add deterministic quality checks for cause, evidence, prevention, regression path, and attempt relation.
- target: scripts/enforcement/enforce-learning-capture.sh, scripts/enforcement/tests/test-learning-capture.sh, scripts/enforcement/simulation-coverage.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Progress Lifecycle Evidence

- start: plan committed before validator changes.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/enforce-learning-capture.sh | checked |
| scripts/enforcement/tests/test-learning-capture.sh | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Claude Run Trace

- goal: close learning closure quality gap.
- hypothesis: reusable learning needs concrete cause, evidence, prevention, and regression linkage.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Current learning gate inspected.
- [x] Current learning tests inspected.
