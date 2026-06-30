# Closure P1

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Target paths | scripts/enforcement/enforce-learning-capture.sh, scripts/enforcement/check-learning-quality.sh, scripts/enforcement/tests/test-learning-capture.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | not required |
| External systems/connectors | github |
| Skills | none |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy, pr-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`

## Connector Evidence

- github: checked target files before edits.

## Connector Usage Evidence

- source: github target files.
- action: inspected gate and fixtures.
- result: github showed structural checks needed stronger content and path checks.
- decision: add helper and fixture coverage.
- target: scripts/enforcement/enforce-learning-capture.sh, scripts/enforcement/check-learning-quality.sh, scripts/enforcement/tests/test-learning-capture.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

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

- goal: close closure quality gap.
- hypothesis: reusable notes need concrete content and path evidence.

## DoD

- [x] Plan created before edits.
