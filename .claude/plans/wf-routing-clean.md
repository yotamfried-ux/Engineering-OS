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
Validation gates: scripts/enforcement/tests/test-route-plan-contract.sh; enforcement-tests; pr-policy; plan-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; documentation-asset-policy
Evidence to check: core/task-router.md; core/workflow.md; scripts/enforcement/result-loop-requirements.tsv; docs/operations/scaling-extension-procedure.md
User decisions required: none
selected_project_type: waiver: Engineering OS governance maintenance
selected_template: governance-maintenance waiver
selected_roadmap: docs/operations/project-type-roadmaps.md checked
selected_result_loop_contract: scripts/enforcement/result-loop-requirements.tsv checked
required_user_simulation: scripts/enforcement/tests/test-route-plan-contract.sh fixture coverage
local_creator_review_path: local CLI enforcement tests
telemetry_export_path: scripts/monitoring/export-telemetry-run.sh
evidence_redaction_rule: metadata-only evidence export
Target paths: scripts/enforcement/check-route-plan-contract.py, scripts/enforcement/tests/test-route-plan-contract.sh, docs/operations/workflow-result-loop-integration-audit.md, .claude/plans/wf-routing-clean.md

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| core/task-router.md | checked | Routing source. |
| core/workflow.md | checked | Workflow source. |

## Documentation Asset Evidence

- internal: core/task-router.md; core/workflow.md; docs/operations/result-loop-contract-plan.md.
- context7: not required because this is internal governance enforcement.
- decision: docs confirmed route-plan checker scope.

## Connector Evidence

- GitHub: used for repository reads and writes.

## Connector Usage Evidence

- source: GitHub repository yotamfried-ux/Engineering-OS.
- action: inspected PR #216 and main policy files.
- result: paths core/task-router.md, core/workflow.md, scripts/enforcement/check-workflow-evidence.sh were checked.
- decision: selected clean branch and route-plan contract target.
- target: scripts/enforcement/check-route-plan-contract.py; scripts/enforcement/tests/test-route-plan-contract.sh; docs/operations/workflow-result-loop-integration-audit.md; .claude/plans/wf-routing-clean.md

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — plan before edits.
- `source.github-repo-read` — repository files read.
- `validation.policy-change-has-validator` — validator in scope.
- `validation.coderabbit-policy` — manual review fallback.

## Claude Run Trace

- read routing and workflow sources.
- added scripts/enforcement/check-route-plan-contract.py.
- added scripts/enforcement/tests/test-route-plan-contract.sh.
- added docs/operations/workflow-result-loop-integration-audit.md.

## Progress Lifecycle Evidence

- start: core/task-router.md and core/workflow.md were checked before the first code/config/test change.
- mid: scripts/enforcement/check-route-plan-contract.py was added after the route plan established scope.
- pre-merge: route-plan checker, fixture test, and audit note were committed on the clean branch.

## DoD

- Add route-plan checker.
- Add fixture tests.
- Add audit note.
- Validate current-head CI and review threads before merge.
