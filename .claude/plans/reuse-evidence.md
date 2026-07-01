# Route Plan - reuse evidence

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Target paths | scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-template-pattern-rating-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | existing workflow evidence fixture style |
| External systems/connectors | GitHub |
| Skills | none |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy, plan-policy, pr-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- GitHub: inspected routing, workflow, capability registry, current checker, fixture tests, known gaps, and readiness audit before implementation.

## Connector Usage Evidence

- source: GitHub files `core/task-router.md`, `core/workflow.md`, `core/capability-registry.yaml`, `scripts/enforcement/check-workflow-evidence.sh`, `scripts/enforcement/tests/test-template-pattern-rating-evidence.sh`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.
- action: checked the remaining reusable asset feedback evidence gap.
- result: current checks require a rating section, but do not prove every declared pattern asset is rated, do not reject extra rated pattern assets, and do not require confidence evidence.
- decision: implemented exact declared pattern asset coverage, confidence evidence, fixtures, and readiness record updates; template assets still require rating evidence and manifest coverage.
- target: scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-template-pattern-rating-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md

## Documentation Asset Evidence

- internal: `scripts/enforcement/check-workflow-evidence.sh`, `scripts/enforcement/tests/test-template-pattern-rating-evidence.sh`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md` were read.
- context7: not required because this is an internal policy and test change.
- decision: close structural pattern-feedback gaps and keep review-based limits explicit.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/capability-registry.yaml | checked |
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/tests/test-template-pattern-rating-evidence.sh | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Progress Lifecycle Evidence

- start: plan committed before modifying enforcement code, tests, or audit files.
- mid: workflow evidence checker updated after implementation began to require exact reusable asset coverage and confidence evidence.
- pre-merge: fixtures and readiness records updated after checker change; branch now covers valid, multi-asset, missing, invalid, wrong, extra, partial, and waiver cases and records the structural gap as closed.
- pre-merge: PR #174 opened after implementation and self-review evidence was added to the PR body.
- pre-merge: failed documentation and connector evidence runs were inspected, then plan evidence fields were corrected with concrete internal file paths and an explicit implemented decision.
- pre-merge: checker compatibility update completed after the evidence repair; existing workflow fixture compatibility is preserved while dedicated reuse fixtures cover wrong, extra, and partial pattern feedback.
- pre-merge: missing helper failure was diagnosed from the workflow evidence run and fixed after the compatibility update.

## Claude Run Trace

- goal: strengthen reusable asset feedback evidence.
- hypothesis: exact pattern-asset matching plus confidence evidence blocks unrelated or partial pattern feedback from satisfying the gate.
- connectors: GitHub used for source inspection, CI status, CI failure analysis, and branch updates.
- steps: read routing, workflow, capability, checker, tests, and readiness files; create this plan; update the checker; add fixture coverage; update known gaps and readiness audit records; open PR #174; inspect failed evidence checks; repair plan evidence fields; adapt checker compatibility after the workflow fixture update was blocked by tool safety; then add the missing helper used by the compatibility checker.
- evidence: checker now compares declared pattern assets with pattern assets named in evidence, requires confidence evidence, and tests cover valid, multi-asset, missing, invalid, wrong, extra, partial, and waiver cases.
- rejected: automatic score truth and forced template exactness without updating the legacy workflow fixture are rejected; score accuracy stays review based and template assets still require rating evidence plus manifest coverage.
- result: implementation complete and missing helper repair recorded.
- follow-up: run CI, address review, and merge after green checks.

## DoD

- [x] Route Plan committed before code/test/doc changes.
- [x] Checker requires exact declared pattern asset coverage.
- [x] Checker rejects extra rated pattern assets.
- [x] Checker requires confidence evidence.
- [x] Fixtures cover valid, missing, invalid, wrong, extra, partial, and waiver cases.
- [x] Known-gaps and audit records are updated.
- [x] PR opened; CI remains the merge gate.
