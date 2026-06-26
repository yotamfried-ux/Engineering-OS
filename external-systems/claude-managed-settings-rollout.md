# Claude Code Managed Settings Rollout

## Purpose

This document records the conservative rollout path for managed settings after the official-patterns adoption work.

It exists to solve one concrete Engineering OS failure: critical workflow rules can be bypassed when they live only in project-level text or project-level settings.

## Decision

Add a managed settings template and validator, but do not enable it in the repository runtime by default.

The template is stored at:

```text
templates/settings/claude-managed-lockdown.json
```

Deploy it only in an environment that intentionally supports Claude Code managed settings.

## Official basis

Claude Code managed scope is intended for security policies, compliance requirements, and standardized configurations that cannot be overridden. Managed settings have highest precedence over command-line, local, project, and user settings.

Claude Code documents the following managed-only fields that are relevant to this first Engineering OS rollout:

- `allowManagedHooksOnly`
- `allowManagedMcpServersOnly`
- `strictPluginOnlyCustomization`
- `allowedMcpServers`

`allowManagedPermissionRulesOnly` is intentionally deferred. It should be added only together with a managed `permissions` block, so existing user/project allow/ask/deny rules are not silently ignored.

## Scope

The first rollout template locks only the surfaces that correspond to failures already observed:

```text
hooks,mcp
```

It intentionally does not lock:

```text
skills,agents,permission-rules
```

Skills are not locked yet because the project has not fully migrated selected skills to official managed/plugin-compatible locations. Agents are not locked because they are not part of the current failure set. Permission rules are not locked yet because this PR does not provide managed replacement permission rules.

## Rollout rules

- Do not copy this file into `.claude/settings.json`.
- Do not enable this template by default in `use-in-project.sh`.
- Deploy only through the managed settings paths documented by Claude Code.
- Validate the template before deployment.
- Pair this with the narrowed GitHub read-only connector profile.
- Add a separate PR before expanding to skills, agents, permission rules, or additional connector servers.

## Validation

The template is validated by:

```text
scripts/enforcement/tests/test-managed-settings-template.sh
```

The test checks that the template keeps managed hooks and MCP controls enabled, defers permission-rule lockdown, limits customization lockdown to `hooks` and `mcp`, and allowlists only the first approved connector profile.
