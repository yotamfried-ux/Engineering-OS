# External Skills — inventory

Inventory of external capabilities that affect how Claude plans, codes, reviews,
remembers, secures, or optimizes context inside Engineering OS.

This README is **index-only**. It lists active skills, replaced items, and adjacent
accelerators. The source of truth for orchestration rules is
[`core/skill-orchestration-policy.md`](../core/skill-orchestration-policy.md).
Bootstrap and presence checks live in [`scripts/skill-bootstrap.sh`](../scripts/skill-bootstrap.sh).

Canonical owners:

| Question | Source of truth |
|---|---|
| Which skill wrappers exist? | This README |
| Skill Integration Protocol | `../core/skill-orchestration-policy.md` |
| Task routing to skills | `../core/task-router.md` |
| Capability vocabulary | `../core/capability-registry.yaml` |
| Install / verification mechanics | `../scripts/skill-bootstrap.sh` plus each skill's `activation.md` |
| One skill's behavior contract | `external-skills/<name>/integration.md` and `policy.md` |

---

## What belongs here

A SIP-managed skill is an external capability with a local contract that changes
Claude's own engineering workflow. It is not app code and not a normal third-party
service integration.

```text
SIP-managed skill = external capability + local contract + activation notes
```

| Layer | Responsibility |
|---|---|
| `core/*` | OS policy and routing decisions |
| `external-skills/README.md` | skill inventory and status |
| `external-skills/<skill>/` | one capability contract |
| `external-systems/*` | services the target app integrates with |
| `patterns/*` | reusable implementation patterns for target apps |

---

## Active SIP-managed skills

| Skill | Classification | Level | Install mechanism | Invocation surface |
|---|---|---|---|---|
| [superpowers](./superpowers/) | planning, review, orchestration, self-correction | L2 default baseline | Claude Code plugin | Skill tool entries such as `brainstorming`, `writing-plans`, `test-driven-development`, `systematic-debugging`, `verification-before-completion` |
| [security-review](./security-review/) | security, review | L2 for production-bound work | GitHub Action + slash command | `/security-review`, `anthropics/claude-code-security-review@main` Action |
| [claude-mem](./claude-mem/) | memory, context-persistence | L2 where environment allows persistence | plugin + MCP + hooks + worker | MCP tools `search`, `timeline`, `get_observations` plus passive lifecycle hooks |
| [graphify](./graphify/) | context-optimization, code-intelligence | L2 default baseline | `uv tool install graphifyy` + MCP | `/graphify .`, MCP tools `query_graph`, `get_node`, `get_pr_impact` |
| [rtk](./rtk/) | context-optimization | L2 default baseline | `cargo install --git https://github.com/rtk-ai/rtk` | PreToolUse hook output compression |
| [ui-ux-pro-max](./ui-ux-pro-max/) | ui-ux, coding | L2 for UI projects / L1 otherwise | Claude Code plugin | UI/UX design workflow, component specs, accessibility review |
| [claude-code-workflows](./claude-code-workflows/) | review, orchestration | L1 / L2 for large refactors | manual file copy templates | `pragmatic-code-review`, `design-review`, `/design-review`, GitHub Action |
| [gstack](./gstack/) | orchestration, role-simulation | L1 opt-in for complex projects | `git clone` + `./setup` | role commands `/autoplan`, `/review`, `/qa`, `/cso`, `/ship` |

---

## Replaced / deprecated wrappers

| Item | Status | Replacement | Action |
|---|---|---|---|
| [frontend-design](./frontend-design/) | replaced | [ui-ux-pro-max](./ui-ux-pro-max/) | keep only as historical wrapper; do not list as active for new projects |

---

## Adjacent accelerators

Adjacent accelerators can support Engineering OS, but they are not listed as active
SIP-managed skills until their ownership and runtime contract are explicit.

| Item | Current home | Status | Why it is adjacent |
|---|---|---|---|
| [nemotron](./nemotron/) | `external-skills/nemotron/` | adjacent accelerator | NVIDIA/NIM-backed LLM support via MCP tools; useful for generation/review/summarization, but not a Claude workflow skill in the same sense as SIP-managed skills |

Follow-up cleanup for adjacent accelerators can either move them to a dedicated
inventory or keep them here under this section, but they should not appear in the
active skill table.

---

## Standard SIP contract

Each active SIP-managed skill directory uses four local files:

| File | Answers |
|---|---|
| `README.md` | identity, real structure, install summary, license |
| `integration.md` | when to use it and which real tools/commands are invoked |
| `policy.md` | classification, level, composition, overrides |
| `activation.md` | install, verification, required secrets, removal |

Each wrapper is written from a verified scan of the real repository, not from a
marketing description. Where a popular claim is inaccurate, the wrapper documents
the reality check locally.

---

## Default activation profile

Default profile expected by `skill-bootstrap.sh` in a standard project:

```text
superpowers · security-review · graphify · rtk · claude-mem
```

Conditional additions:

| Skill | Condition |
|---|---|
| ui-ux-pro-max | UI surface exists |
| claude-code-workflows | PR-review workflow is relevant |
| gstack | complex multi-role work justifies the heavier setup |

Full execution-level definitions and composition rules live in
[`core/skill-orchestration-policy.md`](../core/skill-orchestration-policy.md).

---

## Adding a new skill wrapper

1. Scan the real repo first: structure, manifests, commands and tools.
2. Create `external-skills/<skill-name>/` with the four SIP files.
3. Assign type tags and execution level in `policy.md`.
4. Add or update the row in this inventory.
5. Add detection to [`scripts/skill-bootstrap.sh`](../scripts/skill-bootstrap.sh).
6. For MCP-backed capabilities, keep the MCP server registry aligned with [`core/mcp-servers.md`](../core/mcp-servers.md).

---

## Security note

Skill wrappers reference repositories by their bare URL only. Share links can carry
per-user tokens, such as an `mcp_token` query parameter; those are personal secrets
and stay out of committed files. Secrets needed by a skill are documented by env-var
name and purpose, never by value, in that skill's `activation.md`.
