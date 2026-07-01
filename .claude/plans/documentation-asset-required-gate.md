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

- GitHub: inspected the current required workflow list, main required checks documentation, operational readiness fixtures, ops branch-protection fixtures, and the existing documentation asset workflow before implementation.

## Connector Usage Evidence

- source: GitHub files `scripts/enforcement/check-merge-readiness.sh`, `docs/operations/main-required-checks.md`, `scripts/enforcement/tests/test-operational-readiness-gates.sh`, `scripts/enforcement/tests/test-ops-branch-protection.sh`, and `.github/workflows/documentation-asset-policy.yml`.
- action: checked the workflow/source-of-truth gap where `documentation-asset-policy` exists but is absent from the deterministic required workflow list and branch-protection context docs.
- result: GitHub showed the documentation asset workflow name and job context are available, while merge-readiness and operational fixtures still require only six workflows.
- decision: implement the documentation asset workflow as a required merge-readiness workflow and update the matching human docs plus fixture tests.
- target: scripts/enforcement/check-merge-readiness.sh, docs/operations/main-required-checks.md, scripts/enforcement/tests/test-operational-readiness-gates.sh, scripts/enforcement/tests/test-ops-branch-protection.sh

## Documentation Asset Evidence

- internal: all target files plus `.github/workflows/documentation-asset-policy.yml` and `scripts/enforcement/tests/test-required-workflows-contract.sh` were read.
- context7: not required because this is an internal CI/workflow contract change and does not use external library, SDK, framework, or API behavior.
- decision: update the repository source-of-truth contract and its tests rather than only documenting the gap.

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

## Claude Run Trace

- goal: make `documentation-asset-policy` a required gate instead of a non-required workflow.
- hypothesis: adding the workflow to `REQUIRED_WORKFLOWS_DEFAULT` and updating docs/fixtures will make missing or failing documentation asset evidence block merge-readiness deterministically.
- connectors: GitHub used for repository source inspection and branch updates.
- steps: read routing/workflow/capability registry, read current workflow and tests, create branch, commit this plan before implementation.
- evidence: pending implementation commits and CI.
- rejected: claiming server-side branch protection is already changed is rejected because this environment lacks branch protection admin write access.
- result: pending implementation.
- follow-up: run CI and merge only after green checks and review evidence.

## DoD

- [ ] Route Plan committed before code/config/test/doc changes.
- [ ] `documentation-asset-policy` added to `REQUIRED_WORKFLOWS_DEFAULT`.
- [ ] Main required checks doc mirrors the required workflow and branch-protection context.
- [ ] Operational readiness fixtures require the documentation asset workflow.
- [ ] Ops branch-protection fixture expects `Require documentation/reference asset evidence`.
- [ ] PR opened and CI green before merge.
