# Z

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Target paths | docs/operations/ |
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

- source: github repository files.
- action: github inspected docs.
- result: github selected doc update.
- decision: github kept doc update.
- target: docs/operations/.

## Progress Lifecycle Evidence

- start: plan before docs.
- pre-merge: evidence completed after status docs update.

## Source of Truth Checks

| Source | Status |
|---|---|
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Claude Run Trace

- result: status docs updated.

## DoD

- [x] Plan created.
- [x] Status docs updated.
- [x] Evidence completed.
