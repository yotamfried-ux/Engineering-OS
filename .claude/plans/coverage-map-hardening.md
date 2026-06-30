# Coverage Map Hardening Gate

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | validation, simulation-coverage, coverage-map |
| Target paths | scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/coverage-required-gates.tsv, scripts/enforcement/tests/test-required-gates-map.sh, scripts/enforcement/simulation-coverage.d/coverage-map-hardening.tsv |
| Templates | not required |
| Patterns | TSV manifest validator pattern |
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

- github: repository files were read before implementation.
- notion: unavailable; this plan is the fallback tracker.

## Connector Usage Evidence

- github: checked the current checker and used the result to create `coverage-required-gates.tsv`.
- github: read the audit and used the evidence to keep scope limited to coverage drift.
- github: validated the new manifest, test file, and coverage row on this branch.

## Progress Lifecycle Evidence

- start: plan committed first.
- mid: manifest, checker update, tests, and coverage row were added after the plan.
- pre-merge: final PR workflows, review threads, mergeability, and head SHA will be checked.

## Skill Evidence

- superpowers
- security-review

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-simulation-coverage.sh | checked |
| scripts/enforcement/tests/test-simulation-coverage.sh | checked |
| docs/operations/operational-readiness-audit.md | checked |
| scripts/enforcement/coverage-required-gates.tsv | added |

## Template Gap Waiver

reason: internal validation change; no project template applies.

## Claude Run Trace

- goal: make required simulation gates data-driven.
- hypothesis: a manifest plus tests for active, absent, duplicate, and waived rows catches coverage drift.
- connectors: github, notion fallback.
- result: pending repaired CI.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Required gates manifest added.
- [x] Checker reads required gates from manifest.
- [x] Positive/negative/invalid/waiver simulations added.
- [x] Simulation coverage row added for coverage-map hardening.
- [x] Ready for repaired PR CI validation.
