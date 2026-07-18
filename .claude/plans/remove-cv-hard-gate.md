# Route Plan - Remove CV supervision hard gate

| Field | Decision |
|---|---|
| Task type | governance enforcement correction |
| Task class | engineering_os_governance |
| Domain tags | governance, external-systems, enforcement |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read; routed as Engineering OS maintenance because this changes policy-gate behavior. |
| Workflow evidence | core/workflow.md read; plan-first workflow and validation loop required before code/config changes. |
| Target paths | .github/workflows/capability-evidence-policy.yml; scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh; scripts/enforcement/check-cv-external-system-selection.sh; scripts/enforcement/tests/test-cv-external-system-selection.sh; scripts/enforcement/policy-gate-dependencies.tsv; .claude/plans/remove-cv-hard-gate.md |
| Templates | not required because this is not a project scaffold. |
| Architecture guides | external-systems/README.md; .github/workflows/capability-evidence-policy.yml; scripts/enforcement/policy-gate-dependencies.tsv; scripts/enforcement/validate-capability-evidence.sh |
| Patterns | not required because this removes an over-strict policy gate. |
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | enforcement-tests, capability-evidence-policy, workflow-evidence-policy, connector-evidence-policy, pr-policy |
| Evidence to check | supervision remains listed in external-systems inventory; workflow and capability validator no longer hard-require it. |
| User decisions required | none |

## Source of Truth Checks

| Source | Status | Why |
|---|---|---|
| external-systems/README.md | checked | Confirms supervision should remain an available CV/media AI tool. |
| .github/workflows/capability-evidence-policy.yml | checked | Confirms where the standalone hard gate was wired. |
| scripts/enforcement/validate-capability-evidence.sh | checked | Confirms the remaining embedded supervision hard gate was removed. |
| scripts/enforcement/tests/test-capability-evidence.sh | checked | Confirms CV route plans without supervision are now accepted by the capability validator. |
| scripts/enforcement/policy-gate-dependencies.tsv | checked | Confirms install-time workflow dependencies. |
| core/task-router.md | read | Confirms governance routing. |
| core/workflow.md | read | Confirms plan-first workflow. |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.actions-checked`
- `validation.coderabbit-policy`

## Documentation Asset Evidence

- internal: external-systems/README.md, .github/workflows/capability-evidence-policy.yml, scripts/enforcement/validate-capability-evidence.sh, scripts/enforcement/tests/test-capability-evidence.sh, scripts/enforcement/policy-gate-dependencies.tsv, core/task-router.md, core/workflow.md.
- context7: not required because this removes an internal policy gate and does not use an external SDK or API.
- decision: keep supervision as an inventory option only; remove the mandatory CV-specific policy gate from both the workflow path and the capability validator.

## Connector Evidence

GitHub was used to inspect main branch files and update repository files.

## Connector Usage Evidence

- source: GitHub connector for yotamfried-ux/Engineering-OS.
- action: fetched external-systems/README.md, capability-evidence-policy.yml, validate-capability-evidence.sh, test-capability-evidence.sh, check-cv-external-system-selection.sh, test-cv-external-system-selection.sh, and policy-gate-dependencies.tsv.
- result: GitHub branch p200 now keeps external-systems/README.md unchanged, removes the workflow call, removes the embedded validator requirement, removes the dependency manifest row, and deletes the hard-gate script and test.
- target: .github/workflows/capability-evidence-policy.yml; scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh; scripts/enforcement/check-cv-external-system-selection.sh; scripts/enforcement/tests/test-cv-external-system-selection.sh; scripts/enforcement/policy-gate-dependencies.tsv.
- decision: changed the policy workflow and capability validator while keeping external-systems/README.md unchanged.

## Skill Evidence

- superpowers: used for plan-first correction and validation discipline.

## Graphify Usage Evidence

- source: graphify query "validate-capability-evidence.sh test-capability-evidence.sh" against graphify-out/graph.json.
- action: traversed callers/dependents of validate-capability-evidence.sh and test-capability-evidence.sh (BFS depth=2, 35 nodes) before editing the `/tmp/cv-optional.out` line CodeRabbit flagged as a symlink-hijack risk.
- result: no other script or test depends on that specific fixture's output path; capability-verify.sh and evidence.sh are separate, unrelated callers of validate-capability-evidence.sh.
- decision: safe to change the fixture's output redirection target without impacting any other caller or route.
- target: scripts/enforcement/tests/test-capability-evidence.sh.

## DoD

- [x] supervision remains in external-systems/README.md.
- [x] capability-evidence-policy no longer calls check-cv-external-system-selection.sh.
- [x] validate-capability-evidence.sh no longer requires supervision for CV-like Route Plans.
- [x] test-capability-evidence.sh accepts a CV-like Route Plan without supervision.
- [x] check-cv-external-system-selection.sh is removed.
- [x] test-cv-external-system-selection.sh is removed.
- [x] policy-gate-dependencies.tsv no longer copies the CV hard-gate script.
- [x] CI gates remain the final acceptance signal before merge.

## Claude Run Trace

- goal: align supervision with user intent as an optional repo/tool, not an automatic requirement.
- hypothesis: the current hard gate over-enforces supervision on CV-like Route Plans.
- tools/connectors: GitHub connector.
- steps: read external-systems/README.md, the workflow, the validator, and their tests; removed the standalone check-cv-external-system-selection.sh call and script; removed the embedded validate_external_system_selection function after review found the standalone removal was incomplete; updated fixtures; re-verified with grep that no reference remains.
- evidence: .github/workflows/capability-evidence-policy.yml (call removed); scripts/enforcement/validate-capability-evidence.sh (function removed); scripts/enforcement/tests/test-capability-evidence.sh (fixtures updated); grep for validate_external_system_selection/CV_TERMS/supervision on the current head returns no matches outside external-systems/README.md's inventory listing.
- rejected: removing only the standalone script while leaving the embedded validator check — rejected because a live review thread correctly found that would leave the effective hard gate in place.
- follow-up: none; supervision remains available as an inventory option, not a requirement.
- result: standalone and embedded supervision hard gates were removed while external-systems inventory stayed unchanged.

## Progress Lifecycle Evidence

- start: Route Plan created before modifying workflow, dependency manifest, or enforcement scripts.
- mid: removed the workflow call and dependency manifest entry after verifying supervision remains in external-systems/README.md.
- mid: removed the embedded supervision requirement from validate-capability-evidence.sh after review found the standalone removal was incomplete.
- pre-merge: updated capability validator fixtures so CV-like Route Plans without supervision are accepted; resolved the live review thread confirming the embedded gate removal and fixed a CodeRabbit-flagged symlink-hijack risk in the fixture; CI is the final gate before merge.
- pre-merge: refreshed target paths and evidence after removing the remaining embedded hard gate.
