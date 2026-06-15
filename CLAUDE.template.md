# CLAUDE.md

> Copy this file to your project root as `CLAUDE.md` and fill in `<Project Context>`.
> Keep `./engineering-os/` as a git submodule at that exact path.

---

## Engineering OS — Mandatory Enforcement

This project uses **[Engineering OS](./engineering-os/)** as the authoritative source for every architectural, integration, and implementation decision.

> **Engineering OS is not a reference — it is the decision layer. Claude MUST consult it before writing code, choosing a library, or designing a system.**

---

## Pre-Task Protocol (Required Before Every Feature or Fix)

Before writing any code or making any decision, consult Engineering OS **in this exact order**:

1. `./engineering-os/templates/` — Does a matching project template exist? **Use it as the starting point.**
2. `./engineering-os/docs/architecture-guides/` — Is there an architecture guide for this domain?
3. `./engineering-os/patterns/` — Are there established patterns for this type of problem?
4. `./engineering-os/external-systems/` — Which service does the OS recommend for this use case?
5. `./engineering-os/docs/troubleshooting/` — Are there known bugs in this domain to avoid upfront?

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

### 4. Handle gaps explicitly, never silently
If Engineering OS does not cover a topic:
- State the gap explicitly: "Engineering OS has no entry for X."
- Propose adding it to the OS after the task.
- Use the closest analogous pattern in the OS until the gap is filled.
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
