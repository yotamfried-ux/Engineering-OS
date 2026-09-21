# AI Capability & Connector Registry

Purpose: help an AI agent answer **what capability can I use for this task, on which surface, and how do I activate it?**

This registry is organized by **use**, not implementation type. Before doing expensive manual work, an agent should check this registry for an existing app, plugin, MCP server, skill, or local tool.

## Decision order

1. **Need external data/action?** Check `connectors.md`.
2. **Need to reduce token/context cost?** Check `token-context-efficiency.md` before reading large repos or emitting large CLI output.
3. **Need to test a web/mobile application?** Check `application-testing/README.md` before choosing an automation stack.
4. **Need to improve the agent's own workflow?** Check `agent-tools.md`.
4. Prefer an already-authorized native/official capability over building a new integration.
5. Never assume availability: product surface, plan, workspace policy, OS, authorization and provider permissions can differ.
6. Verify installation/connection before depending on a capability.

## Platform model

### ChatGPT / Codex
Current OpenAI terminology distinguishes:
- **App** — connection to an external service/data/actions.
- **Plugin** — installable workflow package that may contain skills, apps/MCP, or both.
- **MCP app/server** — custom tool surface; exact read/write support depends on product surface and plan.
- **Skill** — reusable workflow/instruction capability.

### Claude / Claude Code
MCP is the common connection protocol across Anthropic products. Claude Code also supports local skills/plugins/hooks that can change the agent's workflow itself.

## Registry contract

Every capability entry should record:
- purpose / trigger
- ChatGPT/Codex support
- Claude/Claude Code support
- mechanism (app, plugin, MCP, skill, hook, CLI/API)
- read/write scope
- installation or connection path
- authentication/secrets
- verification command/check
- limitations and security notes
- source/provenance and last verification date

**Freshness:** product availability changes. Treat this registry as routing knowledge, then verify current platform documentation before installation when the exact availability matters.
