# Route Plan - RTK impact closure

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Target paths | scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-rtk-usage-evidence.sh, scripts/enforcement/simulation-coverage.d/rtk-usage-evidence.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
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

- GitHub: inspected `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-workflow-evidence.sh`, `scripts/enforcement/tests/test-rtk-usage-evidence.sh`, and `scripts/enforcement/simulation-coverage.d/rtk-usage-evidence.tsv` before implementation.

## Connector Usage Evidence

- source: GitHub files `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-workflow-evidence.sh`, `scripts/enforcement/tests/test-rtk-usage-evidence.sh`, and `scripts/enforcement/simulation-coverage.d/rtk-usage-evidence.tsv`.
- action: checked the remaining `rtk-semantic-use` gap after PR #174 merged.
- result: RTK evidence currently requires source, action, result, and decision, but does not require the agent to record the prior assumption, the RTK finding, the impact on the decision, the target affected, confidence, and a reviewer-verifiable limitation.
- decision: require structured RTK impact evidence for RTK-declared code changes, add negative fixtures for missing impact/target/confidence and waiver behavior, align simulation coverage, and close the gap only as a structural impact-evidence gate while keeping true hidden-reasoning proof out of scope.
- target: scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-rtk-usage-evidence.sh, scripts/enforcement/simulation-coverage.d/rtk-usage-evidence.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md

## Documentation Asset Evidence

- internal: `scripts/enforcement/check-workflow-evidence.sh`, `scripts/enforcement/tests/test-rtk-usage-evidence.sh`, `scripts/enforcement/simulation-coverage.d/rtk-usage-evidence.tsv`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md` were read.
- context7: not required because this is an internal policy/test/audit change and does not implement external RTK API behavior.
- decision: close the deterministic RTK impact-evidence gap without claiming access to hidden reasoning.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/capability-registry.yaml | checked |
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/tests/test-rtk-usage-evidence.sh | checked |
| scripts/enforcement/simulation-coverage.d/rtk-usage-evidence.tsv | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Progress Lifecycle Evidence

- start: plan committed before modifying enforcement code, tests, coverage, or audit files.
- mid: workflow evidence checker updated after implementation began to require RTK prior assumption, finding, impact, target, confidence, and limitation evidence.

## Claude Run Trace

- goal: close the RTK semantic-use gap without creating a false claim of hidden-reasoning proof.
- hypothesis: requiring prior assumption, RTK finding, decision impact, target, confidence, and limitation evidence makes RTK use auditable and prevents generic RTK mentions from satisfying the gate.
- connectors: GitHub used for source inspection and branch updates.
- steps: inspect current known gap, readiness audit, workflow checker, RTK usage fixture, simulation coverage; commit this plan; then update the checker.
- evidence: checker now requires source/action/result/decision plus prior assumption/finding/impact/target/confidence/limitation, verifies target linkage, and requires impact wording to show changed/confirmed/rejected/limited/selected/avoided/narrowed decision effect.
- rejected: automatic proof that RTK changed private reasoning is rejected because hidden chain-of-thought is not observable; the closure must be an auditable impact-evidence contract.
- result: checker update complete; fixtures, coverage, and readiness records pending.
- follow-up: add fixtures, coverage alignment, readiness updates, PR, CI, review, and merge.

## DoD

- [x] Route Plan committed before code/test/doc changes.
- [x] RTK usage evidence requires prior assumption, finding, impact, target, confidence, and limitation evidence.
- [ ] Fixtures cover valid, missing, invalid, missing-impact, missing-target, missing-confidence, and waiver behavior.
- [ ] Simulation coverage row points to present fixture tokens.
- [ ] Known-gaps and audit records are updated honestly.
- [ ] PR opened and all required checks are green before merge.
