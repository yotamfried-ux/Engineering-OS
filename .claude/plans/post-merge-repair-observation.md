# Post Merge Repair Observation

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Target paths | scripts/enforcement/tests/test-post-merge-validation-contract.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
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

- source: github post-merge workflow, contract test, known gaps, and audit files.
- action: github inspected current validation contract and open gap.
- result: github selected safe fake-gh simulation evidence.
- decision: github will update only test and readiness status files.
- target: scripts/enforcement/tests/test-post-merge-validation-contract.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Documentation Asset Evidence

- internal: .github/workflows/post-merge-validation.yml, scripts/enforcement/check-post-merge-validation-contract.sh, scripts/enforcement/tests/test-post-merge-validation-contract.sh, and docs/operations/known-gaps.tsv checked.
- context7: not required because this is internal shell and workflow contract enforcement.
- decision: add deterministic safe simulation evidence for the post-merge failure path.

## Progress Lifecycle Evidence

- start: plan before test and docs edits.

## Source of Truth Checks

| Source | Status |
|---|---|
| .github/workflows/post-merge-validation.yml | checked |
| scripts/enforcement/check-post-merge-validation-contract.sh | checked |
| scripts/enforcement/tests/test-post-merge-validation-contract.sh | checked |
| docs/operations/known-gaps.tsv | checked |

## Claude Run Trace

- result: post-merge repair observation work started.

## DoD

- [x] Plan created before edits.
