# Event-Driven CI Continuation

Use this when an agent starts CI and should continue automatically when the run
finishes. Prefer a GitHub event over timers or manual polling.

## Preferred GitHub pattern

Use GitHub Actions `workflow_run` to start a downstream agent workflow after the
upstream workflow completes. Claude Code Action supports `workflow_run` events
and automation mode with a direct prompt.

Minimum shape:

```yaml
on:
  workflow_run:
    workflows: ["<upstream workflow name>"]
    types: [completed]

permissions:
  contents: write
  pull-requests: write
  actions: read
```

The downstream workflow should:

1. inspect `github.event.workflow_run.conclusion`, head SHA/ref and run ID;
2. check out the exact trusted revision intended for repair/verification;
3. run the agent in automation mode with a bounded continuation prompt;
4. grant `actions: read` so the agent can inspect CI status/job logs;
5. repair only reversible in-scope failures;
6. rerun the smallest relevant checks and leave durable evidence in the PR/repo.

## Authentication

Claude Code Action requires a supported Anthropic authentication path, such as a
repository secret containing an Anthropic API key or Claude Code OAuth token.
Do not assume one exists. Verify availability without exposing secret values.

## Security

`workflow_run` can execute with base-repository secrets. Treat upstream actor
and checked-out code as a trust boundary. Use the official Claude Code Action
rather than the lower-level base action when processing potentially untrusted
workflow inputs, because the supported action performs actor permission checks.

## Important boundary

This pattern starts a **new automated agent run in GitHub Actions**. It does not
wake or resume an existing chat UI session.

Therefore, continuation state must be durable: encode the task, current SHA,
acceptance criteria, prior findings and next action in the repository, PR/issue,
artifact or another authoritative project surface. A new agent run can then
resume from that state without reconstructing the conversation.

If the target chat/work platform exposes an explicit webhook for workflow-run
events, that can be used instead; do not invent or simulate such a webhook when
the platform does not expose one.

## Official references

- GitHub workflow_run event:
  https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_run
- Claude Code Action security and workflow_run behavior:
  https://github.com/anthropics/claude-code-action/blob/main/docs/security.md
- Claude Code Action CI permissions:
  https://github.com/anthropics/claude-code-action/blob/main/docs/configuration.md
- Claude Code Action custom automations:
  https://github.com/anthropics/claude-code-action/blob/main/docs/custom-automations.md
