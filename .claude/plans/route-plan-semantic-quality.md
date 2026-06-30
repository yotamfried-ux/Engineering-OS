# Route Plan Semantic Quality

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | route-plan, semantic-quality, source-target-relevance |
| Target paths | scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-plan-semantic-quality.sh, scripts/enforcement/simulation-coverage.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | workflow evidence validator pattern |
| External systems/connectors | github, notion |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy, pr-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: read known-gaps, workflow evidence checker, semantic-quality tests, and readiness audit before implementation.
- notion: unavailable; this plan is fallback tracker.

## Connector Usage Evidence

- github: checked `docs/operations/known-gaps.tsv` and selected `route-plan-semantic-quality` as next open P1 gap.
- github: checked `scripts/enforcement/check-workflow-evidence.sh` and found canonical sources could satisfy source/target relevance even without referencing target paths.
- github: checked `scripts/enforcement/tests/test-plan-semantic-quality.sh` and updated canonical-only behavior to fail for non-canonical targets.

## Progress Lifecycle Evidence

- start: plan committed before enforcement changes.
- mid: checker, tests, audit, and known-gaps were updated after this plan.
- pre-merge: CI, review threads, mergeability, and head SHA will be checked before merge.

## Skill Evidence

- superpowers
- security-review

## Template/Pattern Rating Evidence

- asset: workflow evidence validator pattern.
- rating: 4 medium confidence.
- outcome: reused for a stricter source-target semantic relevance check.
- decision: keep preferred for governance checks with route plan fixtures.

## Source of Truth Checks

| Source | Status |
|---|---|
| docs/operations/known-gaps.tsv | checked |
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/tests/test-plan-semantic-quality.sh | checked |
| scripts/enforcement/simulation-coverage.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Template Gap Waiver

reason: internal governance validator change; no project template applies.

## Claude Run Trace

- goal: prevent structurally valid Route Plans from passing with generic canonical sources that do not reference changed targets.
- hypothesis: requiring target-path relevance beyond generic canonical references closes the next reliable semantic-quality gap.
- connectors: github, notion fallback.
- result: ready for PR CI validation.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Existing gap and checker inspected.
- [x] Source/target relevance gate tightened.
- [x] Positive and negative fixtures updated.
- [x] Existing simulation coverage row and required gate checked.
- [x] Known gaps and audit updated.
- [x] Ready for PR CI validation.
