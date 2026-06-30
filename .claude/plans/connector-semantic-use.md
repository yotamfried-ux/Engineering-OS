# Connector Semantic Use

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | connector, semantic-use, decision-impact |
| Target paths | scripts/enforcement/check-connector-evidence.sh, scripts/enforcement/tests/test-connector-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | connector evidence validator pattern |
| External systems/connectors | github, notion |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests, connector-evidence-policy, workflow-evidence-policy, capability-evidence-policy, plan-policy, pr-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: read known-gaps and connector evidence checker before implementation.
- notion: unavailable; fallback plan file used.

## Connector Usage Evidence

- source: github `docs/operations/known-gaps.tsv`, `scripts/enforcement/check-connector-evidence.sh`, and `scripts/enforcement/tests/test-connector-evidence.sh`.
- action: inspected current connector evidence semantics.
- result: found usage evidence only checks loose words and does not require per-connector decision impact or target path linkage.
- decision: tighten the checker and fixtures so connector use must prove source/action/result/decision/target for changed targets.
- target: scripts/enforcement/check-connector-evidence.sh, scripts/enforcement/tests/test-connector-evidence.sh.

## Progress Lifecycle Evidence

- start: plan committed before enforcement changes.
- mid: checker, tests, audit, and gaps will be updated after this plan.
- pre-merge: CI, review threads, mergeability, and head SHA will be checked before merge.

## Skill Evidence

- superpowers
- security-review

## Template/Pattern Rating Evidence

- asset: connector evidence validator pattern.
- rating: 4 medium confidence.
- outcome: reused to make connector usage evidence strict and target-linked.
- decision: keep preferred for connector governance checks.

## Source of Truth Checks

| Source | Status |
|---|---|
| docs/operations/known-gaps.tsv | checked |
| scripts/enforcement/check-connector-evidence.sh | checked |
| scripts/enforcement/tests/test-connector-evidence.sh | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Template Gap Waiver

reason: internal governance validator change; no project template applies.

## Claude Run Trace

- goal: close connector-semantic-use without leaving a structural future-deep gap.
- hypothesis: per-connector source/action/result/decision/target evidence plus changed-target linkage is the strongest deterministic closure available.
- result: ready for implementation.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Existing gap and checker inspected.
- [x] Ready for implementation and PR CI validation.
