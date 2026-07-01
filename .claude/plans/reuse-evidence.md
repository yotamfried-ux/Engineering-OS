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
- result: current checks require a rating section, but do not prove every declared reusable asset is rated, do not reject extra rated assets, and do not require confidence evidence.
- decision: enforce exact declared-versus-rated asset coverage, require confidence evidence, add fixtures, and keep score-quality review limits visible.
- target: scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-template-pattern-rating-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md

## Documentation Asset Evidence

- internal: target files and readiness rows were read.
- context7: not required because this is an internal policy and test change.
- decision: close structural reuse-evidence gaps and keep review-based limits explicit.

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

## Claude Run Trace

- goal: strengthen reusable asset feedback evidence.
- hypothesis: exact asset matching plus confidence evidence blocks unrelated or partial feedback from satisfying the gate.
- connectors: GitHub used for source inspection and branch updates.
- steps: read routing, workflow, capability, checker, tests, and readiness files; create this plan; update the checker; add fixture coverage; update known gaps and readiness audit records; then open PR #174.
- evidence: checker now compares declared reusable assets with assets named in evidence, requires confidence evidence, and tests cover valid, multi-asset, missing, invalid, wrong, extra, partial, and waiver cases.
- rejected: score accuracy remains review based.
- result: implementation complete and PR opened; CI validation pending.
- follow-up: run CI, address review, and merge after green checks.

## DoD

- [x] Route Plan committed before code/test/doc changes.
- [x] Checker requires exact reusable asset coverage.
- [x] Checker rejects extra rated assets.
- [x] Checker requires confidence evidence.
- [x] Fixtures cover valid, missing, invalid, wrong, extra, partial, and waiver cases.
- [x] Known-gaps and audit records are updated.
- [x] PR opened; CI remains the merge gate.
