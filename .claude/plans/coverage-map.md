# Coverage Map Hardening

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | governance, readiness, coverage, ci, tests |
| Target paths | docs/operations/operational-readiness-audit.md, .github/workflows/enforcement-tests.yml, scripts/enforcement/tests/test-readiness-coverage-map.sh |
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
| docs/operations/operational-readiness-audit.md | checked |
| .github/workflows/enforcement-tests.yml | checked |

## Template Gap Waiver

reason: this is a governance coverage-map calibration and no project template applies.

## Claude Run Trace

- goal: require each readiness row to carry gate, owner, and simulation evidence.
- hypothesis: the existing audit validator is the right CI owner.
- connectors: github.
- steps: read audit, update matrix schema, update validator, add regression simulations, run CI.
- evidence: CI.
- result: pending.
