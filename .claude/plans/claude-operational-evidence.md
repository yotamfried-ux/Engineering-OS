# Operational Evidence Route Plan

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | ops-readiness |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Templates | governance-maintenance waiver |
| Architecture guides | governance-maintenance waiver |
| Patterns | governance evidence pattern |
| External systems/connectors | GitHub |
| Skills | not required |
| Validation gates | scripts/enforcement/check-operational-behavior-evidence.sh, scripts/enforcement/tests/test-operational-behavior-evidence.sh, scripts/enforcement/check-pr-review-evidence.sh, scripts/enforcement/tests/test-pr-review-evidence.sh, scripts/enforcement/check-known-gaps.sh, scripts/enforcement/check-readiness-audit.sh |
| Evidence to check | scripts/enforcement/check-operational-behavior-evidence.sh; scripts/enforcement/tests/test-operational-behavior-evidence.sh; scripts/enforcement/check-pr-review-evidence.sh; scripts/enforcement/tests/test-pr-review-evidence.sh; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md |
| User decisions required | none |
| selected_project_type | engineering_os_governance |
| selected_template | governance-maintenance waiver |
| selected_roadmap | docs/operations/project-type-roadmaps.md |
| selected_result_loop_contract | scripts/enforcement/result-loop-requirements.tsv |
| required_user_simulation | fixture tests |
| local_creator_review_path | local checks |
| telemetry_export_path | evidence section |
| evidence_policy_rule | operational evidence schema connected to PR body policy |
| Target paths | scripts/enforcement/check-operational-behavior-evidence.sh, scripts/enforcement/tests/test-operational-behavior-evidence.sh, scripts/enforcement/check-pr-review-evidence.sh, scripts/enforcement/tests/test-pr-review-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| scripts/enforcement/check-operational-behavior-evidence.sh | checked | Checker requires Operational Behavior Evidence in the PR body. |
| scripts/enforcement/tests/test-operational-behavior-evidence.sh | checked | Fixture path covers complete, missing, and partial body evidence. |
| scripts/enforcement/check-pr-review-evidence.sh | checked | Existing PR evidence script invokes the operational evidence checker. |
| scripts/enforcement/tests/test-pr-review-evidence.sh | checked | PR policy regression fixture covers missing operational evidence. |
| docs/operations/known-gaps.tsv | checked | Gap row records closure through PR policy wiring. |
| docs/operations/operational-readiness-audit.md | checked | Audit row records the PR policy connection. |

## Documentation Asset Evidence

- internal: `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `scripts/enforcement/check-operational-behavior-evidence.sh`; `scripts/enforcement/tests/test-operational-behavior-evidence.sh`; `scripts/enforcement/check-pr-review-evidence.sh`; `scripts/enforcement/tests/test-pr-review-evidence.sh`.
- context7: not required.
- decision: require operational behavior evidence in the PR body and run that check from the existing PR evidence policy script.

## Connector Evidence

- GitHub: repository reads and writes.

## Connector Usage Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS` and target paths.
- action: connected operational behavior evidence validation to the existing PR review evidence checker.
- result: `scripts/enforcement/check-pr-review-evidence.sh` invokes `scripts/enforcement/check-operational-behavior-evidence.sh`, and PR #227 body now records Operational Behavior Evidence directly.
- decision: use the existing pr-policy path instead of a new workflow.
- target: scripts/enforcement/check-operational-behavior-evidence.sh; scripts/enforcement/tests/test-operational-behavior-evidence.sh; scripts/enforcement/check-pr-review-evidence.sh; scripts/enforcement/tests/test-pr-review-evidence.sh; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — plan came before edits.
- `source.github-repo-read` — repository files read.
- `validation.policy-change-has-validator` — checker and test added together.
- `validation.coderabbit-policy` — review or fallback required.

## Claude Run Trace

- goal: add structured operational evidence and connect it to PR policy.
- hypothesis: structured fields improve later evaluation, and PR body evidence is the clearest merge-time location.
- connectors: GitHub.
- steps: add checker, tests, PR evidence script call, gap row, audit row, and PR body evidence.
- evidence: target paths, fixtures, PR policy body validation, and CI runs.
- rejected: unrelated target-run evidence and a separate workflow.
- result: checker path connected to PR policy; CI verification is in progress.
- follow-up: inspect future PR evidence quality.

## Operational Behavior Evidence

- behavior_summary: added a schema and checker for run behavior evidence, then connected it to PR policy.
- engineering_os_influence: route-plan and audit rules kept scope explicit and required a real gate path.
- efficiency_signals: existing PR policy script was reused instead of adding another workflow.
- friction_or_false_positives: route-plan fallback complicated negative fixtures, so the final checker requires PR body evidence directly.
- quality_signals: fixtures cover missing, partial, complete, and PR-policy-path evidence.
- usage_surrogate: exact_metering_available=no; tool_calls=GitHub operations.
- next_system_improvement: review future PR bodies and improve the evidence schema.

## Alternatives

- target-run telemetry was not used.
- separate workflow was avoided in favor of the existing PR policy path.

## Affected Surfaces

- `scripts/enforcement/check-operational-behavior-evidence.sh`.
- `scripts/enforcement/tests/test-operational-behavior-evidence.sh`.
- `scripts/enforcement/check-pr-review-evidence.sh`.
- `scripts/enforcement/tests/test-pr-review-evidence.sh`.
- `docs/operations/known-gaps.tsv`.
- `docs/operations/operational-readiness-audit.md`.

## Data/State Impact

- No application data impact.

## Integration Impact

- PR policy script invokes operational behavior evidence checker against PR body evidence.

## Validation Plan

- Run operational evidence fixture test.
- Run PR review evidence fixture test.
- Run known-gaps check.
- Run readiness audit check.
- Confirm CI.

## Open Questions

- None.

## Progress Lifecycle Evidence

- start: source checks happened before edits.
- mid: checker, fixtures, and audit rows were added.
- mid: CI feedback showed route-plan fallback made negative fixtures ambiguous, so the checker was narrowed to direct PR body evidence and the PR body now records the schema.
- pre-merge: final plan matches changed files.

## DoD

- [x] Register operational evidence gap.
- [x] Add operational evidence checker.
- [x] Add operational evidence fixtures.
- [x] Connect checker to PR review evidence script.
- [x] Require operational evidence in the PR body.
