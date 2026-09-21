# Engineering Knowledge Library

A use-oriented knowledge base for building software and improving AI-assisted engineering. This repository is deliberately a **library, not a runtime**.

## Catalog by purpose

| Purpose | What to search here | Assets |
|---|---|---:|
| **Build projects & implementations** | project starters, code/templates, implementation patterns, framework/API references, example repositories, UI guidance | 101 |
| **Extend agent capabilities** | reusable skills, agent workflows, memory/context helpers, security/design/research capabilities | 42 |
| **Integrate external systems** | APIs, SaaS, auth, databases, AI providers, observability, payments, connectors and infrastructure | 64 |
| **Debug & avoid repeated failures** | troubleshooting, known failure modes, lessons, postmortems, prevention strategies and failed approaches | 58 |
| **Architecture & decisions** | system architecture choices, AI/API/CV/ML/mobile/web architecture and reusable ADR knowledge | 50 |
| **Testing, quality & reliability** | quality gates, contract/regression testing, logging and reliability guidance | 8 |

Total catalogued knowledge assets: **323** (plus this catalog).

### Cross-cutting goal: reduce context and token cost

This is not a separate technical asset type. The whole library is intended to avoid rediscovery: search for an existing pattern, example, integration guide, lesson, or reference before researching or generating the same knowledge again. Especially useful starting points are `external-skills/`, `external-systems/`, `patterns/`, `templates/`, and `docs/reference-repositories/`.

## How to use it

Search this repository by **the job you need to accomplish**. The physical paths below are retained for provenance and precise GitHub search, while this catalog supplies the use-oriented mental model.

- Building something new → start with `templates/`, `patterns/`, `docs/frameworks/`, `docs/reference-repositories/`, and `docs/official-docs/`.
- Giving an AI agent a capability → search `external-skills/` and relevant AI patterns.
- Connecting a service/tool → search `external-systems/` and integration patterns.
- Solving a bug or avoiding a known trap → search `docs/troubleshooting/`, `lessons-learned/`, `failed-solutions/`, and imported Stage 3 lessons.
- Choosing an architecture → search `docs/architecture-guides/` and `architecture-decisions/`.
- Hardening quality → search testing patterns plus the imported quality/reliability assets.

Historical runtime/system implementation is preserved on `archive/pre-knowledge-library`; it is intentionally absent from this library's `main`.
