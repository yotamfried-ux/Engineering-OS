# Operational Work History Route Plan

Plan Scope: standard

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | ops-readiness, enforcement, operational-work-history, learning-loop, result-loop |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Templates | not required |
| Architecture guides | docs/operations/operational-work-history.md, docs/operations/operational-work-history-rollout.md, docs/operations/result-loop-contract-plan.md, docs/operations/runtime-telemetry-archive-plan.md, core/learning-loop.md |
| Patterns | not required |
| External systems/connectors | GitHub |
| Skills | not required |
| Validation gates | scripts/enforcement/check-operational-work-history-evidence.sh, scripts/enforcement/tests/test-operational-work-history-evidence.sh, scripts/enforcement/tests/test-collect-pr-work-history.sh, scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh, scripts/enforcement/check-pr-review-evidence.sh, scripts/enforcement/check-known-gaps.sh, scripts/enforcement/check-readiness-audit.sh, scripts/enforcement/check-simulation-coverage.sh, .github/workflows/enforcement-tests.yml, .github/workflows/pr-policy.yml, workflow-evidence-policy.yml, connector-evidence-policy.yml, capability-evidence-policy.yml |
| Evidence to check | docs/operations/known-gaps.tsv row 27; docs/operations/operational-readiness-audit.md; scripts/enforcement/check-route-plan-contract.sh; scripts/enforcement/check-result-loop-contract.py; scripts/enforcement/check-operational-behavior-evidence.sh; scripts/enforcement/check-pr-review-evidence.sh; scripts/monitoring/eos-telemetry-event.sh; .claude/settings.json; core/learning-loop.md; scripts/enforcement/enforce-learning-capture.sh |
| User decisions required | none — user explicitly chose CI-generated Operational Work History evidence over the 8-field manual Route Plan requirement |
| selected_project_type | engineering_os_governance |
| selected_template | governance-maintenance waiver |
| Target paths | .github/workflows/pr-policy.yml, scripts/monitoring/collect-pr-work-history.py, scripts/enforcement/check-operational-work-history-evidence.sh, scripts/enforcement/tests/test-operational-work-history-evidence.sh, scripts/enforcement/tests/test-collect-pr-work-history.sh, scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| docs/operations/known-gaps.tsv | checked | Result-loop per-PR declaration remains open until the Operational Work History foundation proves itself across real PRs. |
| .github/workflows/pr-policy.yml | checked | PR policy is the live CI path for collecting GitHub check/review metadata and validating the generated artifact. |
| scripts/monitoring/collect-pr-work-history.py | checked | Collector is the artifact source and must preserve metadata-only privacy. |
| scripts/enforcement/check-operational-work-history-evidence.sh | checked | Checker validates the artifact and learning-loop routing for PRs with changed files. |
| scripts/enforcement/check-pr-review-evidence.sh | checked | PR body evidence and merge-readiness validation invoke the work-history checker. |

## Documentation Asset Evidence

- internal: `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `docs/operations/operational-work-history.md`; `docs/operations/operational-work-history-rollout.md`; `docs/operations/result-loop-contract-plan.md`; `docs/operations/runtime-telemetry-archive-plan.md`; `core/learning-loop.md`; `.github/workflows/pr-policy.yml`.
- context7: not required — internal governance/checker/test/workflow work; no third-party API/library behavior changed.
- decision: build Operational Work History on top of existing telemetry and learning-loop systems rather than inventing parallel systems.

## Template Gap Waiver

This internal governance-maintenance PR does not select a project template because it updates repository policy gates, operational documentation, and CI wiring rather than creating or extending a generated project. The template field is intentionally not required for this task.

## Template/Pattern Rating Waiver

No reusable template or pattern asset is selected, modified, or evaluated by this PR. The task reuses existing governance evidence conventions, so template/pattern rating evidence is not applicable.

## Connector Evidence

- GitHub: repository reads/writes, PR #233 review/CI inspection, PR-body evidence, and CI workflow metadata collection.

## Connector Usage Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS`, PR #233, review threads on `.github/workflows/pr-policy.yml`, `scripts/monitoring/collect-pr-work-history.py`, and `scripts/enforcement/check-operational-work-history-evidence.sh`.
- action: used GitHub to inspect CI runs, review threads, current branch files, and then update the affected workflow/checker/collector files.
- result: review-thread fixes preserve non-empty `ci.json` from `gh pr checks`, sanitize review metadata, count MCP calls by frequency, and allow Hebrew friction reasons.
- decision: kept the artifact metadata-only and fail-closed; blocked merge while any policy check or review thread remained open.
- target: .github/workflows/pr-policy.yml; scripts/monitoring/collect-pr-work-history.py; scripts/enforcement/check-operational-work-history-evidence.sh.

## Capability Evidence

- `routing.task-router-read` — task-router source was checked before implementation.
- `workflow.workflow-read` — workflow lifecycle evidence is maintained in this original plan.
- `plan.route-plan-before-write` — this plan existed before the implementation and is the single lifecycle surface for follow-up fixes.
- `source.github-repo-read` — GitHub PR, CI, review, and file state were checked before edits.
- `validation.policy-change-has-validator` — policy/checker behavior is covered by enforcement tests and PR policy CI.
- `validation.actions-checked` — workflow wiring is validated by `test-pr-policy-workflow-wiring.sh` and real `pr-policy` runs.
- `validation.coderabbit-policy` — review-thread comments were inspected and valid findings were fixed before merge.

## Graphify Usage Evidence

- source: original graphify check on operational-readiness assets.
- action: used direct GitHub file reads for governance docs, workflow YAML, shell scripts, and TSV manifests because those surfaces are outside graphify's code-symbol graph.
- result: relevant call sites and workflow pinning were confirmed directly from source files.
- decision: scope changes to the confirmed call sites and target paths; no unrelated refactors.
- target: .github/workflows/pr-policy.yml; scripts/monitoring/collect-pr-work-history.py; scripts/enforcement/check-operational-work-history-evidence.sh.

## Review Findings Addressed

1. Preserve non-empty `ci.json` when `gh pr checks` exits non-zero for pending/failing checks.
2. Sanitize review metadata so raw review bodies are not uploaded in the work-history artifact.
3. Count MCP telemetry by frequency rather than unique MCP tool name.
4. Accept concrete Hebrew friction reasons in addition to English friction keywords.
5. Keep Stage 1 without any automatic filename-only exemption.

## Lessons Reused

- `lessons-learned/bugs/ci-environment-dependent-fixture-premise.md` — fixture unavailability is constructed by test inputs, not by assuming runner tools are absent.
- `lessons-learned/bugs/mawk-ignorecase-unsupported.md` — new case-insensitive matching uses Python regex rather than gawk-only behavior.
- `lessons-learned/bugs/security-gate-silent-diff-truncation.md` — required git facts fail closed instead of collapsing to empty metadata.

## Alternatives

- Wiring `check-route-plan-contract.sh`'s 8 fields into real PR-diff CI gating — rejected.
- A filename-only single-file exemption — rejected after review.
- Committing the generated artifact — rejected; it is a build product.
- Persisting raw changed-file paths, raw commit subjects, or raw review bodies in the artifact — rejected.
- Closing `operational-work-history-foundation`, `monitoring-metrics-sufficiency`, or `project-8-real-run-evidence` — rejected as overclaiming.

## Affected Surfaces

- .github/workflows/pr-policy.yml
- scripts/monitoring/collect-pr-work-history.py
- scripts/enforcement/check-operational-work-history-evidence.sh
- scripts/enforcement/tests/test-operational-work-history-evidence.sh
- scripts/enforcement/tests/test-collect-pr-work-history.sh
- scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh
- docs/operations/known-gaps.tsv
- docs/operations/operational-readiness-audit.md
- docs/operations/operational-work-history.md
- docs/operations/operational-work-history-rollout.md

## Data/State Impact

- No application data impact. `.engineering-os/work-history/` is a gitignored, CI-workspace-only build product.
- The uploaded GitHub Actions artifact remains metadata-only after review metadata sanitization.

## Integration Impact

- `pr-policy.yml` collects CI/review metadata and preserves non-empty CI JSON even when `gh pr checks` exits non-zero.
- `collect-pr-work-history.py` writes sanitized metadata-only review summaries and frequency-accurate MCP counters.
- `check-operational-work-history-evidence.sh` accepts Hebrew or English concrete friction reasons.
- No existing gate is weakened.

## Validation Plan

- Run `bash scripts/enforcement/tests/test-operational-work-history-evidence.sh`.
- Run `bash scripts/enforcement/tests/test-collect-pr-work-history.sh`.
- Run `bash scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh`.
- Run `bash scripts/enforcement/check-known-gaps.sh`, `check-readiness-audit.sh`, and `check-simulation-coverage.sh`.
- Confirm real PR CI: `enforcement-tests`, `pr-policy`, workflow/connector/capability/documentation/plan policy gates, import cleanup, and semantic cleanup.

## Open Questions

- None for this PR. Future low-risk exemptions require a real diff-aware classifier and real-PR evidence.

## DoD

- [x] Add Operational Work History architecture docs and rollout tracking.
- [x] Add CI-generated artifact generator.
- [x] Add same-workspace telemetry handoff helper.
- [x] Add Operational Work History evidence checker.
- [x] Wire the checker into PR review evidence and pr-policy.
- [x] Add named enforcement-tests steps and coverage/simulation registrations.
- [x] Update known-gaps/audit without closing the new foundation gap.
- [x] Add and harden fixtures for no-exemption, empty changed-file metadata, artifact-count mismatch, invalid base SHA, friction-signal learning-loop routing, and workflow wiring.
- [x] Align privacy docs and artifact fields so raw paths/subjects/review bodies are not persisted.
- [x] Fix valid PR review threads before merge.
- [x] External PR checks own merge-readiness verification.

## Claude Run Trace

- goal: replace the open per-PR Route Plan declaration dimension with CI-generated Operational Work History evidence and harden the implementation after review.
- hypothesis: automatic evidence plus learning-loop routing gives better long-term scaling than a heavy manual Route Plan or weak filename-only exemptions.
- connectors: GitHub.
- steps: read source-of-truth docs/checkers; implemented docs, collector, checker, CI wiring, tests; verified CI; inspected review threads; fixed valid review findings.
- evidence: real PR checks now identify only current failures; review-thread fixes are encoded directly in workflow/checker/collector code.
- rejected: raw review-body persistence, unique-only MCP counts, English-only friction reasons, and deleting non-empty CI metadata on non-zero `gh pr checks`.
- result: final branch state is judged by CI and review threads before merge.
- follow-up: evaluate Stage 3 OTLP or a diff-aware low-risk exemption classifier only after several real PRs use this gate.

## Progress Lifecycle Evidence

- start: read known-gaps.tsv row 27, result-loop contract docs, runtime telemetry docs, workflow gates, PR policy, and prior plans before the first implementation edit; this plan existed before implementation.
- mid: implementation commit added docs/schema, artifact generator, checker, CI wiring, and test suites after the Route Plan commit.
- pre-merge: clean-history pre-merge checkpoint follows the implementation and mid checkpoint commits, preserving plan-before-code ordering for workflow-evidence-policy before CI re-verification.

## Operational Behavior Evidence

behavior_summary: Added and hardened a CI-generated Operational Work History artifact/gate that supersedes the open per-PR Route Plan declaration dimension of `result-loop-contract-enforcement`.
engineering_os_influence: Engineering OS gates and review loops shaped the implementation: the design avoided manual reporting, preserved learning-loop routing, removed weak bypasses, and forced lifecycle evidence into the original plan.
efficiency_signals: Reused existing telemetry, PR evidence, workflow, and learning-loop surfaces rather than creating parallel systems.
friction_or_false_positives: Review threads found real issues in metadata preservation, metadata-only review handling, MCP counts, and Hebrew friction reasons; all were fixed directly.
quality_signals: Tests and real PR checks cover positive, negative, dummy, no-exemption, empty metadata, count mismatch, invalid git refs, friction-signal routing, and pr-policy wiring cases.
usage_surrogate: exact_token_usage_available=no; tool_calls=GitHub repo reads/writes, CI status checks, PR review/thread operations.
next_system_improvement: Revisit low-risk exemptions only through a diff-aware classifier after multiple real PRs prove the foundation.

## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
learning_loop_result: none-with-reason — review-thread fixes are encoded directly in code, tests, and plan lifecycle evidence in this PR; no separate lesson file is needed.
