# Context Plan

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | governance, context, tests |
| Target paths | scripts/enforcement/check-required-skills.sh, scripts/enforcement/tests/test-context-skill-selection.sh, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | shell test pattern |
| External systems/connectors | github |
| Skills | superpowers, security-review, graphify, rtk |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy |

## Capability Evidence

- routing.task-router-read
- workflow.workflow-read
- plan.route-plan-before-write
- source.github-repo-read
- validation.policy-change-has-validator
- validation.coderabbit-policy

## Connector Evidence

- github

## Skill Evidence

- superpowers
- security-review
- graphify
- rtk

## Source of Truth Checks

| Source | Status |
|---|---|
| CLAUDE.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/capability-registry.yaml | checked |
| scripts/session-setup.sh | checked |
| scripts/enforcement/check-required-skills.sh | checked |
| docs/operations/operational-readiness-audit.md | checked |
