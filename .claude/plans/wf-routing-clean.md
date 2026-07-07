# Workflow Routing Clean Route Plan

Task type: Engineering OS maintenance
Task class: engineering_os_governance
Domain tags: workflow, governance, routing
Plan Scope: standard
Planning Mode: approved
Task-router evidence: core/task-router.md read
Workflow evidence: core/workflow.md read
Templates: governance-maintenance waiver
Architecture guides: governance-maintenance waiver
Patterns: core/task-router.md routing pattern
External systems/connectors: GitHub
Skills: not required
Validation gates: scripts/enforcement/tests/test-route-plan-contract.sh
Evidence to check: core/task-router.md; core/workflow.md
User decisions required: none

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| core/task-router.md | checked | Routing source. |
| core/workflow.md | checked | Workflow source. |

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — plan before edits.
- `source.github-repo-read` — repository files read.
- `validation.policy-change-has-validator` — validator in scope.
- `validation.coderabbit-policy` — manual review fallback.

## Claude Run Trace

- read routing and workflow sources.

## Progress Lifecycle Evidence

- start: core/task-router.md and core/workflow.md were checked before the first code/config/test change.

## DoD

- Add route-plan checker.
- Add fixture tests.
- Update task router.
- Add audit note.
