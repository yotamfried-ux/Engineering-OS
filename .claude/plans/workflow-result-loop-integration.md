# Workflow Integration for Result Loops — Route Plan

Plan Scope: standard
Planning Mode: evidence-pass

| Field | Value |
|---|---|
| Task type | docs / governance / Engineering OS maintenance |
| Task class | governance-maintenance |
| Domain tags | workflow, governance, testing, observability |
| Target paths | core/task-router.md, core/workflow.md, scripts/enforcement/check-route-plan-contract.py, scripts/enforcement/tests/test-route-plan-contract.sh, docs/operations/workflow-result-loop-integration-audit.md |
| Task-router evidence | core/task-router.md read and selected as canonical routing owner |
| Workflow evidence | core/workflow.md read and selected as canonical write-entry owner |
| Templates | governance-maintenance waiver: not a target-project scaffold |
| Patterns | core/workflow.md and core/task-router.md are the governing assets for this OS-maintenance change |
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
| Evidence to check | CLAUDE.md; core/workflow.md; core/task-router.md; docs/operations/result-loop-contract-plan.md; docs/operations/scaling-extension-procedure.md; docs/operations/result-loop-contract-audit-checklist.md; scripts/enforcement/check-plan-scope.sh; scripts/enforcement/check-workflow-evidence.sh |
| User decisions required | none |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| core/task-router.md | checked | Current Route Plan output lacked selected project type, selected roadmap, selected result-loop contract, simulation, local review, telemetry, and redaction fields before this PR. |
| core/workflow.md | checked | Workflow required plan/evidence before writing but did not explicitly require result evidence selection by project type before this PR. |
| docs/operations/result-loop-contract-plan.md | checked | Result Loop Contract is documented as plan-only until deterministic manifests and gates are added. |
| docs/operations/scaling-extension-procedure.md | checked | New project types must pass through scaling extension procedure and registry-backed path. |
| scripts/enforcement/check-workflow-evidence.sh | checked | Existing PR workflow evidence checker is the correct future home for diff-wide route-plan enforcement. |

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
- Rely on PR CI for full enforcement-tests, workflow-evidence-policy, and plan-policy.

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

## Progress Lifecycle Evidence

- start: PR #212 merged; required planning docs exist on main, but result-loop/scaling gates and manifests are not present. This branch will enforce Route Plan field selection only and document full gate dependency.
- mid: Route Plan fields are now documented in `core/task-router.md` and `core/workflow.md`; `check-route-plan-contract.py` plus `test-route-plan-contract.sh` provide positive/negative fixtures. Direct always-on PR-policy wiring is still not present.
- pre-merge: Final cleanup restored workflow structure to a focused diff, keeps full Result Loop Gate and Scaling Gate as dependencies, and leaves this branch ready for PR review as workflow/route-plan integration rather than full contract enforcement.

## Capability Evidence

- governance-maintenance — selected because this PR changes Engineering OS routing/workflow/enforcement policy.

## Template Gap Waiver

This task modifies Engineering OS governance assets, not a target-project scaffold. Existing target-project template selection remains covered separately by scripts/enforcement/template-requirements.tsv and check-required-templates.py.
