# Route Plan - rating asset match

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Target paths | scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-template-pattern-rating-evidence.sh |
| Templates | not required |
| Patterns | existing workflow evidence fixture style |
| External systems/connectors | GitHub |
| Skills | none |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy, pr-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- GitHub: inspected known gap rows, audit rows, the workflow evidence checker, and rating fixture tests before implementation.

## Connector Usage Evidence

- source: GitHub files `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-workflow-evidence.sh`, and `scripts/enforcement/tests/test-template-pattern-rating-evidence.sh`.
- action: checked current rating evidence enforcement for declared template or pattern assets.
- result: the checker requires rating fields but does not require the rated asset to match the declared reusable asset.
- decision: implement asset-match enforcement and a wrong-asset negative fixture.
- target: scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-template-pattern-rating-evidence.sh

## Documentation Asset Evidence

- internal: target files and readiness gap rows were read.
- context7: not required because this is an internal enforcement change.
- decision: strengthen deterministic structural rating evidence.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| core/workflow.md | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/tests/test-template-pattern-rating-evidence.sh | checked |

## Progress Lifecycle Evidence

- start: plan committed before modifying workflow evidence enforcement or rating evidence fixtures.

## Claude Run Trace

- goal: strengthen template/pattern rating lifecycle.
- hypothesis: rating evidence should cite the same declared reusable asset instead of any unrelated asset.
- connectors: GitHub used for source inspection and branch updates.
- steps: inspect gap rows, audit row, checker, and fixture coverage; then commit this plan before implementation.
- evidence: pending implementation and CI.
- rejected: claiming semantic score quality is solved is rejected; this only strengthens asset linkage.
- result: pending implementation.
- follow-up: run CI and merge only after green checks and review evidence.

## DoD

- [x] Route Plan committed before code/test changes.
- [ ] Checker requires rating evidence asset to match a declared reusable asset.
- [ ] Fixture includes wrong-asset negative case.
- [ ] PR opened and CI green before merge.
