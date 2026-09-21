# Chrome DevTools MCP — Web Debugging & Performance

**Primary use:** complement Playwright with browser internals: console, network and performance evidence.

**Status:** official Chrome DevTools MCP project.

## Source
- Repository: https://github.com/ChromeDevTools/chrome-devtools-mcp

## Requirements
Node.js LTS, npm, and a supported current Chrome/Chrome for Testing installation.

## Install / connect

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest"]
    }
  }
}
```

A slim/headless mode is available upstream for basic browser tasks.

## What it adds

- browser console inspection;
- network request analysis;
- screenshots;
- source-mapped error inspection;
- Chrome performance traces and performance insights;
- browser automation via Puppeteer.

## Routing

Use Playwright MCP as the default web interaction/test-authoring capability. Add Chrome DevTools MCP when a failure requires browser-internal evidence or performance diagnosis.

## Security

The MCP client can inspect and modify data visible in the controlled browser. Do not expose sensitive sessions/data to untrusted MCP clients.
