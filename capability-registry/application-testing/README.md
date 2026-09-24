# Application Testing Capability Registry

Use this registry before manually testing an application. It routes an AI agent to the strongest reusable testing capability for the target surface.

## Default routing

| Target | Primary capability | Secondary / escalation |
|---|---|---|
| Web UI | Playwright MCP + Playwright Test | Chrome DevTools MCP for network/console/performance debugging |
| Android / iOS UI | Maestro MCP + deterministic Maestro flows | Appium MCP when deeper native/device/WebDriver control is required |
| Complex native/device automation | Appium MCP | Native platform frameworks underneath Appium where appropriate |
| MCP-native mobile exploration / supported physical devices | Mobile Next MCP | Maestro for durable regression flows; Appium for deeper native control |

## Agent workflow

1. Identify target surfaces: web, Android, iOS, or several.
2. Check the project tool state first: `python3 /path/to/Engineering-OS/tools/eos_capabilities.py status --project /path/to/project --json`.
3. If the preferred testing tool belongs to the project but is missing, use `ensure --tool <name>` or add it to `.engineering-os-tools.json` and rerun `setup`. Read the capability wrapper only for manual/conditional prerequisites or troubleshooting.
4. Verify the server/device/browser before testing.
5. Explore the real application through MCP.
6. Convert important discovered flows and every reproduced bug into deterministic regression tests stored with the application.
7. Use CI for repeatability; MCP-driven exploratory testing does not replace deterministic test suites.
8. When a failure is ambiguous, collect evidence (screenshots, traces, console/network/device state) before changing code.

## Capability wrappers

- [Playwright MCP](./playwright-mcp.md)
- [Maestro MCP](./maestro-mcp.md)
- [Appium MCP](./appium-mcp.md)
- [Chrome DevTools MCP](./chrome-devtools-mcp.md)
- [Mobile Next MCP](./mobile-next-mcp.md)

## Native frameworks

Espresso (Android) and XCUITest (iOS) remain important native testing technologies, but this registry does **not** invent standalone official MCP servers for them. Appium's official MCP can drive Android/iOS through its mobile automation stack, including UiAutomator2/XCUITest drivers. Add a direct Espresso/XCUITest MCP wrapper only after a trustworthy server is verified.

Last verified: 2026-09-21.
