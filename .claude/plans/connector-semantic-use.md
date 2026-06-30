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

- github: read known-gaps, connector evidence checker, PR #151 review threads, and connector evidence regression tests before implementation.
- notion: unavailable; fallback plan file used.

## Connector Usage Evidence

- source: github `scripts/enforcement/check-connector-evidence.sh`, `scripts/enforcement/tests/test-connector-evidence.sh`, PR #151 review threads, and `docs/operations/known-gaps.tsv`.
- action: inspected GitHub checker code, GitHub review feedback, and GitHub regression-test coverage for connector evidence semantics.
- result: GitHub review showed three valid false-pass paths: first-token connector matching, cross-connector fallback/unavailable leakage, and empty source/action/result/decision labels; GitHub test coverage lacked these regressions.
- decision: changed the checker and tests based on GitHub evidence so active connectors require full-name evidence, scoped fallback handling, non-empty usage fields, impact-bearing decisions, and changed-target linkage.
- target: scripts/enforcement/check-connector-evidence.sh, scripts/enforcement/tests/test-connector-evidence.sh.

## Progress Lifecycle Evidence

- start: plan committed before enforcement changes.
- mid: checker, tests, audit, and gaps were updated after this plan.
- pre-merge: CI, review threads, mergeability, and head SHA must be checked live in GitHub before merge.
- review-repair: PR #151 review threads were treated as blocking because they demonstrated real false-pass paths; fixes and regression tests were added before merge consideration.

## Skill Evidence

- superpowers
- security-review

## Template/Pattern Rating Evidence

- asset: connector evidence validator pattern.
- rating: 4 medium confidence.
- outcome: reused and hardened to make connector usage evidence strict, scoped, and target-linked.
- decision: keep preferred for connector governance checks after adding false-pass regression coverage.

## Source of Truth Checks

| Source | Status |
|---|---|
| docs/operations/known-gaps.tsv | checked |
| scripts/enforcement/check-connector-evidence.sh | checked and updated |
| scripts/enforcement/tests/test-connector-evidence.sh | checked and updated |
| PR #151 review threads | checked and addressed in code/tests |
| docs/operations/operational-readiness-audit.md | checked |

## Template Gap Waiver

reason: internal governance validator change; no project template applies.

## Claude Run Trace

- goal: close connector-semantic-use without leaving a structural future-deep gap.
- hypothesis: per-connector source/action/result/decision/target evidence plus changed-target linkage is the strongest deterministic closure available.
- experiment: local connector evidence regression suite with positive/negative cases for missing evidence, vague usage, target mismatch, n/a, full connector names, scoped unavailable fallback, empty labels, and read-only decisions.
- result: local simulated connector evidence suite passed 11/11 cases before pushing fixes to PR #151.
- follow-up: rerun GitHub Actions and verify review threads are resolved/outdated before merge consideration.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Existing gap and checker inspected.
- [x] PR #151 review threads inspected.
- [x] Full connector-name false-pass fixed and covered by a negative test.
- [x] Cross-connector unavailable/fallback false-pass fixed and covered by negative/positive tests.
- [x] Empty source/action/result/decision placeholder false-pass fixed and covered by a negative test.
- [x] Decision-label-only false-pass fixed and covered by a negative test.
- [x] n/a no-connector regression fixed and covered by a positive test.
- [x] Local simulated connector evidence suite passed before pushing.

## Live External Gates Before Merge

These gates are intentionally not represented as unchecked plan checklist items because `plan-policy` treats every unchecked plan checkbox as a blocker. They must be verified directly against the PR head before merge:

- GitHub Actions passed on the final PR head.
- Review threads are resolved or outdated after the final PR head.
- Mergeability and expected head SHA are checked immediately before merge.
