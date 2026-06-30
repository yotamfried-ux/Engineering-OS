# Progress Lifecycle P1

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | progress, lifecycle, workflow-evidence |
| Target paths | scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-progress-lifecycle.sh, scripts/enforcement/tests/test-workflow-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | governance validator pattern |
| External systems/connectors | github, notion |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests, workflow-evidence-policy, capability-evidence-policy, connector-evidence-policy, plan-policy, pr-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: read workflow validator, progress tests, workflow evidence tests, known gaps, and audit files.
- notion: unavailable; fallback plan file used.

## Connector Usage Evidence

- source: github scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-progress-lifecycle.sh, and scripts/enforcement/tests/test-workflow-evidence.sh.
- action: inspected github validator and progress/workflow fixtures.
- result: github showed final-text checks did not prove checkpoint order and an older workflow fixture still assumed plan-before-code alone was enough.
- decision: implemented ordered progress lifecycle validation and repaired the legacy workflow fixture to use ordered checkpoints.
- target: scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-progress-lifecycle.sh, scripts/enforcement/tests/test-workflow-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Progress Lifecycle Evidence

- start: plan existed before validator changes.
- mid: validator and progress fixtures were committed after implementation began.
- pre-merge: workflow fixture repair was committed after the first CI failure, then this plan update recorded final progress evidence after the last test change.

## Skill Evidence

- superpowers
- security-review

## Template/Pattern Rating Evidence

- asset: governance validator pattern.
- rating: 4 medium confidence.
- outcome: reused ordered history fixtures.
- decision: keep preferred for timing checks.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/tests/test-progress-lifecycle.sh | checked |
| scripts/enforcement/tests/test-workflow-evidence.sh | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Template Gap Waiver

reason: internal governance validator change; no project template applies.

## Claude Run Trace

- goal: close progress lifecycle timing gap.
- hypothesis: commit order proves start, mid, and pre-merge timing better than final text checks.
- experiment: added fixtures for missing progress, prefilled markers, single final update, stale final evidence, valid ordered evidence, and repaired the legacy workflow evidence positive fixture.
- result: validator, tests, known-gaps closure, audit update, fixture repair, and final plan checkpoint are staged in ordered commits.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Validator update committed.
- [x] Regression fixtures committed.
- [x] Legacy workflow evidence fixture aligned with ordered lifecycle enforcement.
- [x] Known-gaps and audit updated.
- [x] Final progress checkpoint committed after implementation, docs, and fixture repair updates.

## Live External Gates Before Merge

- GitHub Actions passed on the final PR head.
- Review threads are resolved or outdated after the final PR head.
- Mergeability and expected head SHA are checked immediately before merge.
