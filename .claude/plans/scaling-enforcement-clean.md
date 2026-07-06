# Scaling Enforcement Route Plan

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | governance, enforcement, scaling, manifests |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md checked. |
| Workflow evidence | core/workflow.md checked. |
| Target paths | scripts/enforcement/check-scaling-extension.py, scripts/enforcement/waiver-requirements.tsv, scripts/enforcement/tests/test-scaling-extension.sh |
| Templates | internal governance work; no app template required |
| Architecture guides | docs/operations/scaling-extension-procedure.md, docs/operations/project-type-roadmaps.md |
| Patterns | internal manifest enforcement; existing enforcement test pattern reused |
| External systems/connectors | GitHub connector |
| Skills | superpowers |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy |
| Evidence to check | scaling procedure, project roadmaps, result-loop audit checklist, template requirements, scaling manifests |
| User decisions required | no user decision required. |

## Scope

Implement deterministic scaling extension enforcement on top of the merged manifest foundation. Do not claim real-run readiness.

## Alternatives

- Wait for manifests to merge first — completed before this branch was created.
- Invent a new manifest format — rejected; the checker reads the manifest foundation format.
- Mark full scaling readiness — rejected because this PR adds enforcement artifacts and tests, not first real target-project run evidence.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| core/workflow.md | checked |
| docs/operations/scaling-extension-procedure.md | checked |
| docs/operations/project-type-roadmaps.md | checked |
| docs/operations/result-loop-contract-audit-checklist.md | checked |
| scripts/enforcement/project-type-roadmaps.tsv | checked |
| scripts/enforcement/result-loop-requirements.tsv | checked |
| scripts/enforcement/template-requirements.tsv | checked |

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `source.github-repo-read` — required repo files and manifest foundation state read.
- `validation.policy-change-has-validator` — checker and shell validation planned.

## Skill Evidence

- superpowers: used planning discipline and verification-first workflow for this governance change.

## Connector Evidence

- GitHub connector: used for repository file inspection and branch creation.

## Connector Usage Evidence

- source: GitHub connector repository yotamfried-ux/Engineering-OS.
- action: GitHub connector inspected main and created branch eos-clean-20260706.
- result: scripts/enforcement/project-type-roadmaps.tsv and docs/operations/result-loop-contract-audit-checklist.md identified the enforcement target.
- decision: selected a clean branch from main and kept the scope to scaling enforcement files.
- target: scripts/enforcement/check-scaling-extension.py; scripts/enforcement/tests/test-scaling-extension.sh; scripts/enforcement/waiver-requirements.tsv

## Documentation Asset Evidence

- internal: docs/operations/scaling-extension-procedure.md, docs/operations/project-type-roadmaps.md, docs/operations/result-loop-contract-audit-checklist.md, scripts/enforcement/README.md.
- decision: internal docs and manifests define the scaling enforcement contract.

## Claude Run Trace

- goal: add deterministic validation for scaling manifests and extension metadata.
- hypothesis: a Python checker plus negative shell fixtures can prove incomplete scaling additions fail.
- connectors: GitHub connector.
- steps: read current source files, add route plan before code, add checker, add tests, validate via CI.
- evidence: scripts/enforcement/check-scaling-extension.py and scripts/enforcement/tests/test-scaling-extension.sh.
- rejected: broad readiness claim and first real target-project evidence.
- result: route plan created before code changes.
- follow-up: run CI and fix any policy comments before merge.

## Progress Lifecycle Evidence

- start: reviewed core/task-router.md, core/workflow.md, scaling procedure, roadmap catalog, audit checklist, and merged manifests before creating code files.

## DoD

- [x] Scaling checker path is defined.
- [x] Manifest validation targets are defined.
- [x] Negative fixture strategy is defined.
- [x] CI validation gates are identified.
- [x] No first real target-project readiness claim is made.
