# Route Plan - CV external-system selection

| Field | Decision |
|---|---|
| Task type | governance enforcement |
| Task class | engineering_os_governance |
| Domain tags | governance, external-systems, enforcement |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read; routed as Engineering OS maintenance. |
| Workflow evidence | core/workflow.md read; standard scope and validation loop. |
| Target paths | scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh; .claude/plans/cvselect.md |
| Templates | not required because this is not a project scaffold |
| Architecture guides | external-systems/README.md; core/capability-registry.yaml |
| Patterns | not required because this extends an existing enforcement script and fixture |
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | enforcement-tests, pr-policy, connector-evidence-policy, workflow-evidence-policy, capability-evidence-policy, plan-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy |
| Evidence to check | validator fixture covers missing selection and selected positive path; exact-head CI |
| User decisions required | none |

## Source of Truth Checks

| Source | Status | Why |
|---|---|---|
| core/task-router.md | read | Confirms governance changes must strengthen enforcement. |
| core/workflow.md | read | Confirms standard plan scope and validation loop. |
| core/capability-registry.yaml | checked | Confirms task class and required capability IDs. |
| scripts/enforcement/validate-capability-evidence.sh | checked | Confirms the validator is the target enforcement point. |
| scripts/enforcement/tests/test-capability-evidence.sh | checked | Confirms fixture coverage for this rule. |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`
- `registry.service-connector-selected`

## Documentation Asset Evidence

- internal: core/task-router.md; core/workflow.md; core/capability-registry.yaml; scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh.
- context7: not required because this edits internal enforcement logic, not an external SDK or API.
- decision: keep the rule in the existing validator and fixture suite instead of a new core policy file.

## Connector Evidence

GitHub was used for PR #198 state, changed files, workflow failures, and file updates.

## Connector Usage Evidence

- source: GitHub connector for PR #198 and branch `cvselect`.
- action: GitHub fetched PR #198, changed files, failing workflow state, and updated repository files.
- result: GitHub PR #198 target files scripts/enforcement/validate-capability-evidence.sh and scripts/enforcement/tests/test-capability-evidence.sh were validated and updated; commit 96f7dce removed core/external-system-selection-policy.md.
- target: scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh; .claude/plans/cvselect.md.
- decision: GitHub evidence updated the fix to use the existing validator/test path and remove the unregistered core policy doc.

## Skill Evidence

- superpowers used for plan-first and verification discipline.

## DoD

- [x] Route Plan contains required routing, workflow, target, source, capability, connector, and skill evidence.
- [x] New unregistered core policy file was removed from the PR.
- [x] Validator fixture rejects the missing external-system selection case.
- [x] Validator fixture accepts the selected external-system case.
- [x] CI gates remain the final acceptance signal.

## Claude Run Trace

- goal: repair PR #198 evidence and keep the external-system selection fix minimal.
- hypothesis: CI failed because required Route Plan evidence was incomplete and a duplicate plan was added late.
- steps: inspected PR files, workflow status, validators, removed the extra policy file, extended the fixture, removed the duplicate plan, and completed this plan.
- tools/connectors: GitHub connector.
- evidence: PR #198, commits 96f7dce, 5e8b258, d02275b, and target paths listed above.
- result: structure is ready for exact-head CI validation.
- follow-up enforcement: update PR body Merge Readiness with the final head SHA.

## Progress Lifecycle Evidence

- start: Route Plan created before code, policy, or test changes.
- mid: added validator logic and a regression test fixture for the missing external-system case.
- mid: removed the unregistered core policy file after reviewing the final changed-file set.
- pre-merge: refreshed final Route Plan evidence after the last test fixture update and before exact-head CI.
