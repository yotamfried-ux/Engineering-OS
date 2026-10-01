# CI Continuation Options

Reference notes for cases where an AI/agent starts CI and later needs the result.
This document describes available mechanisms and trade-offs; it does not require
a particular continuation strategy.

## Common options

| Option | Useful property | Limitation |
|---|---|---|
| Same-session host subscription | can resume the same session when a PR/check suite/workflow completes | depends on host support |
| GitHub `workflow_run` | event-driven continuation inside GitHub Actions | starts a new automated run rather than waking an existing chat |
| Bounded status read/polling | works when no event surface is available | adds latency/API work and needs explicit scheduling |

A same-session subscription can avoid timer loops when the host exposes that
capability. `workflow_run` is useful when continuation should live entirely in
GitHub. Polling remains a technical option when event-driven mechanisms are not
available.

## GitHub `workflow_run`

GitHub Actions can trigger a downstream workflow after an upstream workflow
completes:

```yaml
on:
  workflow_run:
    workflows: ["<upstream workflow name>"]
    types: [completed]
```

Claude Code Action and other automation can be used from such a workflow when
the repository has the required authentication and permissions.

## Authentication and security notes

Claude Code Action requires a supported Anthropic authentication path when it is
used. `workflow_run` may execute with base-repository secrets, so upstream actor
and checked-out code are part of the trust boundary.

The downstream workflow is a new process. State needed by a new process can be
stored in a PR, issue, repository file, artifact, or another durable project
surface.

## Official references

- GitHub workflow_run event:
  https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_run
- Claude Code Action security:
  https://github.com/anthropics/claude-code-action/blob/main/docs/security.md
- Claude Code Action configuration:
  https://github.com/anthropics/claude-code-action/blob/main/docs/configuration.md
- Claude Code Action custom automations:
  https://github.com/anthropics/claude-code-action/blob/main/docs/custom-automations.md
