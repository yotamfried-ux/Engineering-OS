# Coverage Map Hardening Gate

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | validation, simulation-coverage, coverage-map, enforcement-inventory |
| Target paths | scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/coverage-required-gates.tsv, scripts/enforcement/tests/test-required-gates-map.sh, scripts/enforcement/simulation-coverage.d/coverage-map-hardening.tsv |
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

- github: current required gates were hidden in `check-simulation-coverage.sh` defaults while newer coverage rows live in extension files.
- github: this change makes required gates data-driven through `coverage-required-gates.tsv` and includes newer gates such as documentation-hygiene, semantic-cleanup, and coverage-map-hardening.
- github: the audit says Positive/negative simulations are partially enforced and remaining work is requiring every future gate in the manifest; this PR targets that gap without claiming full policy-row semantic mapping.
- notion: unavailable; progress lifecycle is tracked in this plan.

## Notion Progress Validation

- start: plan created before modifying coverage map enforcement.
- mid: required-gates manifest, validator update, dedicated tests, and coverage row were added before PR creation.
- pre-merge: workflows, review threads, mergeability, and head SHA will be checked before merge.

## Skill Evidence

- superpowers
- security-review

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-simulation-coverage.sh | checked and updated |
| scripts/enforcement/tests/test-simulation-coverage.sh | checked |
| scripts/enforcement/coverage-required-gates.tsv | added |
| scripts/enforcement/tests/test-required-gates-map.sh | added |
| scripts/enforcement/simulation-coverage.d/coverage-map-hardening.tsv | added |
| docs/operations/operational-readiness-audit.md | checked |

## Template Gap Waiver

reason: internal validation/governance change; no project template applies.

## Claude Run Trace

- goal: harden coverage map so required gates are not hidden inside script defaults and can be updated as a manifest.
- hypothesis: a `coverage-required-gates.tsv` manifest plus tests for active, missing, duplicate, and waived required gates will make future gate coverage drift visible in CI.
- connectors: github, notion fallback.
- result: pending CI and review.
- follow-up enforcement: deeper policy-row-to-gate mapping can build on this manifest.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Current simulation coverage checker and tests read.
- [x] Audit gap mapped to implementation scope.
- [x] Required gates manifest added.
- [x] Checker reads required gates from manifest.
- [x] Positive/negative/invalid/waiver simulations added.
- [x] Simulation coverage row added for coverage-map hardening.
- [x] Ready for PR CI validation.
