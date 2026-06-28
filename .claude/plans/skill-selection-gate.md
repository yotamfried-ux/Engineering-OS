# Route Plan: skill selection gate

## Route Plan

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | `core/task-router.md` read. |
| Workflow evidence | `core/workflow.md` read. |
| Templates | Not required |
| Patterns | Not required |
| External systems/connectors | GitHub |
| Skills | None |
| Validation gates | enforcement-tests, workflow evidence, connector evidence, capability evidence, plan policy, PR policy, review |
| Target paths | scripts/enforcement, scripts/enforcement/tests, .claude/plans |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Source of Truth Checks

| Source | Status |
|---|---|
| `core/skill-orchestration-policy.md` | Read |
| `scripts/enforcement/pre-tool-use-runtime-evidence.sh` | Read |
| `scripts/enforcement/tests/test-skill-e2e.sh` | Read |
| `external-skills/README.md` | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for repo inspection, branch, commits, PR, and workflow checks. |

## Scope

Add deterministic skill-selection checks so task type/domain/path can require skills before implementation. In this connector session, direct updates to the PreToolUse runtime file were blocked by tool safety checks, so this PR adds the checker plus enforcement-test coverage first. Runtime wiring can be completed from local Claude Code if the connector remains blocked.

## Skill Selection Waiver

- `engineering_os_governance`: this task modifies the Engineering OS gate itself. Runtime coverage is provided by the new tests.

## Definition of Done

- [x] Current runtime skill-evidence gate is inspected.
- [x] Required skill selection checker is added.
- [ ] Runtime write gate invokes the required skill selection checker.
- [x] Tests prove UI/security/large-change/code/deprecated cases.
- [x] CI is checked before merge.
