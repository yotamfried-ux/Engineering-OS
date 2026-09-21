# MCP & Tool Usability Audit — 2026-09-21

Scope: every operational MCP server / agent tool currently cataloged under `external-skills/`, `external-systems/connectors/`, and `capability-registry/application-testing/`.

## Status vocabulary
- **LIVE** — exercised through the current ChatGPT environment against an authenticated service.
- **AVAILABLE** — current upstream/vendor implementation exists and is usable, but this session did not have an authenticated/runnable connection to perform an end-to-end handshake.
- **CONDITIONAL** — usable only with a specific host, credential, platform, or external dependency.
- **STALE DOC** — capability exists, but the library points at an obsolete/moved implementation or makes an outdated “official MCP” claim.
- **BROKEN IN LIBRARY** — documented activation depends on files removed from this knowledge-only repository.

## Coverage summary

27 operational entries reviewed: 10 agent skills/tools, 12 service connectors, 5 application-testing MCPs.

### Agent skills / tools

| Capability | Status | Evidence / practical result |
|---|---|---|
| superpowers | AVAILABLE | Upstream `obra/superpowers` is active; ChatGPT plugin directory reports Superpowers installed. Claude activation remains host-specific. |
| claude-mem | CONDITIONAL | Active upstream; requires Claude Code/plugin hooks, worker, local storage and credentials. Not live-tested in this ChatGPT host. |
| Graphify | STALE DOC | Active project, but GitHub now resolves the old `safishamsi/graphify` identity to `Graphify-Labs/graphify`; catalog source/provenance needs refresh. MCP requires local package + graph. |
| RTK | CONDITIONAL | Active `rtk-ai/rtk`; Claude Code PreToolUse hook path. Requires local install; current execution sandbox has no Cargo and cannot validate hook activation. |
| gstack | CONDITIONAL | Active `garrytan/gstack`; requires Bun + host setup. Not a remote MCP. |
| ui-ux-pro-max | CONDITIONAL | Active upstream; Claude plugin/npm workflow. Not live-tested in current host. |
| frontend-design | DEPRECATED | Source `anthropics/skills` exists, but our own catalog already says to use ui-ux-pro-max for new projects. |
| claude-code-workflows | CONDITIONAL | Active upstream template repo; manual-copy workflow, not a drop-in MCP. Some library instructions still refer to runtime files removed during knowledge-library conversion. |
| security-review | **BROKEN IN LIBRARY** | Primary Nemotron MCP and fallback commands/scripts documented here depend on removed `scripts/` / `.claude/` runtime artifacts. Must not be advertised as immediately usable from this repo. |
| Nemotron engine/MCP wrapper | **BROKEN IN LIBRARY** | NVIDIA API may be usable independently, but the documented MCP command points to `scripts/nemotron-mcp-server.py`, which does not exist in the knowledge-only repo. |

### Service connectors

| Connector | Status | Evidence / correction |
|---|---|---|
| GitHub | **LIVE + STALE DOC** | Current GitHub connector successfully read/wrote this repository during the audit. Library's old `modelcontextprotocol/servers/src/github` link no longer exists; current official server is `github/github-mcp-server` / GitHub remote MCP. |
| Notion | **LIVE + STALE DOC** | Authenticated `fetch self` succeeded and returned current tool access. Old modelcontextprotocol path is obsolete; Notion now provides official Remote Notion MCP; self-hosted `makenotion/notion-mcp-server` is no longer the preferred supported route. |
| Supabase | **LIVE + STALE DOC** | Authenticated project listing succeeded. Old `supabase-community/supabase-mcp` resolves to `supabase/mcp`; current recommended path is remote `https://mcp.supabase.com/mcp`. |
| Slack | AVAILABLE + STALE DOC | Slack launched an official MCP server in 2026 and an official MCP+Skills plugin. Library still points to removed `modelcontextprotocol/servers/src/slack`. |
| Linear | AVAILABLE + STALE DOC | Linear has an official hosted remote MCP server; library points to removed `modelcontextprotocol/servers/src/linear`. |
| Figma | AVAILABLE + STALE DOC | Figma now has an official remote MCP and ChatGPT plugin; library still labels third-party `GLips/Figma-Context-MCP` as the primary MCP. |
| Google Drive | AVAILABLE + STALE DOC | ChatGPT plugin directory reports Google Drive available. The old `modelcontextprotocol/servers/src/gdrive` path is gone. Do not call it a current official MCP implementation. |
| Google Sheets | AVAILABLE VIA DRIVE / API | ChatGPT's Google Drive plugin is the current native entry point for Drive/Docs/Sheets/Slides. Library correctly did not identify a concrete official Sheets MCP, but its wording should be tightened. |
| Jira | CONDITIONAL | `sooperset/mcp-atlassian` is active but community, not Atlassian-official. No ChatGPT Jira plugin was found in the current plugin directory search. |
| Discord | CONDITIONAL | `v-3/discordmcp` repository exists but is community and very small; no native ChatGPT Discord plugin was found in current directory search. Treat as lower-trust until a stronger implementation is selected. |
| Stripe | AVAILABLE + STALE DOC | Stripe Agent Toolkit/MCP is active; repository identity now resolves from `stripe/agent-toolkit` to `stripe/ai`. No first-party Stripe ChatGPT plugin surfaced in current plugin search. |
| PostgreSQL | STALE DOC / CONDITIONAL | Old `modelcontextprotocol/servers/src/postgres` path is gone. Current ChatGPT environment has live PostgreSQL-capable integrations through Supabase and Neon, but that is not a generic PostgreSQL MCP replacement. |

### Application-testing MCPs

| Capability | Status | Evidence / practical constraint |
|---|---|---|
| Playwright MCP | AVAILABLE | `microsoft/playwright-mcp` active and not archived. Requires a runnable browser/host connection for end-to-end verification. |
| Maestro MCP | CONDITIONAL | `mobile-dev-inc/Maestro` active. Full functional test requires Maestro CLI plus Android emulator/device or macOS+iOS simulator. Current sandbox has neither ADB nor Xcode. |
| Appium MCP | CONDITIONAL | Official `appium/appium-mcp` active; official documentation MCP also active. Requires platform SDK/device/session; current sandbox lacks ADB/Xcode. |
| Chrome DevTools MCP | AVAILABLE | Official `ChromeDevTools/chrome-devtools-mcp` active. Requires Chrome/browser process and local MCP launch for handshake. |
| Mobile Next MCP | CONDITIONAL | `mobile-next/mobile-mcp` active. Requires Android/iOS target and local tooling for a real smoke test. |

## Live connection tests actually executed

1. **GitHub** — repository tree/file reads, repo metadata, blob/tree/commit creation and main ref updates all succeeded during catalog work and this audit.
2. **Notion** — authenticated `fetch(self)` succeeded. Core search/fetch/create/update tools are available; some AI-search/session features are plan-gated.
3. **Supabase** — authenticated `list_projects` succeeded and returned active projects.
4. **ChatGPT plugin discovery** — confirmed current availability for Google Drive, Figma, Linear and Slack; confirmed Superpowers installed; confirmed Supabase/Notion installed. Jira/Discord/first-party Stripe did not surface in targeted searches.
5. **Local runtime prerequisites** — Node 22, npm 10, Python 3.13, uv and Java are present. Cargo, ADB and Xcode are absent. Therefore RTK's Cargo route and real Android/iOS qualification cannot be honestly marked live in this environment.

## Important structural finding

The knowledge-library conversion intentionally removed runtime directories such as `scripts/`, `.claude/`, and `core/`, but several retained documents still describe those deleted files as executable dependencies. This creates false-positive “ready to use” instructions. The clearest operational breakage is the local Nemotron MCP/security-review path, but the same stale-reference class appears elsewhere.

**Rule going forward:** a knowledge wrapper may describe an external tool, but it must not claim that a local helper exists unless that helper is retained as a reusable template asset or the wrapper contains a self-contained upstream install path.

## Action priorities

1. Replace obsolete modelcontextprotocol/servers connector links with current vendor MCPs where they exist: GitHub, Slack, Notion, Linear, Figma, Supabase.
2. Downgrade/remove “official MCP” claims for Google Drive, PostgreSQL and any connector without a verified current vendor server.
3. Repair or retire the local Nemotron MCP/security-review activation path.
4. Refresh Graphify provenance to `Graphify-Labs/graphify` and Stripe provenance to `stripe/ai`.
5. Add a repeatable validation contract to every operational wrapper: upstream existence → installability → MCP initialize/tools-list → harmless read call → optional write test with explicit authorization.
6. Run mobile MCP handshakes on a machine with Android SDK/emulator and macOS/Xcode for iOS; repository existence alone is not proof that a device workflow works.

## Audit limitation

This report deliberately distinguishes **live connection evidence** from **upstream availability**. The current sandbox cannot reach arbitrary package registries/GitHub from the shell and has no Android/iOS device toolchain, so it would be misleading to mark every local MCP as end-to-end tested. Active upstream repositories were verified through GitHub access; vendor state was checked against current vendor documentation/plugin discovery; only connected services were marked LIVE.
