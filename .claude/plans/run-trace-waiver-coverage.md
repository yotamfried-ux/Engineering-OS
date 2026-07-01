# Route Plan — run trace waiver simulation coverage

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Target paths | scripts/enforcement/tests/test-run-trace.sh, scripts/enforcement/simulation-coverage.tsv |
| Templates | not required |
| Patterns | existing run trace simulation fixture style |
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

- GitHub: inspected the current run trace gate, test fixture, and simulation coverage manifest before implementation.

## Connector Usage Evidence

- source: GitHub files `scripts/enforcement/enforce-run-trace.sh`, `scripts/enforcement/tests/test-run-trace.sh`, and `scripts/enforcement/simulation-coverage.tsv`.
- action: checked GitHub source and coverage rows to identify the run trace waiver fixture gap.
- result: GitHub showed the gate supports `## Run Trace Waiver`, while `simulation-coverage.tsv` still marks waiver coverage as pending.
- decision: update the run trace test with a focused waiver fixture and update the simulation manifest to require it.
- target: scripts/enforcement/tests/test-run-trace.sh, scripts/enforcement/simulation-coverage.tsv

## Documentation Asset Evidence

- internal: `scripts/enforcement/enforce-run-trace.sh`, `scripts/enforcement/tests/test-run-trace.sh`, `scripts/enforcement/check-simulation-coverage.sh`, and `scripts/enforcement/simulation-coverage.tsv` were read.
- context7: not required because this is an internal shell fixture and manifest change with no external framework, SDK, API, library, or service behavior.
- decision: the current sources confirm that a direct waiver fixture plus manifest update is the minimal complete fix.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/enforce-run-trace.sh | checked |
| scripts/enforcement/tests/test-run-trace.sh | checked |
| scripts/enforcement/check-simulation-coverage.sh | checked |
| scripts/enforcement/simulation-coverage.tsv | checked |

## Progress Lifecycle Evidence

- start: plan committed before modifying the run trace test fixture or simulation coverage manifest.

## Claude Run Trace

- goal: close the explicit run trace waiver simulation coverage gap.
- hypothesis: a direct waiver fixture will let the coverage manifest replace the waiver note with a concrete covered token.
- connectors: GitHub used for repo source inspection; no external runtime connector is needed for this internal shell fixture.
- steps: read the enforcer, test fixture, and simulation coverage contract; then add the missing waiver case.
- evidence: implementation and validation will be recorded in later lifecycle updates.
- rejected: leaving the manifest waiver in place was rejected because feasible coverage waivers should become fixtures.
- result: pending implementation.
- follow-up: update the manifest token and verify the related test suites.

## DoD

- [ ] Route Plan committed before code/config/test changes.
- [ ] Run trace waiver fixture added.
- [ ] Simulation coverage manifest points to the new waiver fixture.
- [ ] Relevant enforcement tests verified.
- [ ] PR checks reviewed before merge decision.
