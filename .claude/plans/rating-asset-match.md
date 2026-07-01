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

- GitHub: inspected known gap rows, audit rows, checker, and fixture tests before implementation.

## Connector Usage Evidence

- source: GitHub files `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-workflow-evidence.sh`, and `scripts/enforcement/tests/test-template-pattern-rating-evidence.sh`.
- action: checked rating evidence enforcement.
- result: rating evidence fields existed without asset linkage.
- decision: implemented asset-match enforcement.
- target: scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-template-pattern-rating-evidence.sh

## Documentation Asset Evidence

- internal: target files and readiness gap rows were read.
- context7: not required for internal enforcement.
- decision: strengthen structural rating evidence.

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
- mid: checker updated after implementation began.

## Claude Run Trace

- goal: strengthen template/pattern rating lifecycle.
- hypothesis: rating evidence should cite the declared reusable asset.
- connectors: GitHub used for source inspection and branch updates.
- steps: inspect sources, commit plan, update checker.
- evidence: checker now compares declared reusable assets with rating evidence asset.
- rejected: score accuracy remains reviewer based.
- result: checker update complete; fixture update pending.
- follow-up: add negative fixture, run CI, and merge only after green checks.

## DoD

- [x] Route Plan committed before code/test changes.
- [x] Checker requires rating evidence asset linkage.
- [ ] Fixture includes wrong-asset negative case.
- [ ] PR opened and CI green before merge.
