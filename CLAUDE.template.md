# CLAUDE.md

> **How to use this template — choose one mode:**
>
> **Mode A — Recommended (shared reference via `use-in-project.sh`):**
> Run this once from your target project's root:
> ```bash
> bash ~/.engineering-os/scripts/use-in-project.sh
> ```
> This installs Engineering OS at `~/.engineering-os/` and auto-generates the correct
> CLAUDE.md block with the right paths. **You do not need to copy this file manually.**
>
> **Mode B — Git submodule (if you want the OS pinned to your repo):**
> ```bash
> git submodule add https://github.com/yotamfried-ux/Engineering-OS ./engineering-os
> ```
> Then copy this file to your project root as `CLAUDE.md` and replace every
> `./engineering-os/` path below with the actual submodule path.
>
> **Path note:** Mode A uses `~/.engineering-os/` everywhere. Mode B uses `./engineering-os/`.
> The paths in this template use `./engineering-os/` (Mode B). If using Mode A, adjust accordingly
> or let `use-in-project.sh` generate the block automatically.

---

## Engineering OS — Mandatory Enforcement

This project uses **[Engineering OS](./engineering-os/)** as the authoritative source for every architectural, integration, and implementation decision.

> **Engineering OS is not a reference — it is the decision layer. Claude MUST consult it before writing code, choosing a library, or designing a system.**

---

## Boundary Rule (Non-Negotiable)

- `./engineering-os/` (or the shared `ENGINEERING_OS_HOME` reference) is **read-only from the perspective of this project**.
- **Never write directly** to Engineering OS files while working on this project.
- If this project uncovers a reusable lesson / pattern / improvement for the OS:
  1. document it locally in this project first,
  2. then promote it via a PR to the Engineering OS repository.
- Only edit Engineering OS directly when the active repository is the Engineering OS repo itself.

---

## Pre-Task Protocol (Required Before Every Feature or Fix)

Before writing any code or making any decision, consult Engineering OS **in this exact order**:

1. `./engineering-os/core/task-router.md` — classify the task and build the route plan.
2. `./engineering-os/templates/` — Does a matching project template exist? **Use it as the starting point.**
3. `./engineering-os/docs/architecture-guides/` — Is there an architecture guide for this domain?
4. `./engineering-os/patterns/` — Are there established patterns for this type of problem?
5. `./engineering-os/external-systems/` — Which service does the OS recommend for this use case?
6. `./engineering-os/docs/troubleshooting/` — Are there known bugs in this domain to avoid upfront?

**If you skip this protocol, you are operating outside the Engineering OS. Stop and go back.**

---

## Non-Negotiable Rules

### 1. Never invent what Engineering OS already defines
If `./engineering-os/` has a pattern, template, or recommended integration for a use case — use it.
Do not create an alternative. Do not default to general knowledge.

### 2. Never choose an external service without checking `./engineering-os/external-systems/`
The OS defines the approved integrations, their capabilities, limitations, pricing, and how to integrate them. If the OS has an entry for the service type you need (auth, payments, search, email, etc.) — use the OS recommendation, not your prior knowledge.

### 3. Never design an architecture without checking `./engineering-os/docs/architecture-guides/`
If a guide exists for the domain (web, API, AI, mobile, data, MCP) — follow it. If it conflicts with the task requirements, stop and discuss with the user before proceeding.

### 4. Template or architecture doc gap → STOP, do not proceed

If you search `./engineering-os/templates/` for the current project type and find nothing:
- **Stop immediately.** Do not scaffold from general knowledge.
- Say: `"Engineering OS has no template for [project type]. I cannot scaffold this project without one."`
- Propose adding the template. Wait for user direction before writing any project structure.

If you search `./engineering-os/docs/architecture-guides/` for the current domain and find nothing:
- **Stop immediately.** Do not design an architecture from training data.
- Say: `"Engineering OS has no architecture guide for [domain]. I cannot make a reliable design decision without one."`
- Propose adding the guide. Wait for user direction before making any structural decisions.

### 5. Pattern gap → proceed with the closest analogous, document the gap
If a *code pattern* is missing from `./engineering-os/patterns/`:
- State the gap: `"Engineering OS has no pattern for [X]. Using the closest analogous pattern: [Y]."`
- Proceed with the closest analogous pattern.
- Propose adding the missing pattern to the OS after the task.
- Never silently fall back to general knowledge as if the OS didn't exist.

---

## Project Context

Fill this in at the start of the project and update it as the stack changes.

```
- Owner:
- Goal:
- Type: <web app / mobile app / API / AI agent / ML / CLI / library / other>
- Stack:
- Stage: <prototype / production>
- Key services:
```

---

## Engineering OS Quick Reference

| What you need | Where to look |
|---|---|
| Task routing — which template/pattern/skill/connector applies | `./engineering-os/core/task-router.md` |
| Project structure / boilerplate | `./engineering-os/templates/` |
| Architecture for a domain (web, AI, API, mobile, data, MCP) | `./engineering-os/docs/architecture-guides/` |
| Code pattern (auth, billing, database, API, AI agents, observability) | `./engineering-os/patterns/` |
| External service integration (Stripe, Supabase, OpenAI, Clerk, etc.) | `./engineering-os/external-systems/` |
| MCP connectors (GitHub, Slack, Notion, Linear, Stripe, Postgres…) | `./engineering-os/external-systems/connectors/` |
| Known bugs and domain-specific fixes | `./engineering-os/docs/troubleshooting/` |
| Framework references (Next.js, FastAPI, React Native, etc.) | `./engineering-os/docs/frameworks/` |
| Workflow — how to start a task / onboarding sequence | `./engineering-os/core/workflow.md` |
| Pre-commit checklist and definition of done | `./engineering-os/core/quality-gates.md` |
| Git policy — branches, commits, safe operations | `./engineering-os/core/git-policy.md` |
| When instructions conflict — which rule wins | `./engineering-os/core/precedence.md` |
| Debugging a bug — systematic loop | `./engineering-os/core/debugging-policy.md` |
| MCP servers to add for this session | `./engineering-os/core/mcp-servers.md` |
| Post-mortem / lessons learned | `./engineering-os/lessons-learned/` |
| Past failed approaches (to avoid repeating) | `./engineering-os/failed-solutions/` |
| Architecture Decision Records | `./engineering-os/architecture-decisions/` |

---

## Precedence

When two instructions conflict, the higher rule wins:

1. **Do not cause irreversible or shared damage without explicit human approval** — secrets, data loss, production, merging to main only with explicit approval.
2. **Validate, never guess** — no unverified state presented as fact; "success" requires tests, logs, UI, or API proof.
3. **Do not bypass deterministic enforcement (hooks)** — if a hook blocks, the block is valid; fix the root cause.
4. **Explicit current user instruction** — overrides written rules within limits 1–3; surface the conflict in one sentence first.
5. This `CLAUDE.md` → `./engineering-os/core/` → `./engineering-os/patterns/` → `./engineering-os/docs/` → general knowledge.

---

## Communication

- Language: English (or match the project's primary language).
- Show diffs, not full files, on edits.
- After every non-trivial action, state which Engineering OS file guided the decision. This lets the user verify OS compliance and update the OS if needed.
- "It works" is not evidence. Proof = passing tests, observable logs, or confirmed UI/API behavior.