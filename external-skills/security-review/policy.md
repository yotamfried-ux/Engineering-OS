# Security Review — Policy

## Classification

| Field | Value |
|---|---|
| Type tags | `security`, `review` |
| Source | https://github.com/anthropics/claude-code-security-review |
| License | MIT (Anthropic) |
| Wrapper status | Active |

---

## Execution Level

**LEVEL 2 — MANDATORY before production AND before merge to main (conditioned on installation).**

"Conditioned on installation" means: if this skill is not installed in a given repository, the gate does not apply to that repository. Once installed, the gate is unconditional for that repository.

Mandatory trigger conditions (both must be satisfied for the gate to fire):

1. The skill is installed (the GitHub Action workflow exists in `.github/workflows/` OR the slash command is available in `.claude/commands/`).
2. Any of the following is about to happen: merge to `main` (or the repository's production branch), production deployment, final sign-off on a branch.

---

## Composition and Override Rules

### Core rule

> **No skill may override a SECURITY-level skill.**

This rule is unconditional. It does not yield to:

- Convenience ("we're in a hurry")
- Other skills with lower classification (code-review, simplify, run, deploy helpers)
- Implicit user pressure to move fast

If the gate has not been satisfied, Claude must surface that fact explicitly before proceeding with any merge or deployment step.

### Gate sequencing

```
branch changes ready
       |
       v
[SECURITY REVIEW GATE]  <-- this skill; must pass first
       |
       v
[general code review / sign-off]
       |
       v
[merge to main / deploy]
```

No step below the gate may be executed until the gate step is complete and its findings are resolved or explicitly waived by a human.

### Waiver protocol

A finding may be waived ONLY by the repository owner with an explicit, documented decision (e.g., a PR comment stating the rationale). Claude does not self-waive. Claude does not treat silence or time pressure as a waiver.

---

## Security Notes

### Trusted PRs only — prompt injection not hardened

The underlying Python engine and Claude prompts are **not hardened against prompt injection**. A malicious actor can embed instructions in source code, comments, or commit messages that influence the review output.

Mandatory mitigation: **require explicit human approval before the workflow triggers on any PR from an external or untrusted contributor.** Use GitHub's "Require approval for first-time contributors" or equivalent branch protection rules.

### Scope limits — excluded categories

The engine explicitly excludes the following from its scope. These require dedicated tooling:

| Excluded category | Recommended alternative |
|---|---|
| Denial-of-service (DoS) vulnerabilities | Manual review; load/stress testing |
| Rate-limiting gaps | Manual review; API gateway rules |
| On-disk secrets / secrets in repository history | `trufflehog`, `git-secrets`, GitHub secret scanning |

**Do not treat a clean security-review result as a guarantee that the above categories are safe.** The skill's scope is limited to newly-introduced security issues in changed code only.

### Diff-only scope

The skill reviews only the diff — files changed in the current PR or branch. Pre-existing vulnerabilities in unchanged code are not reported. This is intentional (reduces noise) but means the skill is not a substitute for periodic full-codebase security audits.
