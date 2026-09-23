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

If `get.maestro.mobile.dev` is blocked by egress policy, install the same artifact from `https://github.com/mobile-dev-inc/Maestro/releases/download/cli-<version>/maestro.zip`. Set `MAESTRO_CLI_NO_ANALYTICS=1` in CI/sandboxes.

## Host without a local emulator

On a host without KVM/Android SDK (e.g. Claude Code cloud containers), local
`list_devices` may expose no Android target. That blocks **local** agentic
mobile exploration; it does not mean Maestro itself is unusable.

Three execution routes remain:

1. a local/attached emulator or device visible to Maestro MCP;
2. deterministic `maestro test` flows inside CI/device infrastructure;
3. Maestro Cloud, when an account/credentials are available, using the CLI/cloud
   path or the MCP cloud tools exposed by current Maestro versions.

Maestro Cloud is the preferred acceleration path when repeatedly booting a CI
emulator is the bottleneck: upload the built app once, run flows on managed
devices, and parallelize independent scenarios. Keep authoritative backend
checks outside UI text when the product action has server-side effects.

Live 2026-09-23 SportReel evidence showed Maestro driving the real Android
operator flow through the system Photo Picker to a visible
`Verified · 100%` result. The run failed only on an obsolete filename
assertion because Android's Photo Picker renamed the media item; the UI
automation itself completed the upload journey. See the host qualification and
the SportReel UPL-01 evidence trail for the exact revision/run.

Pass secrets as `MAESTRO_*` environment variables, never in YAML, and scrub
debug artifacts because evaluated `inputText` can contain runtime values.
Live host evidence: [2026-09-23 host qualification](../evaluations/2026-09-23-claude-code-cloud-host-qualification.md).

Codex and other MCP clients can use the same local server command in their MCP configuration.

## Useful MCP behavior

The official MCP can enumerate available Android emulators, iOS simulators and Chromium targets, drive the application, inspect screens, execute/assert flows and expose Maestro Viewer for observing/interacting with the live device.

## Agent routing

Use Maestro first for:
- fast agent-driven exploration of Android/iOS user journeys before hand-writing a large deterministic suite;
- Android/iOS E2E user journeys;
- cross-platform regression flows;
- feature verification on emulator/simulator;
- producing readable tests that remain in the repo and run in CI.

Escalate to Appium MCP when the task needs deeper native/device/WebDriver capabilities that Maestro cannot expose.

## Verification

Confirm Maestro CLI is on PATH, MCP reconnects successfully, and `list_devices` sees the intended emulator/simulator/device before testing.
