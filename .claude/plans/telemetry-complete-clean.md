# Route Plan: Telemetry correlation and local summary hardening

| Field | Decision |
|---|---|
| Task type | Engineering OS observability correctness fix |
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md and merged telemetry files inspected before edits. |
| Workflow evidence | This Route Plan was committed before code and test changes on this branch. |
| Domain tags | observability, telemetry, hooks, monitoring, privacy, governance |
| Plan Scope | Harden the local runtime telemetry baseline so future investigations have safe correlation metadata and local stop summaries. |
| Planning Mode | Plan-first PR with implementation and verification after the plan commit. |
| Templates | not required |
| Architecture guides | core/hooks-policy.md, docs/operations/operational-readiness-audit.md |
| External docs | Claude Code hooks reference; OpenTelemetry traces and resources concepts. |
| Patterns | not required |
| External systems/connectors | github |
| Skills | not required |
| Validation gates | enforcement-tests, pr-policy, plan-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy |
| Evidence to check | hook input schema, hashed identifiers, no raw runtime values, local summary output, CI result |
| User decisions required | owner approval before merge |
| Target paths | scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py, scripts/enforcement/tests/test-eos-telemetry.sh |

## Source of Truth Checks

| Source | Check | Result |
|---|---|---|
| Claude Code hooks reference | checked | Hook events provide JSON input suitable for safe correlation metadata. |
| OpenTelemetry traces concepts | checked | Trace/span identifiers, timestamps, events, status, and attributes are suitable for local span-event records. |
| OpenTelemetry resources concepts | checked | service.name and resource attributes should identify the local service context. |
| scripts/monitoring/eos-telemetry-event.sh | checked | Updated with hashed correlation fields, response/error metadata hashes, and stop-triggered summary generation. |
| scripts/monitoring/eos-telemetry-summary.py | checked | Updated with session and turn correlation counts plus missing-correlation signals. |
| scripts/enforcement/tests/test-eos-telemetry.sh | checked | Existing fixture kept aligned with changed privacy summary wording. |

## Documentation Asset Evidence

- internal: core/hooks-policy.md, docs/operations/operational-readiness-audit.md, scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py, scripts/enforcement/tests/test-eos-telemetry.sh.
- external: Claude Code hooks reference and OpenTelemetry traces/resources concepts.
- decision: collect only safe metadata, produce a local summary from the already-wired stop telemetry event, and avoid modifying settings or audit files in this PR.

## Capability Evidence

- routing.task-router-read: governance route selected before edits.
- workflow.workflow-read: plan-first lifecycle followed.
- source.github-repo-read: current merged telemetry files inspected before edits.
- validation.policy-change-has-validator: telemetry fixture remains part of the implementation and will be run in CI.
- validation.actions-checked: PR CI will be checked before merge.

## Connector Evidence

- github: current main telemetry files, summary reporter, fixture, and hook wiring inspected before implementation.

## Connector Usage Evidence

- source: github main files `scripts/monitoring/eos-telemetry-event.sh`, `scripts/monitoring/eos-telemetry-summary.py`, `scripts/enforcement/tests/test-eos-telemetry.sh`, and `.claude/settings.json`.
- action: read merged telemetry and hook state before implementation.
- result: github confirmed target files `scripts/monitoring/eos-telemetry-event.sh`, `scripts/monitoring/eos-telemetry-summary.py`, and `scripts/enforcement/tests/test-eos-telemetry.sh`; `.claude/settings.json` already wires `eos-telemetry-event.sh stop`.
- decision: implement stop summary generation inside the already-wired recorder instead of changing hook settings.
- target: scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py, scripts/enforcement/tests/test-eos-telemetry.sh

## Definition of Done

- [x] Recorder writes hashed session, turn, transcript, cwd, permission, source, model, response, and error metadata.
- [x] Recorder does not store raw commands, paths, transcript paths, model text, responses, connector payloads, environment values, or sensitive values.
- [x] Summary reports session and turn correlation plus missing-correlation counts.
- [x] Stop telemetry event writes a latest local summary without modifying hook settings.
- [x] Existing telemetry fixture remains aligned with privacy summary output.
- [ ] PR CI is green before requesting merge.

## Progress Lifecycle Evidence

- start: Branch created from main and this Route Plan committed before implementation changes.
- mid: Recorder, summary, and fixture alignment updates committed after the plan-first commit.
- pre-merge: Scope aligned to the files actually changed in this clean branch; audit gap closure is not claimed.

## Claude Run Trace

- goal: improve telemetry investigation data without storing raw sensitive runtime data.
- connectors: github.
- evidence: current main telemetry implementation, settings hook wiring, updated recorder, updated summary reporter, and telemetry fixture alignment.
- limitation: runtime monitoring is not closed as a production-readiness claim; real project-8 and future target-project data are still required before declaring sufficiency.
