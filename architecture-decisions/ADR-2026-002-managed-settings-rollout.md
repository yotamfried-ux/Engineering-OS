# ADR-2026-002: Claude Code managed settings rollout

**Date:** 2026-06-27
**Status:** Accepted
**Deciders:** Yotam Friedman
**Related patterns:** `templates/settings/claude-managed-lockdown.json`

## Context

A conservative rollout path was needed for managed settings after the official-patterns adoption
work. It exists to solve one concrete Engineering OS failure: critical workflow rules can be
bypassed when they live only in project-level text or project-level settings.

Claude Code managed scope is intended for security policies, compliance requirements, and
standardized configurations that cannot be overridden, and has highest precedence over
command-line, local, project, and user settings.

## Decision

Add a managed settings **template and validator**, but **do not enable it in the repository
runtime by default**. The template lives at `templates/settings/claude-managed-lockdown.json`;
deploy it only in an environment that intentionally supports Claude Code managed settings.

The first rollout locks only the surfaces that correspond to already-observed failures: `hooks`
and `mcp`. It uses the managed-only fields `allowManagedHooksOnly`,
`allowManagedMcpServersOnly`, `strictPluginOnlyCustomization`, and `allowedMcpServers`.

## Alternatives Considered

| Option | Pros | Cons | Reason rejected |
|---|---|---|---|
| Template + validator, lock `hooks,mcp` only (chosen) | Closes observed bypass; low blast radius | Partial coverage | — |
| Lock `skills,agents,permission-rules` now | Stronger lockdown | Project hasn't migrated skills to managed/plugin locations; no managed replacement permission rules | Would silently ignore existing user/project allow/ask/deny rules |
| Enable in repo runtime by default | Immediate enforcement | Risk of breaking local/dev flows | Deploy only through documented managed paths |

## Trade-offs Accepted

`allowManagedPermissionRulesOnly` is deferred — it should be added only together with a managed
`permissions` block so existing user/project rules are not silently ignored. Skills and agents
are not locked yet.

## Consequences

- Immediate: template + validator available; not copied into `.claude/settings.json` and not
  enabled by `use-in-project.sh`.
- Long-term: expansion to skills, agents, permission rules, or additional connector servers
  requires a separate PR.
- Risks: pair this with the narrowed GitHub read-only connector profile (ADR-2026-001).

## Future Review Criteria

Revisit when selected skills are migrated to managed/plugin-compatible locations, or when a
managed `permissions` block is introduced.

## Implementation Notes

Validated by `scripts/enforcement/tests/test-managed-settings-template.sh`, which checks the
template keeps managed hooks and MCP controls enabled, defers permission-rule lockdown, limits
customization lockdown to `hooks` and `mcp`, and allowlists only the first approved connector
profile.
