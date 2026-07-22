# Engineering OS

A read-only governance and knowledge layer that Claude loads before every coding task.
It enforces consistent workflow, patterns, and quality gates across all your projects —
without rewriting the rules each time.

## What's inside

| Directory | Purpose |
|---|---|
| `CLAUDE.md` | **Entry point.** Loaded by Claude at the start of every session. Defines role, principles, skill activation, and navigation. |
| `core/` | Canonical policy files for workflow, quality gates, git policy, hooks, debugging, learning, skill orchestration, and related governance. The live inventory is the directory itself and the navigation table in `CLAUDE.md`. |
| `patterns/` | Code-pattern domains for auth, billing, API, database, UI, AI agents, observability, security, testing, integrations, and more. Lifecycle metadata is owned by `patterns/registry.yaml`. |
| `external-skills/` | External skill wrappers such as superpowers, security-review, graphify, rtk, claude-mem, ui-ux-pro-max, gstack, and claude-code-workflows. The live inventory is `external-skills/README.md`; each installed wrapper follows its documented SIP contract. |
| `external-systems/` | Third-party service and connector guides for LLM providers, databases, auth, payments, observability, CRM, and more. The live inventory is `external-systems/README.md`. |
| `templates/` | Project scaffolds and reusable file templates (including `hooks/pre-commit`). |
| `scripts/` | `use-in-project.sh` (apply OS to a new project), `skill-bootstrap.sh` (detect/install skills), `session-setup.sh` (SessionStart hook). |
| `docs/` | Architecture guides, framework references, troubleshooting. |
| `lessons-learned/` | Documented bugs, post-mortems, prevention strategies. |
| `failed-solutions/` | Approaches that were tried and failed — read before repeating them. |
| `architecture-decisions/` | ADRs for cross-project architectural choices. |

## How to use in a new project

**Recommended — one command from your project root:**

```bash
bash ~/.engineering-os/scripts/use-in-project.sh
```

This clones Engineering OS to `~/.engineering-os/`, wires it into your project's
`CLAUDE.md`, runs skill bootstrap, and prints the manual steps that can't be automated
(superpowers plugin install, GitHub secrets for security-review).

For submodule mode (pin the OS version to your repo), see `CLAUDE.template.md`.

## First-time machine setup

```bash
# 1. Required tools
curl -LsSf https://astral.sh/uv/install.sh | sh   # for graphify
# node/npm must already be installed

# 2. MCP servers (run inside Claude Code CLI once per machine)
claude mcp add notion https://mcp.notion.com/mcp
claude mcp add context7 https://mcp.context7.com/mcp

# 3. superpowers plugin (inside Claude Code CLI)
/plugin install superpowers@claude-plugins-official

# 4. Verify
/mcp          # Notion and Context7 should show as connected
/plugin list  # superpowers should appear
```

## Requirements

- [Claude Code CLI](https://claude.ai/code) with an Anthropic API key
- `git` 2.x+
- `uv` (Python package manager, for graphify)
- `node` / `npm` (for rtk and other skills)

## Philosophy

> Validate, don't guess. The system enforces quality gates deterministically —
> not through reminders, but through hooks and policy files that Claude re-reads
> before every action.

Full rationale and principles: `CLAUDE.md` → `<core_principles>`.
