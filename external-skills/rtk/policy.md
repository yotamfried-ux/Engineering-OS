# RTK — Policy

## Classification

```yaml
type: [context-optimization]
execution_level: LEVEL_2 # transparently on, where a compatible Claude Code hook is installed
activation_scope: host-global-once
```

RTK reduces token cost for supported shell output when its **PreToolUse hook is actually active**. The 60–90% figure is an upstream estimate, not a verified saving for every project or command.

## Use and safeguards

- On a persistent host, install and configure the Claude Code native hook **once** with `rtk init -g`. Verify with `rtk init --show` and a real harmless Bash execution.
- The hook rewrites supported Bash commands; **Read**, **Grep**, **Glob** and other non-Bash tools are outside its scope.
- Do not reinstall, reinitialize or upgrade on every session start. Existing global hook registration carries across projects.
- When precision matters, use unfiltered output (e.g. `rtk proxy <command>` where supported, or the direct command) and preserve full evidence for logs, security reviews, failures, and tests.
- If the tool is missing, incompatible, or the hook is disabled, report this and continue safely; never claim a reduction without measured evidence.
- Review RTK edition and license for your use case. Newer upstream releases include Apache-2.0 and BUSL-1.1 editions; do not repeat the previous blanket MIT claim.

RTK provides output compression; it never replaces required testing, security, or review steps.

## Upstream

- https://github.com/rtk-ai/rtk
- https://github.com/rtk-ai/rtk/blob/develop/INSTALL.md
