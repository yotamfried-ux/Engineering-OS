# Architecture Guides

Domain-specific system design patterns. Each guide defines the recognized architectural options for a domain, their trade-offs, and which option to use under which conditions.

**Consult before designing any system, choosing a data flow pattern, or making a persistence or communication decision.**

---

## Gap Protocol — MANDATORY

> **If the domain you need an architecture guide for is not listed below, STOP and inform the user.**
> Do not design an architecture from general knowledge. State the gap, propose adding a guide, and wait for user direction.

---

## Available Guides

### Web Applications
[`web/`](./web/)

| Pattern | File | Use When |
|---|---|---|
| Monolith | [`web/monolith.md`](./web/monolith.md) | Single team, early stage, simple deployment |
| Modular Monolith | [`web/modular-monolith.md`](./web/modular-monolith.md) | Monolith that needs internal domain separation without service split |
| Microservices | [`web/microservices.md`](./web/microservices.md) | Multiple teams, independent scaling, bounded domains |
| Serverless | [`web/serverless.md`](./web/serverless.md) | Event-driven workloads, unpredictable traffic, low ops overhead |
| BFF (Backend for Frontend) | [`web/bff.md`](./web/bff.md) | Multiple clients (web + mobile) needing different data shapes |
| Multi-Tenant SaaS | [`web/multi-tenant-saas.md`](./web/multi-tenant-saas.md) | B2B product with tenant isolation requirements |
| Event-Driven | [`web/event-driven.md`](./web/event-driven.md) | Decoupled services that react to domain events |

### API Services
[`api/`](./api/)

| Pattern | File | Use When |
|---|---|---|
| REST | [`api/rest.md`](./api/rest.md) | Standard CRUD, broad client compatibility |
| GraphQL | [`api/graphql.md`](./api/graphql.md) | Flexible queries, multiple clients with different field needs |
| gRPC | [`api/grpc.md`](./api/grpc.md) | High-throughput service-to-service, typed contracts, streaming |
| CQRS | [`api/cqrs.md`](./api/cqrs.md) | Separate read/write models, complex query requirements |
| Event-Driven | [`api/event-driven.md`](./api/event-driven.md) | Async processing, decoupled consumers |
| Webhook-Driven | [`api/webhook-driven.md`](./api/webhook-driven.md) | Notifying external systems on state change |

### AI Agents
[`ai/`](./ai/)

| Pattern | File | Use When |
|---|---|---|
| Single Agent | [`ai/single-agent.md`](./ai/single-agent.md) | One LLM with tools, linear task execution |
| ReAct Agent | [`ai/react-agent.md`](./ai/react-agent.md) | Reason-Act loop, needs to decide which tool to call |
| RAG Agent | [`ai/rag-agent.md`](./ai/rag-agent.md) | Needs retrieval from a knowledge base before responding |
| Hybrid RAG | [`ai/hybrid-rag.md`](./ai/hybrid-rag.md) | Semantic + keyword retrieval combined |
| Planner-Executor | [`ai/planner-executor.md`](./ai/planner-executor.md) | Complex multi-step tasks with upfront planning |
| Multi-Agent | [`ai/multi-agent.md`](./ai/multi-agent.md) | Parallel specialist agents with an orchestrator |
| Workflow Agent | [`ai/workflow-agent.md`](./ai/workflow-agent.md) | Deterministic DAG with LLM steps at decision nodes |
| Memory Agent | [`ai/memory-agent.md`](./ai/memory-agent.md) | Persistent long-term memory across sessions |
| Human-in-the-Loop | [`ai/human-in-the-loop.md`](./ai/human-in-the-loop.md) | Agent pauses for human review before irreversible actions |
| Tool-Calling Agent | [`ai/tool-calling-agent.md`](./ai/tool-calling-agent.md) | LLM that calls structured tools via function calling |

### MCP (Model Context Protocol)
[`mcp/`](./mcp/)

| Pattern | File | Use When |
|---|---|---|
| Local Process | [`mcp/local-process.md`](./mcp/local-process.md) | MCP server running as a local subprocess (stdio transport) |
| Remote Server | [`mcp/remote-server.md`](./mcp/remote-server.md) | MCP server running over HTTP/SSE for multi-client access |

### Mobile Applications
[`mobile/`](./mobile/)

| Pattern | File | Use When |
|---|---|---|
| Online-First | [`mobile/online-first.md`](./mobile/online-first.md) | Always-connected app, no offline requirements |
| Offline-First | [`mobile/offline-first.md`](./mobile/offline-first.md) | Must work without network, sync when connected |
| Local-First | [`mobile/local-first.md`](./mobile/local-first.md) | Data lives on device by default, cloud is secondary |

### Machine Learning
[`ml/`](./ml/)

| Pattern | File | Use When |
|---|---|---|
| Batch Training | [`ml/batch-training.md`](./ml/batch-training.md) | Periodic retraining on accumulated data |
| Online Learning | [`ml/online-learning.md`](./ml/online-learning.md) | Model updates continuously as data arrives |
| Streaming ML | [`ml/streaming-ml.md`](./ml/streaming-ml.md) | Real-time inference on streaming data |
| Classification | [`ml/classification.md`](./ml/classification.md) | Categorical output prediction |
| Forecasting | [`ml/forecasting-systems.md`](./ml/forecasting-systems.md) | Time-series prediction |
| Recommendations | [`ml/recommendation-systems.md`](./ml/recommendation-systems.md) | Collaborative/content-based filtering |

### Computer Vision
[`cv/`](./cv/)

| Pattern | File | Use When |
|---|---|---|
| Classification | [`cv/classification.md`](./cv/classification.md) | Assign a label to an entire image |
| Object Detection | [`cv/object-detection.md`](./cv/object-detection.md) | Locate and classify objects in an image |
| Segmentation | [`cv/segmentation.md`](./cv/segmentation.md) | Pixel-level classification |
| Tracking | [`cv/tracking.md`](./cv/tracking.md) | Follow objects across video frames |
| Video Analytics | [`cv/video-analytics.md`](./cv/video-analytics.md) | Temporal patterns and event detection in video |

---

## Known Gaps

The following domains are expected but have no architecture guide yet. If your task requires one, follow the Gap Protocol above.

| Missing Guide | Status |
|---|---|
| CLI tools — argument parsing, plugin systems, distribution | Not yet added |
| Data pipelines — batch vs streaming ingestion patterns | Not yet added |
| Browser extensions — background service workers, content scripts | Not yet added |
| Desktop applications — Electron, Tauri, native | Not yet added |
