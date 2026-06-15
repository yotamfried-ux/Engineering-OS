# Engineering OS

A modular knowledge system that governs Claude's behavior across software projects — covering architecture, patterns, integrations, workflows, and debugging. Designed to be used as a **git submodule** inside any project so Claude always has an authoritative, up-to-date decision layer to consult.

---

## What It Does

Without Engineering OS, Claude makes decisions from general training knowledge — inconsistent, uncalibrated, and disconnected from your actual stack.

With Engineering OS, Claude follows a mandatory consultation protocol before every decision:
1. Checks approved templates before writing boilerplate
2. Checks architecture guides before designing a system
3. Checks approved patterns before writing code
4. Checks approved integrations before choosing an external service
5. Checks troubleshooting guides before implementing a risky domain

The result: **deterministic, reviewable, improvable AI behavior** — not a black box.

---

## Structure

```
engineering-os/
├── CLAUDE.md                    ← Governs Claude when working ON this repo
├── CLAUDE.template.md           ← Copy to consumer project root as CLAUDE.md
│
├── core/                        ← Operating rules (always loaded by CLAUDE.md)
│   ├── workflow.md              ← Task start protocol, onboarding, agent loop
│   ├── quality-gates.md        ← Pre-commit checklist, definition of done
│   ├── git-policy.md           ← Branch strategy, commit protocol, safety rules
│   ├── debugging-policy.md     ← Systematic bug-finding loop
│   ├── learning-loop.md        ← Lessons learned, post-mortems
│   ├── pattern-lifecycle.md    ← How patterns are scored, promoted, retired
│   ├── precedence.md           ← Conflict resolution hierarchy
│   ├── connector-policy.md     ← How to pick integrations and handle fallbacks
│   ├── hooks-policy.md         ← Deterministic enforcement via git/claude hooks
│   └── mcp-servers.md          ← MCP servers available for Claude sessions
│
├── templates/                   ← Full project skeletons with starter template picks
│   ├── web-application/
│   ├── mobile-app/
│   ├── saas-platform/
│   ├── api-service/
│   └── ...
│
├── patterns/                    ← Scored, versioned code patterns
│   ├── auth/
│   ├── billing/
│   ├── database/
│   ├── api/
│   ├── ai-agents/
│   ├── observability/
│   └── ...
│
├── external-systems/            ← Approved integrations with setup + pitfalls
│   ├── anthropic/
│   ├── stripe/
│   ├── supabase/
│   ├── clerk/
│   ├── connectors/              ← MCP connectors (GitHub, Slack, Notion, etc.)
│   └── ...
│
├── docs/
│   ├── architecture-guides/     ← Domain architecture (web, API, AI, mobile, MCP)
│   ├── frameworks/              ← Framework references (Next.js, FastAPI, etc.)
│   ├── troubleshooting/         ← Common bugs + fixes per domain
│   ├── official-docs/           ← Official API documentation indexes
│   └── reference-repositories/  ← Curated external repos to learn from
│
├── lessons-learned/             ← Post-mortems and regression notes
├── failed-solutions/            ← Approaches tried and discarded (with reasons)
└── architecture-decisions/      ← ADRs
```

---

## Using Engineering OS in a Project

### 1. Add as a submodule

```bash
git submodule add https://github.com/yotamfried-ux/Engineering-OS engineering-os
git submodule update --init --recursive
```

### 2. Create your project CLAUDE.md

Copy the enforcement template to your project root:

```bash
cp engineering-os/CLAUDE.template.md CLAUDE.md
```

Then fill in the `<Project Context>` section with your project's stack, goal, and stage.

### 3. How the enforcement works

When Claude starts a session in your project, it reads `CLAUDE.md` first. The template enforces a mandatory consultation order:

```
Task arrives
    ↓
Check engineering-os/templates/          → use matching skeleton
    ↓
Check engineering-os/docs/architecture-guides/  → follow domain guide
    ↓
Check engineering-os/patterns/           → use approved pattern
    ↓
Check engineering-os/external-systems/   → use approved integration
    ↓
Check engineering-os/docs/troubleshooting/  → avoid known bugs
    ↓
Write code
```

Claude is prohibited from inventing architectures, patterns, or integrations that Engineering OS already covers. Gaps must be surfaced explicitly — not silently filled with general knowledge.

### 4. Keeping Engineering OS up to date

```bash
# Pull latest OS updates into your project
git submodule update --remote engineering-os
git add engineering-os
git commit -m "chore: update engineering-os to latest"
```

---

## Contributing to Engineering OS

When you encounter a pattern, integration, bug fix, or architecture decision that isn't in the OS:
1. Add it to the appropriate directory (`patterns/`, `external-systems/`, `docs/troubleshooting/`, etc.)
2. Follow the format of existing files in that directory
3. For patterns: apply the scoring rubric in `core/pattern-lifecycle.md`
4. Commit to a feature branch and open a PR

---

## Philosophy

Engineering OS treats Claude as a **deterministic execution layer**, not a creative problem-solver. The creativity belongs to the developer (you) — captured in the OS's templates, patterns, and guides. Claude's job is to follow those decisions precisely, surface gaps, and not improvise.

Three things make it work:
- **Comprehensiveness** — the OS must cover enough ground that Claude rarely needs to fall back to general knowledge
- **Enforcement** — `CLAUDE.md` in the consumer project must mandate consultation, not suggest it
- **Feedback loop** — gaps found during projects must be written back into the OS so it improves over time
