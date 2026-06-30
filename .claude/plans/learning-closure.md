# Learning Closure Gate

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | governance, learning, closure, bug, debug, tests |
| Target paths | scripts/enforcement/enforce-learning-capture.sh, scripts/enforcement/tests/test-learning-capture.sh, docs/operations/operational-readiness-audit.md |
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
| scripts/enforcement/enforce-learning-capture.sh | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Template Gap Waiver

reason: this is an internal governance gate calibration and no project template applies.

## Claude Run Trace

- goal: require complete bug/debug/incident closure evidence.
- hypothesis: learning capture gate is the right enforcement point because it already owns bug/debug/incident lessons.
- connectors: github.
- steps: read current learning gate and tests, require prevention enforcement update or waiver evidence, add simulations, update audit, run CI, self-review, merge.
- evidence: CI.
- result: pending.
