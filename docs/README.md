# Docs

Authoritative documentation for architecture decisions, framework selection, external API references, troubleshooting guides, and UI/UX patterns.

---

## Gap Protocol — MANDATORY

> **If you search for documentation needed for the current task and it does not exist in this directory, you MUST stop immediately and inform the user.**
>
> Do NOT:
> - Substitute general training knowledge for a missing OS document
> - Proceed with an architectural or integration decision that the missing doc would have governed
> - Use a partially relevant doc as a silent substitute
>
> DO:
> 1. State explicitly: `"Engineering OS has no [architecture guide / framework guide / troubleshooting entry] for [topic]. I cannot make a reliable decision without it."`
> 2. Propose adding the document to the OS.
> 3. Wait for user guidance: either approve a new doc, point to the closest existing one, or authorize a one-off decision for this task.
>
> **Reason:** Missing documentation means the OS has not yet codified a decision for this domain. Filling that gap with training knowledge bypasses the OS's quality and consistency guarantees. The right response is to surface the gap, not to paper over it.

---

## Directory Structure

| Directory | Purpose | Consult When |
|---|---|---|
| [`architecture-guides/`](./architecture-guides/) | System-level design patterns per domain | Before designing any system or choosing a data flow pattern |
| [`frameworks/`](./frameworks/) | Framework comparison and selection guides | Before choosing a framework for a new project or component |
| [`official-docs/`](./official-docs/) | Indexed links to official API/SDK documentation | Before integrating a service or using an unfamiliar API |
| [`reference-repositories/`](./reference-repositories/) | Curated external repos to study for implementation patterns | When you need a concrete reference implementation |
| [`troubleshooting/`](./troubleshooting/) | Known bugs and domain-specific fixes | Before implementing in a domain with known pitfalls |
| [`api-design/`](./api-design/) | REST/GraphQL design rules, versioning, auth flows | Before designing or reviewing an API contract |
| [`ui-ux/`](./ui-ux/) | UX patterns, component library guidance, accessibility rules | Before designing any user-facing surface |

---

## Architecture Guides

| Domain | Subdirectory | Patterns Covered |
|---|---|---|
| Web | [`architecture-guides/web/`](./architecture-guides/web/) | Monolith, modular monolith, microservices, serverless, BFF, multi-tenant SaaS, event-driven |
| API | [`architecture-guides/api/`](./architecture-guides/api/) | REST, GraphQL, gRPC, CQRS, event-driven, webhook-driven |
| AI Agents | [`architecture-guides/ai/`](./architecture-guides/ai/) | Single-agent, ReAct, RAG, planner-executor, multi-agent, memory, workflow, HITL |
| MCP | [`architecture-guides/mcp/`](./architecture-guides/mcp/) | Local process, remote server |
| Mobile | [`architecture-guides/mobile/`](./architecture-guides/mobile/) | Online-first, offline-first, local-first |
| ML | [`architecture-guides/ml/`](./architecture-guides/ml/) | Batch training, online learning, streaming ML, classification, forecasting, recommendations |
| Computer Vision | [`architecture-guides/cv/`](./architecture-guides/cv/) | Classification, object detection, segmentation, tracking, video analytics |

## Framework Guides

| Domain | Guide |
|---|---|
| Web | [`frameworks/web/`](./frameworks/web/) |
| AI / Agents | [`frameworks/ai/`](./frameworks/ai/) |
| Mobile | [`frameworks/mobile/`](./frameworks/mobile/) |
| API | [`frameworks/api/`](./frameworks/api/) |
| ML | [`frameworks/ml/`](./frameworks/ml/) |
| Data | [`frameworks/data/`](./frameworks/data/) |

## Troubleshooting Coverage

| Domain | File |
|---|---|
| AI / LLM | [`troubleshooting/ai-llm.md`](./troubleshooting/ai-llm.md) |
| API | [`troubleshooting/api.md`](./troubleshooting/api.md) |
| Auth | [`troubleshooting/auth.md`](./troubleshooting/auth.md) |
| Database | [`troubleshooting/database.md`](./troubleshooting/database.md) |
| MCP | [`troubleshooting/mcp.md`](./troubleshooting/mcp.md) |
| Observability | [`troubleshooting/observability.md`](./troubleshooting/observability.md) |
| Payments | [`troubleshooting/payments.md`](./troubleshooting/payments.md) |
| Realtime | [`troubleshooting/realtime.md`](./troubleshooting/realtime.md) |
| Search / Vector | [`troubleshooting/search-vector.md`](./troubleshooting/search-vector.md) |
| Web | [`troubleshooting/web.md`](./troubleshooting/web.md) |

---

## Known Gaps (Not Yet Documented)

The following topics are expected based on the OS scope but have no document yet. **If your task requires one of these, follow the Gap Protocol above.**

| Missing Document | Status |
|---|---|
| `architecture-guides/` — top-level domain selection guide | Stub only |
| `api-references/` — external API quick-reference index | Stub only |
| `official/` — superseded by `official-docs/`; not yet merged | Legacy stub |
| `reference-repos/` — superseded by `reference-repositories/`; not yet merged | Legacy stub |
