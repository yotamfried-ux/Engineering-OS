# Route Plan — RTK simulation coverage fixtures

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Target paths | scripts/enforcement/tests/test-context-optimizer-contract.sh, scripts/enforcement/simulation-coverage.d/rtk-context-fixtures.tsv |
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

- GitHub: inspected the current RTK contract checker, current context optimizer test, and simulation coverage manifest before implementation.

## Connector Usage Evidence

- source: GitHub files `scripts/enforcement/check-rtk-contract.sh`, `scripts/enforcement/tests/test-context-optimizer-contract.sh`, and `scripts/enforcement/simulation-coverage.tsv`.
- action: checked the RTK gate and coverage row to identify missing separated invalid and waiver fixtures.
- result: the checker already has deterministic failures for missing policy, setup, or settings content.
- decision: add direct invalid fixture coverage for a non-mandatory policy and a manifest row for the intentionally non-waivable RTK contract.
- target: scripts/enforcement/tests/test-context-optimizer-contract.sh, scripts/enforcement/simulation-coverage.d/rtk-context-fixtures.tsv

## Documentation Asset Evidence

- internal: `scripts/enforcement/check-rtk-contract.sh`, `scripts/enforcement/tests/test-context-optimizer-contract.sh`, `scripts/enforcement/check-simulation-coverage.sh`, and `scripts/enforcement/simulation-coverage.tsv` were read.
- context7: not required because this change only adds internal shell fixtures for an existing checker and does not change external RTK installation or API behavior.
- decision: direct test fixture coverage is enough for the deterministic gap; deeper semantic RTK reasoning impact remains a Claude/runtime-level future gap.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-rtk-contract.sh | checked |
| scripts/enforcement/tests/test-context-optimizer-contract.sh | checked |
| scripts/enforcement/check-simulation-coverage.sh | checked |
| scripts/enforcement/simulation-coverage.tsv | checked |

## Progress Lifecycle Evidence

- start: plan committed before modifying RTK fixture tests or simulation coverage fragments.

## Claude Run Trace

- goal: replace feasible RTK fixture waivers with direct simulation evidence where the checker can deterministically test them.
- hypothesis: adding a non-mandatory policy failure fixture will split invalid coverage from missing-hook coverage, and a focused manifest row can document the remaining non-waivable contract behavior.
- connectors: GitHub used for repository source inspection; no external runtime connector is needed for this shell fixture change.
- steps: read the checker, read current test fixtures, read coverage manifest, add the missing invalid case and coverage fragment.
- evidence: implementation and validation will be recorded in mid/pre-merge lifecycle updates.
- rejected: claiming deep RTK semantic reasoning impact was rejected; this change only covers deterministic contract fixtures.
- result: pending implementation.
- follow-up: if CI fails, fix the specific fixture before approval.

## DoD

- [ ] Route Plan committed before code/test/manifest changes.
- [ ] Invalid RTK contract fixture separated from missing-hook coverage.
- [ ] RTK coverage fragment added.
- [ ] Related tests verified by CI.
- [ ] PR opened for review.
