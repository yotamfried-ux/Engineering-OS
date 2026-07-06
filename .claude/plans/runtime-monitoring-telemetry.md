# Route Plan: Runtime monitoring telemetry collector

## Goal

Add privacy-safe runtime telemetry collection so Engineering OS can gather real behavior data from `project-8` and future target projects.

## Plan

1. Record target-project hook events as OpenTelemetry-style local JSONL span events.
2. Generate a Markdown summary on Stop hook.
3. Keep the `performance-runtime-monitoring` gap open until real `project-8` data exists.
4. Add fixture coverage proving privacy and installed hook wiring.

## Alternatives

- Rely on audit notes only — rejected because it does not produce runtime data.
- Store raw operational text — rejected because telemetry must be safe to share.
- Require cloud backend first — rejected because tomorrow's experiment needs local collection immediately.

| Field | Decision |
|---|---|
| Task class | observability_governance |
| Task-router evidence | Engineering OS route reviewed in prior readiness work. |
| Workflow evidence | Runtime evidence and post-stop flow reviewed. |
| Domain tags | observability, telemetry, monitoring, evals, project-8 |
| Templates | not required |
| Patterns | not required |
| External systems/connectors | github |
| Skills | not required |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy |
| Evidence to check | telemetry JSONL schema, privacy assertions, settings hook wiring, installed target contract |
| User decisions required | none before local telemetry baseline; future external dashboard choice remains open |

## Source of Truth Checks

| Need | Source checked | Result |
|---|---|---|
| Observability standard | Official OpenTelemetry/OpenAI/Google/Microsoft docs checked in chat | local span-event summary chosen |
| Existing hook wiring | `.claude/settings.json` | telemetry recorder added to hooks |
| Stop hook summary point | `scripts/enforcement/post-stop-hook.sh` | summary generated at session stop |
| Known gap tracking | `docs/operations/known-gaps.tsv` | gap remains open until project-8 data exists |

## Definition of Done

- [x] Privacy-safe event recorder added.
- [x] Summary reporter added.
- [x] Claude settings record telemetry from hooks.
- [x] Stop hook generates summary.
- [x] Fixture test verifies raw operational text is not stored.
- [x] Enforcement CI contract checks telemetry hook wiring in installed target settings.
- [x] Known gap remains open and notes that project-8 data is still required.

## Progress Lifecycle Evidence

- start: Route Plan created after initial implementation gap was identified.
- mid: Telemetry recorder, summary reporter, hook wiring, and fixture coverage added.
- pre-merge: Telemetry route plan and readiness audit refreshed after test and CI contract updates; pending live GitHub Actions validation.

## Claude Run Trace

- goal: add a minimal, standard-aligned telemetry collector before the project-8 experiment.
- hypothesis: local OpenTelemetry-style JSONL can provide useful behavior metrics while storing metadata only.
- connectors: github for repository files, branch, PR, and workflow state.
- steps: add recorder, add summary reporter, wire hooks, add privacy fixture, update known gap notes.
- evidence: scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py, scripts/enforcement/tests/test-eos-telemetry.sh, .claude/settings.json, .github/workflows/enforcement-tests.yml.
- rejected: cloud-first monitoring because tomorrow's target-project run needs local data collection immediately.
- result: baseline telemetry collection is implemented but the P0 gap remains open until project-8 produces real data.
- follow-up: run the project-8 experiment and attach the telemetry summary to the experiment report.
