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
| Target paths | .github/workflows/capability-evidence-policy.yml; scripts/enforcement/check-cv-external-system-selection.sh; scripts/enforcement/tests/test-cv-external-system-selection.sh; scripts/enforcement/policy-gate-dependencies.tsv; .claude/plans/remove-cv-hard-gate.md |
| Templates | not required because this is not a project scaffold. |
| Architecture guides | external-systems/README.md; .github/workflows/capability-evidence-policy.yml; scripts/enforcement/policy-gate-dependencies.tsv |
| Patterns | not required because this removes an over-strict policy gate. |
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | enforcement-tests, capability-evidence-policy, workflow-evidence-policy, connector-evidence-policy, pr-policy |
| Evidence to check | supervision remains listed in external-systems inventory; hard gate is removed from workflow/dependency/test paths. |
| User decisions required | none |

## Source of Truth Checks

| Source | Status | Why |
|---|---|---|
| external-systems/README.md | checked | Confirms supervision should remain an available CV/media AI tool. |
| .github/workflows/capability-evidence-policy.yml | checked | Confirms where the hard gate was wired. |
| scripts/enforcement/policy-gate-dependencies.tsv | checked | Confirms install-time workflow dependencies. |
| core/task-router.md | read | Confirms governance routing. |
| core/workflow.md | read | Confirms plan-first workflow. |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Documentation Asset Evidence

- internal: external-systems/README.md, .github/workflows/capability-evidence-policy.yml, scripts/enforcement/policy-gate-dependencies.tsv, core/task-router.md, core/workflow.md.
- context7: not required because this removes an internal policy gate and does not use an external SDK or API.
- decision: keep supervision as an inventory option only; remove the mandatory CV-specific policy gate.

## Connector Evidence

GitHub was used to inspect main branch files and update repository files.

## Connector Usage Evidence

- source: GitHub connector for yotamfried-ux/Engineering-OS.
- action: fetched external-systems/README.md, capability-evidence-policy.yml, check-cv-external-system-selection.sh, test-cv-external-system-selection.sh, and policy-gate-dependencies.tsv.
- result: GitHub branch p200 now keeps external-systems/README.md unchanged, removes the workflow call, removes the dependency manifest row, and deletes the hard-gate script and test.
- target: .github/workflows/capability-evidence-policy.yml; scripts/enforcement/check-cv-external-system-selection.sh; scripts/enforcement/tests/test-cv-external-system-selection.sh; scripts/enforcement/policy-gate-dependencies.tsv.
- decision: remove workflow enforcement and related gate files while preserving external-systems/README.md.

## Skill Evidence

- superpowers: used for plan-first correction and validation discipline.

## DoD

- [x] supervision remains in external-systems/README.md.
- [x] capability-evidence-policy no longer calls check-cv-external-system-selection.sh.
- [x] check-cv-external-system-selection.sh is removed.
- [x] test-cv-external-system-selection.sh is removed.
- [x] policy-gate-dependencies.tsv no longer copies the CV hard-gate script.
- [ ] CI gates pass before merge.

## Claude Run Trace

- goal: align supervision with user intent as an optional repo/tool, not an automatic requirement.
- hypothesis: the current hard gate over-enforces supervision on CV-like Route Plans.
- tools/connectors: GitHub connector.
- result: hard-gate workflow call, install dependency, script, and test were removed while external-systems inventory stayed unchanged.

## Progress Lifecycle Evidence

- start: Route Plan created before modifying workflow, dependency manifest, or enforcement scripts.
- mid: removed the workflow call and dependency manifest entry after verifying supervision remains in external-systems/README.md.
- pre-merge: deleted the CV hard-gate script and test; CI remains the final gate.
