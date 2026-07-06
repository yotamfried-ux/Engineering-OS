# Route Plan: Complete runtime telemetry correlation and validation

| Field | Decision |
|---|---|
| Task type | Engineering OS observability correctness fix |
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md and operational readiness audit policy shape used from the merged repo state. |
| Workflow evidence | Route Plan committed before code/config/test changes on this branch. |
| Domain tags | observability, telemetry, hooks, monitoring, privacy, project-8, governance |
| Plan Scope | Close the post-merge telemetry sufficiency gaps without weakening existing hooks. |
| Planning Mode | Plan-first PR with documentation-backed implementation and simulation fixtures. |
| Templates | not required |
| Architecture guides | core/hooks-policy.md, docs/operations/operational-readiness-audit.md, docs/operations/known-gaps.tsv |
| External docs | Claude Code hooks reference, OpenTelemetry traces/resources concepts. |
| Patterns | not required |
| External systems/connectors | github, web-docs |
| Skills | not required |
| Validation gates | enforcement-tests, pr-policy, plan-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy |
| Evidence to check | hook input schema, safe hashed identifiers, summary generation, restored governance hooks, target install contract |
| User decisions required | owner approval before merge |
| Target paths | scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py, scripts/enforcement/tests/test-eos-telemetry.sh, .claude/settings.json, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |

## Source of Truth Checks

| Source | Check | Result |
|---|---|---|
| Claude Code hooks reference | checked | Hook common input includes session_id, prompt_id, transcript_path, cwd; prompt_id is for correlation with telemetry for a single prompt. |
| OpenTelemetry traces concepts | checked | Span contains trace/span ids, parent, timestamps, attributes, events, status; span events represent meaningful points in time. |
| OpenTelemetry resources concepts | checked | service.name should be set explicitly. |
| .claude/settings.json | checked | Telemetry exists but must not replace existing governance hooks. |
| scripts/monitoring/eos-telemetry-event.sh | checked | Needs hashed Claude correlation ids and safer event-source fields. |
| scripts/monitoring/eos-telemetry-summary.py | checked | Needs prompt/session counters and automatic Stop summary wiring. |
| docs/operations/known-gaps.tsv | checked | Needs an open tracked runtime telemetry sufficiency gap until real project-8 data validates coverage. |

## Documentation Asset Evidence

- internal: core/hooks-policy.md, docs/operations/operational-readiness-audit.md, docs/operations/known-gaps.tsv, .claude/settings.json, scripts/use-in-project.sh
- external: Claude Code hooks reference and OpenTelemetry traces/resources concepts.
- decision: add hashed correlation fields and summary generation while preserving privacy and existing hook governance.

## Capability Evidence

- routing.task-router-read: task type and governance route selected before edits.
- workflow.workflow-read: plan-first branch and lifecycle checkpoints used.
- validation.policy-change-has-validator: telemetry fixture will be extended with correlation, summary, privacy, disabled-mode, and invalid JSON simulations.
- source.github-repo-read: merged main files inspected before edits.
- validation.actions-checked: CI will be checked before any merge request.

## Connector Evidence

- github: repository main files, merged telemetry scripts, settings, known gaps, and audit files inspected.
- web-docs: official Claude Code and OpenTelemetry documentation inspected before implementation.

## Connector Usage Evidence

- source: github main files `.claude/settings.json`, `scripts/monitoring/eos-telemetry-event.sh`, `scripts/monitoring/eos-telemetry-summary.py`, `scripts/enforcement/tests/test-eos-telemetry.sh`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.
- action: read merged code/config/audit state and compare against expected telemetry requirements.
- result: github confirmed telemetry baseline exists but lacks stored hashed session_id/prompt_id/transcript/cwd, Stop summary generation, restored advisory hooks, and an open runtime sufficiency gap.
- decision: update only telemetry and governance/audit files required to make runtime data collection auditable.
- target: scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py, scripts/enforcement/tests/test-eos-telemetry.sh, .claude/settings.json, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md

## Definition of Done

- [ ] Telemetry records hashed Claude session, prompt, cwd, transcript, permission mode, and event source without storing raw prompts/paths/payloads.
- [ ] Telemetry summary reports prompt/session correlation counts and missing-correlation signals.
- [ ] Stop hook generates a local latest summary without weakening the existing post-stop enforcement hook.
- [ ] Previously existing governance advisory/enforcement hooks are restored or preserved.
- [ ] Simulations verify privacy, command categories, correlation, summary generation, disabled mode, invalid JSON, and no raw prompt/response leaks.
- [ ] Runtime telemetry sufficiency remains tracked as open until project-8/future runs produce real data.
- [ ] PR CI is green before requesting merge.

## Progress Lifecycle Evidence

- start: Branch created from main and this Route Plan committed before code/config/test/audit changes.

## Claude Run Trace

- goal: complete the telemetry baseline so future incidents can be correlated and summarized without storing sensitive raw data.
- hypothesis: hashed Claude hook identifiers plus trace/span metadata and Stop summary artifacts provide enough local evidence for project-8 investigation while preserving privacy.
- connectors: github and web-docs.
- evidence: official hook schema, OpenTelemetry trace/resource concepts, merged baseline code, and internal audit contract.
