# RTK Blocking Readiness

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | governance, context, rtk, install, tests |
| Target paths | scripts/session-setup.sh, scripts/enforcement/tests/test-rtk-session-blocking.sh, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | shell test pattern |
| External systems/connectors | github |
| Skills | superpowers, security-review, rtk |
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
- rtk

## Source of Truth Checks

| Source | Status |
|---|---|
| CLAUDE.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| scripts/session-setup.sh | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Template Gap Waiver

reason: this is an internal governance enforcement change and no project template applies.

## Claude Run Trace

- goal: make RTK setup failures blocking.
- hypothesis: session setup is the correct enforcement point because it runs before work begins.
- connectors: github.
- steps: read current session setup, update RTK install/init handling, add tests, update audit, run CI, review, merge.
- evidence: CI.
- result: pending.
