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
- decision: updated the checker, fixtures, simulation coverage, known-gaps ledger, and readiness audit to require structured RTK impact evidence while keeping hidden-reasoning proof out of scope.
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
- pre-merge: RTK usage fixtures, simulation coverage, known-gaps ledger, and readiness audit were updated after the checker change; the branch now covers valid, missing, invalid, missing-impact, weak-impact, missing-target, wrong-target, missing-confidence, and waiver behavior.
- pre-merge: PR #175 opened after implementation and structured self-review evidence was added to the PR body.
- pre-merge: connector-evidence failure was inspected after CI and the Connector Usage Evidence decision field was corrected to state the concrete updated targets.
- pre-merge: enforcement-tests failure was inspected after CI and RTK target matching was tightened to require exact declared target path or filename evidence, preventing directory-only matches such as `src/other.js` from satisfying `src/app.js`.

## Claude Run Trace

- goal: close the RTK semantic-use gap without creating a false claim of hidden-reasoning proof.
- hypothesis: requiring prior assumption, RTK finding, decision impact, target, confidence, and limitation evidence makes RTK use auditable and prevents generic RTK mentions from satisfying the gate.
- connectors: GitHub used for source inspection, CI status, failure analysis, and branch updates.
- steps: inspect current known gap, readiness audit, workflow checker, RTK usage fixture, simulation coverage; commit this plan; update the checker; add fixture coverage; align simulation coverage; update known-gaps and audit records; open PR #175; repair Connector Usage Evidence after CI failure; then tighten exact RTK target matching after enforcement-tests exposed the directory-only match weakness.
- evidence: checker now requires source/action/result/decision plus prior assumption/finding/impact/target/confidence/limitation, verifies exact target linkage, and requires impact wording to show changed/confirmed/rejected/limited/selected/avoided/narrowed decision effect; fixtures cover missing and weak impact signals plus waiver behavior.
- rejected: automatic proof that RTK changed private reasoning is rejected because hidden chain-of-thought is not observable; the closure is an auditable impact-evidence contract.
- result: implementation complete and exact target matching repaired; CI validation pending.
- follow-up: run CI, address review, and merge.

## DoD

- [x] Route Plan committed before code/test/doc changes.
- [x] RTK usage evidence requires prior assumption, finding, impact, target, confidence, and limitation evidence.
- [x] Fixtures cover valid, missing, invalid, missing-impact, missing-target, missing-confidence, and waiver behavior.
- [x] Simulation coverage row points to present fixture tokens.
- [x] Known-gaps and audit records are updated honestly.
- [x] PR opened; CI remains the merge gate.
