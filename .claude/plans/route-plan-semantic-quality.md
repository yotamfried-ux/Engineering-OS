# Route Plan Semantic Quality

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | route-plan, semantic-quality |
| Target paths | scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-plan-semantic-quality.sh, scripts/enforcement/tests/test-progress-lifecycle.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
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

- github: read repo sources before implementation.
- notion: unavailable; fallback plan file used.

## Connector Usage Evidence

- github: checked known-gaps and workflow checker before editing.

## Progress Lifecycle Evidence

- start: plan committed before enforcement edits.
- mid: checker, tests, audit, and gaps updated after plan.
- pre-merge: CI and review checked before merge.

## Skill Evidence

- superpowers
- security-review

## Template/Pattern Rating Evidence

- asset: workflow evidence validator pattern.
- rating: 4 medium confidence.
- outcome: reused for source-target relevance tests.
- decision: keep preferred for similar governance checks.

## Source of Truth Checks

| Source | Status |
|---|---|
| docs/operations/known-gaps.tsv | checked |
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/tests/test-plan-semantic-quality.sh | checked |
| scripts/enforcement/tests/test-progress-lifecycle.sh | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Template Gap Waiver

reason: internal governance validator change; no project template applies.

## Claude Run Trace

- goal: strengthen Route Plan source and target relevance.
- hypothesis: stricter path matching improves semantic quality.
- result: ready for implementation.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Sources inspected.
- [x] Ready for implementation and PR CI validation.
