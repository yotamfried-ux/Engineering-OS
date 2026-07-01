# Route Plan - simulation coverage freshness

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Target paths | scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/tests/test-simulation-coverage.sh, scripts/enforcement/simulation-coverage.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | existing simulation coverage fixture style |
| External systems/connectors | GitHub |
| Skills | none |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy, plan-policy, pr-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- GitHub: inspected simulation coverage checker, required gate manifest, simulation coverage tests, run trace gate/tests, coverage manifests, and readiness audit before implementation.

## Connector Usage Evidence

- source: GitHub files `scripts/enforcement/check-simulation-coverage.sh`, `scripts/enforcement/tests/test-simulation-coverage.sh`, `scripts/enforcement/simulation-coverage.tsv`, `scripts/enforcement/simulation-coverage.d/run-trace-waiver.tsv`, `scripts/enforcement/enforce-run-trace.sh`, `scripts/enforcement/tests/test-run-trace.sh`, and `docs/operations/operational-readiness-audit.md`.
- action: checked the next audit hardening target after all official known gaps closed.
- result: the coverage manifest still allowed old future/pending language even when a dedicated fixture exists.
- decision: add a freshness check for stale pending language, add tests, align the run-trace row with the existing fixture token, and update the audit.
- target: scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/tests/test-simulation-coverage.sh, scripts/enforcement/simulation-coverage.tsv, docs/operations/operational-readiness-audit.md

## Documentation Asset Evidence

- internal: `scripts/enforcement/check-simulation-coverage.sh`, `scripts/enforcement/tests/test-simulation-coverage.sh`, `scripts/enforcement/simulation-coverage.tsv`, and `docs/operations/operational-readiness-audit.md` were read.
- context7: not required because this is an internal policy, test, and audit change.
- decision: prevent future simulation coverage notes from going stale.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| core/workflow.md | checked |
| scripts/enforcement/check-simulation-coverage.sh | checked |
| scripts/enforcement/tests/test-simulation-coverage.sh | checked |
| scripts/enforcement/simulation-coverage.tsv | checked |
| scripts/enforcement/simulation-coverage.d/run-trace-waiver.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Progress Lifecycle Evidence

- start: plan committed before modifying checker, tests, coverage manifest, or audit files.
- mid: simulation coverage checker updated after implementation began to reject deferred-language in coverage rows.

## Claude Run Trace

- goal: harden simulation coverage freshness.
- hypothesis: rejecting old future/pending language in coverage rows will keep the manifest aligned with actual fixtures.
- connectors: GitHub used for source inspection and branch updates.
- steps: inspect coverage checker/tests/manifests, run-trace tests, and audit row; create this Route Plan; then update the simulation coverage checker.
- evidence: checker now rejects coverage rows that still mention future loop, pending, not yet, todo, or tbd language.
- rejected: claiming all qualitative simulation depth is solved is rejected; this loop targets stale coverage notes only.
- result: checker update complete; tests, manifest, and audit pending.
- follow-up: update fixtures, manifest, audit, open PR, run CI, address review, and merge.

## DoD

- [x] Route Plan committed before code/test/doc changes.
- [x] Checker rejects stale pending/future coverage language.
- [ ] Test fixture covers stale coverage rejection.
- [ ] Run trace base coverage row uses the existing fixture token.
- [ ] Audit records stale coverage notes as blocked.
- [ ] PR opened and all required checks are green before merge.
