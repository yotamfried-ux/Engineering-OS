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
| Validation gates | scripts/enforcement/check-operational-behavior-evidence.sh, scripts/enforcement/tests/test-operational-behavior-evidence.sh, scripts/enforcement/check-pr-review-evidence.sh, scripts/enforcement/tests/test-pr-review-evidence.sh, scripts/enforcement/check-known-gaps.sh, scripts/enforcement/check-readiness-audit.sh, scripts/enforcement/check-simulation-coverage.sh |
| Evidence to check | scripts/enforcement/check-operational-behavior-evidence.sh; scripts/enforcement/tests/test-operational-behavior-evidence.sh; scripts/enforcement/check-pr-review-evidence.sh; scripts/enforcement/tests/test-pr-review-evidence.sh; scripts/enforcement/coverage-required-gates.tsv; scripts/enforcement/simulation-coverage.d/operational-behavior-evidence.tsv; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md |
| User decisions required | none |
| selected_project_type | engineering_os_governance |
| selected_template | governance-maintenance waiver |
| selected_roadmap | docs/operations/project-type-roadmaps.md |
| selected_result_loop_contract | scripts/enforcement/result-loop-requirements.tsv |
| required_user_simulation | fixture tests |
| local_creator_review_path | local checks |
| telemetry_export_path | evidence section |
| evidence_policy_rule | operational evidence schema connected to PR body policy |
| Target paths | scripts/enforcement/check-operational-behavior-evidence.sh, scripts/enforcement/tests/test-operational-behavior-evidence.sh, scripts/enforcement/check-pr-review-evidence.sh, scripts/enforcement/tests/test-pr-review-evidence.sh, scripts/enforcement/coverage-required-gates.tsv, scripts/enforcement/simulation-coverage.d/operational-behavior-evidence.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| scripts/enforcement/check-operational-behavior-evidence.sh | checked | Checker requires Operational Behavior Evidence in the PR body. |
| scripts/enforcement/tests/test-operational-behavior-evidence.sh | checked | Fixture path covers complete, missing, partial, and invalid usage availability body evidence. |
| scripts/enforcement/check-pr-review-evidence.sh | checked | Existing PR evidence script invokes the operational evidence checker. |
| scripts/enforcement/tests/test-pr-review-evidence.sh | checked | PR policy regression fixture covers missing operational evidence. |
| scripts/enforcement/coverage-required-gates.tsv | checked | Operational behavior evidence is now an active required simulation coverage gate. |
| scripts/enforcement/simulation-coverage.d/operational-behavior-evidence.tsv | checked | Meta-coverage row points at the operational behavior evidence checker and fixtures. |
| docs/operations/known-gaps.tsv | checked | Gap row records closure through PR policy wiring. |
| docs/operations/operational-readiness-audit.md | checked | Audit row records the PR policy connection and checklist paths use parse-safe formatting. |

## Documentation Asset Evidence

- internal: `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `scripts/enforcement/check-operational-behavior-evidence.sh`; `scripts/enforcement/tests/test-operational-behavior-evidence.sh`; `scripts/enforcement/check-pr-review-evidence.sh`; `scripts/enforcement/tests/test-pr-review-evidence.sh`; `scripts/enforcement/coverage-required-gates.tsv`; `scripts/enforcement/simulation-coverage.d/operational-behavior-evidence.tsv`.
- context7: not required because this is internal-only shell/Python enforcement, manifest, and audit documentation work; it does not implement, touch, use, or integrate any external library, framework, SDK, API, or service.
- decision: require operational behavior evidence in the PR body, run that check from the existing PR evidence policy script, and register the new gate in simulation coverage.

## Connector Evidence

- GitHub: repository reads and writes.

## Connector Usage Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS` and target paths.
- action: GitHub connector reads and writes connected operational behavior evidence validation to the existing PR review evidence checker and the simulation coverage manifest.
- result: `scripts/enforcement/check-pr-review-evidence.sh` invokes `scripts/enforcement/check-operational-behavior-evidence.sh`, PR #227 body records Operational Behavior Evidence directly, commit `d9de836` tightens usage availability validation, and commit `94b41de` makes `operational-behavior-evidence` an active required coverage gate.
- decision: selected the existing pr-policy path, updated checker/test/coverage scope, and avoided adding a separate workflow.
- target: scripts/enforcement/check-operational-behavior-evidence.sh; scripts/enforcement/tests/test-operational-behavior-evidence.sh; scripts/enforcement/check-pr-review-evidence.sh; scripts/enforcement/tests/test-pr-review-evidence.sh; scripts/enforcement/coverage-required-gates.tsv; scripts/enforcement/simulation-coverage.d/operational-behavior-evidence.tsv; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — plan came before edits.
- `source.github-repo-read` — repository files read.
- `validation.policy-change-has-validator` — checker, test, and coverage row added together.
- `validation.coderabbit-policy` — review or fallback required.

## Claude Run Trace

- goal: add structured operational evidence and connect it to PR policy.
- hypothesis: structured fields improve later evaluation, and PR body evidence is the clearest merge-time location.
- connectors: GitHub.
- steps: add checker, tests, PR evidence script call, gap row, audit row, coverage manifest row, and PR body evidence.
- evidence: target paths, fixtures, PR policy body validation, simulation coverage registration, and CI runs.
- rejected: unrelated target-run evidence and a separate workflow.
- result: checker path connected to PR policy; usage availability validation now requires yes/no; simulation coverage now requires the operational behavior gate.
- follow-up: inspect future PR evidence quality.

## Operational Behavior Evidence

- behavior_summary: added a schema and checker for run behavior evidence, then connected it to PR policy.
- engineering_os_influence: route-plan and audit rules kept scope explicit and required a real gate path.
- efficiency_signals: existing PR policy script was reused instead of adding another workflow.
- friction_or_false_positives: route-plan fallback complicated negative fixtures, so the final checker requires PR body evidence directly.
- quality_signals: fixtures cover missing, partial, complete, invalid usage availability, and PR-policy-path evidence.
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
- `scripts/enforcement/coverage-required-gates.tsv`.
- `scripts/enforcement/simulation-coverage.d/operational-behavior-evidence.tsv`.
- `docs/operations/known-gaps.tsv`.
- `docs/operations/operational-readiness-audit.md`.

## Data/State Impact

- No application data impact.

## Integration Impact

- PR policy script invokes operational behavior evidence checker against PR body evidence.
- Simulation coverage requires the operational behavior evidence gate to stay fixture-covered.

## Validation Plan

- Run operational evidence fixture test.
- Run PR review evidence fixture test.
- Run known-gaps check.
- Run readiness audit check.
- Run simulation coverage check.
- Confirm CI.

## Open Questions

- None.

## Progress Lifecycle Evidence

- start: source checks happened before edits.
- mid: checker, fixtures, and audit rows were added.
- mid: CI feedback showed route-plan fallback made negative fixtures ambiguous, so the checker was narrowed to direct PR body evidence and the PR body now records the schema.
- pre-merge: final plan matches changed files.
- pre-merge: after commit `d9de836`, usage availability validation requires yes/no and this plan records the final documentation, connector, and lifecycle evidence.
- pre-merge: after commit `94b41de`, the new operational behavior evidence gate is registered in simulation coverage and the required-gates manifest.

## DoD

- [x] Register operational evidence gap.
- [x] Add operational evidence checker.
- [x] Add operational evidence fixtures.
- [x] Connect checker to PR review evidence script.
- [x] Require operational evidence in the PR body.
- [x] Require usage availability to be recorded as yes/no.
- [x] Register operational behavior evidence in simulation coverage.
