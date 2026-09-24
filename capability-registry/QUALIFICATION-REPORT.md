# Capability Qualification Report — 2026-09-21

## Scope
Post-cleanup qualification of project-owned AI capability wrappers and MCP assets. Built-in ChatGPT connectors are out of scope. Nemotron and its dependent Engineering-OS security-review implementation were removed before this pass.

## Verdicts
- **READY**: wrapper is self-contained, upstream exists, and no removed Engineering-OS runtime is required.
- **READY / HOST-DEPENDENT**: same, but functional execution requires the documented host/runtime/device.
- **REFERENCE ONLY**: intentionally retained but not routed for new use.
- **NOT QUALIFIED END-TO-END**: repository/instructions are sound, but this environment cannot execute the required external host/device handshake.

## Agent capabilities

| Asset | Verdict | Qualification |
|---|---|---|
| RTK | READY / HOST-DEPENDENT | Active upstream `rtk-ai/rtk`. Activation is self-contained. Requires supported local install and Claude Code hook registration for transparent interception. Removed stale Engineering-OS bootstrap claim. |
| Graphify | READY / HOST-DEPENDENT | Active upstream `Graphify-Labs/graphify`. CLI, graph build, optional MCP registration and verification are self-contained. Requires local Python/uv and a target repo; MCP path requires host registration. |
| claude-mem | READY / HOST-DEPENDENT | Active upstream `thedotmack/claude-mem`. Plugin/npx install, worker health and MCP verification are self-contained. Requires Claude Code/runtime prerequisites and persistent local worker/storage. |
| gstack | READY / HOST-DEPENDENT | Active upstream `garrytan/gstack`. Clone/setup path is self-contained; supports host selection. Removed references to deleted Engineering-OS security/runtime gates. |
| superpowers | READY / HOST-DEPENDENT | Active upstream `obra/superpowers`. Official/plugin route is self-contained. Removed the nonexistent Engineering-OS verifier and portable fallback. |
| ui-ux-pro-max | READY / HOST-DEPENDENT | Active upstream `nextlevelbuilder/ui-ux-pro-max-skill`. No deleted Engineering-OS runtime dependency remains. |
| claude-code-workflows | READY / TEMPLATE | Active upstream `OneRedOak/claude-code-workflows`. Exact current upstream artifact filenames are pinned; no placeholder filename remains. This is intentionally a copy/adapt template, not a plugin. |
| frontend-design | REFERENCE ONLY | Deprecated by this library in favor of ui-ux-pro-max. Retained for historical/reference use; no new-project routing. |

## Application-testing MCPs

| Asset | Verdict | Qualification |
|---|---|---|
| Playwright MCP | READY / HOST-DEPENDENT | Active official upstream `microsoft/playwright-mcp`; self-contained npx route. Needs MCP host/browser for live handshake. |
| Maestro MCP | READY / HOST-DEPENDENT | Active official Maestro repo; `maestro mcp` route documented. Needs Maestro CLI and Android/iOS target. |
| Appium MCP | READY / HOST-DEPENDENT | Active official `appium/appium-mcp`; needs Node/platform SDK/device or remote Appium endpoint. |
| Chrome DevTools MCP | READY / HOST-DEPENDENT | Active official `ChromeDevTools/chrome-devtools-mcp`; needs Chrome and MCP host. |
| Mobile Next MCP | READY / HOST-DEPENDENT | Active `mobile-next/mobile-mcp`; needs supported mobile target/toolchain. |

All 12 active upstream repositories checked in the 2026-09-21 pass were reachable and not archived at that time. This is dated evidence, not a claim about every capability currently catalogued.

## Connector template

`templates/connectors/engineering-os-mcp.json` was repaired. It now contains only concrete, non-placeholder entries:
- Context7 remote MCP
- Notion remote MCP
- Stripe remote MCP
- Supabase remote MCP
- Playwright stdio MCP

Unresolved placeholder entries for Slack, Linear, Jira, PostgreSQL, Google Drive, Google Sheets, Figma, Sentry, Postman and Composio were removed from the drop-in template. Their knowledge can remain elsewhere, but a reusable config must not pretend an unknown URL is runnable.

## Stale runtime assumptions repaired

This pass removed or neutralized operational references to the deleted Engineering-OS runtime from the active capability layer, including:
- `scripts/skill-bootstrap.sh`
- `session-setup.sh`
- `use-in-project.sh`
- deleted `core/*` quality/precedence/hook policy files
- deleted project-local security-review implementation
- placeholder slash-command filenames in claude-code-workflows

`external-skills/official-packages.md` is now explicitly a historical note instead of claiming that removed `.claude/skills` and `scripts/enforcement` assets are present.

Historical lessons/postmortems may still mention removed runtime files as historical evidence. Those references are not activation dependencies and should not be rewritten merely to erase history.

## What this qualification proves

It proves the active library wrappers are internally coherent after the knowledge-library conversion: they either contain a self-contained upstream activation path or are explicitly marked reference-only. It also proves the named upstream repositories still exist and are not archived as of 2026-09-21.

It does **not** falsely claim that every MCP completed a live initialize/tools/call handshake in this ChatGPT environment. Mobile MCPs require a mobile toolchain/device; Claude-specific skills require Claude Code; local stdio MCPs require an MCP host capable of launching them. Those are execution-environment qualifications, not library consistency failures.

## Remaining execution qualification

First live Claude Code host results: [2026-09-23 host qualification](./evaluations/2026-09-23-claude-code-cloud-host-qualification.md) (Superpowers, RTK, Graphify CLI+MCP, Maestro CLI PASS; Maestro MCP PARTIAL — no emulator on that host).

For a stronger L3-style qualification, run each host-dependent capability in its intended environment:
1. install using the wrapper;
2. verify version/presence;
3. for MCP: initialize + tools/list;
4. perform one harmless read-only tool call;
5. for mobile/browser tools: perform one real interaction against a disposable test target;
6. record host/version/date and evidence.

Until that environment-specific test is run, use **READY / HOST-DEPENDENT**, never “live verified”.

## Final library state

At the 2026-09-21 qualification pass, **broken active project-owned capability wrappers found after remediation: 0**.

Since that report, the integrated skill set has changed; current status is governed by the live wrappers, routing map and Knowledge Integrity gate rather than this historical snapshot. Host/runtime/device requirements remain explicit and must still be verified on the target environment.
