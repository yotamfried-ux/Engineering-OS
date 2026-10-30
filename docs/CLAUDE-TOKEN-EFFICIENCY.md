# Claude Code: token-efficient setup across sessions (2026-10-30)

Engineering-OS is a **knowledge library, not an always-running agent or runtime**. This document describes how to make its token-saving tools available to Claude Code after a **one-time, host-local setup**. A GitHub checkout alone cannot change a user's Claude Code settings, and a setup verified on a cloud container does not verify another Windows/macOS/Linux host.

## Minimal recurring context

Claude Code loads `~/.claude/CLAUDE.md` in every project session. Keep a short, user-level instruction there (merge with existing content; never overwrite other rules). Copy only this block, not this whole document:

```md
## Engineering-OS: efficient context
- Prefer task-scoped Engineering-OS guidance when its local checkout is accessible. Start at AGENTS.md and capability-registry/ROUTING-MAP.md only when needed. Never bulk-load the library.
- Use RTK's existing PreToolUse hook for supported shell commands; never reinitialize it per session. Recover unfiltered output when exact evidence matters.
- For a large or unfamiliar codebase, use an existing, current Graphify graph/skill for focused queries before opening many files. Check freshness; verify conclusions in source. Do not rebuild graphs for every session or for trivial/non-code tasks.
- If claude-mem is installed and healthy, retrieve relevant cross-session context selectively. Current files/tests override memory; do not copy secrets into memory.
- Reuse installed tools. Do not clone, install, upgrade, restart workers, or run expensive status/diagnostic commands on every session merely to satisfy these instructions; check on demand and diagnose failures.
```

The above is **guidance**, not proof of activation: RTK needs a working hook, Graphify needs the installed skill and a useful project graph, and claude-mem needs a working plugin/worker. Keep repository-specific workflow rules in the repository's own `AGENTS.md` or `CLAUDE.md`.

## One-time setup on your actual persistent machine

Run these from the same Windows PowerShell, WSL, macOS or Linux environment where you launch Claude Code. Avoid installing the same tool separately on host and WSL unless you run Claude Code in both. These are **local commands, not GitHub actions**. Review the tools' licenses/privacy and existing configurations before installing.

1. **Claude Code**: run `claude --version` and `claude update` if an update is needed. Claude Code v2.1.277+ can read repository `AGENTS.md` directly when no project-level `CLAUDE.md` overrides it. Run `/context` in Claude Code to verify which instructions actually loaded; project support and configuration can vary.

2. **RTK**: after installing its official CLI, run `rtk --version`, `rtk init -g --dry-run`, review changes, then `rtk init -g` **once** and approve its settings patch. For an existing compatible install do not reinstall. Check `rtk init --show` for hook registration, and `rtk gain` **after real commands** for measured savings. Newer RTK supports a **native Windows** hook, not only WSL. Optional `rtk init -g --hook-only` avoids even the tiny RTK instruction import; use only if the hook's operation is understood. The hook does not affect Claude Code's native Read/Grep/Glob tools. Use raw output when filtering would hide required evidence.

3. **Graphify**: when code-navigation workload justifies it, install its CLI once with `uv tool install graphifyy`, register the Claude skill using `graphify install`, and check `graphify --version`. Build a per-project code graph only when useful (e.g. `graphify extract . --code-only` for keyless source-code extraction). Prefer narrow graph queries and read the source files needed for confirmation. Refresh the graph when source changes invalidate it; do not unconditionally extract on every session. MCP is **optional**: local CLI+skill already provide functionality, whereas per-project MCP registration adds tools and startup overhead. If used, register it against the **correct project's absolute graph path** and confirm `claude mcp list`.

4. **claude-mem**: only if persistent memory is desirable after privacy/security review, use the upstream Claude Code plugin instructions (`/plugin marketplace add thedotmack/claude-mem` and `/plugin install claude-mem`) or `npx claude-mem@latest install` once. Restart Claude Code. Validate with `npx claude-mem doctor` and `claude plugin list`; then test actual retrieval on a new session. Modern claude-mem requires a sufficiently recent Claude Code for its exec-form hooks. Its storage, optional providers, and summarization may have privacy or financial costs; do not assume local-only/no API usage.

5. **Engineering-OS checkout**: clone only once. On a persistent host, use `git -C <path-to-Engineering-OS> pull --ff-only` when you intentionally update the library (not on every session). For a project that has adopted its install-once manager, run `python tools/eos_capabilities.py status --project <project-path> --json` **on demand**. This is a *declared-profile readiness check*, not a complete Claude-global readiness test, and `ready=true` does not prove claude-mem, freshness of upstream versions, or real MCP tool calls.

## When to update versions

**Do not install latest versions automatically on every session.** This burns startup time, risks breaking hooks and graphs, and does not ensure the newer release is qualified.

As of 2026-10-30, the upstream stable releases checked were RTK **1.1.0**, Graphify **0.9.96** and claude-mem **15.6.0**. In contrast, `capability-registry/INSTALL-PROFILES.json` still pins *previously qualified host recipes* RTK **0.49.0** and Graphify **0.9.66**. These versions are intentionally **not represented as newly qualified** merely because a newer upstream release exists. Before changing the pins, run the same harmless host integration checks (RTK hook rewrites a Bash call; Graphify graph query+MCP if configured) and preserve evidence. The manager may downgrade/update to its pin during setup; do not run `setup` blindly against a newer working installation.

Check for upstream stable releases periodically or when a compatibility/security issue is found. Then intentionally upgrade and re-qualify:

- RTK: consult its current official installation/upgrade instructions, run `rtk init -g --dry-run`, then re-check hook registration and output.
- Graphify: `uv tool upgrade graphifyy` (or the matching pipx path), confirm its installed skill and refresh project graphs if the graph schema changes.
- claude-mem: `npx claude-mem update` or the supported marketplace update path, `npx claude-mem doctor`, then verify a new session's memory behavior.

## New-session acceptance test (run once after setup or meaningful upgrades)

- `/context` displays the **user-level** `~/.claude/CLAUDE.md`; if working in Engineering-OS, its local `AGENTS.md` is also loaded (directly or through `@AGENTS.md` import).
- `rtk init --show` reports the native Claude Code PreToolUse hook; a harmless Bash command is rewritten and `rtk gain` records an actual saving. A registered hook without execution is insufficient.
- `graphify --version` and the `/graphify` skill are available; on a chosen test code repository, a scoped graph query returns a relevant symbol and source inspection confirms it. Check MCP only if intentionally configured.
- If using claude-mem, `npx claude-mem doctor` is healthy and a fresh session can retrieve a non-sensitive known observation from an earlier session.
- No duplicate instructions/hooks, needless session-start rebuild, unexpected startup downloads, or unexplained credential transmission.
- Record PASS / FAIL / BLOCKED / NOT TESTED separately for **the local Windows Claude host**, **WSL**, and **cloud/disposable hosts** actually in use. If no host test ran, status is NOT TESTED.

## Authoritative references

- Claude Code memory and AGENTS.md: https://code.claude.com/docs/en/memory
- Claude Code hooks: https://code.claude.com/docs/en/hooks
- RTK upstream install and hooks: https://github.com/rtk-ai/rtk/blob/develop/INSTALL.md
- RTK releases: https://github.com/rtk-ai/rtk/releases
- Graphify official docs: https://github.com/Graphify-Labs/docs/blob/main/quickstart.mdx
- Graphify releases: https://github.com/Graphify-Labs/graphify/releases
- claude-mem installation: https://github.com/thedotmack/claude-mem/blob/main/docs/public/installation.mdx
- claude-mem releases: https://github.com/thedotmack/claude-mem/releases
