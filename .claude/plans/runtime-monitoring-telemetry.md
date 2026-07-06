# Route Plan: Runtime monitoring telemetry collector

| Field | Decision |
|---|---|
| Task type | Engineering OS observability governance implementation |
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read before implementation. |
| Workflow evidence | core/workflow.md read before implementation. |
| Domain tags | observability, telemetry, monitoring, hooks, project-8, governance |
| Plan Scope | Add local runtime telemetry baseline and install wiring while keeping monitoring gaps open. |
| Planning Mode | Route Plan with ordered lifecycle evidence and CI-gated implementation. |
| Templates | not required |
| Architecture guides | core/task-router.md, core/workflow.md, core/hooks-policy.md, docs/operations/operational-readiness-audit.md |
| Patterns | not required |
| External systems/connectors | github |
| Skills | not required |
| Validation gates | enforcement-tests, pr-policy, plan-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy |
| Evidence to check | telemetry schema, settings hook wiring, target install contract, known gap ledger, PR CI logs |
| User decisions required | owner approval before merge |
| Target paths | scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py, scripts/enforcement/tests/test-eos-telemetry.sh, .claude/settings.json, scripts/enforcement/post-stop-hook.sh, .github/workflows/enforcement-tests.yml, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |

## Source of Truth Checks

| Source | Check | Result |
|---|---|---|
| core/task-router.md | read | Route Plan contract used. |
| core/workflow.md | read | Ordered lifecycle checkpoints used. |
| core/hooks-policy.md | read | Hook ordering considered. |
| .claude/settings.json | checked | Telemetry is wired after hard JSON guards. |
| scripts/enforcement/tests/test-eos-telemetry.sh | checked | Privacy and disabled-mode fixtures added. |

## Documentation Asset Evidence

- internal: core/task-router.md, core/workflow.md, core/hooks-policy.md, docs/operations/operational-readiness-audit.md
- context7: OpenTelemetry traces/resources, OpenAI Agents SDK tracing, Google ADK observability, Microsoft Foundry tracing, and Claude Code hooks documentation were checked.
- decision: Use local trace/span-style metadata records and hook lifecycle wiring. Do not store prompts, raw command text, raw paths, file contents, connector payloads, environment values, or sensitive values.

## Capability Evidence

- `routing.task-router-read`: task-router route contract checked before implementation.
- `workflow.workflow-read`: workflow lifecycle contract checked before implementation.
- `plan.route-plan-before-write`: this plan is committed before implementation changes in this clean branch.
- `source.github-repo-read`: repository state was read before the clean rebuild.
- `validation.policy-change-has-validator`: fixture and CI contract changes are part of the implementation plan.
- `validation.actions-checked`: Actions evidence from the prior branch was inspected.
- `validation.coderabbit-policy`: merge remains blocked until CI and owner approval.

## Connector Evidence

- github: GitHub PR metadata, workflow runs, failing logs, review thread state, settings, and enforcement checker files were inspected.

## Connector Usage Evidence

- source: github PR 201, workflow run 28761726034, job 85278330479, and head SHA 8819c4841a3b3233979b439c4a62baa4a962114e.
- action: read PR metadata, changed files, workflow jobs/logs, settings, and enforcement checker contracts.
- result: confirmed that a clean branch needs this Route Plan before any code/config/test change and hard JSON guards before telemetry.
- decision: rebuilt on a clean branch with plan-first history and hook ordering preserved.
- target: .claude/settings.json, scripts/monitoring/eos-telemetry-event.sh, scripts/enforcement/tests/test-eos-telemetry.sh

## Definition of Done

- [x] Route Plan committed before implementation changes.
- [x] Telemetry recorder and summary reporter added.
- [x] Hook ordering constraint preserved.
- [x] Telemetry privacy fixture added.
- [x] CI and owner approval required before merge.

## Progress Lifecycle Evidence

- start: Clean branch created from main and this Route Plan committed before any code/config/test change.
- mid: Telemetry recorder, summary reporter, hook wiring, and telemetry fixture added after the plan-first commit.

## Claude Run Trace

- goal: add a local telemetry baseline without overclaiming production monitoring readiness.
- hypothesis: local JSONL event records can provide useful target-project behavior data while storing only safe metadata.
- connectors: github.
- steps: inspect prior PR, identify order failure, start clean plan-first rebuild, add telemetry scripts, wire settings, and add fixture coverage.
- evidence: PR 201 workflow logs, settings hook contract, telemetry scripts, and telemetry fixture.
- rejected: cloud-first monitoring because the immediate project-8 experiment needs local collection.
- result: clean branch now has implementation commits after the Route Plan.
