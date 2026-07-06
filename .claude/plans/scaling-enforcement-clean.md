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
| Patterns | internal manifest enforcement pattern reused |
| External systems/connectors | GitHub connector |
| Skills | superpowers |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy |
| Evidence to check | scaling manifests and audit checklist |
| User decisions required | no user decision required. |

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
- `source.github-repo-read` — merged manifests read.
- `validation.policy-change-has-validator` — checker and shell validation added.

## Skill Evidence

- superpowers: used planning discipline and verification-first workflow.

## Connector Evidence

- GitHub connector: used for repository inspection and branch edits.

## Connector Usage Evidence

- source: GitHub connector repository yotamfried-ux/Engineering-OS.
- action: GitHub connector inspected main and created branch eos-clean-20260706.
- result: scripts/enforcement/project-type-roadmaps.tsv and docs/operations/result-loop-contract-audit-checklist.md identified the target.
- decision: selected a clean branch from main and kept the scope to scaling enforcement files.
- target: scripts/enforcement/check-scaling-extension.py; scripts/enforcement/tests/test-scaling-extension.sh; scripts/enforcement/waiver-requirements.tsv

## Documentation Asset Evidence

- internal: docs/operations/scaling-extension-procedure.md, docs/operations/project-type-roadmaps.md, docs/operations/result-loop-contract-audit-checklist.md, scripts/enforcement/README.md.
- decision: internal docs and manifests define the scaling enforcement contract.

## Claude Run Trace

- goal: validate scaling manifests and extension metadata deterministically.
- hypothesis: a Python checker plus shell fixtures can reject incomplete scaling additions.
- connectors: GitHub connector.
- steps: read current sources, add route plan first, add checker, add tests, validate via CI.
- evidence: scripts/enforcement/check-scaling-extension.py and scripts/enforcement/tests/test-scaling-extension.sh.
- rejected: broad readiness claim and first real target-project evidence.
- result: checker, waiver manifest, and shell fixture test were added after the route plan.

## Progress Lifecycle Evidence

- start: reviewed routing, workflow, scaling procedure, roadmap catalog, audit checklist, and merged manifests before code files.
- mid: added the checker, waiver manifest, and shell fixture test after the route plan.
- pre-merge: reviewed the final changed files and prepared CI validation with no real-run readiness claim.

## DoD

- [x] Scaling checker exists.
- [x] Manifest validation targets are defined.
- [x] Negative fixture strategy is implemented.
- [x] CI validation gates are identified.
- [x] No first real target-project readiness claim is made.
