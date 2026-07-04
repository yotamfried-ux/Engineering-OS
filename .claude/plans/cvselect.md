# Route Plan - CV external-system selection

| Field | Decision |
|---|---|
| Task type | governance enforcement |
| Task class | engineering_os_governance |
| Domain tags | governance, external-systems, enforcement |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read. |
| Workflow evidence | core/workflow.md read. |
| Target paths | scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh; scripts/enforcement/check-cv-external-system-selection.sh; scripts/enforcement/tests/test-cv-external-system-selection.sh; .github/workflows/capability-evidence-policy.yml; scripts/enforcement/policy-gate-dependencies.tsv; .claude/plans/cvselect.md |
| Templates | not required because this is not a project scaffold |
| Architecture guides | core/capability-registry.yaml; .github/workflows/capability-evidence-policy.yml; scripts/enforcement/policy-gate-dependencies.tsv |
| Patterns | not required because this extends existing enforcement scripts and fixtures |
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | enforcement-tests, pr-policy, connector-evidence-policy, workflow-evidence-policy, capability-evidence-policy, plan-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy |
| Evidence to check | route checker fixtures cover missing selection, selected path, focused waiver, shallow waiver rejection, and template-based CV detection; exact-head CI |
| User decisions required | none |

## Source of Truth Checks

| Source | Status | Why |
|---|---|---|
| scripts/enforcement/check-cv-external-system-selection.sh | checked | Target checker. |
| scripts/enforcement/tests/test-cv-external-system-selection.sh | checked | Target fixtures. |
| .github/workflows/capability-evidence-policy.yml | checked | Target workflow. |
| scripts/enforcement/policy-gate-dependencies.tsv | checked | Target install manifest. |
| core/task-router.md | read | Routing source. |
| core/workflow.md | read | Workflow source. |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`
- `registry.service-connector-selected`

## Documentation Asset Evidence

- internal: core/task-router.md; core/workflow.md; core/capability-registry.yaml; scripts/enforcement/check-cv-external-system-selection.sh; scripts/enforcement/tests/test-cv-external-system-selection.sh; .github/workflows/capability-evidence-policy.yml; scripts/enforcement/policy-gate-dependencies.tsv.
- context7: not required because this edits internal enforcement logic, not an external SDK or API.
- decision: close the template route bypass with a focused checker wired into the existing capability policy.

## Connector Evidence

GitHub was used for PR #198 state, changed files, workflow failures, review threads, and file updates.

## Connector Usage Evidence

- source: GitHub connector for PR #198 and branch `cvselect`.
- action: GitHub fetched PR #198, changed files, workflow state, review threads, and updated repository files.
- result: GitHub PR #198 target files include scripts/enforcement/check-cv-external-system-selection.sh, scripts/enforcement/tests/test-cv-external-system-selection.sh, .github/workflows/capability-evidence-policy.yml, scripts/enforcement/policy-gate-dependencies.tsv, scripts/enforcement/validate-capability-evidence.sh, and scripts/enforcement/tests/test-capability-evidence.sh.
- target: scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh; scripts/enforcement/check-cv-external-system-selection.sh; scripts/enforcement/tests/test-cv-external-system-selection.sh; .github/workflows/capability-evidence-policy.yml; scripts/enforcement/policy-gate-dependencies.tsv; .claude/plans/cvselect.md.
- decision: GitHub review thread evidence changed the fix from domain-only detection to route-field detection.

## External System Selection Waiver

- supervision reason: governance-only checker work; GitHub is the active connector.

## Skill Evidence

- superpowers used for plan-first and verification discipline.

## DoD

- [x] Route Plan evidence is complete.
- [x] Unregistered core policy file was removed.
- [x] Validator fixture rejects missing selection.
- [x] Validator fixture accepts selected path.
- [x] Route checker fixture rejects templates/computer-vision without supervision.
- [x] Route checker fixture accepts selected supervision and focused waiver paths.
- [x] Route checker is wired into capability-evidence-policy and install dependency manifest.
- [x] CI gates remain the final acceptance signal.

## Claude Run Trace

- goal: repair PR #198 and close the template route bypass.
- hypothesis: the open review thread was valid because template fields were not scanned.
- steps: inspected PR files, workflow status, validators, review threads, added a focused route checker, added template-route fixtures, wired the checker into the capability policy workflow, updated install dependency coverage, and refreshed this plan after code changes.
- tools/connectors: GitHub connector.
- evidence: PR #198 and target paths listed above.
- result: ready for exact-head CI validation.
- follow-up enforcement: update PR body Merge Readiness with the final head SHA.

## Progress Lifecycle Evidence

- start: Route Plan created before code, policy, or test changes.
- mid: added validator logic and regression fixture.
- mid: removed unregistered core policy file.
- mid: added template-aware checker, fixtures, workflow wiring, and install dependency row.
- pre-merge: added focused supervision waiver for this governance-only plan after the checker flagged its route text; exact-head CI remains the final gate.
- pre-merge: refreshed checkpoint after the latest checker update; exact-head CI remains the final gate.
