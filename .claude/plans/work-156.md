# Work 156

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | policy, lesson-quality |
| Target paths | scripts/enforcement/enforce-learning-capture.sh, scripts/enforcement/tests/test-learning-capture.sh, scripts/enforcement/tests/test-learning-quality.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | not required |
| External systems/connectors | github |
| Skills | none |
| Validation gates | pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy, enforcement-tests |

## Capability Evidence

- `routing.task-router-read` — checked.
- `workflow.workflow-read` — checked.
- `plan.route-plan-before-write` — this plan is committed before script edits.
- `source.github-repo-read` — GitHub files inspected before edits.
- `validation.policy-change-has-validator` — script change includes regression fixtures.
- `validation.coderabbit-policy` — PR review policy will be checked before merge.

## Connector Evidence

- github: checked scripts/enforcement/enforce-learning-capture.sh, scripts/enforcement/tests/test-learning-capture.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Connector Usage Evidence

- source: github scripts/enforcement/enforce-learning-capture.sh, scripts/enforcement/tests/test-learning-capture.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.
- action: github checked current gate, tests, gap row, and audit row.
- result: github showed the gate checks headings but not enough content quality.
- decision: github selected enforce-learning-capture.sh and test-learning-quality.sh for stronger validation.
- target: scripts/enforcement/enforce-learning-capture.sh, scripts/enforcement/tests/test-learning-capture.sh, scripts/enforcement/tests/test-learning-quality.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Progress Lifecycle Evidence

- start: plan committed before script, test, gap, and audit edits.
- mid: script and regression fixture commits exist after implementation began.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/enforce-learning-capture.sh | checked |
| scripts/enforcement/tests/test-learning-capture.sh | checked |
| scripts/enforcement/tests/test-learning-quality.sh | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Claude Run Trace

- goal: close the P1 lesson-quality gap with deterministic content checks.
- hypothesis: root-cause, evidence, regression, prevention, and failed-solution linkage checks block shallow lessons.
- result: script and dedicated regression fixture were added.

## DoD

- [x] Plan created before edits.
- [x] Script quality checks added.
- [x] Regression fixture added.
