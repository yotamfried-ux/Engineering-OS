# Progress Lifecycle P1

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | progress, lifecycle, workflow-evidence |
| Target paths | scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-progress-lifecycle.sh, scripts/enforcement/tests/test-workflow-evidence.sh, scripts/enforcement/tests/test-plan-quality.sh, scripts/enforcement/tests/test-plan-semantic-quality.sh, scripts/enforcement/tests/test-rtk-usage-evidence.sh, scripts/enforcement/tests/test-template-pattern-rating-evidence.sh, scripts/enforcement/simulation-coverage.tsv, scripts/enforcement/simulation-coverage.d/rtk-usage-evidence.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | governance validator pattern |
| External systems/connectors | github |
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

- github: read workflow validator, progress tests, legacy workflow tests, plan quality tests, RTK tests, template rating tests, simulation coverage, known gaps, and audit files.

## Connector Usage Evidence

- source: github workflow validator, test fixtures, and simulation coverage manifests.
- action: inspected github fixtures after enforcement-tests failed.
- result: github showed legacy fixtures still used plan-before-code without ordered lifecycle updates, and coverage rows needed alignment with the repaired tests.
- decision: kept ordered lifecycle enforcement, aligned legacy fixtures, and aligned coverage metadata for the repaired test set.
- target: scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-progress-lifecycle.sh, scripts/enforcement/tests/test-workflow-evidence.sh, scripts/enforcement/tests/test-plan-quality.sh, scripts/enforcement/tests/test-plan-semantic-quality.sh, scripts/enforcement/tests/test-rtk-usage-evidence.sh, scripts/enforcement/tests/test-template-pattern-rating-evidence.sh, scripts/enforcement/simulation-coverage.tsv, scripts/enforcement/simulation-coverage.d/rtk-usage-evidence.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Progress Lifecycle Evidence

- start: plan existed before validator changes.
- mid: validator and first progress fixtures were committed after implementation began.
- pre-merge: fixture and coverage repairs were committed after CI exposed them, then this plan update recorded final progress evidence after the last simulation manifest change.

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
| scripts/enforcement/tests/test-plan-quality.sh | checked |
| scripts/enforcement/tests/test-plan-semantic-quality.sh | checked |
| scripts/enforcement/tests/test-rtk-usage-evidence.sh | checked |
| scripts/enforcement/tests/test-template-pattern-rating-evidence.sh | checked |
| scripts/enforcement/simulation-coverage.tsv | checked |
| scripts/enforcement/simulation-coverage.d/rtk-usage-evidence.tsv | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Claude Run Trace

- goal: close progress lifecycle timing gap.
- hypothesis: commit order proves start, mid, and pre-merge timing better than final text checks.
- experiment: added ordered progress fixtures, repaired legacy fixtures that called the workflow evidence checker, and aligned simulation coverage metadata.
- result: validator, tests, known-gaps closure, audit update, fixture repair, coverage repair, simulation manifest repair, and final plan checkpoint are staged in ordered commits.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Validator update committed.
- [x] Progress regression fixtures committed.
- [x] Legacy workflow, plan quality, semantic quality, RTK, and template rating fixtures aligned with ordered lifecycle enforcement.
- [x] Simulation coverage metadata aligned with the repaired test set.
- [x] Known-gaps and audit updated.
- [x] Final progress checkpoint committed after implementation, docs, fixture, coverage, and simulation manifest updates.

## Live External Gates Before Merge

- GitHub Actions passed on the final PR head.
- Review threads are resolved or outdated after the final PR head.
- Mergeability and expected head SHA are checked immediately before merge.
