# Clean Workflow Integration Route Plan

Plan Scope: standard
Planning Mode: approved

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | workflow, governance, result-loop, scaling |
| selected_project_type | waiver: Engineering OS governance maintenance |
| selected_template | waiver: governance maintenance has no scaffold template |
| selected_roadmap | docs/operations/project-type-roadmaps.md checked |
| selected_result_loop_contract | scripts/enforcement/result-loop-requirements.tsv checked |
| required_user_simulation | scripts/enforcement/tests/test-route-plan-contract.sh |
| local_creator_review_path | local CLI enforcement tests |
| telemetry_export_path | scripts/monitoring/export-telemetry-run.sh |
| evidence_redaction_rule | metadata-only evidence export |
| Target paths | core/task-router.md, scripts/enforcement/check-route-plan-contract.py, scripts/enforcement/tests/test-route-plan-contract.sh, docs/operations/workflow-result-loop-integration-audit.md, .claude/plans/wf-clean.md |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy |
| User decisions required | none |

## Source of Truth Checks

| Source | Status |
|---|---|
| PR #216 | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| scripts/enforcement/result-loop-requirements.tsv | checked |
| docs/operations/scaling-extension-procedure.md | checked |

## Connector Usage Evidence

- source: GitHub connector repository yotamfried-ux/Engineering-OS.
- action: inspected PR #216 and current main governance files.
- result: clean branch `eos-wf-clean` contains route-plan checker, fixtures, audit addendum, and targeted task-router update.
- decision: created a clean workflow-integration PR path instead of merging PR #216 directly.
- target: core/task-router.md; scripts/enforcement/check-route-plan-contract.py; scripts/enforcement/tests/test-route-plan-contract.sh; docs/operations/workflow-result-loop-integration-audit.md; .claude/plans/wf-clean.md

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read before writing.
- `workflow.workflow-read` — core/workflow.md read before writing.
- `plan.route-plan-before-write` — plan created before clean-branch enforcement edits.
- `source.github-repo-read` — PR #216 and current main files inspected through GitHub.
- `validation.policy-change-has-validator` — checker and fixtures were added.
- `validation.coderabbit-policy` — PR body will record review fallback.

## Progress Lifecycle Evidence

- start: PR #216 and current main were inspected before writing.
- mid: clean branch created from current main; checker, fixtures, audit addendum, and targeted router update added.
- pre-merge: pending PR creation, current-head CI, and review-thread validation.

## DoD

- [x] Add route-plan contract checker.
- [x] Add positive and negative fixtures.
- [x] Update routing contract without rewriting core workflow.
- [x] Add workflow integration audit note.
- [ ] Open clean PR and validate CI.