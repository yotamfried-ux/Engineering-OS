# Route Plan Semantic Quality Gate

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | governance, workflow, plan, semantic-quality, tests |
| Target paths | scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-plan-semantic-quality.sh, docs/operations/operational-readiness-audit.md |
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

## Claude Run Trace

- goal: require source-of-truth checks to relate to the changed target paths.
- hypothesis: changed plans should not pass by citing generic sources only when target paths are concrete.
- connectors: github.
- steps: read current checker, add target/source relation check, add positive and negative tests, update audit, run CI, self-review, merge.
- evidence: CI.
- result: pending.
