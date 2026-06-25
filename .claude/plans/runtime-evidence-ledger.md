# Route Plan: Runtime Evidence Ledger Gate

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance / governance |
| Domain tags | governance, workflow, hooks, enforcement, connectors, skills |
| Templates | none |
| Architecture guides | core/hooks-policy.md, core/workflow.md, core/task-router.md, core/connector-policy.md, core/skill-orchestration-policy.md |
| Patterns | scripts/enforcement/lib/evidence.sh, scripts/enforcement/post-stop-hook.sh, scripts/enforcement/post-tool-use-bash.sh |
| External systems/connectors | GitHub |
| Skills | superpowers-verify |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, plan-policy, pr-policy |
| Task-router evidence | Engineering OS maintenance route reviewed |
| Workflow evidence | workflow hook requirements reviewed |

## Connector Evidence

- [x] GitHub used for repository state and PR changes.

## Source of Truth Checks

| Need | Source checked | Result |
|---|---|---|
| Evidence ledger | scripts/enforcement/lib/evidence.sh | available |
| Bash recorder | scripts/enforcement/post-tool-use-bash.sh | records graphify and tests |
| Stop hook | scripts/enforcement/post-stop-hook.sh | currently warning-only |
| Hook wiring | .claude/settings.json | no generic MCP recorder |

## Skill Evidence

- [x] superpowers-verify planned through regression tests.

## Template Gap Waiver

Internal hook/enforcer change; no project scaffold template needed.

## Implementation Checklist

- [x] Add generic PostToolUse MCP evidence recorder.
- [x] Add Stop-time evidence checker for declared connectors/skills.
- [x] Wire recorder/checker through .claude/settings.json.
- [x] Add regression tests.
