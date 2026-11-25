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

## Installable capabilities extracted from 19 Instagram Reels (Nov 2026)

The [video intake and evidence matrix](docs/instagram-intake-2026-11-25.md) records the original 19 unique Reels, exact upstreams, uncertainty and deployment status. This is **executable installation support**, not merely documentation.

- **Real upstream Claude Skills and agents:** opt-in `reels-design`, `reels-engineering`, `reels-marketing`, `reels-media` and `reels-all` profiles in [INSTALL-PROFILES.json](capability-registry/INSTALL-PROFILES.json). Installer checks canonical origin, does an actual Git clone, links `SKILL.md` / native Agent definitions to Claude Code, detects conflicts, and verifies reuse. Official Claude plugins install through the existing Claude CLI route.
- **Built-in executable tools:** `tools/openverse_audio_search.py` (read-only audio discovery and license metadata) and `tools/reactbits_component.py` (install an actual React Bits component into a selected project). No arbitrary package installation is performed by default.
- **Project React dependencies:** `ui-sdk-react` installs `@ui-sdk/core` and `@ui-sdk/react` with `npm --ignore-scripts --save-exact` into the target project, then checks `package.json` and `node_modules`.
- **Full desktop/server apps** (Chatwoot, OpenProject, AppFlowy, etc.) are registered as **conditional** and not deployed automatically. They require deliberate host, secrets, storage, networking and resource decisions.

From a persistent Linux/macOS host with Claude Code and Git installed:

```bash
python3 tools/eos_capabilities.py catalog
python3 tools/eos_capabilities.py ensure --tool hallmark
python3 tools/eos_capabilities.py ensure --tool agency-agents
python3 tools/eos_capabilities.py setup --project /your/project --profile reels-design
python3 tools/eos_capabilities.py status --project /your/project --profile reels-design --json

# Bundled CLI (no installation other than checking out this repository):
python3 tools/openverse_audio_search.py "ui click" --limit 5
python3 tools/reactbits_component.py --examples
```

**Verification boundary:** [independent CI](https://github.com/yotamfried-ux/Engineering-OS/actions/workflows/eos-reel-capabilities.yml) performs compile/unit/upstream checks and installs actual third-party Skills in disposable Linux homes. This proves installation logic on the test host, **not** that any specific user's persistent machine has been provisioned, that paid APIs are configured, or that every generated output passes quality gates.

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

For **Claude Code setup that survives new sessions across projects**, see [the one-time host setup and verification guide](docs/CLAUDE-TOKEN-EFFICIENCY.md). GitHub instructions alone do not register global hooks or verify local tools.

This is not a separate technical asset type. The whole library is intended to avoid rediscovery: search for an existing pattern, example, integration guide, lesson, or reference before researching or generating the same knowledge again. Especially useful starting points are `external-skills/`, `external-systems/`, `patterns/`, `templates/`, and `docs/reference-repositories/`.


- Preparing any audience-facing product for legal/privacy/consumer/contractual risk → use [Legal & Compliance knowledge](./docs/legal-compliance/README.md) and [jurisdiction applicability routing](./docs/legal-compliance/APPLICABILITY-AND-ROUTING.md). This is source-backed **REFERENCE ONLY**, not a lawyer's approval or guarantee against litigation.
- Releasing/publishing a web app, SaaS, Android/iOS app or other public-facing product → use [pre-launch and app store publication](./capability-registry/release-readiness/README.md), with current Google/Apple official requirements, test-account eligibility, metadata, privacy, launch and rollback evidence. This expands the existing Google Play wrapper rather than replacing it.
## n8n Project Factory — proposed V7 specification

For the separate live n8n Engineering OS runtime, see the [Dynamic Development Environments & Autonomous Capability Manager specification](docs/specifications/n8n-dynamic-development-environments-and-capability-manager-v7.md). This is a **proposed implementation specification**, not evidence that the host or agent runtime has been upgraded. This repository remains a knowledge library, not the n8n runtime.

## AI capability registry

Before doing expensive manual work, check [`capability-registry/`](./capability-registry/README.md). It tells an AI worker what tools/connectors may already solve the task, how to route to ChatGPT/Codex vs Claude/Claude Code capabilities, and when to install token/context-saving tools.

High-value entry points:
- [Token & context efficiency](./capability-registry/token-context-efficiency.md) — RTK, Graphify, claude-mem and routing rules.
- [Connector matrix](./capability-registry/connectors.md) — external-service capability routing for ChatGPT/Codex and Claude.
- [Agent workflow tools](./capability-registry/agent-tools.md) — tools that improve the AI worker itself.
- [Agent & execution fast path](./capability-registry/EXECUTION-FAST-PATH.json) — choose deterministic, local-model, included-credit or paid execution with minimum context.
- [Testing fast path](./patterns/testing/FAST-PATH.md) — low-context routing + copy/adapt skeletons for unit, regression, integration, contract and UI tests.

## How to use it

Search this repository by **the job you need to accomplish**. The physical paths below are retained for provenance and precise GitHub search, while this catalog supplies the use-oriented mental model.

- Designing **any** customer-facing experience (web, mobile, desktop, kiosk, chat, service, email, SMS/push) → start with [experience routing](./docs/ui-ux/EXPERIENCE-ROUTING.md) and its [source/example atlas](./docs/ui-ux/SOURCE-ATLAS.md); write real copy, flows, exceptional states, motion intent and prove usability. This complements—not replaces—the existing UI skill and UI patterns.
- Building something new → start with `templates/`, `patterns/`, `docs/frameworks/`, `docs/reference-repositories/`, and `docs/official-docs/`.
- Delegating work / choosing an agent or model → start with `capability-registry/EXECUTION-FAST-PATH.json`; prefer no-LLM/local execution when it can be independently verified.
- Giving an AI agent a capability → search `external-skills/` and relevant AI patterns.
- Connecting a service/tool → search `external-systems/` and integration patterns.
- Solving a bug or avoiding a known trap → search `docs/troubleshooting/`, `lessons-learned/`, `failed-solutions/`, and imported Stage 3 lessons.
- Choosing an architecture → search `docs/architecture-guides/` and `architecture-decisions/`.
- Writing/choosing a test → start with `patterns/testing/FAST-PATH.json`; open `FAST-PATH.md` only when you need a skeleton/explanation.
- Hardening/qualifying a whole project → use the full testing map and qualification patterns.

Historical runtime/system implementation is preserved on `archive/pre-knowledge-library`; it is intentionally absent from this library's `main`.
