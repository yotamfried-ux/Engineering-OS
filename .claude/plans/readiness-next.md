# Route Plan: readiness next

## Route Plan

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read. |
| Workflow evidence | core/workflow.md read. |
| Templates | Not required. |
| Patterns | Not required. |
| External systems/connectors | GitHub |
| Skills | None |
| Validation gates | enforcement-tests, workflow evidence, connector evidence, capability evidence, plan policy, PR policy, review |

## Capability Evidence

- routing.task-router-read
- workflow.workflow-read
- plan.route-plan-before-write
- source.github-repo-read
- validation.policy-change-has-validator
- validation.coderabbit-policy

## Source of Truth Checks

| Source | Status |
|---|---|
| core/hooks-policy.md | Read |
| core/git-policy.md | Read |
| external-systems/nvidia-nemotron/orchestration.md | Read |
| .claude/agents/nemotron-coder.md | Read |
| .claude/agents/nemotron-code-reviewer.md | Read |
| scripts/enforcement/check-merge-readiness.sh | Read |
| scripts/enforcement/tests/ | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for repo inspection and PR workflow. |

## Scope

Improve operational readiness items that can be tested now.

## Definition of Done

- [x] Nemotron behavior is inspected.
- [ ] Readiness checks are added or updated.
- [ ] Tests cover added behavior.
- [ ] CI is green before merge.
