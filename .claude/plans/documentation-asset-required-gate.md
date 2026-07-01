# Route Plan - documentation asset required gate

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Target paths | scripts/enforcement/check-merge-readiness.sh, docs/operations/main-required-checks.md, scripts/enforcement/tests/test-operational-readiness-gates.sh, scripts/enforcement/tests/test-ops-branch-protection.sh |
| Templates | not required |
| Patterns | existing required workflow contract test style |
| External systems/connectors | GitHub |
| Skills | none |
| Validation gates | enforcement-tests, required workflow contract, merge readiness fixtures, ops branch protection fixtures, workflow evidence, connector evidence, plan policy, PR policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- GitHub: inspected required workflow, documentation, readiness fixture, branch protection fixture, and documentation asset workflow sources before implementation.

## Connector Usage Evidence

- source: GitHub files `scripts/enforcement/check-merge-readiness.sh`, `docs/operations/main-required-checks.md`, `scripts/enforcement/tests/test-operational-readiness-gates.sh`, `scripts/enforcement/tests/test-ops-branch-protection.sh`, and `.github/workflows/documentation-asset-policy.yml`.
- action: checked why the documentation asset workflow existed but was absent from the required workflow contract.
- result: GitHub showed the workflow and its job context were available and the required contract still had six workflows.
- decision: implemented the workflow as a required merge-readiness workflow and updated docs plus fixtures.
- target: scripts/enforcement/check-merge-readiness.sh, docs/operations/main-required-checks.md, scripts/enforcement/tests/test-operational-readiness-gates.sh, scripts/enforcement/tests/test-ops-branch-protection.sh

## Documentation Asset Evidence

- internal: target files, `.github/workflows/documentation-asset-policy.yml`, and `scripts/enforcement/tests/test-required-workflows-contract.sh` were read.
- context7: not required because this is an internal CI contract change.
- decision: update the enforced contract and tests.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/capability-registry.yaml | checked |
| scripts/enforcement/check-merge-readiness.sh | checked |
| docs/operations/main-required-checks.md | checked |
| scripts/enforcement/tests/test-operational-readiness-gates.sh | checked |
| scripts/enforcement/tests/test-ops-branch-protection.sh | checked |
| .github/workflows/documentation-asset-policy.yml | checked |

## Progress Lifecycle Evidence

- start: plan committed before modifying merge-readiness, operations docs, or enforcement fixture tests.
- mid: required workflow contract, required checks doc, merge readiness fixture, and branch protection fixture were updated after implementation began.
- pre-merge: final branch review completed after all target file updates; deterministic readiness fixtures now include documentation asset workflow coverage.

## Claude Run Trace

- goal: make the documentation asset workflow part of merge readiness.
- hypothesis: adding the workflow to the required list and fixtures makes missing or failing documentation asset evidence block merge-readiness.
- connectors: GitHub was used for source inspection and branch updates.
- steps: read routing/workflow/capability sources, read current workflow and tests, create plan, update contract files, then review final branch diff evidence.
- evidence: implementation updates required workflow list, required-check docs, merge-readiness fixtures, and expected context fixtures.
- rejected: admin rule application remains outside this connector scope.
- result: implementation complete; CI validation through PR remains.
- follow-up: run CI and merge only after green checks and review evidence.

## DoD

- [x] Route Plan committed before code/config/test/doc changes.
- [x] `documentation-asset-policy` added to `REQUIRED_WORKFLOWS_DEFAULT`.
- [x] Main required checks doc mirrors the required workflow and context.
- [x] Operational readiness fixtures require the documentation asset workflow.
- [x] Ops fixture expects `Require documentation/reference asset evidence`.
- [ ] PR opened and CI green before merge.
