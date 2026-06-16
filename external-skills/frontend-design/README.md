# frontend-design

**One-line summary:** A Claude Code skill that reframes Claude as a design lead and enforces a multi-pass, intentional visual design process when building or reshaping UI.

---

## Source

- **Repository:** https://github.com/anthropics/skills/tree/main/skills/frontend-design
- **Monorepo:** `anthropics/skills` (the Anthropic-maintained Claude Code plugin marketplace)
- **License:** Apache-2.0

## What it ships

A single file: `SKILL.md`. No scripts, no dependencies, no subfolders. The skill is distributed via the `example-skills` plugin in the `anthropic-agent-skills` marketplace bundle. It is entirely self-contained.

## Status

| Field | Value |
|---|---|
| Wrapper status | Active |
| Type tags | `ui-ux`, `coding` |
| Execution Level | **Level 2** for UI build/reshape work; **Level 1** otherwise |
| Trigger | Automatic on description match (no explicit slash command needed) |

## Install (quick summary)

Install via `/plugin` commands in Claude Code — see [`activation.md`](./activation.md) for the exact commands and a manual fallback.

> **Note:** `frontend-design` is bundled inside the `example-skills` plugin, not as a standalone plugin. You install the `example-skills` plugin to get access to it.

---

## See also

| File | Purpose |
|---|---|
| [`integration.md`](./integration.md) | Functional role, when to use, workflow impact, composition |
| [`policy.md`](./policy.md) | Classification, execution level, trigger rules, constraints |
| [`activation.md`](./activation.md) | Prerequisites, install commands, verification, disable/uninstall |
