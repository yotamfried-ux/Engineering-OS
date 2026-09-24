# Engineering Knowledge Library

A use-oriented knowledge base for building software and improving AI-assisted engineering. This repository is deliberately a **library, not a runtime**.

## 60-second start

**Persistent machine:** clone Engineering-OS once; later use `git pull --ff-only`.

**New project:** create a durable project tool manifest, then run setup:

```bash
python3 ~/Engineering-OS/tools/eos_capabilities.py init-project --project /path/to/project --profile core
# use --profile mobile for mobile apps

python3 ~/Engineering-OS/tools/eos_capabilities.py setup --project /path/to/project
```

`setup` processes **every tool declared in the project's
`.engineering-os-tools.json`**, installing/activating only what is missing.
Later sessions use:

```bash
python3 ~/Engineering-OS/tools/eos_capabilities.py status --project /path/to/project --json
```

If it reports `"ready":true`, do not reread install docs or reinstall tools.
Use `catalog` to see all centrally known installable/conditional tools and
`ensure --tool <name>` when the project adopts another capability.

Code examples, patterns, templates and reference repositories remain knowledge,
not dependencies.

See [Engineering-OS — 60-second start](docs/GETTING-STARTED.md).

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


## AI capability registry

[`capability-registry/`](./capability-registry/README.md) catalogs tools/connectors that may help with a task, host-specific capabilities, and token/context-saving options.

High-value entry points:
- [Token & context efficiency](./capability-registry/token-context-efficiency.md) — RTK, Graphify, claude-mem and routing rules.
- [Connector matrix](./capability-registry/connectors.md) — external-service capability routing for ChatGPT/Codex and Claude.
- [Agent workflow tools](./capability-registry/agent-tools.md) — tools that improve the AI worker itself.
- [Agent & execution fast path](./capability-registry/EXECUTION-FAST-PATH.json) — choose deterministic, local-model, included-credit or paid execution with minimum context.
- [Testing fast path](./patterns/testing/FAST-PATH.md) — low-context routing + copy/adapt skeletons for unit, regression, integration, contract and UI tests.

## How to use it

Search this repository by **the job you need to accomplish**. The physical paths below are retained for provenance and precise GitHub search, while this catalog supplies the use-oriented mental model.

- Building something new → start with `templates/`, `patterns/`, `docs/frameworks/`, `docs/reference-repositories/`, and `docs/official-docs/`.
- Delegating work / choosing an agent or model → `capability-registry/EXECUTION-FAST-PATH.json` describes available execution routes and cost classes.
- Giving an AI agent a capability → search `external-skills/` and relevant AI patterns.
- Connecting a service/tool → search `external-systems/` and integration patterns.
- Solving a bug or avoiding a known trap → search `docs/troubleshooting/`, `lessons-learned/`, `failed-solutions/`, and imported Stage 3 lessons.
- Choosing an architecture → search `docs/architecture-guides/` and `architecture-decisions/`.
- Writing/choosing a test → start with `patterns/testing/FAST-PATH.json`; open `FAST-PATH.md` only when you need a skeleton/explanation.
- Hardening/qualifying a whole project → use the full testing map and qualification patterns.

Historical runtime/system implementation is preserved on `archive/pre-knowledge-library`; it is intentionally absent from this library's `main`.
