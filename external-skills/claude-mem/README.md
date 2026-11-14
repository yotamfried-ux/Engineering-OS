# claude-mem

Cross-session memory for Claude Code: automatically captures tool-use observations,
generates semantic summaries, and injects prior context into future sessions.

## Source

- **Repo:** https://github.com/thedotmack/claude-mem
- **License:** Apache-2.0
- **Upstream stable release checked 2026-10-30:** v15.6.0 (the historical host qualification is separate; no new local host test is implied)

## What it ships

claude-mem is a **combination system**, not a single component:

| Component | Description |
|---|---|
| Claude Code plugin | Registered via `/plugin marketplace add` or `npx claude-mem install` |
| MCP server (`mcp-search`) | stdio server (`scripts/mcp-server.cjs`) exposing `search`, `timeline`, `get_observations` |
| Lifecycle hooks | `plugin/hooks/hooks.json` — Setup, SessionStart, UserPromptSubmit, PostToolUse(*), PreToolUse(Read), Stop |
| Background worker | HTTP service (`worker-service.cjs`) on **port 37777**, started by hooks automatically |
| npm SDK/library | Published to npm (`claude-mem` package) — the SDK only; does not install hooks or plugin |
| Storage | SQLite with FTS5 at `~/.claude-mem/`; optional Chroma vector DB |
| Skills (16) | `mem-search`, `how-it-works`, `make-plan`, `learn-codebase`, `smart-explore`, `timeline-report`, `standup`, `version-bump`, `babysit`, `pathfinder`, and 6 more |

### How it works in brief

```
PostToolUse hook   → captures observations about every tool call
Stop hook          → generates a semantic summary of the session
SessionStart hook  → injects prior context into the new session
UserPromptSubmit   → enriches prompt with relevant memories
```

Observations and summaries have a local data directory (`~/.claude-mem/`), **but processing and optional memory providers can use remote APIs or hosted sync** depending on configuration. Review the current provider selection, data policy and cost before enabling automatic capture.

## Status

| Field | Value |
|---|---|
| Wrapper status | Active |
| Classification | `memory`, `context-persistence` |
| Execution Level | **LEVEL 2 — system dependency** for multi-session projects (passive once installed; hooks operate automatically) |

## Install summary

**Recommended (plugin marketplace):**

```
# Inside Claude Code:
/plugin marketplace add thedotmack/claude-mem
/plugin install claude-mem
# Then restart Claude Code
```

**Alternative (npx):**

```bash
npx claude-mem@latest install
# Optional: npx claude-mem install --ide gemini-cli
```

> **WARNING:** `npm install -g claude-mem` installs the SDK/library ONLY.
> It does NOT register plugin hooks, set up the worker, or configure the MCP server.
> Use the plugin install path above for the full system.

Full prerequisites, verification, and config: [activation.md](./activation.md).

## Privacy

A local data directory is normally used at **`~/.claude-mem/`**, but external processing/sync depends on configured provider. The worker usually exposes a localhost web UI; discover its actual port from the current runtime rather than assuming that `37777` is always configured.

Do not assume that wrapping text in `<private>` tags alone protects every file, tool output or provider path. Check the current redaction and capture settings and keep credentials and sensitive data out of prompts/tool output whenever possible. Use `npx claude-mem doctor` after an install/upgrade to verify hooks and launcher.

---

See also:
- [integration.md](./integration.md) — functional role, when to use, composition model
- [policy.md](./policy.md) — classification, execution level, composition rules
- [activation.md](./activation.md) — prerequisites, install steps, config, disable/uninstall
