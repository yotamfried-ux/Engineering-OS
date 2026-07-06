# Workflow Integration for Result Loops — Route Plan

Plan Scope: standard
Planning Mode: evidence-pass

| Field | Value |
|---|---|
| Task type | docs / governance / Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | workflow, governance, testing, observability |
| Target paths | core/task-router.md, core/workflow.md, scripts/enforcement/check-route-plan-contract.py, scripts/enforcement/tests/test-route-plan-contract.sh, docs/operations/workflow-result-loop-integration-audit.md |
| Task-router evidence | core/task-router.md read and selected as canonical routing owner |
| Workflow evidence | core/workflow.md read and selected as canonical write-entry owner |
| Templates | governance-maintenance waiver: not a target-project scaffold |
| Architecture guides | waiver: Engineering OS governance change; no target-project architecture guide applies |
| Patterns | core/workflow.md and core/task-router.md are the governing assets for this OS-maintenance change |
| External systems/connectors | not required |
| Skills | not required |
| Validation gates | scripts/enforcement/tests/test-route-plan-contract.sh; scripts/enforcement/check-route-plan-contract.py |
| selected_project_type | waiver: Engineering OS governance maintenance, not a target-project type |
| selected_template | waiver: Engineering OS governance maintenance is not scaffolded from a target-project template |
| selected_roadmap | waiver: docs/operations/project-type-roadmaps.md is the target-project roadmap catalog |
| selected_result_loop_contract | requirement via docs/operations/result-loop-contract-plan.md; full contract manifest/gate dependency is absent on main |
| required_user_simulation | scripts/enforcement/tests/test-route-plan-contract.sh fixture coverage |
| local_creator_review_path | local CLI enforcement tests, no UI surface |
| telemetry_export_path | scripts/monitoring/export-telemetry-run.sh |
| evidence_redaction_rule | metadata-only telemetry; redact or exclude restricted evidence before export |
| Evidence to check | CLAUDE.md; core/workflow.md; core/task-router.md; core/capability-registry.yaml; docs/operations/result-loop-contract-plan.md; docs/operations/scaling-extension-procedure.md; docs/operations/result-loop-contract-audit-checklist.md |
| User decisions required | none |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| core/task-router.md | checked | Route Plan output needs selected project type, roadmap, result-loop contract, simulation, local review, telemetry, and redaction fields. |
| core/workflow.md | checked | Workflow needs result evidence selection by project type. |
| core/capability-registry.yaml | checked | Selected task class is `engineering_os_governance`. |
| docs/operations/result-loop-contract-plan.md | checked | Contract work is plan-level until deterministic manifests and gates are added. |
| docs/operations/scaling-extension-procedure.md | checked | New project types require the scaling extension path. |

## Documentation Asset Evidence

- internal: core/task-router.md; core/workflow.md; docs/operations/result-loop-contract-plan.md; docs/operations/scaling-extension-procedure.md; docs/operations/result-loop-contract-audit-checklist.md
- context7: not required because this governance change is internal-only and does not implement or integrate any external library, framework, sdk, api, or service.
- decision: internal docs shaped the route-plan and workflow integration scope.

## Affected Surfaces

- `core/task-router.md`
- `core/workflow.md`
- `scripts/enforcement/check-route-plan-contract.py`
- `scripts/enforcement/tests/test-route-plan-contract.sh`
- `docs/operations/workflow-result-loop-integration-audit.md`

## Data/State Impact

No runtime product data changes.

## Integration Impact

No external connector behavior changes.

## Validation Plan

- Run `python3 -m py_compile scripts/enforcement/check-route-plan-contract.py`.
- Run `bash scripts/enforcement/tests/test-route-plan-contract.sh`.
- Rely on PR CI for enforcement-tests and policy workflows.

## Open Questions

None.

## DoD / Definition of Done

- [ ] Route Plan contract fields are documented in `core/task-router.md`.
- [ ] Workflow entry gate text requires result evidence selection, not only CI.
- [ ] Reusable checker rejects route plans missing roadmap/contract fields for code/config/test changes.
- [ ] Positive and negative fixtures cover the new checker.
- [ ] Audit addendum is updated without claiming full result-loop enforcement.
- [ ] PR body documents dependencies and merge readiness honestly.

## Claude Run Trace

- Read required source files on main before writing.
- Created this plan before any code/config/test changes on the branch.

## Progress Lifecycle Evidence

- start: PR #212 merged; required planning docs exist on main; result-loop and scaling gates plus manifests are absent on main; branch scope is Route Plan field selection only.

## Capability Evidence

- `routing.task-router-read` — selected because `core/task-router.md` was read before this plan.
- `workflow.workflow-read` — selected because `core/workflow.md` was read before this plan.
- `plan.route-plan-before-write` — selected because this plan is the first branch commit before code/config/test changes.
- `source.github-repo-read` — selected because required repo files and PR #212 state were checked through GitHub before writing.
- `validation.policy-change-has-validator` — selected because a route-plan checker and fixture test are part of the plan.
- `validation.coderabbit-policy` — selected because review state is checked before final merge readiness.

## Template Gap Waiver

This task modifies Engineering OS governance assets, not a target-project scaffold.
