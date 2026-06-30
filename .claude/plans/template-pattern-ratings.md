# Template and Pattern Ratings Lifecycle

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | templates, patterns, rating, reuse, learning |
| Target paths | docs/operations/template-pattern-ratings.tsv, scripts/enforcement/check-template-pattern-ratings.sh, scripts/enforcement/tests/test-template-pattern-ratings.sh, scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-template-pattern-rating-evidence.sh, scripts/enforcement/simulation-coverage.d/template-pattern-ratings.tsv, scripts/enforcement/coverage-required-gates.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
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

- github: read task-router, known-gaps, workflow evidence checker, plan quality tests, and required-gates manifest before implementation.
- notion: unavailable in this session; this plan is the fallback tracker.

## Connector Usage Evidence

- github: checked `core/task-router.md` and found templates/patterns are selected before work but not systematically rated after use.
- github: checked `check-workflow-evidence.sh` and found it validates presence/evidence/waiver but has no template/pattern rating lifecycle gate.
- github: checked `known-gaps.tsv` and found no dedicated gap for template/pattern rating feedback.
- github: checked `coverage-required-gates.tsv` and used it to plan a required gate for template-pattern-ratings.

## Progress Lifecycle Evidence

- start: this Route Plan is committed before rating lifecycle enforcement changes.
- mid: rating manifest, validator, workflow gate, tests, coverage, and audit/gaps updates will be committed after this plan.
- pre-merge: final PR workflows, review threads, mergeability, and head SHA will be checked before merge.

## Skill Evidence

- superpowers
- security-review

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/tests/test-plan-quality.sh | checked |
| docs/operations/known-gaps.tsv | checked |
| scripts/enforcement/coverage-required-gates.tsv | checked |

## Template Gap Waiver

reason: internal governance/enforcement change for template and pattern rating lifecycle; no project template applies.

## Claude Run Trace

- goal: enforce systematic rating of templates and patterns so future Route Plans can prefer proven assets and avoid weak ones.
- hypothesis: a rating manifest plus Route Plan rating evidence gate catches silent reuse without feedback.
- connectors: github, notion fallback.
- result: pending CI/review/merge.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Current template/pattern routing and workflow evidence enforcement inspected.
- [ ] Rating manifest added.
- [ ] Rating manifest validator added.
- [ ] Route Plan rating evidence gate added for concrete templates/patterns.
- [ ] Positive/negative/invalid/waiver simulations added.
- [ ] Simulation coverage row and required gate added.
- [ ] Known gaps and audit updated.
- [ ] CI green on PR head.
- [ ] Review threads resolved/outdated with evidence.
- [ ] PR merged to main.
