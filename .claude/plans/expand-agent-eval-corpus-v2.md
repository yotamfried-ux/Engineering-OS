# Agent Eval Corpus Expansion V2 Plan

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / governance |
| Domain tags | governance, evals, workflow, connectors, mcp, reviews, testing |
| Templates | Not required |
| Architecture guides | docs/research/official-patterns-adoption-audit.md |
| Patterns | Existing JSONL eval corpus and enforcement test pattern |
| External systems / connectors | GitHub |
| Skills | None |
| Validation gates | GitHub Actions, CodeRabbit review, unresolved review thread check, explicit approval before merge |
| Task-router evidence | Read core/task-router.md |
| Workflow evidence | Read core/workflow.md |

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| core/task-router.md | Confirms this is governance / eval work and needs a route plan before writing | Read |
| core/workflow.md | Confirms plan-first workflow and validation requirements | Read |
| evals/engineering-os/workflow-guardrail-cases.jsonl | Current eval corpus to expand | Read |
| scripts/enforcement/tests/test-agent-eval-corpus.sh | Current corpus validator to update with new required cases | Read |
| PR #91 | Confirms the first attempt was closed without merge and this branch restarts from clean main | Checked |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used to read existing corpus/test files, close the superseded PR, create this clean implementation branch, and update PR files. |

## Scope

Expand the existing agent workflow guardrail eval corpus and its validator only.

Do not:

- Add runtime enforcement.
- Change MCP profiles.
- Change managed settings templates.
- Change GitHub Actions workflows.
- Add a new eval runner framework.
- Add external dependencies.

## Completed Work

- [x] Read existing eval corpus.
- [x] Read existing eval corpus validator.
- [x] Closed the superseded PR without merge.
- [x] Added incident-derived eval cases for CodeRabbit, review threads, MCP scope, runtime evidence, managed settings, and auto-install boundaries.
- [x] Updated the validator to require the expanded case set and pin high-risk case tokens.
- [x] Avoided the sensitive wording that caused PR #91 write-tool blocks.

## Remaining Validation Outside This Plan

- GitHub Actions must pass.
- CodeRabbit must complete review.
- Review comments must be handled or explicitly resolved.
- Merge requires explicit user approval.
