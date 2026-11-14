# claude-mem — Claude Code activation

claude-mem supplies optional **cross-session memory**. Installing it is not inherently a token saving: context injection, storage/retention, indexing and optional model providers carry overhead and privacy implications. Use it when repeated reconstruction demonstrably outweighs those costs.

## One-time install (persistent Claude Code host)

Check the current [upstream installation guide](https://github.com/thedotmack/claude-mem/blob/main/docs/public/installation.mdx) and [releases](https://github.com/thedotmack/claude-mem/releases) before making changes. These steps are **not** carried out by cloning Engineering-OS.

Inside Claude Code:

```text
/plugin marketplace add thedotmack/claude-mem
/plugin install claude-mem
```

Or from a terminal, to run the upstream installer and ensure a working hook launcher:

```bash
npx claude-mem@latest install
```

Use **one** installation route for a working setup. If marketplace-only setup is missing runtime dependencies or launcher, the upstream installer/repair command may be needed; do not blindly duplicate registration. Restart Claude Code after installation or changing PATH. Do **not** use `npm install -g claude-mem` as a substitute: that installs the SDK/library, not the plugin hooks.

Recent upstream versions implement native launcher / exec-form hooks. They require a compatible Claude Code; when the host is older, upgrade Claude Code rather than assuming memory is active. On Windows the launcher is placed in the user-local `claude-mem\bin` directory; on Linux/macOS normally `~/.local/bin`. Do not write machine-specific paths into a shared repository.

## Verify actual activation

```bash
claude --version
claude plugin list
npx claude-mem doctor
```

Confirm that the plugin is enabled, hook launcher resolves correctly on PATH, and the worker is healthy. Open **a fresh session**, then verify retrieval of one known **non-sensitive** prior observation. Do not interpret successful installation alone as proof of recall. The worker's port may be configured/dynamic; consult its actual state/logs rather than always assuming 37777.

## Privacy, cost, and scope

- Review what the `PostToolUse`, `SessionStart`, prompt and session-summary hooks capture; exclude secrets, credentials and sensitive tool outputs.
- The local data directory is normally `~/.claude-mem/`, but configured providers, sync or summarization can send data outside the machine or incur API cost. Confirm the **actual provider**; do not assert that all processing is local or that an API key is always required.
- Limit context injection to relevant observations and verify source-of-truth from current code/test results.
- Check project separation and memory reset/export controls before relying on cross-project recall.
- On disposable cloud containers, cross-session memory may not persist; document this as a host limitation rather than reinstalling every session.

## Updates / repair

A marketplace update or `npx claude-mem update` is an intentional maintenance action, **not a per-session startup task**. After changes, run `npx claude-mem doctor` and re-test on a fresh session. Consult upstream diagnostics for incompatible hooks, launcher shadowing or missing dependencies.

## Disable

Disable or uninstall using the supported `/plugin` commands or `npx claude-mem uninstall`. Stored memory may remain in `~/.claude-mem/`; check and export data before any deletion. Do not delete the memory directory automatically.

Also see [the host-wide token efficiency guide](../../docs/CLAUDE-TOKEN-EFFICIENCY.md).
