# Route Plan: Complete telemetry monitoring fix

| Field | Decision |
|---|---|
| Task type | Engineering OS observability correctness fix |
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md and existing telemetry/audit files inspected before edits. |
| Workflow evidence | This Route Plan is committed before code, config, test, and audit changes on this branch. |
| Domain tags | observability, telemetry, hooks, monitoring, privacy, governance |
| Plan Scope | Complete the local runtime telemetry baseline so future investigations have safe correlation metadata, automatic summaries, restored hook behavior, tests, and explicit audit gap tracking. |
| Planning Mode | Plan-first PR with implementation and verification after the plan commit. |
| Templates | not required |
| Architecture guides | core/hooks-policy.md, docs/operations/operational-readiness-audit.md, docs/operations/known-gaps.tsv |
| External docs | Claude Code hooks reference; OpenTelemetry traces and resources concepts. |
| Patterns | not required |
| External systems/connectors | github |
| Skills | not required |
| Validation gates | enforcement-tests, pr-policy, plan-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy |
| Evidence to check | hook input schema, hashed identifiers, no raw runtime values, Stop summary wiring, restored hook behavior, known-gap linkage, CI result |
| User decisions required | owner approval before merge |
| Target paths | .claude/settings.json, scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py, scripts/enforcement/tests/test-eos-telemetry.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |

## Source of Truth Checks

| Source | Check | Result |
|---|---|---|
| Claude Code hooks reference | checked | Hook events provide JSON input suitable for safe correlation metadata. |
| OpenTelemetry traces concepts | checked | Trace/span identifiers, timestamps, events, status, and attributes are suitable for local span-event records. |
| OpenTelemetry resources concepts | checked | service.name and resource attributes should identify the local service context. |
| .claude/settings.json | checked | Telemetry must be added without weakening existing enforcement or advisory hooks; Stop must keep post-stop enforcement first. |
| scripts/monitoring/eos-telemetry-event.sh | checked | Needs hashed correlation fields and response/error hashes while keeping raw values out of JSONL. |
| scripts/monitoring/eos-telemetry-summary.py | checked | Needs session and turn correlation counts plus missing-correlation signals. |
| scripts/enforcement/tests/test-eos-telemetry.sh | checked | Needs simulations for correlation, privacy, invalid JSON, disabled mode, and summary output. |
| docs/operations/known-gaps.tsv | checked | Runtime telemetry sufficiency must remain open until real target-project data proves coverage. |
| docs/operations/operational-readiness-audit.md | checked | Any non-closed gap must be referenced by the readiness matrix and freshness ledger. |

## Documentation Asset Evidence

- internal: core/hooks-policy.md, .claude/settings.json, scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py, scripts/enforcement/tests/test-eos-telemetry.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.
- external: Claude Code hooks reference and OpenTelemetry traces/resources concepts.
- decision: collect safe metadata only, create an automatic local summary at Stop, and keep the monitoring sufficiency gap open until project-8/future runs validate actual investigation coverage.

## Capability Evidence

- routing.task-router-read: governance route selected before edits.
- workflow.workflow-read: plan-first lifecycle followed.
- source.github-repo-read: current merged files inspected before edits.
- validation.policy-change-has-validator: telemetry fixture covers the new behavior.
- validation.actions-checked: PR CI will be checked before merge.

## Connector Evidence

- github: current main files and prior PR/CI state inspected before implementation.

## Connector Usage Evidence

- source: github main files `.claude/settings.json`, `scripts/monitoring/eos-telemetry-event.sh`, `scripts/monitoring/eos-telemetry-summary.py`, `scripts/enforcement/tests/test-eos-telemetry.sh`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.
- action: read merged telemetry, hook, test, and audit state before implementation.
- result: github confirmed target files and the missing pieces: hashed runtime correlation, Stop summary, restored hook behavior, stronger fixture coverage, and open audit gap linkage.
- decision: update those targets in one clean branch after this plan-first commit.
- target: .claude/settings.json, scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py, scripts/enforcement/tests/test-eos-telemetry.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md

## Definition of Done

- [ ] Recorder writes hashed session, turn, transcript, cwd, permission, source, model, response, and error metadata.
- [ ] Recorder does not store raw commands, paths, transcript paths, user text, responses, connector payloads, environment values, or sensitive values.
- [ ] Summary reports session and turn correlation plus missing-correlation counts.
- [ ] Stop hook writes latest summary after post-stop enforcement.
- [ ] Existing advisory/enforcement hooks are preserved or restored.
- [ ] Fixture checks schema, trace/span/resource/attributes, category detection, correlation, summary, invalid JSON, disabled mode, and raw-value absence.
- [ ] Runtime telemetry sufficiency is tracked as an open P0 gap until real target-project data validates coverage.
- [ ] PR CI is green before requesting merge.

## Progress Lifecycle Evidence

- start: Branch created from main and this Route Plan committed before implementation changes.

## Claude Run Trace

- goal: complete telemetry data collection for future investigation without storing raw sensitive runtime data.
- connectors: github.
- evidence: current main telemetry implementation, settings hook wiring, telemetry fixture, and audit files.
