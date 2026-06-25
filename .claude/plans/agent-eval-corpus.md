# Agent Eval Corpus Plan

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / governance |
| Domain tags | governance, workflow, testing, evidence |
| Templates | Not required |
| Architecture guides | `docs/research/official-patterns-adoption-audit.md`; OpenAI Evals repository README |
| Patterns | Existing enforcement test workflow |
| External systems / connectors | GitHub connector; Web official OpenAI Evals source |
| Skills | None |
| Validation gates | GitHub PR, GitHub Actions, CodeRabbit review, explicit approval before merge |
| Task-router evidence | Read `core/task-router.md` during this rollout sequence. |
| Workflow evidence | Read `core/workflow.md` during this rollout sequence. |

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| `docs/research/official-patterns-adoption-audit.md` | Confirms eval corpus is PR sequence item 3 | Read |
| OpenAI Evals repository README | Confirms evals are suitable for LLM/system regression cases | Read |
| `.github/workflows/enforcement-tests.yml` | Confirms how test files are discovered | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for repository files and PR workflow. |
| Web | Used for official OpenAI Evals source. |

## Skill Evidence

No skill is required for this focused test-data change.

## Template Gap Waiver

This PR adds an eval-style corpus and schema test, not a new scaffold.

## Scope

Add data-driven behavior scenarios for the ClientPulse failure modes and a small schema test. Do not add an LLM runner or external dependency.

## Completed Work

- [x] Read adoption audit.
- [x] Read OpenAI Evals source.
- [x] Read enforcement test workflow.

## Remaining Validation Outside This Plan

GitHub Actions, CodeRabbit review, response to review comments, and merge approval are tracked in the PR checklist.
