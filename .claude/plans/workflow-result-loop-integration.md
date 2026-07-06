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
| Validation gates | scripts/enforcement/tests/test-route-plan-contract.sh; scripts/enforcement/check-route-plan-contract.py; enforcement-tests picks up test-route-plan-contract.sh |
| selected_project_type | waiver: Engineering OS governance maintenance, not a target-project type; route plans for target projects must choose a concrete project type |
| selected_template | waiver: Engineering OS governance maintenance is not scaffolded from a target-project template |
| selected_roadmap | waiver: docs/operations/project-type-roadmaps.md is the target-project roadmap catalog; this PR wires roadmap selection into Route Plan contract |
| selected_result_loop_contract | planned requirement via docs/operations/result-loop-contract-plan.md; full contract manifest/gate dependency is not present on main |
| required_user_simulation | scripts/enforcement/tests/test-route-plan-contract.sh positive and negative route-plan fixtures |
| local_creator_review_path | local CLI enforcement tests, no UI surface |
| telemetry_export_path | scripts/monitoring/export-telemetry-run.sh |
| evidence_redaction_rule | metadata-only telemetry; redact or exclude restricted evidence before export |
| Evidence to check | CLAUDE.md; core/workflow.md; core/task-router.md; core/capability-registry.yaml; docs/operations/result-loop-contract-plan.md; docs/operations/scaling-extension-procedure.md; docs/operations/result-loop-contract-audit-checklist.md; scripts/enforcement/check-plan-scope.sh; scripts/enforcement/check-workflow-evidence.sh |
| User decisions required | none |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| core/task-router.md | checked | Current Route Plan output lacked selected project type, selected roadmap, selected result-loop contract, simulation, local review, telemetry, and redaction fields before this PR. |
| core/workflow.md | checked | Workflow required plan/evidence before writing but did not explicitly require result evidence selection by project type before this PR. |
| core/capability-registry.yaml | checked | Selected task class is `engineering_os_governance`; required capabilities are listed below. |
| docs/operations/result-loop-contract-plan.md | checked | Result Loop Contract is documented as plan-only until deterministic manifests and gates are added. |
| docs/operations/scaling-extension-procedure.md | checked | New project types must pass through scaling extension procedure and registry-backed path. |
| scripts/enforcement/check-workflow-evidence.sh | checked | Existing PR workflow evidence checker is the correct future home for diff-wide route-plan enforcement. |

## Documentation Asset Evidence

- internal: core/task-router.md; core/workflow.md; docs/operations/result-loop-contract-plan.md; docs/operations/scaling-extension-procedure.md; docs/operations/result-loop-contract-audit-checklist.md
- context7: not required because this governance change is internal-only and does not implement or integrate any external library, framework, sdk, api, or service.
- decision: internal docs confirmed that this PR should wire route-plan selection into workflow/router and keep full gate enforcement as a separate dependency.

## Affected Surfaces

- `core/task-router.md` — add deterministic Route Plan field requirements.
- `core/workflow.md` — connect project-type route planning to result evidence before writing.
- `scripts/enforcement/check-route-plan-contract.py` — new reusable checker for Route Plan integration fields.
- `scripts/enforcement/tests/test-route-plan-contract.sh` — positive and negative fixtures.
- `docs/operations/workflow-result-loop-integration-audit.md` — audit addendum without claiming full result-loop enforcement.

## Data/State Impact

No runtime product data changes. Enforcement reads Markdown plan files and target paths only.

## Integration Impact

No external connector behavior changes. This integrates existing workflow guidance and test-backed Route Plan validation with the Result Loop path. Direct always-on PR-policy wiring and runtime hook wiring remain documented limitations rather than claimed enforcement.

## Validation Plan

- Run `python3 -m py_compile scripts/enforcement/check-route-plan-contract.py`.
- Run `bash scripts/enforcement/tests/test-route-plan-contract.sh`.
- Rely on PR CI for full enforcement-tests, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, and plan-policy.

## Open Questions

None. Full result-loop manifest/gate work remains dependent on separate Scaling Gate and Result Loop Gate PRs.

## DoD / Definition of Done

- [x] Route Plan contract fields are documented in `core/task-router.md`.
- [x] Workflow entry gate text requires result evidence selection, not only CI.
- [x] Reusable checker rejects route plans missing roadmap/contract fields for code/config/test changes.
- [x] Positive and negative fixtures cover the new checker.
- [x] Audit addendum is updated without claiming full result-loop enforcement.
- [x] PR body documents dependencies and merge readiness honestly.

## Claude Run Trace

- Read required source files on main before writing.
- Created this plan before any code/config/test changes on the branch.
- Added router/workflow docs, route-plan checker, fixture tests, and audit addendum.
- Direct always-on PR-policy wiring and runtime hook wiring are not present in this branch.
- Restored `core/workflow.md` to a focused diff after detecting that an earlier replacement removed too much existing content.
- Updated this plan after CI showed missing route-plan, capability, connector, and documentation evidence fields.

## Progress Lifecycle Evidence

- start: PR #212 merged; required planning docs exist on main; result-loop and scaling gates plus manifests are absent on main; branch scope is Route Plan field selection only.
- mid: Route Plan fields are documented in `core/task-router.md` and `core/workflow.md`; `check-route-plan-contract.py` plus `test-route-plan-contract.sh` provide positive and negative fixtures.
- pre-merge: Workflow structure is restored to a focused diff; full Result Loop Gate and Scaling Gate remain dependencies; this branch is workflow and route-plan integration rather than full contract enforcement.
- pre-merge-ci-fix: Plan-only update adds missing Architecture guides, External systems/connectors, registry-backed Capability Evidence, and Documentation Asset Evidence fields after CI identified missing plan evidence.

## Capability Evidence

- `routing.task-router-read` — selected because `core/task-router.md` was read and updated.
- `workflow.workflow-read` — selected because `core/workflow.md` was read and updated.
- `plan.route-plan-before-write` — selected because `.claude/plans/workflow-result-loop-integration.md` was created before code/config/test changes.
- `source.github-repo-read` — selected because required repo files and PR #212 state were checked through GitHub before writing.
- `validation.policy-change-has-validator` — selected because `scripts/enforcement/check-route-plan-contract.py` and `scripts/enforcement/tests/test-route-plan-contract.sh` were added.
- `validation.coderabbit-policy` — selected because PR review state was checked; no CodeRabbit review thread is open yet.

## Template Gap Waiver

This task modifies Engineering OS governance assets, not a target-project scaffold. Existing target-project template selection remains covered separately by scripts/enforcement/template-requirements.tsv and check-required-templates.py.
