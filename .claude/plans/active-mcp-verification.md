# Active MCP Verification Plan

## Route Plan

| Field | Decision |
|---|---|
| Task type | Engineering OS maintenance / governance |
| Domain tags | governance, mcp, connectors, verification, operations, security |
| Templates | templates/connectors/github-readonly.json |
| Architecture guides | docs/research/official-patterns-adoption-audit.md |
| Patterns | Existing enforcement test pattern under scripts/enforcement/tests/ |
| External systems / connectors | GitHub |
| Skills | engineering-route package available, but no runtime package invocation is required for this docs/test PR |
| Validation gates | GitHub Actions, CodeRabbit review, unresolved review thread check, explicit approval before merge |
| Task-router evidence | Read core/task-router.md |
| Workflow evidence | Read core/workflow.md |

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| core/task-router.md | Confirms this is governance / MCP work and needs a route plan before writing | Read |
| core/workflow.md | Confirms plan-first workflow and validation requirements | Read |
| templates/connectors/github-readonly.json | Current read-only GitHub MCP profile that must not be expanded in this PR | Read |
| external-systems/github-readonly-connector.md | Current connector profile decision and safety boundaries | Read |
| scripts/enforcement/tests/test-github-connector-profile.sh | Existing static profile validator that this proof must complement, not replace | Read |
| .github/workflows/enforcement-tests.yml | Confirms test suites are auto-discovered by scripts/enforcement/tests/test-*.sh | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used to read repository policy files, create the implementation branch, and add this PR's files. |

## Skill Evidence

No additional runtime skill is required. The engineering-route package is relevant as policy context, but this PR is executed through the existing repository governance workflow and validated by CI.

## Scope

Add an active MCP verification runbook and CI validator only.

Do not:

- Change templates/connectors/github-readonly.json semantics.
- Add GitHub MCP write tools.
- Add a broad all or default toolset.
- Add git, copilot, notifications, gists, dependabot, code_security, or discussions to this profile.
- Commit a real token.
- Enable .mcp.json from use-in-project.sh.
- Auto-install or auto-activate MCP in target projects.
- Add a write profile.

## Completed Work

- [x] Read task router.
- [x] Read workflow.
- [x] Read GitHub read-only connector template.
- [x] Read GitHub read-only connector profile doc.
- [x] Read existing GitHub connector profile validator.
- [x] Added active MCP verification runbook.
- [x] Added active MCP verification validator.
- [x] Added explicit skill evidence for the workflow evidence gate.

## Remaining Validation Outside This Plan

- GitHub Actions must pass.
- CodeRabbit must complete review.
- Review comments must be handled or explicitly resolved.
- Merge requires explicit user approval.
