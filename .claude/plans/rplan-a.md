# RPlan A

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Target paths | scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-plan-semantic-quality.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
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

- source: github scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-plan-semantic-quality.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.
- action: github inspected route quality gate and gap row.
- result: github found source checks still allow generic directory evidence.
- decision: github selected workflow evidence gate and fixtures for update.
- target: scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-plan-semantic-quality.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Progress Lifecycle Evidence

- start: plan committed before script, test, gap, and audit edits.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/tests/test-plan-semantic-quality.sh | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Claude Run Trace

- result: route quality closure started.

## DoD

- [x] Plan created before edits.
