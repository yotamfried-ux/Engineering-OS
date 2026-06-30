# Progress Lifecycle Gate

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | governance, workflow, progress, checkpoints, tests |
| Target paths | scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-progress-lifecycle.sh, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | shell test pattern |
| External systems/connectors | github |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github

## Skill Evidence

- superpowers
- security-review

## Source of Truth Checks

| Source | Status |
|---|---|
| CLAUDE.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| scripts/enforcement/check-workflow-evidence.sh | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Template Gap Waiver

reason: this is an internal governance gate calibration and no project template applies.

## Progress Lifecycle Evidence

- start: plan created before changing code.
- mid: CI/simulation loop will validate the checker and tests.
- pre-merge: final PR checks, review threads, expected head SHA, and CI will be verified before merge.

## Claude Run Trace

- goal: require start, mid, and pre-merge progress checkpoint evidence for non-trivial code/config/test changes.
- hypothesis: workflow evidence gate is the correct CI owner because it already validates plan quality for changed code.
- connectors: github.
- steps: read current workflow checker, add progress lifecycle section requirement, add simulations, update audit, run CI, self-review, merge.
- evidence: CI.
- result: pending.
