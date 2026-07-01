# Route Plan - coverage completion

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

- GitHub: inspected the branch changes after implementation.

## Connector Usage Evidence

- source: GitHub files `scripts/enforcement/check-simulation-coverage.sh`, `scripts/enforcement/tests/test-simulation-coverage.sh`, `scripts/enforcement/simulation-coverage.tsv`, and `docs/operations/operational-readiness-audit.md`.
- action: recorded completion evidence for the coverage hardening branch.
- result: checker, tests, manifest, and audit were updated.
- decision: keep PR #176 as draft until the original plan evidence is repaired.
- target: scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/tests/test-simulation-coverage.sh, scripts/enforcement/simulation-coverage.tsv, docs/operations/operational-readiness-audit.md

## Documentation Asset Evidence

- internal: target files were read.
- context7: not required for an internal policy change.
- decision: use local enforcement tests as the validation source.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-simulation-coverage.sh | checked |
| scripts/enforcement/tests/test-simulation-coverage.sh | checked |
| scripts/enforcement/simulation-coverage.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Progress Lifecycle Evidence

- start: plan evidence is in coverage-hardening.md before implementation.
- mid: checker change is recorded in coverage-hardening.md after implementation began.
- pre-merge: tests, manifest, audit, and PR #176 draft status were recorded after implementation.

## Claude Run Trace

- goal: record coverage hardening completion.
- hypothesis: branch can proceed once plan evidence is repaired.
- connectors: GitHub used for branch inspection and PR creation.
- steps: inspect branch and open draft PR.
- evidence: PR #176 exists as draft with changed checker, tests, manifest, and audit files.
- result: draft PR opened; original plan still needs repair.
- follow-up: repair original plan, rerun CI, and merge after green checks.

## DoD

- [x] Completion evidence recorded.
