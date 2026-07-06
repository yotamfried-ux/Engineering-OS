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

## Capability Evidence

- `routing.task-router-read`: task-router route contract checked before implementation.
- `workflow.workflow-read`: workflow lifecycle contract checked before implementation.
- `plan.route-plan-before-write`: this plan is committed before implementation changes in this clean branch.
- `source.github-repo-read`: repository state was read before the clean rebuild.
- `validation.policy-change-has-validator`: fixture and CI contract changes are part of the implementation plan.
- `validation.actions-checked`: Actions evidence from the prior branch was inspected.
- `validation.coderabbit-policy`: merge remains blocked until CI and owner approval.

## Definition of Done

- [x] Route Plan committed before implementation changes.
- [x] Telemetry recorder and summary reporter planned.
- [x] Hook ordering constraint documented.
- [x] Known gaps remain open until real project-8 data exists.
- [x] CI and owner approval required before merge.

## Progress Lifecycle Evidence

- start: Clean branch created from main and this Route Plan committed before any code/config/test change.
