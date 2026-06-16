# External Skills — Skill Orchestration Layer

> The integration layer that turns Engineering OS from a **knowledge system** into a **Skill Orchestration Framework**. Every external capability — repo, skill, plugin, MCP server, or agent system — enters the OS **only** through a uniform adapter defined here.
>
> **Governing policy:** [`core/skill-orchestration-policy.md`](../core/skill-orchestration-policy.md) (the SIP — Skill Integration Protocol).
> **Bootstrap / verification:** [`scripts/skill-bootstrap.sh`](../scripts/skill-bootstrap.sh).

---

## What this layer is

A skill is not "code to integrate into the app you are building" (that is [`external-systems/`](../external-systems/) and [`patterns/`](../patterns/)). A **skill** is an external capability that changes **how Claude itself works** — how it plans, codes, reviews, remembers, secures, or optimizes context. This directory holds the *integration contracts* for those capabilities, not the capabilities' source code.

```
Skill = External Capability + Integration Contract + Execution Rules
```

| Layer | What it governs |
|---|---|
| `external-skills/*` | Capabilities that change **Claude's own workflow** (this directory) |
| `external-systems/*` | Third-party **services the target app integrates with** (Stripe, Supabase…) |
| `patterns/*` | Reusable **code patterns** for the target app |
| `core/*` | The OS's own **policies** |

---

## The standard 4-file contract

Every skill lives in `external-skills/<skill-name>/` with exactly four files:

| File | Answers |
|---|---|
| `README.md` | *What is it?* — identity, real structure, install summary, license |
| `integration.md` | *How & when do I use it?* — behavioral contract + the real tools/commands you invoke |
| `policy.md` | *How does it fit the orchestration?* — classification, level, composition, override |
| `activation.md` | *How do I install & verify it?* — exact commands, presence check, secrets, removal |

Each wrapper is written from a **verified scan of the real repository** — not a marketing description. Where a popular claim was inaccurate, the wrapper says so (see the "Reality check" in `claude-code-workflows`).

---

## Skill registry

| Skill | Classification (`type`) | Level | Install mechanism | What you actually invoke |
|---|---|---|---|---|
| **[superpowers](./superpowers/)** | planning, review, orchestration, self-correction | **L2** for non-trivial dev work | Claude Code plugin (`/plugin install`) | 14 skills via the Skill tool (`brainstorming`, `writing-plans`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`…) |
| **[frontend-design](./frontend-design/)** | ui-ux, coding | **L2** for UI / L1 otherwise | plugin marketplace (`example-skills@anthropic-agent-skills`) | `frontend-design` skill (auto-triggers on UI requests) |
| **[claude-code-workflows](./claude-code-workflows/)** | review, orchestration | L1 / **L2** for large refactors | manual file copy (templates) | `pragmatic-code-review` & `design-review` subagents, `/design-review`, GitHub Action |
| **[security-review](./security-review/)** | security, review | **L2** before production | GitHub Action + slash command | `/security-review`, `anthropics/claude-code-security-review@main` Action |
| **[claude-mem](./claude-mem/)** | memory, context-persistence | **L2** (passive system dependency) | plugin + MCP + hooks + worker | MCP tools `search`, `timeline`, `get_observations` (+ passive lifecycle hooks) |
| **[gstack](./gstack/)** | orchestration, role-simulation | L1 (complex projects) | `git clone` + `./setup` (needs Bun) | role commands `/autoplan`, `/review`, `/qa`, `/cso`, `/ship` (23 specialists + 8 power tools) |
| **[graphify](./graphify/)** | context-optimization, code-intelligence | L1 (recommended default-on) | `uv tool install graphifyy` + MCP | `/graphify .`, MCP tools `query_graph`, `get_node`, `get_pr_impact`… |

---

## Execution levels (summary)

- **LEVEL 0 — optional**: Claude decides.
- **LEVEL 1 — recommended**: default-on unless there's an explicit reason to skip.
- **LEVEL 2 — mandatory**: runs whenever its trigger conditions are met **and** it is installed. A missing L2 skill is a reported gap, not a silent skip — see the bootstrap protocol.

Full definitions, the selection pipeline, the composition order, and the security-override rule are in [`core/skill-orchestration-policy.md`](../core/skill-orchestration-policy.md).

---

## Composition order (when several apply)

```
context-optimization (graphify)   → build/refresh code graph first, cross-cutting
memory (claude-mem)               → restore at session start, summarize at stop (passive)
1. planning   (superpowers, gstack /autoplan)   → before any code
2. coding     (frontend-design, superpowers TDD)
3. SECURITY GATE (security-review, gstack /cso)  → blocks before production; cannot be overridden
4. review     (claude-code-workflows, gstack /review, superpowers receiving-code-review) → last
```

**Three rules:** planning first · security always overrides · review runs last.

---

## Adding a new skill

1. **Scan the real repo first** (structure, manifests, real commands/tools) — never wrap from a description.
2. Create `external-skills/<skill-name>/` with the four contract files.
3. Assign `type` tags and an execution level in `policy.md`.
4. Add a row to the registry table above.
5. Add a detection entry to [`scripts/skill-bootstrap.sh`](../scripts/skill-bootstrap.sh).
6. If it is an MCP server, also register it in [`core/mcp-servers.md`](../core/mcp-servers.md).
7. If it is a significant capability, add it to [`CLAUDE.md`](../CLAUDE.md) navigation.

---

## Security note

Skill wrappers reference repositories by their **bare URL only**. Share links may carry per-user tokens (e.g. a `mcp_token` query parameter) — these are personal secrets and are **never** committed to any file here. Secrets required by a skill are documented by their env-var **name and purpose**, never their value, in that skill's `activation.md`.
