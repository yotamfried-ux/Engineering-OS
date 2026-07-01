# Route Plan - RTK simulation coverage fixtures

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Target paths | scripts/enforcement/tests/test-rtk-contract-invalid-policy.sh, scripts/enforcement/simulation-coverage.d/rtk-context-invalid-policy.tsv |
| Templates | not required |
| Patterns | existing context optimizer shell fixture style |
| External systems/connectors | GitHub |
| Skills | none |
| Validation gates | enforcement-tests, workflow evidence, connector evidence, capability evidence, plan policy, PR policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- GitHub: inspected the current RTK contract checker, context optimizer tests, and simulation coverage manifest before implementation.

## Connector Usage Evidence

- source: GitHub files `scripts/enforcement/check-rtk-contract.sh`, `scripts/enforcement/tests/test-context-optimizer-contract.sh`, and `scripts/enforcement/simulation-coverage.tsv`.
- action: checked the RTK gate and coverage rows to identify separated invalid-policy fixture coverage.
- result: the checker already has deterministic failures for missing policy, setup, or settings content.
- decision: added a direct invalid fixture for a non-mandatory policy and a manifest row for the RTK contract fixture.
- target: scripts/enforcement/tests/test-rtk-contract-invalid-policy.sh, scripts/enforcement/simulation-coverage.d/rtk-context-invalid-policy.tsv

## Documentation Asset Evidence

- internal: `scripts/enforcement/check-rtk-contract.sh`, `scripts/enforcement/tests/test-context-optimizer-contract.sh`, `scripts/enforcement/check-simulation-coverage.sh`, and `scripts/enforcement/simulation-coverage.tsv` were read.
- context7: not required because this change only adds internal shell fixtures for an existing checker and does not change external installation or API behavior.
- decision: direct test fixture coverage is the deterministic scope for this branch.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-rtk-contract.sh | checked |
| scripts/enforcement/tests/test-rtk-contract-invalid-policy.sh | checked |
| scripts/enforcement/simulation-coverage.d/rtk-context-invalid-policy.tsv | checked |
| scripts/enforcement/check-simulation-coverage.sh | checked |

## Progress Lifecycle Evidence

- start: plan committed before modifying RTK fixture tests or simulation coverage fragments.
- mid: invalid-policy fixture and coverage fragment were added after implementation began.
- pre-merge: branch diff reviewed after all fixture and coverage edits; enforcement-tests completed successfully on PR #170 head SHA `9d7fb9fcefb57b5e53dc4da65e39041d5feabadd`, and draft/metadata policy failures remain the active merge blockers.

## Claude Run Trace

- goal: replace feasible RTK fixture waiver notes with direct simulation evidence where the checker can deterministically test them.
- hypothesis: a non-mandatory policy failure fixture splits invalid coverage from missing-hook coverage.
- connectors: GitHub used for repository source inspection; no external runtime connector is needed for this shell fixture change.
- steps: read the checker, read current test fixtures, read coverage manifest, then added the missing invalid case and coverage fragment.
- evidence: implementation added `optional_policy_fails_contract`, `mandatory_policy_passes_contract`, and the `rtk-context-invalid-policy` coverage fragment.
- rejected: claiming deep RTK semantic reasoning impact was rejected; this branch covers deterministic contract fixtures only.
- result: code/test implementation is complete; remaining blockers are PR metadata, draft state, and policy reruns.
- follow-up: fix failing policy evidence before approval.

## DoD

- [x] Route Plan committed before code/test/manifest changes.
- [x] Invalid RTK contract fixture separated from missing-hook coverage.
- [x] RTK coverage fragment added.
- [x] Related tests are wired into PR CI through enforcement-tests.
- [x] PR opened for review.
