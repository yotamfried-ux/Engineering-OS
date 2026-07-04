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
| Target paths | scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh; scripts/enforcement/check-cv-external-system-selection.sh; scripts/enforcement/tests/test-cv-external-system-selection.sh; .github/workflows/capability-evidence-policy.yml; scripts/enforcement/policy-gate-dependencies.tsv; .claude/plans/cvselect.md |
| Templates | not required because this is not a project scaffold |
| Architecture guides | external-systems/README.md; core/capability-registry.yaml; .github/workflows/capability-evidence-policy.yml; scripts/enforcement/policy-gate-dependencies.tsv |
| Patterns | not required because this extends existing enforcement scripts and fixtures |
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | enforcement-tests, pr-policy, connector-evidence-policy, workflow-evidence-policy, capability-evidence-policy, plan-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy |
| Evidence to check | validator and CV checker fixtures cover missing selection, selected path, focused waiver, shallow waiver rejection, and template-based CV detection; exact-head CI |
| User decisions required | none |

## Source of Truth Checks

| Source | Status | Why |
|---|---|---|
| core/task-router.md | read | Confirms governance changes must strengthen enforcement. |
| core/workflow.md | read | Confirms standard plan scope and validation loop. |
| core/capability-registry.yaml | checked | Confirms task class and required capability IDs. |
| scripts/enforcement/validate-capability-evidence.sh | checked | Confirms the original validator path. |
| scripts/enforcement/check-cv-external-system-selection.sh | checked | Confirms CV matching now scans template, architecture, and pattern route-plan fields. |
| scripts/enforcement/tests/test-cv-external-system-selection.sh | checked | Confirms the template/computer-vision bypass is covered. |
| .github/workflows/capability-evidence-policy.yml | checked | Confirms the new checker is part of the PR policy gate. |
| scripts/enforcement/policy-gate-dependencies.tsv | checked | Confirms installed target projects copy the new checker when the policy workflow is installed. |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`
- `registry.service-connector-selected`

## Documentation Asset Evidence

- internal: core/task-router.md; core/workflow.md; core/capability-registry.yaml; scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/check-cv-external-system-selection.sh; scripts/enforcement/tests/test-cv-external-system-selection.sh; .github/workflows/capability-evidence-policy.yml; scripts/enforcement/policy-gate-dependencies.tsv.
- context7: not required because this edits internal enforcement logic, not an external SDK or API.
- decision: close the template-based CV bypass with a small checker wired into the existing capability policy rather than broadening the large validator in this PR.

## Connector Evidence

GitHub was used for PR #198 state, changed files, workflow failures, review threads, and file updates.

## Connector Usage Evidence

- source: GitHub connector for PR #198 and branch `cvselect`.
- action: GitHub fetched PR #198, changed files, failing workflow state, review threads, and updated repository files.
- result: GitHub PR #198 target files include scripts/enforcement/check-cv-external-system-selection.sh, scripts/enforcement/tests/test-cv-external-system-selection.sh, .github/workflows/capability-evidence-policy.yml, scripts/enforcement/policy-gate-dependencies.tsv, scripts/enforcement/validate-capability-evidence.sh, and scripts/enforcement/tests/test-capability-evidence.sh.
- target: scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh; scripts/enforcement/check-cv-external-system-selection.sh; scripts/enforcement/tests/test-cv-external-system-selection.sh; .github/workflows/capability-evidence-policy.yml; scripts/enforcement/policy-gate-dependencies.tsv; .claude/plans/cvselect.md.
- decision: GitHub review thread evidence changed the fix from domain-only CV detection to template/architecture/pattern-aware CV route detection.

## Skill Evidence

- superpowers used for plan-first and verification discipline.

## DoD

- [x] Route Plan contains required routing, workflow, target, source, capability, connector, and skill evidence.
- [x] New unregistered core policy file was removed from the PR.
- [x] Validator fixture rejects the missing external-system selection case.
- [x] Validator fixture accepts the selected external-system case.
- [x] CV checker fixture rejects templates/computer-vision without supervision.
- [x] CV checker fixture accepts selected supervision and focused waiver paths.
- [x] CV checker is wired into capability-evidence-policy and install dependency manifest.
- [x] CI gates remain the final acceptance signal.

## Claude Run Trace

- goal: repair PR #198 evidence and close the template-based CV external-system bypass.
- hypothesis: CI was green but review thread showed a real bypass because template fields were not scanned.
- steps: inspected PR files, workflow status, validators, review threads, added a focused CV route checker, added template-route fixtures, wired the checker into the capability policy workflow, updated install dependency coverage, and refreshed this plan after code changes.
- tools/connectors: GitHub connector.
- evidence: PR #198, commits 96f7dce, 5e8b258, d02275b, c4c74f6, 6b69ef8, 9d4c523, ba75c0a, and target paths listed above.
- result: structure is ready for exact-head CI validation.
- follow-up enforcement: update PR body Merge Readiness with the final head SHA.

## Progress Lifecycle Evidence

- start: Route Plan created before code, policy, or test changes.
- mid: added validator logic and a regression test fixture for the missing external-system case.
- mid: removed the unregistered core policy file after reviewing the final changed-file set.
- mid: added dedicated template-aware CV checker, fixtures, workflow wiring, and install dependency row after reviewing open PR thread evidence.
- pre-merge: refreshed final Route Plan evidence after the last code/config/test change and before exact-head CI.
