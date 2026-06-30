# Coverage Map Hardening Gate

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | validation, simulation-coverage, coverage-map, enforcement-inventory |
| Target paths | scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/tests/test-simulation-coverage.sh, scripts/enforcement/coverage-required-gates.tsv, scripts/enforcement/simulation-coverage.d/coverage-map.tsv |
| Templates | not required |
| Patterns | TSV manifest validator pattern, simulation coverage manifest pattern |
| External systems/connectors | github, notion |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: read `check-simulation-coverage.sh`, `test-simulation-coverage.sh`, and the operational readiness audit before implementation.
- notion: unavailable in this session; this plan is the fallback progress tracker.

## Connector Usage Evidence

- github: current simulation coverage required gates are hard-coded in `check-simulation-coverage.sh`, while newer gate rows can live in extension files. The next hardening step is to make required gates data-driven and versioned in a manifest.
- github: the audit says Positive/negative simulations are partially enforced and remaining work is requiring every future gate in the manifest. This PR targets that exact gap by adding a required-gates manifest and validator behavior.
- notion: unavailable; progress lifecycle is tracked in this plan.

## Notion Progress Validation

- start: plan created before modifying coverage map enforcement.
- mid: required-gates manifest, validator update, and tests will be added before PR creation.
- pre-merge: workflows, review threads, mergeability, and head SHA will be checked before merge.

## Skill Evidence

- superpowers
- security-review

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-simulation-coverage.sh | checked |
| scripts/enforcement/tests/test-simulation-coverage.sh | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Template Gap Waiver

reason: internal validation/governance change; no project template applies.

## Claude Run Trace

- goal: harden coverage map so required gates are not hidden inside script defaults and can be updated as a manifest.
- hypothesis: a `coverage-required-gates.tsv` manifest plus tests for missing/duplicate/waived required gates will make future gate coverage drift visible in CI.
- connectors: github, notion fallback.
- result: pending CI and review.
- follow-up enforcement: deeper policy-row-to-gate mapping can build on this manifest.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Current simulation coverage checker and tests read.
- [x] Audit gap mapped to implementation scope.
- [ ] Required gates manifest added.
- [ ] Checker reads required gates from manifest.
- [ ] Positive/negative/invalid/waiver simulations added.
- [ ] Simulation coverage row added for coverage-map hardening.
- [ ] CI green on PR head.
- [ ] Review threads resolved/outdated with evidence.
- [ ] PR merged to main.
