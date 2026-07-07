# Operational Evidence PR Gate Plan

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | ops-readiness, pr-policy |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Templates | governance-maintenance waiver |
| Architecture guides | governance-maintenance waiver |
| Patterns | governance evidence pattern |
| External systems/connectors | GitHub |
| Skills | not required |
| Validation gates | scripts/enforcement/check-pr-review-evidence.sh, scripts/enforcement/check-operational-behavior-evidence.sh, scripts/enforcement/tests/test-pr-review-evidence.sh, scripts/enforcement/tests/test-operational-behavior-evidence.sh, scripts/enforcement/check-known-gaps.sh, scripts/enforcement/check-readiness-audit.sh |
| Evidence to check | scripts/enforcement/check-pr-review-evidence.sh; scripts/enforcement/check-operational-behavior-evidence.sh; scripts/enforcement/tests/test-pr-review-evidence.sh; scripts/enforcement/tests/test-operational-behavior-evidence.sh; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md |
| User decisions required | none |
| selected_project_type | engineering_os_governance |
| selected_template | governance-maintenance waiver |
| selected_roadmap | docs/operations/project-type-roadmaps.md |
| selected_result_loop_contract | scripts/enforcement/result-loop-requirements.tsv |
| required_user_simulation | PR evidence and operational evidence fixtures |
| local_creator_review_path | local checks |
| telemetry_export_path | surrogate evidence section |
| evidence_policy_rule | operational evidence checker invoked from PR review checker |
| Target paths | scripts/enforcement/check-pr-review-evidence.sh, scripts/enforcement/check-operational-behavior-evidence.sh, scripts/enforcement/tests/test-operational-behavior-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| scripts/enforcement/check-pr-review-evidence.sh | checked | Existing script is invoked by pr-policy on PRs; this task connects the new operational evidence checker here. |
| scripts/enforcement/check-operational-behavior-evidence.sh | checked | New checker validates behavior, system influence, efficiency, friction, quality, surrogate data, and next improvement fields. |
| scripts/enforcement/tests/test-operational-behavior-evidence.sh | checked | Fixtures cover complete, missing, partial, and incomplete evidence. |
| docs/operations/known-gaps.tsv | checked | Gap is closed only after PR policy script wiring. |
| docs/operations/operational-readiness-audit.md | checked | Matrix row is Enforced only after wiring. |

## Documentation Asset Evidence

- internal: `scripts/enforcement/check-pr-review-evidence.sh`; `scripts/enforcement/check-operational-behavior-evidence.sh`; `scripts/enforcement/tests/test-operational-behavior-evidence.sh`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`.
- context7: not required.
- decision: use the existing PR policy script instead of adding a new workflow.

## Connector Evidence

- GitHub: repository reads and writes.

## Connector Usage Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS`, paths named in Target paths.
- action: connected operational evidence validation to the existing PR review evidence checker.
- result: `scripts/enforcement/check-pr-review-evidence.sh` now invokes `scripts/enforcement/check-operational-behavior-evidence.sh`; `docs/operations/known-gaps.tsv` and `docs/operations/operational-readiness-audit.md` record the connection.
- decision: rely on the existing `pr-policy` workflow path that already runs `check-pr-review-evidence.sh`.
- target: scripts/enforcement/check-pr-review-evidence.sh; scripts/enforcement/check-operational-behavior-evidence.sh; scripts/enforcement/tests/test-operational-behavior-evidence.sh; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — original plan existed before code edits; this plan records the final PR gate wiring.
- `source.github-repo-read` — repository files read.
- `validation.policy-change-has-validator` — checker and fixture test are paired.
- `validation.coderabbit-policy` — review or fallback required.

## Claude Run Trace

- goal: connect operational behavior evidence to a real PR gate.
- hypothesis: using the existing PR evidence script gives a real CI path with less workflow risk.
- connectors: GitHub.
- steps: add checker, add fixtures, call checker from PR evidence script, update gap and audit status.
- evidence: changed target paths and CI results.
- rejected: adding a new workflow file.
- result: pending CI.
- follow-up: inspect future PR evidence quality.

## Operational Behavior Evidence

- behavior_summary: this task connects operational behavior evidence to PR policy.
- engineering_os_influence: audit, known-gaps, route-plan, and PR-policy rules forced a real gate path before closure.
- efficiency_signals: used the existing PR evidence script instead of a new workflow.
- friction_or_false_positives: direct workflow creation was avoided after connector friction.
- quality_signals: fixture coverage exists for missing, partial, and complete evidence.
- usage_surrogate: exact_metering_available=no; tool_calls=GitHub operations.
- next_system_improvement: review evidence quality in future PRs.

## Alternatives

- New workflow file — rejected.
- Project 8 evidence — out of scope.

## Affected Surfaces

- `scripts/enforcement/check-pr-review-evidence.sh`.
- `scripts/enforcement/check-operational-behavior-evidence.sh`.
- `scripts/enforcement/tests/test-operational-behavior-evidence.sh`.
- `docs/operations/known-gaps.tsv`.
- `docs/operations/operational-readiness-audit.md`.

## Data/State Impact

- No application data impact.

## Integration Impact

- Existing PR policy script now invokes the operational evidence checker.

## Validation Plan

- Run operational evidence fixture test.
- Run PR review evidence fixture test.
- Run known-gaps check.
- Run readiness audit check.
- Confirm CI.

## Open Questions

- None.

## Progress Lifecycle Evidence

- start: source checks and initial plan existed before code edits.
- mid: checker, fixture, audit, and gap rows were added.
- pre-merge: final plan records the PR policy script connection before CI re-check.

## DoD

- [x] Add operational evidence checker.
- [x] Add operational evidence fixtures.
- [x] Connect checker to PR review evidence script.
- [x] Mark gap and audit as connected through existing PR policy path.
