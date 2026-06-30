# Progress Lifecycle P1

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| External systems/connectors | github |
| Templates | not required |
| Patterns | not required |
| Skills | none |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy, pr-policy |
| Target paths | scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-progress-lifecycle.sh |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: checked workflow validator and progress lifecycle tests.

## Connector Usage Evidence

- source: github scripts/enforcement/check-workflow-evidence.sh and scripts/enforcement/tests/test-progress-lifecycle.sh.
- action: checked github validator and progress fixture behavior.
- result: github showed checkpoint timing needed introduction checks.
- decision: updated the validator and regression fixture.
- target: scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-progress-lifecycle.sh.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/tests/test-progress-lifecycle.sh | checked |

## Progress Lifecycle Evidence

- start: plan existed before implementation.
- mid: validator and tests were committed after implementation began.
- pre-merge: this update was committed after the latest validator and test changes.

## Claude Run Trace

- goal: close progress lifecycle timing gap.
- hypothesis: ordered plan updates are required.
- result: final plan update is after the latest validator and test changes.

## DoD

- [x] Plan created before changes.
- [x] Validator committed.
- [x] Tests committed.
- [x] Docs updated.
- [x] Final plan update committed after latest validator and test changes.
