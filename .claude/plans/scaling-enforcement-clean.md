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
| Target paths | scripts/enforcement/check-scaling-extension.py, scripts/enforcement/project-type-roadmaps.tsv, scripts/enforcement/tests/test-scaling-extension.sh, scripts/enforcement/tests/test-scaling-manifests.sh, scripts/enforcement/reference-repositories.tsv, scripts/enforcement/waiver-requirements.tsv |
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
| scripts/enforcement/template-requirements.tsv | checked |

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — route plan was committed before checker and test files.
- `source.github-repo-read` — manifests and PR files were read from GitHub.
- `validation.policy-change-has-validator` — checker and negative fixtures were added.
- `validation.coderabbit-policy` — fallback self-review is recorded in the PR body.

## Skill Evidence

- superpowers: used planning discipline and verification-first workflow.

## Connector Evidence

- GitHub connector: used for repository inspection and branch edits.

## Connector Usage Evidence

- source: GitHub connector repository yotamfried-ux/Engineering-OS.
- action: inspected branch eos-clean-20260706, PR #219 files, and CI status.
- result: enforcement-tests isolated the remaining issue to game-development visual evidence coverage in scripts/enforcement/project-type-roadmaps.tsv.
- decision: updated scripts/enforcement/project-type-roadmaps.tsv to match the documented visual evidence contract while keeping the checker requirement unchanged.
- target: scripts/enforcement/check-scaling-extension.py; scripts/enforcement/project-type-roadmaps.tsv; scripts/enforcement/tests/test-scaling-extension.sh; scripts/enforcement/tests/test-scaling-manifests.sh; scripts/enforcement/reference-repositories.tsv; scripts/enforcement/waiver-requirements.tsv

## Documentation Asset Evidence

- internal: docs/operations/scaling-extension-procedure.md, docs/operations/project-type-roadmaps.md, docs/operations/result-loop-contract-audit-checklist.md, scripts/enforcement/README.md.
- context7: not required because this PR changes internal manifest enforcement logic and adds no external library, framework, SDK, API, or service.
- decision: internal docs and manifests define the scaling enforcement contract.

## Claude Run Trace

- result: current scaling gate files were reviewed after fixture repair.
- result: enforcement-tests logs were checked on head 87c66047f155b6957ed370b1312ce1612bef78c9 and the observed suite issue was game-development visual evidence coverage.

## Progress Lifecycle Evidence

- start: reviewed routing, workflow, scaling procedure, roadmap catalog, audit checklist, and merged manifests before code files.
- mid: added the checker, waiver manifest, and shell fixture test after the route plan.
- pre-merge: reviewed changed files and prepared CI validation with no real-run readiness claim.
- cleanup: recorded missing capability and documentation evidence after CI policy feedback.
- pre-merge: fixed root calculation, checker coverage, manifest schema validation, and docs metadata fixture selector.
- pre-merge: aligned game-development required_evidence with the documented visual evidence contract after enforcement-tests reported missing visual coverage on current head 87c66047f155b6957ed370b1312ce1612bef78c9.
- pre-merge: updated Connector Usage Evidence decision wording so connector-evidence-policy can verify the branch edit decision impact.

## DoD

- [x] Scaling checker exists.
- [x] Manifest validation targets are defined.
- [x] Negative fixture strategy is implemented.
- [x] CI validation gates are identified.
- [x] No first real target-project readiness claim is made.