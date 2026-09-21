# Token & Context Efficiency Tools

These are capabilities whose **primary practical value includes reducing context/token use or avoiding repeated retrieval**. An agent should inspect this list before consuming a large repository, long CLI output, or multi-session history.

| Tool | Primary saving mechanism | Surface | Install / activate | Agent trigger |
|---|---|---|---|---|
| **RTK (Rust Token Killer)** | Compresses/filter/groups/deduplicates Bash output before it reaches model context; wrapper documents typical 60–90% savings on dev-tool output | Claude Code | Install RTK, then `rtk init -g` to register PreToolUse hook | Before repeated Bash-heavy work, tests, builds, git, grep/find, Docker/K8s |
| **Graphify** | Builds a queryable code knowledge graph so the agent retrieves relevant symbols/subgraphs instead of repeatedly reading whole files | Claude Code; optional MCP server may expose graph queries to compatible clients | `uv tool install graphifyy`, `graphify install`; optional `graphifyy[mcp]` | Non-trivial/large repo, unfamiliar codebase, impact analysis, cross-file navigation |
| **claude-mem** | Persists semantic observations/summaries across sessions, reducing repeated rediscovery and context reconstruction | Claude Code | Claude Code plugin marketplace or `npx claude-mem install` | Multi-session projects where prior decisions/context would otherwise be reread/reconstructed |

## Mandatory routing rule for agents

Before a large engineering task:
1. Estimate whether the task will involve a large repo, high-volume shell output, or repeated sessions.
2. If shell-output heavy → consider **RTK**.
3. If repository-reading heavy → consider **Graphify**.
4. If multi-session/context-reconstruction heavy → consider **claude-mem**.
5. Check the tool's `external-skills/<tool>/activation.md` before installation.
6. Verify presence after installation; never silently assume a tool is active.
7. If the environment cannot install it, continue normally and record the capability gap.

## Important distinction

A knowledge library can reduce tokens by avoiding rediscovery, but the tools above are **operational capabilities designed to change how the agent consumes context**. They therefore get first-class routing treatment.

Detailed wrappers:
- `external-skills/rtk/`
- `external-skills/graphify/`
- `external-skills/claude-mem/`
