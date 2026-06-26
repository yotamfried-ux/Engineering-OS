# Official Skill Package Plan

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / governance |
| Domain tags | governance, skills, Claude Code, official patterns, validation |
| Templates | Not required |
| Architecture guides | `docs/research/official-patterns-adoption-audit.md`; Anthropic skill package format summarized by the audit |
| Patterns | Existing skill orchestration policy and enforcement test workflow |
| External systems / connectors | GitHub connector; Web official docs checked during the rollout |
| Skills | None |
| Validation gates | GitHub PR, GitHub Actions, CodeRabbit review, explicit approval before merge |
| Task-router evidence | Read `core/task-router.md` during this rollout sequence. |
| Workflow evidence | Read `core/workflow.md` during this rollout sequence. |

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| `docs/research/official-patterns-adoption-audit.md` | Confirms official skill packaging should be adopted partially, not as a broad import | Read |
| `external-skills/README.md` | Confirms current custom four-file wrapper model and default skill registry | Read |
| `core/skill-orchestration-policy.md` | Confirms current SIP model and enforcement expectations | Read |
| Existing enforcement workflow | Confirms new validator scripts are automatically executed in CI | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for repository files and PR workflow. |
| Web | Official Anthropic skill format was checked during the official-patterns rollout. |

## Skill Evidence

No runtime skill is required for this packaging-template change.

## Template Gap Waiver

This PR adds the first official skill package template and validator. No application scaffold is needed.

## Scope

Add one official-format Engineering OS skill package as a template and validator only. Do not migrate all external-skills, do not delete the existing SIP wrapper contract, and do not enable managed skill lockdown yet.

## Completed Work

- [x] Read adoption audit.
- [x] Read external skills registry.
- [x] Read skill orchestration policy.
- [x] Read enforcement workflow.

## Remaining Validation Outside This Plan

GitHub Actions, CodeRabbit review, response to review comments, and merge approval are tracked in the PR checklist.
