# Route Plan: skill E2E simulations

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
| Target paths | scripts/enforcement/tests, .claude/plans |

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
| `external-skills/README.md` | Read |
| `scripts/skill-bootstrap.sh` | Read |
| `scripts/enforcement/enforce-skill.sh` | Read |
| `scripts/enforcement/pre-tool-use-runtime-evidence.sh` | Read |
| `scripts/enforcement/tests/test-clean-install-and-usage.sh` | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for repo inspection, branch, commits, PR, and workflow checks. |

## Scope

Add skill E2E simulations that prove skill contracts, bootstrap behavior, runtime skill evidence gating, target install wiring, and deprecated/engine boundary behavior.

## Definition of Done

- [x] Current skill policy and enforcement are inspected.
- [x] E2E simulation test is added.
- [x] Test proves skill contract enforcement for new skills.
- [x] Test proves runtime write gate blocks declared skills without evidence and allows after evidence.
- [x] Test proves default bootstrap profile reports missing default L2 skills in a target project.
- [x] Test proves frontend-design is deprecated and Nemotron is not treated as a skill.
- [x] CI is checked before merge.
