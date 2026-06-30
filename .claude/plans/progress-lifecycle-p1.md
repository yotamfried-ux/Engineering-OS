# Progress Lifecycle P1

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | progress, lifecycle, workflow-evidence, anti-backfill |
| Target paths | scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-progress-lifecycle.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
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

- github: read `scripts/enforcement/check-workflow-evidence.sh`, `scripts/enforcement/tests/test-progress-lifecycle.sh`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md` before implementation.
- notion: unavailable; fallback plan file used for progress tracking.

## Connector Usage Evidence

- source: github `scripts/enforcement/check-workflow-evidence.sh`, `scripts/enforcement/tests/test-progress-lifecycle.sh`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.
- action: inspected GitHub workflow evidence validator, existing progress lifecycle fixtures, and current gap/audit state.
- result: GitHub showed progress lifecycle enforcement only checks that final plan text contains start/mid/pre-merge words; it does not prove checkpoints were committed in the correct order.
- decision: implemented a deterministic commit-order lifecycle gate that requires start evidence before code/config/test changes, mid evidence after work begins, and pre-merge evidence after the last code/config/test change.
- target: scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-progress-lifecycle.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Progress Lifecycle Evidence

- start: this plan is committed before enforcement changes.
- mid: workflow validator and progress lifecycle regression tests were committed after implementation work began.
- pre-merge: final CI/review/mergeability evidence will be recorded after the last implementation/doc change.

## Skill Evidence

- superpowers
- security-review

## Template/Pattern Rating Evidence

- asset: governance validator pattern.
- rating: 4 medium confidence.
- outcome: reused the shell/Python semantic validator plus ordered git-history fixture pattern.
- decision: keep preferred because commit order is the strongest deterministic signal available for progress lifecycle timing.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/tests/test-progress-lifecycle.sh | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |
| .github/workflows/workflow-evidence-policy.yml | checked |

## Template Gap Waiver

reason: internal governance validator change; no project template applies.

## Claude Run Trace

- goal: close `progress-semantic-lifecycle` without leaving a future-deep backfill path.
- hypothesis: final plan text alone cannot prove lifecycle timing; git commit ordering can deterministically prove start before work, mid after work begins, and pre-merge after the last implementation change.
- experiment: implemented ordered git-history fixtures covering prefilled markers, single final backfill, code after pre-merge evidence, missing progress evidence, and a valid ordered lifecycle.
- result: implementation and regression fixtures are committed; CI validation is pending after PR creation.
- follow-up: update known-gaps/audit, add final pre-merge checkpoint, rerun GitHub Actions, inspect CodeRabbit/Codex review threads, then merge only with expected head SHA.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Existing workflow evidence validator inspected.
- [x] Existing progress lifecycle tests inspected.
- [x] Existing known-gaps/audit state inspected.
- [x] Validator fails when lifecycle markers exist only in the initial pre-code plan.
- [x] Validator fails when lifecycle markers are added only once after all code without ordered evidence.
- [x] Validator fails when code/config/test changes after the final pre-merge progress update.
- [x] Validator passes when start is committed before code, mid after work begins, and pre-merge after last code change.
- [ ] `progress-semantic-lifecycle` row is updated only after validator and tests prove ordered lifecycle enforcement.
- [ ] GitHub Actions passed on final PR head.
- [ ] Review threads resolved or outdated after final PR head.
- [ ] Mergeability and expected head SHA checked before merge.
