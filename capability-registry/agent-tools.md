# Agent Workflow Tools

Capabilities that improve **how the AI worker operates**, rather than becoming dependencies of the application being built.

Before spawning a worker or choosing a model/provider, read [`EXECUTION-FAST-PATH.json`](./EXECUTION-FAST-PATH.json). It prefers deterministic and qualified local-model execution before hosted usage when the task can be verified independently.

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

## Install-once fast path

Before spending context reading install docs, check the qualified profile:

```bash
python3 /path/to/Engineering-OS/tools/eos_capabilities.py status --project /path/to/project --profile core --json
```

If READY, use the tools immediately. For a new project, run `setup` once. Host-level matching installs are reused and project-level Graphify/MCP state is prepared without reinstalling the host tools.

Automatic profiles:
- `core`: Superpowers + RTK + Graphify.
- `mobile`: core + Maestro.

The profile list is deliberately small and stored in `INSTALL-PROFILES.json`; it is not permission to install every catalog capability.

## Cost-aware delegation

Agent frameworks and agent definitions are not automatically free. Their model cost follows the selected runtime/provider. Ollama-backed local inference can avoid per-call hosted API charges, but still consumes local compute and must be qualified for task quality. Claude-Code-specific skills are not automatically portable to local models.

Use local/parallel agents mainly for bounded independent analysis, candidate generation and triage; keep final correctness/release claims behind deterministic evidence and one coordinating agent.

## Agent rule

Do not install every tool blindly. Select by task trigger. For the live-qualified profile, use the manager before opening individual activation docs. For capabilities outside that profile, inspect `activation.md`, verify prerequisites and trust/source, install only when appropriate, and verify activation. Token/context tools are separately indexed in `token-context-efficiency.md` so they can be discovered before expensive work begins.

## Application testing

For application testing, use the dedicated [application testing registry](./application-testing/README.md): Playwright MCP for web, Maestro MCP as the default Android/iOS route, Appium MCP for deeper mobile automation, and Chrome DevTools MCP for web debugging/performance evidence.

## Media understanding

- **MCP Video Analyzer (`guimatheus92/mcp-video-analyzer`)** — preferred route for local pipeline-generated video artifacts. It exposes key frames, OCR, timeline, exact-frame, focused-moment and burst-frame evidence, with a one-shot CLI fallback when MCP is unavailable. See `video-analysis/mcp-video-analyzer.md`. Current qualification: **READY AS KNOWLEDGE / NOT YET END-TO-END QUALIFIED ON TARGET HOST**. For visual defect claims require timestamp/frame evidence, and for a fix require analysis of the rerun output rather than pipeline success alone.
- **Video URL Analyzer MCP (`u2n4/video-url-analyzer-mcp`)** — complementary hosted multimodal analysis of supported video URLs (YouTube, TikTok, public Instagram). See `video-analysis/video-url-analyzer-mcp.md`. Current qualification: **CONDITIONAL / NOT END-TO-END QUALIFIED**; require the wrapper's live verification contract before use as a trusted active capability.
- **`/watch` (`mathiaschu/watch`)** — local-first skill fallback/alternative for URL or local-file video understanding when its host integration is preferable. See `external-skills/watch-video/README.md`. Current qualification: **READY AS KNOWLEDGE / NOT YET END-TO-END QUALIFIED ON TARGET HOST**.

For pipeline QA, start with the smallest route that can falsify the visual claim. Escalate from overview to a narrow moment/frame/burst and higher/native frame resolution only when needed; do not load dense full-video frames by default.
