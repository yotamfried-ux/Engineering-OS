# Event-Driven CI Continuation

Use this when an agent starts CI and should continue automatically when the run
finishes. Prefer an event subscription over timers or manual polling.

## Priority order

1. **Same-session host subscription first.** If the current agent host can
   subscribe to PR/check-suite/workflow completion notifications and resume the
   same session, subscribe before yielding. Persist the current SHA, acceptance
   criteria and next action in the PR/audit. While that subscription is live,
   do **not** add a timer, sleep-loop or status-poll fallback.
2. **GitHub `workflow_run` fallback.** If the host cannot resume from a completion
   subscription, start a new automated agent run after the upstream workflow
   completes. The repository must carry enough durable state for the new run to
   continue without reconstructing the chat.
3. **Polling only as a last resort.** Use a single bounded status read only when
   neither event path exists; record the missing capability as friction.

A job-specific event is not required when a check-suite/PR completion event
already proves that all required jobs reached terminal state. Do not add timers
merely to wake earlier for one long-running job.

## GitHub workflow_run fallback

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

The `workflow_run` fallback starts a **new automated agent run in GitHub
Actions**. It does not wake an existing chat UI session. A host-native
subscription is preferred when it can resume the same session.

Continuation state must therefore be durable: encode the task, current SHA,
acceptance criteria, prior findings and next action in the repository, PR/issue,
artifact or another authoritative project surface.

If the target platform exposes another explicit completion webhook/subscription,
use it; do not invent or simulate one.

## Official references

- GitHub workflow_run event:
  https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_run
- Claude Code Action security and workflow_run behavior:
  https://github.com/anthropics/claude-code-action/blob/main/docs/security.md
- Claude Code Action CI permissions:
  https://github.com/anthropics/claude-code-action/blob/main/docs/configuration.md
- Claude Code Action custom automations:
  https://github.com/anthropics/claude-code-action/blob/main/docs/custom-automations.md
