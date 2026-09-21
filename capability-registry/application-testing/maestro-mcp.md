# Maestro MCP — Android, iOS and Cross-Platform UI Testing

**Primary use:** AI-driven mobile UI testing and creation/debugging of repeatable Maestro flows.

**Status:** official Maestro MCP, bundled in the Maestro CLI.

## Source
- Repository: https://github.com/mobile-dev-inc/Maestro
- Documentation: https://docs.maestro.dev/get-started/maestro-mcp
- Documentation source: https://github.com/mobile-dev-inc/maestro-docs/blob/main/introduction/get-started/maestro-mcp.md

## Why it is the default mobile route

Maestro provides one flow model across Android and iOS and supports native, React Native, Flutter, Ionic/hybrid applications. Its MCP exposes live device automation to coding agents and can turn exploration into deterministic YAML E2E flows.

## Install / connect

Install Maestro CLI first. The MCP server ships with it.

Generic stdio configuration:

```json
{
  "mcpServers": {
    "maestro": {
      "command": "maestro",
      "args": ["mcp"]
    }
  }
}
```

Claude Code:

```bash
claude mcp add maestro -- maestro mcp
```

Codex and other MCP clients can use the same local server command in their MCP configuration.

## Useful MCP behavior

The official MCP can enumerate available Android emulators, iOS simulators and Chromium targets, drive the application, inspect screens, execute/assert flows and expose Maestro Viewer for observing/interacting with the live device.

## Agent routing

Use Maestro first for:
- Android/iOS E2E user journeys;
- cross-platform regression flows;
- feature verification on emulator/simulator;
- producing readable tests that remain in the repo and run in CI.

Escalate to Appium MCP when the task needs deeper native/device/WebDriver capabilities that Maestro cannot expose.

## Verification

Confirm Maestro CLI is on PATH, MCP reconnects successfully, and `list_devices` sees the intended emulator/simulator/device before testing.
