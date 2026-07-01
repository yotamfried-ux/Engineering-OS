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

- source: github .github/workflows/post-merge-validation.yml, scripts/enforcement/check-post-merge-validation-contract.sh, scripts/enforcement/tests/test-post-merge-validation-contract.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.
- action: github inspected current validation contract and open gap.
- result: github selected safe fake-gh simulation evidence.
- decision: github updated the test fixture and readiness status files.
- target: scripts/enforcement/tests/test-post-merge-validation-contract.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Documentation Asset Evidence

- internal: .github/workflows/post-merge-validation.yml, scripts/enforcement/check-post-merge-validation-contract.sh, scripts/enforcement/tests/test-post-merge-validation-contract.sh, docs/operations/known-gaps.tsv, and docs/operations/operational-readiness-audit.md checked.
- context7: not required because this is internal shell and workflow contract enforcement.
- decision: add deterministic safe simulation evidence for the post-merge failure path.

## Progress Lifecycle Evidence

- start: plan before test and docs edits.
- mid: safe fake-gh simulation selected after source inspection.
- mid: simulation test and readiness docs were added after implementation began.
- pre-merge: final checkpoint after simulation test and readiness docs updates.
- pre-merge: evidence paths tightened after CI reported plan evidence gaps.
- pre-merge: final checkpoint refreshed after mid lifecycle correction.
- pre-merge: final CI trigger checkpoint after ordered lifecycle repair.

## Source of Truth Checks

| Source | Status |
|---|---|
| .github/workflows/post-merge-validation.yml | checked |
| scripts/enforcement/check-post-merge-validation-contract.sh | checked |
| scripts/enforcement/tests/test-post-merge-validation-contract.sh | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Claude Run Trace

- result: post-merge repair observation work completed for PR validation.

## DoD

- [x] Plan created before edits.
- [x] Mid checkpoint recorded.
- [x] Safe simulation added.
- [x] Known gaps and audit synced.
- [x] Pre-merge checkpoint recorded.
- [x] Evidence paths tightened.
- [x] Mid checkpoint refreshed after implementation.
- [x] Final checkpoint refreshed after mid correction.
- [x] Final CI trigger checkpoint recorded.
