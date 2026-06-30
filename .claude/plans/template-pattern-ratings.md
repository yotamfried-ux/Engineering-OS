# Template Pattern Ratings

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | templates, patterns, rating, reuse |
| Target paths | docs/operations/template-pattern-ratings.tsv, scripts/enforcement/check-template-pattern-ratings.sh, scripts/enforcement/tests/test-template-pattern-ratings.sh, scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-template-pattern-rating-evidence.sh, scripts/enforcement/simulation-coverage.d/template-pattern-ratings.tsv |
| Templates | not required |
| Patterns | workflow evidence validator pattern, TSV manifest validator pattern |
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

- github: read task-router, workflow checker, known-gaps, and required gates before implementation.
- notion: unavailable; this plan is the fallback tracker.

## Connector Usage Evidence

- github: checked `core/task-router.md` and found selection exists but rating feedback was missing.
- github: checked `check-workflow-evidence.sh` and used it to add Route Plan rating evidence.
- github: checked `coverage-required-gates.tsv` and used it to add required coverage for rating lifecycle.

## Progress Lifecycle Evidence

- start: plan created before code changes.
- mid: manifest, validator, workflow gate, tests, coverage, audit, and known-gaps were added after the plan.
- pre-merge: final CI, review threads, mergeability, and head SHA will be checked before merge.

## Skill Evidence

- superpowers
- security-review

## Template/Pattern Rating Evidence

- asset: TSV manifest validator pattern.
- rating: 4 medium confidence.
- outcome: reused successfully for template-pattern rating lifecycle.
- decision: prefer this pattern for future small governance manifests.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/tests/test-plan-quality.sh | checked |
| docs/operations/known-gaps.tsv | checked |
| scripts/enforcement/coverage-required-gates.tsv | checked |

## Template Gap Waiver

reason: internal governance change; no project template applies.

## Claude Run Trace

- goal: enforce systematic template/pattern ratings for future reuse decisions.
- hypothesis: rating manifest plus Route Plan rating evidence catches silent reuse without feedback.
- connectors: github, notion fallback.
- result: ready for PR CI validation.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Current routing and workflow evidence enforcement inspected.
- [x] Rating manifest added.
- [x] Rating validator added.
- [x] Route Plan rating evidence gate added.
- [x] Positive/negative/invalid/waiver simulations added.
- [x] Simulation coverage rows and required gates added.
- [x] Known gaps and audit updated.
- [x] Ready for PR CI validation.
