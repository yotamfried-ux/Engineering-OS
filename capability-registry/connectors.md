# ChatGPT / Claude Connector Matrix

This file is a **routing matrix**, not a promise that every capability is enabled in the current account. Availability depends on product surface, plan/workspace, provider authorization, admin policy, and current vendor support.

## Library connector coverage

The repository currently has dedicated connector knowledge for:

| Service | Existing knowledge | Typical mechanism |
|---|---|---|
| GitHub | `external-systems/connectors/github/` | App/plugin and/or MCP/API depending on client |
| Slack | `external-systems/connectors/slack/` | App/plugin and/or MCP/API |
| Notion | `external-systems/connectors/notion/` | App/plugin and/or MCP/API |
| Linear | `external-systems/connectors/linear/` | MCP/API |
| Google Drive | `external-systems/connectors/google-drive/` | Connected app and/or MCP/API |
| Google Sheets | `external-systems/connectors/google-sheets/` | Connected app and/or MCP/API |
| Jira | `external-systems/connectors/jira/` | App/MCP/API depending on environment |
| Discord | `external-systems/connectors/discord/` | Bot/MCP/API |
| Figma | `external-systems/connectors/figma/` | App/MCP/API |
| Stripe | `external-systems/connectors/stripe/` | Plugin/app/MCP/API |
| Supabase | `external-systems/connectors/supabase/` | MCP/API |
| PostgreSQL | `external-systems/connectors/postgres/` | MCP/database connector |

## ChatGPT / Codex routing

OpenAI's current plugin architecture allows a plugin to contain **skills, an MCP server, or both**. Connected apps provide access to external services/data/actions. Therefore an agent should:
1. Check whether a relevant installed plugin/app already exists.
2. Use the connected capability when it provides the required read/write action.
3. If no suitable app exists and custom MCP is supported on the current surface/workspace, evaluate the trusted MCP route.
4. Do not build a duplicate connector before checking the available plugin/app directory.
5. Treat write actions as permission-sensitive and expect approval/security controls.

Official references verified 2026-09-21:
- OpenAI Help: Plugins in ChatGPT and Codex
- OpenAI Help: Connected apps in ChatGPT
- OpenAI Help: Developer mode and MCP apps in ChatGPT
- OpenAI Developers: Plugin architecture

## Claude / Claude Code routing

Anthropic documents MCP across Claude products, including Claude Code, Claude.ai, Claude Desktop, and the Messages API. An agent should:
1. Prefer an existing trusted connector/MCP integration.
2. For Claude Code local developer tooling, inspect local MCP/skill/plugin support and the wrapper's activation instructions.
3. Distinguish **application integration** (the software being built talks to a service) from **agent integration** (Claude itself gets a tool).
4. Verify authentication and tool scope before use.

Official reference verified 2026-09-21:
- Anthropic Docs: Model Context Protocol (MCP)

## Missing/expansion rule

This matrix intentionally does not claim to enumerate every connector in either vendor ecosystem. When a task needs a service not listed here:
- check the current vendor directory/docs;
- if a reusable, trustworthy capability exists, add a knowledge wrapper recording setup, auth, actions, limitations and verification;
- classify it by practical use in this registry.
