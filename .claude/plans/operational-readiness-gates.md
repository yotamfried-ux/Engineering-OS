# Route Plan: operational readiness gates

## Route Plan

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | `core/task-router.md` read and used for Engineering OS governance routing. |
| Workflow evidence | `core/workflow.md` read and used for plan-first workflow. |
| Templates | Not required. |
| Patterns | Not required. |
| External systems/connectors | GitHub |
| Skills | None |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy, pr-policy, review |

## Capability Evidence

- `routing.task-router-read` — router policy used.
- `workflow.workflow-read` — workflow policy used.
- `plan.route-plan-before-write` — plan created first.
- `source.github-repo-read` — GitHub connector used to inspect PR state, workflows, and source files.
- `validation.policy-change-has-validator` — regression tests added.
- `validation.coderabbit-policy` — PR review flow required.

## Source of Truth Checks

| Source | Status |
|---|---|
| `CLAUDE.md` | Read |
| `core/task-router.md` | Read |
| `core/workflow.md` | Read |
| `core/hooks-policy.md` | Read |
| `.github/workflows/workflow-evidence-policy.yml` | Read |
| `.github/workflows/connector-evidence-policy.yml` | Read |
| `scripts/enforcement/pre-tool-use-runtime-evidence.sh` | Read |
| `scripts/enforcement/tests/` | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for repo, PR, workflow, log, and source inspection. |

## Skill Evidence

None required.

## Definition of Done

- [x] Merge-readiness checker blocks failed workflow runs.
- [x] Merge-readiness checker passes all-success workflow runs.
- [x] Runtime evidence gate blocks malformed hook JSON.
- [x] PreToolUse JSON guard blocks malformed JSON and missing write or bash inputs.
- [x] Enforcement tests cover the negative and positive cases.
- [x] PR is ready for review.
- [x] Review is required before merge.
