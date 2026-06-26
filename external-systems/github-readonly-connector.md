# GitHub Read-Only Connector Profile

## Purpose

This profile records the first official connector profile selected by the official-patterns adoption audit.

It exists to solve one concrete Engineering OS failure: agents changed repository files or PRs without first consulting repository state through an approved source-of-truth connector.

## Decision

Adopt a narrow GitHub connector profile as a template, not as enabled runtime configuration.

The template is stored at:

```text
templates/connectors/github-readonly.json
```

Copy it to a project-scoped `.mcp.json` only when the target project explicitly opts in.

## Official basis

- Claude Code supports project-scoped server configuration in `.mcp.json`.
- Claude Code supports environment variable expansion in `.mcp.json`, including `env` values.
- GitHub maintains the official GitHub MCP Server image at `ghcr.io/github/github-mcp-server`.
- The GitHub MCP Server supports toolset allow-lists through `GITHUB_TOOLSETS`.
- The GitHub MCP Server supports read-only mode through `GITHUB_READ_ONLY=1`.

## Scope

The initial profile uses only:

```text
context,repos,pull_requests,issues,actions
```

This is intentionally enough for repository state, PR review state, issue/spec context, and CI status.

The profile intentionally does not include:

```text
all, default, code_security, dependabot, discussions, gists, notifications, labels, git, copilot
```

These can be added later only when a concrete failure requires them.

## Security rules

- Never commit a real GitHub token.
- Use `${GITHUB_PERSONAL_ACCESS_TOKEN}` expansion only.
- Keep `GITHUB_READ_ONLY` set to `1` for this profile.
- Do not use this profile for write operations.
- Create a separate explicit write profile only if a later PR proves the need and adds tests.

## Validation

The profile is validated by:

```text
scripts/enforcement/tests/test-github-connector-profile.sh
```

The test checks that the profile remains read-only, uses the official GitHub image, uses a narrow toolset allow-list, and does not include broad toolsets.
