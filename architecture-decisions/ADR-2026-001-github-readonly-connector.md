# ADR-2026-001: GitHub read-only connector profile

**Date:** 2026-06-27
**Status:** Accepted
**Deciders:** Yotam Friedman
**Related patterns:** `templates/connectors/github-readonly.json`

## Context

The official-patterns adoption audit needed a first official connector profile. It exists to
solve one concrete Engineering OS failure: agents changed repository files or PRs without first
consulting repository state through an approved source-of-truth connector.

Claude Code supports project-scoped server configuration in `.mcp.json` (including environment
variable expansion), and GitHub maintains the official MCP Server image at
`ghcr.io/github/github-mcp-server`, which supports toolset allow-lists (`GITHUB_TOOLSETS`) and
read-only mode (`GITHUB_READ_ONLY=1`).

## Decision

Adopt a **narrow GitHub connector profile as a template**, not as enabled runtime configuration.
The template lives at `templates/connectors/github-readonly.json`; copy it to a project-scoped
`.mcp.json` only when the target project explicitly opts in.

The initial profile uses only `context,repos,pull_requests,issues,actions` — enough for
repository state, PR review state, issue/spec context, and CI status.

## Alternatives Considered

| Option | Pros | Cons | Reason rejected |
|---|---|---|---|
| Narrow read-only template (chosen) | Minimal access surface; solves the observed failure | No write ops via this profile | — |
| Broad toolsets (`all`/`default`) | One profile fits all | Large access surface without a failure mapping | Adds ambiguity and risk without need |
| Write-enabled profile now | Enables automation | Not required by any observed failure | Defer until a PR proves the need + adds tests |

## Trade-offs Accepted

Read-only means this profile cannot perform write operations. A separate explicit write profile
must be created only if a later PR proves the need and adds tests.

## Consequences

- Immediate: template available; not wired into runtime by default.
- Long-term: toolset stays narrow; broaden (`code_security`, `git`, `copilot`, …) only on a
  concrete failure.
- Risks: a real token must never be committed — use `${GITHUB_PERSONAL_ACCESS_TOKEN}` expansion
  only and keep `GITHUB_READ_ONLY=1`.

## Future Review Criteria

Revisit if a concrete failure requires write access or additional toolsets.

## Implementation Notes

Validated by `scripts/enforcement/tests/test-github-connector-profile.sh`, which checks the
profile stays read-only, uses the official GitHub image, uses a narrow toolset allow-list, and
excludes broad toolsets.
