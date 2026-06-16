# Security Review — SIP Wrapper

**One-line summary:** Diff-aware AI security review gate that scans only changed code, produces severity-ranked findings with remediation guidance, and posts PR comments automatically.

---

## Source

- **Repository:** https://github.com/anthropics/claude-code-security-review
- **License:** MIT (Anthropic)

---

## What It Ships

A combination of three integrated components that share a single Python audit engine:

| Component | Path / Reference |
|---|---|
| GitHub Action | `anthropics/claude-code-security-review@main` (name: "Claude Code Security Reviewer") |
| Claude Code slash command | `/security-review` (`.claude/commands/security-review.md`) |
| Python audit engine | `claudecode/` — `github_action_audit.py`, `prompts.py`, `findings_filter.py`, `claude_api_client.py` |

Supporting files: `.github/workflows/`, `docs/`, `examples/`, `scripts/comment-pr-findings.js`.

---

## Status

| Field | Value |
|---|---|
| Wrapper status | Active |
| Type tags | `security`, `review` |
| Execution level | **LEVEL 2 — MANDATORY before production / before merge to main** (conditioned on installation) |

---

## Install Summary

- **GitHub Action:** Add the `security.yml` workflow snippet (see `activation.md`). Set the `CLAUDE_API_KEY` repository secret.
- **Slash command:** Copy `security-review.md` into `.claude/commands/` in the target repository.

Full setup steps, the exact YAML snippet, secrets config, and verification steps are in `activation.md`.

---

## CRITICAL CAVEAT

> **This skill is NOT hardened against prompt injection attacks.**
> Run it ONLY on trusted code. For external contributor PRs, require explicit approval before the workflow triggers. See `policy.md` for the full security constraint and scope limits.

---

## Navigation

| File | Contents |
|---|---|
| `integration.md` | Functional role, when to use / not use, how it affects Claude's workflow, composition rules |
| `policy.md` | Classification, execution level, override rules, security constraints |
| `activation.md` | Prerequisites, install steps, YAML snippet, secrets config, verify, disable |
