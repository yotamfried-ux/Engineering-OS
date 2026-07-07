# Workflow Routing Route Plan

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | workflow, governance, routing |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Templates | governance-maintenance waiver |
| Architecture guides | governance-maintenance waiver |
| Patterns | core/task-router.md routing pattern |
| External systems/connectors | GitHub |
| Skills | not required |
| Validation gates | scripts/enforcement/tests/test-route-plan-contract.sh |
| Evidence to check | core/task-router.md; core/workflow.md; scripts/enforcement/check-route-plan-contract.sh |
| User decisions required | none |
| selected_project_type | engineering_os_governance |
| selected_template | governance-maintenance waiver |
| selected_roadmap | docs/operations/project-type-roadmaps.md |
| selected_result_loop_contract | scripts/enforcement/result-loop-requirements.tsv |
| required_user_simulation | fixture test coverage |
| local_creator_review_path | local CLI tests |
| telemetry_export_path | scripts/monitoring/export-telemetry-run.sh |
| evidence_policy_rule | metadata-only evidence export |
| Target paths | scripts/enforcement/check-route-plan-contract.sh, scripts/enforcement/tests/test-route-plan-contract.sh, docs/operations/workflow-result-loop-integration-audit.md |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| core/task-router.md | checked | Routing source. |
| core/workflow.md | checked | Workflow source. |
| scripts/enforcement/check-route-plan-contract.sh | checked | Validator target. |

## Documentation Asset Evidence

- internal: core/task-router.md; core/workflow.md; docs/operations/result-loop-contract-plan.md.
- context7: not required because this is internal governance enforcement.
- decision: docs confirmed checker scope.

## Connector Evidence

- GitHub: used for repository reads and writes.

## Connector Usage Evidence

- source: GitHub repository yotamfried-ux/Engineering-OS.
- action: GitHub inspected main policy files.
- result: GitHub checked scripts/enforcement/check-route-plan-contract.sh and core/workflow.md.
- decision: GitHub selected clean branch and checker target.
- target: scripts/enforcement/check-route-plan-contract.sh; scripts/enforcement/tests/test-route-plan-contract.sh; docs/operations/workflow-result-loop-integration-audit.md

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — plan before edits.
- `source.github-repo-read` — repository files read.
- `validation.policy-change-has-validator` — validator in scope.
- `validation.coderabbit-policy` — manual review fallback.

## Claude Run Trace

- read routing and workflow sources.
- added route-plan checker and fixture test.
- added workflow integration audit note.
- added route loop fields used by checker.
- switched route checker to shell implementation.
- fixed route field matcher for colon and table forms.

## Progress Lifecycle Evidence

- start: core/task-router.md and core/workflow.md were checked before the first code/config/test change.
- mid: route-plan checker was added after the route plan established scope.
- pre-merge: final readiness evidence recorded after matcher fix.

## DoD

- Add route-plan checker.
- Add fixture tests.
- Add audit note.