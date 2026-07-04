# Connector Verification Matrix

> Owner: connector-governance. Inventory source of truth stays
> [`external-systems/README.md`](../../external-systems/README.md) /
> [`core/capability-registry.yaml`](../../core/capability-registry.yaml); selection policy stays
> [`core/connector-policy.md`](../../core/connector-policy.md). This matrix records **verification
> status** per inventory entry — what was actually proven, where, and how — so "documented" is
> never silently presented as "ready".

## Current status after MCP auto-install change

Engineering OS now installs **project-scoped MCP server profiles** into target projects through:

```text
templates/connectors/github-readonly.json
templates/connectors/engineering-os-mcp.json
scripts/install-mcp-servers.sh
scripts/use-in-project.sh
```

This proves configuration availability: Claude Code / MCP-aware clients opened in the target
project can discover the server profiles from `.mcp.json`. It does **not** prove that every
service has been authenticated or that every connector returned live production data.
Authentication and live smoke checks remain per-project evidence.

## Status vocabulary

- **configured-auto** — installed into target `.mcp.json` automatically.
- **configured-auto-auth-required** — installed automatically, but OAuth/token/approval is still required before live use.
- **configured-auto-fallback** — installed through the shared Composio fallback profile.
- **verified-live** — exercised with a concrete call/output in the current session/run.
- **knowledge-layer** — service guide consulted during routing; no runtime endpoint in Engineering OS itself.

## Deterministic layer

| Check | Result | Evidence |
|---|---|---|
| Project MCP installer exists | ✅ pass | `scripts/install-mcp-servers.sh` |
| Target install is wired from `use-in-project.sh` | ✅ pass | `use-in-project.sh` runs the MCP installer |
| GitHub read-only profile remains separate and constrained | ✅ pass | `templates/connectors/github-readonly.json` + `test-github-connector-profile.sh` |
| MCP bundle validates and merges into existing `.mcp.json` | ✅ pass | `scripts/enforcement/tests/test-mcp-auto-install.sh` |
| Installer preserves existing custom MCP servers | ✅ pass | merge fixture in `test-mcp-auto-install.sh` |
| Installer backs up existing `.mcp.json` | ✅ pass | repeatability fixture in `test-mcp-auto-install.sh` |
| Invalid existing `.mcp.json` fails closed | ✅ pass | invalid JSON fixture in `test-mcp-auto-install.sh` |
| Secrets are not written by the installer | ✅ pass | templates use placeholders / operator auth |

## MCP connectors (12)

| Connector | Auto-installed server profile | Classification | Live-use requirement |
|---|---|---|---|
| github | `github-readonly` | configured-auto-auth-required | PAT/OAuth approval; read-only smoke via repo/PR/Actions metadata |
| notion | `notion` | configured-auto-auth-required | `/mcp` approval and page/database access |
| slack | `composio` | configured-auto-fallback | Composio auth + Slack tool selection |
| linear | `composio` | configured-auto-fallback | Composio auth + Linear tool selection |
| jira | `composio` | configured-auto-fallback | Composio auth + Jira site/account selection |
| stripe | `stripe` | configured-auto-auth-required | Stripe auth; default to test mode until user approves live work |
| supabase | `supabase` | configured-auto-auth-required | Supabase project auth/approval |
| postgres | `composio` or project-specific profile | configured-auto-fallback | project-specific connection string / read-only DB credentials |
| google-drive | `composio` | configured-auto-fallback | Composio/Google OAuth and Drive scope approval |
| google-sheets | `composio` | configured-auto-fallback | Composio/Google OAuth and Sheets scope approval |
| figma | `figma` | configured-auto-auth-required | Figma auth and file permission |
| discord | `composio` | configured-auto-fallback | Composio auth + Discord bot/server permission |

## Policy-level connectors

| Connector | Policy role | Current configuration status |
|---|---|---|
| GitHub | core-fixed | configured-auto as read-only MCP profile |
| Context7 | core-fixed | configured-auto; also available as built-in connector in Claude app surfaces |
| Sentry | core-fixed for debugging | configured-auto with environment-specific MCP endpoint placeholder |
| Figma / Postman / Composio | project-dependent | configured-auto; auth/approval still required |

## Service connectors (47 — knowledge layer)

All 47 service entries remain knowledge-layer entries unless a task selects one and authenticates
its runtime connector. The MCP auto-install change improves discovery and default availability for
Claude Code, but service truth still comes from the selected MCP server, SDK, official docs, or
project-specific credentials.

## Explicit non-gaps and remaining live-proof requirement

- **Not a gap:** `.mcp.json` is now installed automatically into governed target projects.
- **Not a gap:** credentials are not auto-written; this is required for safety.
- **Still required before claiming live connector success:** run `/mcp` or `claude mcp list`, approve/authenticate the server, and record a concrete smoke-check result in the Route Plan.
