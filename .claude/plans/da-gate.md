# DA Gate

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Target paths | scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-workflow-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | not required |
| Skills | none |
| External systems/connectors | github |
| Validation gates | pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy, enforcement-tests |

## Capability Evidence

- `routing.task-router-read` checked.
- `workflow.workflow-read` checked.
- `plan.route-plan-before-write` checked.
- `source.github-repo-read` checked.
- `validation.policy-change-has-validator` checked.
- `validation.coderabbit-policy` checked.

## Connector Evidence

- github: checked repository files.

## Connector Usage Evidence

- source: github scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-workflow-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.
- action: github inspected workflow evidence gate and documentation asset gap.
- result: github selected workflow evidence gate and fixtures.
- decision: github kept documentation asset gate implementation.
- target: scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-workflow-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Documentation Asset Evidence

- internal: docs/operations/known-gaps.tsv and docs/operations/operational-readiness-audit.md checked for the open asset-selection gap.
- context7: not required for this internal enforcement change because no external library API is being implemented.
- decision: implement a Route Plan evidence gate for documentation/reference asset selection.

## Progress Lifecycle Evidence

- start: plan committed before script, test, and docs edits.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/tests/test-workflow-evidence.sh | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Claude Run Trace

- result: documentation asset gate work started.

## DoD

- [x] Plan created before edits.
