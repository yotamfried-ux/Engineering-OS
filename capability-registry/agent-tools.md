# Agent Workflow Tools

Capabilities that improve **how the AI worker operates**, rather than becoming dependencies of the application being built.

| Capability | Practical use | Activation source |
|---|---|---|
| superpowers | planning, TDD, debugging, verification, review discipline | `external-skills/superpowers/` |
| RTK | token-efficient Bash output | `external-skills/rtk/` |
| Graphify | token-efficient code intelligence and impact/navigation | `external-skills/graphify/` |
| claude-mem | cross-session memory/context persistence | `external-skills/claude-mem/` |
| ui-ux-pro-max | UI/UX design workflow and accessibility review | `external-skills/ui-ux-pro-max/` |
| claude-code-workflows | PR/design review workflows | `external-skills/claude-code-workflows/` |
| gstack | multi-role planning/review/QA/ship workflows | `external-skills/gstack/` |
| cli-anything | generate tested CLI harnesses for GUI-heavy/non-agent-native software | `external-skills/cli-anything/` |
| laya-coreml | local typed decision inference on supported Apple Silicon targets | `external-skills/laya-coreml/` |
| frontend-design | deprecated; use ui-ux-pro-max | `external-skills/frontend-design/` |

## Agent rule

Do not install every tool blindly. Select by task trigger, inspect `activation.md`, verify prerequisites and trust/source, install only when appropriate, and verify activation. Token/context tools are separately indexed in `token-context-efficiency.md` so they can be discovered before expensive work begins.

## Application testing

For application testing, use the dedicated [application testing registry](./application-testing/README.md): Playwright MCP for web, Maestro MCP as the default Android/iOS route, Appium MCP for deeper mobile automation, and Chrome DevTools MCP for web debugging/performance evidence.


## Media understanding

- **Video URL Analyzer MCP** — multimodal analysis of supported video URLs (YouTube, TikTok, public Instagram). See `video-analysis/video-url-analyzer-mcp.md`. Current qualification: **CONDITIONAL / NOT END-TO-END QUALIFIED**; require the wrapper's live verification contract before use as a trusted active capability.
