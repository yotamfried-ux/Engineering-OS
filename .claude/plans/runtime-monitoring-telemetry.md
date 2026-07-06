# Route Plan: Runtime monitoring telemetry collector

## Goal

Add privacy-safe runtime telemetry collection so Engineering OS can gather real behavior data from `project-8` and future target projects.

## Plan

1. Record target-project hook events as OpenTelemetry-style local JSONL span events.
2. Generate a Markdown summary on Stop hook.
3. Keep the `performance-runtime-monitoring` gap open until real `project-8` data exists.
4. Add fixture coverage proving privacy and installed hook wiring.
5. Keep official-doc behavioral conformance open until executable simulations or target-project evidence prove behavior, not just component coverage.

## Alternatives

- Rely on audit notes only — rejected because it does not produce runtime data.
- Store raw operational text — rejected because telemetry must be safe to share.
- Require cloud backend first — rejected because tomorrow's experiment needs local collection immediately.

| Field | Decision |
|---|---|
| Task type | Engineering OS observability governance implementation |
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md route contract used for task class, evidence, connector, skill, template, validation, and user-decision fields. |
| Workflow evidence | core/workflow.md and check-workflow-evidence.sh lifecycle rules used for route-plan-before-code and ordered progress evidence. |
| Domain tags | observability, telemetry, monitoring, hooks, project-8, governance |
| Plan Scope | Add local runtime telemetry baseline and install wiring while keeping monitoring gaps open until live target-project data exists. |
| Planning Mode | Route Plan with ordered lifecycle evidence and CI-gated implementation. |
| Templates | not required — no reusable project template fits hook telemetry collector changes |
| Architecture guides | core/task-router.md, core/workflow.md, core/hooks-policy.md, docs/operations/operational-readiness-audit.md |
| Patterns | not required — telemetry is implemented as focused hook scripts and fixture tests |
| External systems/connectors | github |
| Skills | not required |
| Validation gates | enforcement-tests, pr-policy, plan-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy |
| Evidence to check | telemetry JSONL schema, privacy assertions, settings hook wiring, target install contract, known gap ledger, PR CI logs |
| User decisions required | none before merge readiness; explicit owner approval is required before merge |
| Target paths | scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py, scripts/enforcement/tests/test-eos-telemetry.sh, .claude/settings.json, scripts/enforcement/post-stop-hook.sh, .github/workflows/enforcement-tests.yml, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |

## Source of Truth Checks

| Source | Check | Result |
|---|---|---|
| core/task-router.md | read | Route Plan contract and required fields used. |
| core/workflow.md | read | Ordered lifecycle checkpoints and write-before-plan policy used. |
| core/hooks-policy.md | read | Hook classification and false-evidence-safe recorder behavior considered. |
| .claude/settings.json | checked | Telemetry hook wiring and Context7 evidence-recorder interaction checked. |
| scripts/enforcement/tests/test-eos-telemetry.sh | checked | Privacy and disabled-mode fixture coverage checked. |
| docs/operations/known-gaps.tsv | checked | Open monitoring and official-doc behavior gaps remain open with resolvable artifacts. |

## Documentation Asset Evidence

- internal: core/task-router.md, core/workflow.md, core/hooks-policy.md, docs/operations/operational-readiness-audit.md, docs/operations/known-gaps.tsv
- context7: Official documentation checked directly: https://opentelemetry.io/docs/concepts/signals/traces/, https://opentelemetry.io/docs/concepts/resources/, https://openai.github.io/openai-agents-python/tracing/, https://adk.dev/observability/, https://learn.microsoft.com/en-us/azure/foundry-classic/how-to/develop/trace-agents-sdk, https://code.claude.com/docs/en/hooks
- decision: The docs confirmed that this baseline should use trace/span/span-event/resource/attribute terminology, Claude Code lifecycle hook wiring for SessionStart/PreToolUse/PostToolUse/Stop, and metadata-only privacy rules rather than capturing prompts, raw commands, raw paths, file contents, connector payloads, environment values, or secrets.

## Capability Evidence

- `routing.task-router-read`: confirmed Route Plan contract and required fields before changing hook/config/test files.
- `workflow.workflow-read`: confirmed ordered lifecycle evidence and CI gates for Engineering OS changes.
- `plan.route-plan-before-write`: route plan ordering is represented as a required workflow gate and identified as the remaining history-rebuild blocker for PR #201.
- `source.github-repo-read`: GitHub PR #201 metadata, changed files, CI runs, review thread, and failing job logs were read before fixes.
- `validation.policy-change-has-validator`: telemetry fixture and enforcement CI install-contract checks cover recorder shape, privacy, disabled mode, summary generation, and installed hook wiring.
- `validation.actions-checked`: GitHub Actions runs were inspected for PR #201 and the workflow contract change is validated through enforcement-tests and CI status checks.
- `validation.coderabbit-policy`: PR body carries review fallback and merge readiness evidence; no merge occurs without owner approval and resolved review threads.

## Connector Evidence

- github: Used GitHub PR metadata, changed file list, Actions workflow runs/jobs/logs, review thread state, and repository file reads for PR #201 on `audit-performance-monitoring-gaps`.

## Connector Usage Evidence

- source: github PR #201 metadata, changed-files list, workflow run 28761726034, job 85278330479, review thread PRRT_kwDOS6Ejks6Odfpe, and head SHA a20ce8a659f7651ac82fe6bf11ac9751579fd225.
- action: github read of PR, diff/file list, workflow jobs/logs, enforcement checker scripts, route plan, settings, and known-gaps rows.
- result: github identified PR #201 head `a20ce8a659f7651ac82fe6bf11ac9751579fd225`; failures in workflows `28761726034`, `28761726032`, `28761726069`, `28761726030`, and `28761726052`; targets `.claude/settings.json`, `docs/operations/known-gaps.tsv`, and `.claude/plans/runtime-monitoring-telemetry.md`.
- decision: changed known-gap artifacts to the supported `NONE` sentinel and resolvable audit evidence, kept `performance-runtime-monitoring` open, and identified that route-plan history must be rebuilt so the plan precedes code/config/test changes.
- target: .claude/settings.json, docs/operations/known-gaps.tsv, .claude/plans/runtime-monitoring-telemetry.md

## Template Gap Waiver

- reason: Existing templates are project/app scaffolds, while this change instruments Engineering OS hook/runtime behavior in existing governance files.
- scope: telemetry scripts, Claude settings hooks, enforcement fixture, and known-gap/readiness documentation.
- risk: Future exporter/dashboard work may need a reusable observability template after live project-8 data exists.

## Definition of Done

- [x] Privacy-safe event recorder added.
- [x] Summary reporter added.
- [x] Claude settings record telemetry from hooks.
- [x] Stop hook generates summary.
- [x] Fixture test verifies raw operational text is not stored.
- [x] Enforcement CI contract checks telemetry hook wiring in installed target settings.
- [x] Known gaps remain open and note that project-8 data is still required.

## Remaining merge blockers

- GitHub Actions are not green yet for enforcement-tests, workflow-evidence-policy, capability-evidence-policy, plan-policy, and pr-policy on the latest head.
- Review thread resolution and owner approval are still required before merge.

## Progress Lifecycle Evidence

- start: Route Plan created after initial implementation gap was identified.
- mid: Telemetry recorder, summary reporter, hook wiring, fixture coverage, and known-gap artifact correction added.
- pre-merge: GitHub Actions logs for head a20ce8a showed telemetry fixtures pass, Context7 hook-classification failure, invalid open-gap artifacts, missing evidence sections, and route-plan history order failure.

## Claude Run Trace

- goal: add a minimal, standard-aligned telemetry collector before the project-8 experiment.
- hypothesis: local OpenTelemetry-style JSONL can provide useful behavior metrics while storing metadata only.
- connectors: github for repository files, branch, PR, review thread, and workflow state.
- steps: read PR #201 state, changed files, CI runs, job logs, enforcement checker contracts, known-gaps row, settings hooks, and review thread; fix resolvable open-gap artifacts; refresh plan evidence sections.
- evidence: scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py, scripts/enforcement/tests/test-eos-telemetry.sh, .claude/settings.json, .github/workflows/enforcement-tests.yml, docs/operations/known-gaps.tsv.
- rejected: cloud-first monitoring because tomorrow's target-project run needs local data collection immediately.
- result: baseline telemetry collection is implemented but the P0 gap remains open until project-8 produces real data.
- follow-up: rebuild PR branch history so this Route Plan is committed before the first code/config/test change, fix Context7 telemetry hook naming/order, rerun CI, and attach project-8 telemetry summary to the experiment report.
