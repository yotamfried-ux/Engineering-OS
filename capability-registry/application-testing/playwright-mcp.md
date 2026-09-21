# Playwright MCP — Web Application Testing

**Primary use:** AI-driven browser automation, exploration and web test authoring.

**Status:** official Microsoft Playwright MCP server.

## Source
- Repository: https://github.com/microsoft/playwright-mcp
- Documentation: https://playwright.dev/mcp/

## Install / connect

Prerequisite: Node.js 20+ and an MCP-capable client.

Generic stdio configuration:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

Claude Code:

```bash
claude mcp add playwright npx @playwright/mcp@latest
```

The standard MCP configuration also works with compatible clients such as Codex.

## What the agent gets

Playwright MCP controls web pages using structured accessibility snapshots, with browser navigation, interaction, form filling, screenshots, browser selection and configurable browser contexts. It can also run Playwright code and supports advanced configuration.

## When to route here

Use by default for:
- web UI exploratory testing;
- reproducing user journeys;
- authentication and form flows;
- turning discovered flows into Playwright regression tests;
- multi-browser checks.

For deep Chrome network/console/performance analysis, compose with Chrome DevTools MCP.

## Verification

After connection, ask the agent to navigate to a known page and inspect/interact with it. For project testing, verify the intended browser/profile and authentication state before trusting results.
