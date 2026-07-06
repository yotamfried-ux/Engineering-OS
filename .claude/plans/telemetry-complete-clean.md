# Route Plan: Telemetry correlation and summary hardening

| Field | Decision |
|---|---|
| Task type | Engineering OS observability correctness fix |
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read before edits. |
| Workflow evidence | Route Plan committed before code and test changes. |
| Domain tags | observability, telemetry, hooks, monitoring, privacy, governance |
| Plan Scope | Harden local telemetry correlation and summary output. |
| Planning Mode | Plan-first PR with implementation after the plan commit. |
| Templates | not required |
| Architecture guides | core/hooks-policy.md, docs/operations/operational-readiness-audit.md |
| External docs | docs.anthropic.com/claude-code/hooks; opentelemetry.io/docs/concepts/signals/traces; opentelemetry.io/docs/concepts/resources |
| Patterns | not required |
| External systems/connectors | github |
| Skills | not required |
| Validation gates | enforcement-tests, pr-policy, plan-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy |
| Evidence to check | hook input schema, hashed identifiers, local summary output, CI result |
| User decisions required | owner approval before merge |
| Target paths | scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py, scripts/enforcement/tests/test-eos-telemetry.sh |

## Source of Truth Checks

| Source | Check | Result |
|---|---|---|
| docs.anthropic.com/claude-code/hooks | checked | Hook events provide JSON input for correlation metadata. |
| opentelemetry.io/docs/concepts/signals/traces | checked | Trace and span fields fit local event records. |
| opentelemetry.io/docs/concepts/resources | checked | service.name identifies local service context. |
| scripts/monitoring/eos-telemetry-event.sh | checked | Updated recorder target. |
| scripts/monitoring/eos-telemetry-summary.py | checked | Updated summary target. |
| scripts/enforcement/tests/test-eos-telemetry.sh | checked | Updated fixture target. |

## Documentation Asset Evidence

- internal: core/hooks-policy.md, docs/operations/operational-readiness-audit.md, scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py, scripts/enforcement/tests/test-eos-telemetry.sh.
- context7: docs.anthropic.com/claude-code/hooks, opentelemetry.io/docs/concepts/signals/traces, opentelemetry.io/docs/concepts/resources.
- decision: core/hooks-policy.md and the telemetry scripts confirmed that the fix should stay local and use metadata-only telemetry with a latest summary produced by the already wired stop event.

## Capability Evidence

- `routing.task-router-read`: governance route selected before edits.
- `workflow.workflow-read`: plan-first lifecycle followed.
- `plan.route-plan-before-write`: this plan was committed before implementation changes.
- `source.github-repo-read`: merged telemetry files inspected before edits.
- `validation.policy-change-has-validator`: telemetry fixture is part of CI validation.
- `validation.coderabbit-policy`: PR body records manual review fallback and owner approval requirement.

## Connector Evidence

- github: current main telemetry files, summary reporter, fixture, and hook wiring inspected before implementation.

## Connector Usage Evidence

- source: github main files `scripts/monitoring/eos-telemetry-event.sh`, `scripts/monitoring/eos-telemetry-summary.py`, `scripts/enforcement/tests/test-eos-telemetry.sh`, and `.claude/settings.json`.
- action: read merged telemetry and hook state before implementation.
- result: github confirmed target files `scripts/monitoring/eos-telemetry-event.sh`, `scripts/monitoring/eos-telemetry-summary.py`, and `scripts/enforcement/tests/test-eos-telemetry.sh`; `.claude/settings.json` already wires the stop telemetry event.
- decision: updated the recorder to generate summaries inside the already wired stop event instead of changing hook settings.
- target: scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py, scripts/enforcement/tests/test-eos-telemetry.sh

## Definition of Done

- [x] Recorder writes hashed session, turn, transcript, cwd, permission, source, model, response, and error metadata.
- [x] Summary reports session and turn correlation plus missing-correlation counts.
- [x] Stop telemetry event writes a latest local summary.
- [x] Telemetry fixture remains aligned with summary output.
- [x] PR CI is required before merge approval.

## Progress Lifecycle Evidence

- start: Branch created from main and this Route Plan committed before implementation changes.
- mid: Recorder, summary, and fixture alignment updates were committed after the plan-first commit.
- pre-merge: After the follow-up fixture assertion commit, the changed targets are limited to recorder, summary, fixture, and this plan; PR CI remains the merge gate.

## Claude Run Trace

- goal: improve telemetry investigation data.
- connectors: github.
- evidence: current main telemetry implementation, settings hook wiring, updated recorder, updated summary reporter, fixture alignment, and PR #205 CI.
- limitation: full monitoring sufficiency still needs real project data before closure.
