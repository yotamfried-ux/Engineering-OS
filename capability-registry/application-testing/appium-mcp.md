# Appium MCP — Deep Mobile Automation

**Primary use:** advanced Android/iOS development, automation and test generation through Appium.

**Status:** official Appium project MCP server.

## Source
- Repository: https://github.com/appium/appium-mcp
- Official Appium tools documentation: https://appium.io/docs/en/latest/ecosystem/tools/
- MCP documentation plugin: https://github.com/appium/appium-mcp-documentation

## Requirements

Current server documentation requires Node.js 22+, with Android SDK for Android and Xcode on macOS for iOS. It supports embedded local Android/iOS drivers or connection to an existing remote Appium/WebDriver server.

## Install

Package: `appium-mcp` (npm). The MCP registry identifier is `io.github.appium/appium-mcp`; stdio is supported.

A compatible MCP client can launch the installed package/server through its standard MCP configuration. Consult the upstream README for the current client-specific command/options rather than freezing a client config here.

## Documentation-aware mode

Appium also maintains `@appium/mcp-documentation`. When enabled with Appium MCP it adds:
- `appium_documentation_query` — RAG queries over Appium documentation;
- `appium_skills` — ordered setup/troubleshooting guidance for Android/iOS environments.

This is especially valuable for an AI worker because setup and driver failures can be diagnosed using Appium's own indexed knowledge.

## When to route here

Use when:
- Maestro cannot expose a required native/device capability;
- existing Appium infrastructure/device farms must be reused;
- the test requires advanced session/device control;
- Android/iOS driver-specific behavior matters;
- remote WebDriver/Appium infrastructure is part of the system.

## Security

Treat device control and `remoteServerUrl` as trusted configuration. Do not derive remote destinations from untrusted PR/prompt content. Appium documents allow-list controls for remote server URLs. Keep the MCP surface restricted to trusted agents/users.

## Verification

Verify platform SDK/toolchain, target device, Appium MCP discovery, and creation/attachment of a test session before running application scenarios.
