# Mobile Next MCP — Agent-Native Mobile Testing

**Primary use:** MCP-native control of Android and iOS applications from AI agents, including emulators/simulators and supported physical devices.

**Project:** `mobile-next/mobile-mcp`

## Why it belongs in the library

Mobile Next MCP exposes a common mobile automation surface directly through MCP. It is useful when an AI agent needs to inspect and operate a real mobile UI rather than only generate a deterministic test file.

It complements, rather than replaces:
- **Maestro MCP** — preferred default for cross-platform E2E flows and durable regression tests.
- **Appium MCP** — escalation path for deeper native/device/WebDriver automation.

## Agent routing

Consider Mobile Next MCP when:
- the task is exploratory testing driven directly by an MCP agent;
- Android and iOS should expose a similar agent-facing interface;
- a physical-device workflow is required and supported by the environment;
- structured/accessibility-driven interaction can reduce reliance on screenshot-only reasoning.

For qualification of an entire application, do not treat successful MCP interaction as sufficient evidence. Cover critical user journeys, backend effects, persistence, permissions/error states and convert important scenarios into repeatable regression tests.

## Source and installation

Repository: https://github.com/mobile-next/mobile-mcp

Before installation, read the current upstream README and verify its supported platforms, prerequisites, client configuration and device requirements. Do not freeze credentials or machine-specific device configuration into this knowledge repository.

## Verification

After connection:
1. confirm the MCP server is discoverable by the AI client;
2. enumerate/identify the intended Android or iOS target;
3. launch or attach to the application;
4. inspect the current UI;
5. perform a harmless interaction and verify the resulting state;
6. only then begin qualification scenarios.

## Security

A mobile-control MCP can interact with authenticated applications and data visible on the device. Use dedicated test accounts/devices where possible and do not expose production credentials or unrelated personal data.

Last cataloged: 2026-09-21.
