# claude-mem — Policy

## Classification

| Field | Value |
|---|---|
| Type tags | `memory`, `context-persistence` |
| Source | https://github.com/thedotmack/claude-mem |
| Activation | Claude Code plugin / installer, persistent host only |
| Default | **Optional** — enable only when measured cross-session value and privacy are acceptable |

## Decision

Use claude-mem for longer-running, multi-session work **if** its memory retrieval reduces re-exploration and the intended host has persistent state. It is **not mandatory** for every project or session: Claude Code has its own CLAUDE.md / AGENTS.md and auto-memory mechanisms. A temporary cloud host, one-off task, sensitive project or provider-cost constraint can justify leaving it disabled.

Once installed, do **not** run installation, manual memory injection, or worker restart commands at every session start. The plugin's own lifecycle hooks manage startup, capture and retrieval. Verify that hooks and launcher are actually working after setup or upgrades.

## Safety and cost

- Review the current version's providers, storage location, optional hosted sync, privacy/capture/redaction behavior, and retention before enabling it. Local disk storage does **not** mean summarization or sync always stays local.
- Never assume that `<private>` tags alone exclude all sensitive files, tool results, secrets or credential paths from every hook or external provider.
- User prompts, source code, CI logs and tool outputs may carry secrets or PII; avoid unnecessary capture and apply exclusions supported by the installed version.
- Any model/provider processing can incur tokens, credits or compute cost. Do not assume an Anthropic API key is universally mandatory or that all models are free.
- Memory across projects can be useful but can also leak irrelevant context: inspect actual project isolation and retrieval quality.
- Treat remembered assertions as hints only. Current code, official documentation and tests override them.
- Use `npx claude-mem doctor` after setup/change to detect missing launcher/hooks. A reported plugin registration alone is not end-to-end qualification.

## Operational reference

See [activation](activation.md) and [cross-session setup](../../docs/CLAUDE-TOKEN-EFFICIENCY.md). Never delete or reset a user's stored memory without explicit authorization.
