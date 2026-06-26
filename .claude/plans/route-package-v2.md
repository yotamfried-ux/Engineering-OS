# Route Package Plan

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / governance |
| Domain tags | governance, skills, packaging, validation |
| Templates | Not required |
| Architecture guides | `docs/research/official-patterns-adoption-audit.md` |
| Patterns | None |
| External systems / connectors | GitHub |
| Skills | None |
| Validation gates | GitHub PR, GitHub Actions, CodeRabbit review, explicit approval before merge |
| Task-router evidence | Read `core/task-router.md` during this rollout sequence. |
| Workflow evidence | Read `core/workflow.md` during this rollout sequence. |

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| `docs/research/official-patterns-adoption-audit.md` | Confirms one-package-at-a-time adoption | Read |
| `external-skills/README.md` | Confirms current external skill registry model | Read |
| `core/skill-orchestration-policy.md` | Confirms current governance model | Read |
| Existing enforcement workflow | Confirms new tests run in CI | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for repository files and PR workflow. |

## Skill Evidence

No runtime skill is required for this packaging change.

## Template Gap Waiver

This PR adds one package template and validator. No application scaffold is needed.

## Scope

Add one route package and validator only. Do not migrate all external entries, delete the existing registry model, add write or shell tools, or enable managed package lockdown.

## Completed Work

- [x] Read adoption audit.
- [x] Read external registry.
- [x] Read orchestration policy.
- [x] Read enforcement workflow.
- [x] Read core/task-router.md.
- [x] Read core/workflow.md.

## Remaining Validation Outside This Plan

GitHub Actions, CodeRabbit review, response to review comments, and merge approval are tracked in the PR checklist.
