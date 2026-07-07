# Claude Operational Evidence Route Plan

Plan Scope: standard

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | ops-readiness, telemetry, run-trace, claude-behavior |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Templates | governance-maintenance waiver |
| Architecture guides | governance-maintenance waiver |
| Patterns | governance evidence pattern |
| External systems/connectors | GitHub |
| Skills | not required |
| Validation gates | scripts/enforcement/enforce-run-trace.sh, scripts/enforcement/tests/test-run-trace.sh, scripts/enforcement/check-known-gaps.sh, scripts/enforcement/check-readiness-audit.sh |
| Evidence to check | scripts/enforcement/enforce-run-trace.sh; scripts/enforcement/tests/test-run-trace.sh; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md |
| User decisions required | none |
| selected_project_type | engineering_os_governance |
| selected_template | governance-maintenance waiver |
| selected_roadmap | docs/operations/project-type-roadmaps.md |
| selected_result_loop_contract | scripts/enforcement/result-loop-requirements.tsv |
| required_user_simulation | fixture tests for missing and present operational evidence |
| local_creator_review_path | local enforcement tests |
| telemetry_export_path | not exact-token telemetry; surrogate evidence in Route Plan |
| evidence_policy_rule | Claude Operational Evidence required for significant Engineering OS runs |
| Target paths | scripts/enforcement/enforce-run-trace.sh, scripts/enforcement/tests/test-run-trace.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| scripts/enforcement/enforce-run-trace.sh | checked | Existing gate requires Claude Run Trace for significant staged changes, but only validates goal/hypothesis/connectors/steps/evidence/rejected/result/follow-up. It does not require operational behavior evidence about Engineering OS impact, friction, false positives, quality signals, or usage surrogate. |
| scripts/enforcement/tests/test-run-trace.sh | checked | Existing fixtures cover missing trace, partial trace, connector trace, trace waiver, and significant-change triggers. New negative/positive fixtures should extend this suite. |
| docs/operations/known-gaps.tsv | checked | No explicit gap exists for Claude operational behavior evidence; monitoring is too broad and Project 8 is target-run-specific. |
| docs/operations/operational-readiness-audit.md | checked | The audit has Claude run trace coverage, monitoring sufficiency, and Project 8 gaps, but no explicit row for measuring how Engineering OS affects Claude's behavior and efficiency on every significant run. |

## Documentation Asset Evidence

- internal: `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `scripts/enforcement/enforce-run-trace.sh`; `scripts/enforcement/tests/test-run-trace.sh`.
- context7: not required; this is internal governance enforcement, not external API/library work.
- decision: extend the existing run trace gate instead of inventing a parallel monitoring mechanism, because the existing gate already identifies significant Claude runs before commit.

## Connector Evidence

- GitHub: used for repository reads/writes, PR creation, CI verification, and merge-readiness checks.

## Connector Usage Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS`, paths `scripts/enforcement/enforce-run-trace.sh`, `scripts/enforcement/tests/test-run-trace.sh`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.
- action: inspected existing run trace enforcement and audit gaps, selected the smallest extension point for collecting Claude operational behavior evidence without Claude API access.
- result: files `scripts/enforcement/enforce-run-trace.sh` and `scripts/enforcement/tests/test-run-trace.sh` show the existing gate can be extended to require new operational evidence fields on significant runs.
- decision: add required operational behavior evidence fields to the existing run trace gate, add fixtures, and register the gap/audit row so future runs collect evidence about Claude performance and Engineering OS impact, not only token usage.
- target: scripts/enforcement/enforce-run-trace.sh; scripts/enforcement/tests/test-run-trace.sh; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — this Route Plan is committed before code/config/test changes.
- `source.github-repo-read` — repository files read through GitHub.
- `validation.policy-change-has-validator` — enforcement script and fixture suite updated together.
- `validation.coderabbit-policy` — PR review or self-review fallback required before merge.

## Claude Run Trace

- goal: require future significant Claude runs to record operational behavior evidence, including how Engineering OS affected decisions, where friction occurred, and whether the run was efficient and correct.
- hypothesis: extending the existing run trace gate is the highest-ROI path because it already triggers on significant Engineering OS changes, while exact Claude token usage is unavailable without API access.
- connectors: GitHub is used for source-of-truth reads/writes and PR verification.
- steps: add audit gap, extend run trace required fields, add negative and positive fixtures, update readiness audit, open PR, verify CI, and merge only if green.
- evidence: existing run-trace gate and tests show the enforcement point; new fixtures will prove missing operational evidence fails and complete evidence passes.
- rejected: exact token accounting, because the user has no Claude API access; Project 8 telemetry, because the user explicitly excluded that real-run experiment.
- result: pending implementation.
- follow-up: use collected evidence to evaluate whether Engineering OS improves Claude's correctness and efficiency over time.

## Operational Behavior Evidence

- behavior_summary: this task strengthens Engineering OS self-observation by turning subjective Claude run quality into required structured evidence.
- engineering_os_influence: the existing Route Plan and run trace gates guided scope selection toward the existing enforcement point instead of a new parallel mechanism.
- efficiency_signals: branch creation initially failed in earlier attempts; reusing a neutral branch strategy avoided writing to main and reduced risk.
- friction_or_false_positives: exact token usage is unavailable; surrogate fields are required instead.
- quality_signals: fixture-driven enforcement is selected so future missing evidence is blocked before merge.
- usage_surrogate: exact_token_usage_available=no; wall_clock_minutes=unknown; tool_calls=GitHub reads/writes/checks; ci_runs=pending; failed_checks=pending.
- next_system_improvement: collect these fields on every significant Claude run and analyze them alongside CI/review outcomes.

## Alternatives

- Add a separate telemetry-only gate — rejected because it would duplicate run-trace selection logic and would still not access Claude API token counts.
- Require Project 8 telemetry now — rejected because the user explicitly excluded Project 8.
- Only update audit without enforcement — rejected because the user asked to start the first ROI task and avoid losing future Claude-run data.

## Affected Surfaces

- `scripts/enforcement/enforce-run-trace.sh`.
- `scripts/enforcement/tests/test-run-trace.sh`.
- `docs/operations/known-gaps.tsv`.
- `docs/operations/operational-readiness-audit.md`.

## Data/State Impact

- No application data impact. Adds governance evidence requirements only.

## Integration Impact

- No external service integration change. Uses existing GitHub PR/CI flow.

## Validation Plan

- Run `bash scripts/enforcement/tests/test-run-trace.sh`.
- Run `bash scripts/enforcement/check-known-gaps.sh`.
- Run `bash scripts/enforcement/check-readiness-audit.sh`.
- Run full `scripts/enforcement/tests/test-*.sh` suite via CI.
- Confirm all required GitHub Actions checks are green before merge.

## Open Questions

- None for the scoped implementation.

## Progress Lifecycle Evidence

- start: existing run trace enforcement, run trace fixtures, known gaps, and readiness audit were read before code/config/test edits.
- mid: pending after implementation.
- pre-merge: pending after validation and CI.

## DoD

- [ ] Register the Claude operational behavior evidence gap in known-gaps and the readiness audit.
- [ ] Extend `enforce-run-trace.sh` so significant runs require operational behavior evidence fields.
- [ ] Add negative fixture for a trace that lacks operational behavior evidence.
- [ ] Add positive fixture for complete operational behavior evidence.
- [ ] Verify run-trace, known-gaps, and readiness-audit tests.
- [ ] Do not claim exact token usage, Project 8 evidence, monitoring sufficiency, or full operational readiness.
