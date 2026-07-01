# Route Plan - documentation asset required gate

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Target paths | scripts/enforcement/check-merge-readiness.sh, docs/operations/main-required-checks.md, scripts/enforcement/tests/test-operational-readiness-gates.sh, scripts/enforcement/tests/test-ops-branch-protection.sh, scripts/install-policy-gates.sh, scripts/enforcement/tests/test-clean-install-and-usage.sh |
| Templates | not required |
| Patterns | existing required workflow contract test style |
| External systems/connectors | GitHub |
| Skills | none |
| Validation gates | enforcement-tests, required workflow contract, merge readiness fixtures, ops branch protection fixtures, clean install contract, workflow evidence, connector evidence, plan policy, PR policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- GitHub: inspected required workflow, documentation, readiness fixture, branch protection fixture, clean install fixture, policy gate installer, and documentation asset workflow sources before implementation.

## Connector Usage Evidence

- source: GitHub files `scripts/enforcement/check-merge-readiness.sh`, `docs/operations/main-required-checks.md`, `scripts/enforcement/tests/test-operational-readiness-gates.sh`, `scripts/enforcement/tests/test-ops-branch-protection.sh`, `scripts/install-policy-gates.sh`, `scripts/enforcement/tests/test-clean-install-and-usage.sh`, and `.github/workflows/documentation-asset-policy.yml`.
- action: checked why the documentation asset workflow existed but was absent from the required workflow contract and target-project installer contract.
- result: GitHub showed the workflow and its job context were available, the required contract still had six workflows, and clean-install fixtures still omitted the new required workflow.
- decision: implemented the workflow as a required merge-readiness workflow, updated docs plus fixtures, and installed it into governed target projects.
- target: scripts/enforcement/check-merge-readiness.sh, docs/operations/main-required-checks.md, scripts/enforcement/tests/test-operational-readiness-gates.sh, scripts/enforcement/tests/test-ops-branch-protection.sh, scripts/install-policy-gates.sh, scripts/enforcement/tests/test-clean-install-and-usage.sh

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
| scripts/install-policy-gates.sh | checked |
| scripts/enforcement/tests/test-clean-install-and-usage.sh | checked |
| .github/workflows/documentation-asset-policy.yml | checked |

## Progress Lifecycle Evidence

- start: plan committed before modifying merge-readiness, operations docs, or enforcement fixture tests.
- mid: required workflow contract, required checks doc, merge readiness fixture, and branch protection fixture were updated after implementation began.
- pre-merge: enforcement-tests exposed the missing target-project installer path; the branch now also installs and validates the documentation asset workflow in clean-install fixtures.

## Claude Run Trace

- goal: make the documentation asset workflow part of merge readiness.
- hypothesis: adding the workflow to the required list and fixtures makes missing or failing documentation asset evidence block merge-readiness.
- connectors: GitHub was used for source inspection, CI status, logs, and branch updates.
- steps: read routing/workflow/capability sources, read current workflow and tests, create plan, update contract files, inspect failing CI, then update installer and clean-install fixtures.
- evidence: implementation updates required workflow list, required-check docs, merge-readiness fixtures, expected context fixtures, policy gate installer, and clean-install required workflow fixtures.
- rejected: admin rule application remains outside this connector scope.
- result: implementation patched after CI failure; CI rerun pending.
- follow-up: use green PR checks as the merge gate.

## DoD

- [x] Route Plan committed before code/config/test/doc changes.
- [x] `documentation-asset-policy` added to `REQUIRED_WORKFLOWS_DEFAULT`.
- [x] Main required checks doc mirrors the required workflow and context.
- [x] Operational readiness fixtures require the documentation asset workflow.
- [x] Ops fixture expects `Require documentation/reference asset evidence`.
- [x] Target-project installer includes the documentation asset workflow.
- [x] Clean-install usage fixtures include the documentation asset workflow.
- [x] PR opened; CI remains the gate before merge.
