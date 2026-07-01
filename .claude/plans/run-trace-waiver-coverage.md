# Route Plan — run trace waiver simulation coverage

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Target paths | scripts/enforcement/tests/test-run-trace.sh, scripts/enforcement/tests/test-simulation-coverage.sh, scripts/enforcement/simulation-coverage.d/run-trace-waiver.tsv |
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

- source: GitHub files `scripts/enforcement/enforce-run-trace.sh`, `scripts/enforcement/tests/test-run-trace.sh`, `scripts/enforcement/tests/test-simulation-coverage.sh`, and `scripts/enforcement/simulation-coverage.tsv`.
- action: checked GitHub source and coverage rows to identify the run trace waiver fixture gap.
- result: GitHub showed the gate supports `## Run Trace Waiver`, while coverage still lacked a direct fixture token for it.
- decision: added a focused run trace waiver fixture, a coverage fragment for that fixture, and a simulation-coverage regression that requires the new fragment.
- target: scripts/enforcement/tests/test-run-trace.sh, scripts/enforcement/tests/test-simulation-coverage.sh, scripts/enforcement/simulation-coverage.d/run-trace-waiver.tsv

## Documentation Asset Evidence

- internal: `scripts/enforcement/enforce-run-trace.sh`, `scripts/enforcement/tests/test-run-trace.sh`, `scripts/enforcement/tests/test-simulation-coverage.sh`, `scripts/enforcement/check-simulation-coverage.sh`, and `scripts/enforcement/simulation-coverage.tsv` were read.
- context7: not required because this is an internal shell fixture and manifest change with no external framework, SDK, API, library, or service behavior.
- decision: the current sources confirm that a direct waiver fixture plus manifest fragment is the minimal complete fix available in this editing path.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/enforce-run-trace.sh | checked |
| scripts/enforcement/tests/test-run-trace.sh | checked |
| scripts/enforcement/tests/test-simulation-coverage.sh | checked |
| scripts/enforcement/check-simulation-coverage.sh | checked |
| scripts/enforcement/simulation-coverage.tsv | checked |

## Progress Lifecycle Evidence

- start: plan committed before modifying the run trace test fixture or simulation coverage manifest.
- mid: run trace waiver fixture, coverage fragment, and simulation coverage regression were added after implementation began.
- pre-merge: branch diff reviewed after all test and manifest edits; enforcement-tests completed successfully on PR #169 head SHA `9ff9c9d522bf269bd5013ac24ac7065142ca655e`, and workflow-evidence/pr-policy failures remain the active merge blockers.

## Claude Run Trace

- goal: close the explicit run trace waiver simulation coverage gap.
- hypothesis: a direct waiver fixture lets simulation coverage require a concrete covered token.
- connectors: GitHub used for repo source inspection; no external runtime connector is needed for this internal shell fixture.
- steps: read the enforcer, test fixture, and simulation coverage contract; then added the missing waiver case and manifest fragment.
- evidence: implementation added `focused_run_trace_waiver_allows_connector_change` and a current-manifest regression requiring `run-trace-waiver`.
- rejected: changing the root simulation TSV directly was rejected because the supported `.d/` fragment path gives a smaller, safer change.
- result: code/test implementation is complete; remaining blockers are PR metadata, draft state, and policy reruns.
- follow-up: fix failing policy evidence before approval.

## DoD

- [x] Route Plan committed before code/config/test changes.
- [x] Run trace waiver fixture added.
- [x] Simulation coverage fragment points to the new waiver fixture.
- [x] Simulation coverage regression requires the new fragment.
- [x] PR checks are the gate before final approval.
