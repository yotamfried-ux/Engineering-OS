# AI Agent Template

## Overview
Use this template for LLM-powered agent systems that call tools, maintain memory, and orchestrate multi-step reasoning. Covers single-agent assistants, multi-agent pipelines, and autonomous background workers where the system must plan, act, and adapt based on LLM outputs.

## Recommended Architecture Options

| Option | Pros | Cons |
|---|---|---|
| Single agent + tool loop (ReAct) | Simple, debuggable, low latency | Limited parallelism; one model bottleneck |
| Multi-agent (orchestrator + specialists) | Parallel execution, role separation | Complex state management, harder to debug |
| Human-in-the-loop agent | Safe for high-stakes actions | Slower; requires UI for approval flows |
| Stateful agent with persistent memory | Handles long tasks across sessions | Memory retrieval adds latency and cost |

## Recommended Frameworks & Platforms

- **LLM provider:** Anthropic Claude (claude-sonnet-4-5 for reasoning, claude-haiku-3-5 for speed)
- **Agent framework:** Anthropic Agent SDK, LangGraph, or custom ReAct loop
- **Orchestration:** LangGraph (stateful graphs), CrewAI (role-based), or plain Python async
- **Tool calling:** Anthropic tool use API (native), or MCP (Model Context Protocol) servers
- **Memory:** Short-term: conversation history in context; Long-term: pgvector (PostgreSQL), Pinecone, or Qdrant
- **Vector embeddings:** Voyage AI, OpenAI embeddings, or local via sentence-transformers
- **Backend:** Python (primary), FastAPI for HTTP interface
- **Queue:** Redis + BullMQ or Celery for async agent jobs
- **Observability:** LangSmith, or custom trace logging with structured JSON

## Required Components

- Tool registry with typed input/output schemas (Zod / Pydantic)
- System prompt versioned and externalized (not hardcoded)
- Token budget management (context window tracking)
- Agent loop with configurable max-iterations / timeout
- Human-in-the-loop approval gate for destructive tool calls
- Structured output parser with fallback on parse failure
- Trace/span logging for every LLM call and tool invocation
- Cost tracking per run (input + output tokens × model price)

## Security Checklist

- [ ] Tool schemas define exact allowed parameters — no free-form shell execution unless sandboxed
- [ ] Prompt injection mitigations: user input treated as untrusted data, not instructions
- [ ] Destructive tools (delete, send email, deploy) require explicit human confirmation
- [ ] LLM API keys scoped to minimum permissions and rotated on schedule
- [ ] Agent cannot access secrets beyond what its tool definitions explicitly expose
- [ ] Max iterations and timeout enforced to prevent infinite loops and runaway costs
- [ ] All tool outputs sanitized before being fed back into the next LLM context
- [ ] PII in inputs/outputs logged only to secure, access-controlled log sinks

## Testing Checklist

- [ ] Unit tests for each tool implementation (mocked external calls)
- [ ] Agent behavior tests with recorded LLM responses (deterministic replay)
- [ ] Prompt regression tests: key scenarios produce expected tool call sequences
- [ ] Adversarial input tests: prompt injection attempts, malformed tool outputs
- [ ] Token budget test: agent handles context overflow gracefully
- [ ] Cost benchmark: typical run cost within acceptable range
- [ ] Human-in-the-loop gate tested: agent pauses and resumes correctly

## Deployment Checklist

- [ ] LLM API keys in secrets manager (never in `.env` committed to repo)
- [ ] Model name pinned to a specific version string (not `latest`)
- [ ] Agent runs isolated in a container or sandbox (no host filesystem access)
- [ ] Rate limits and concurrency caps set to control API spend
- [ ] Trace logging piped to observability platform (LangSmith, Datadog, or custom)
- [ ] Alerting on error rate, cost per run, and agent timeout frequency
- [ ] Rollback plan: previous system prompt version retrievable and deployable

## Starter Templates

| Option | Description | Recommended |
|---|---|---|
| [anthropics/anthropic-quickstarts](https://github.com/anthropics/anthropic-quickstarts) | Official Anthropic agent quickstarts (computer-use demo, customer support agent) | ✅ Best pick |
| [langchain-ai/langchain/templates](https://github.com/langchain-ai/langchain/tree/master/templates) | LangChain official templates including RAG, agents, chatbots | |
| [microsoft/autogen/samples](https://github.com/microsoft/autogen/tree/main/python/samples) | AutoGen multi-agent samples | |

**Best Pick:** [anthropics/anthropic-quickstarts](https://github.com/anthropics/anthropic-quickstarts) — official, up-to-date with latest APIs, includes production-ready computer-use and customer support agent examples

## Reference Repositories

- [anthropics/anthropic-cookbook](https://github.com/anthropics/anthropic-cookbook) — tool use, agents, MCP patterns
- [langchain-ai/langgraph](https://github.com/langchain-ai/langgraph) — stateful multi-agent graph examples
- [anthropics/model-context-protocol](https://github.com/modelcontextprotocol/servers) — official MCP server implementations

## Official Documentation

- [Anthropic API Docs](https://docs.anthropic.com) — tool use, streaming, model specs, pricing
- [Anthropic Agent Docs](https://docs.anthropic.com/en/docs/build-with-claude/tool-use) — tool use and agent patterns
- [Anthropic Agent SDK](https://github.com/anthropics/anthropic-sdk-python) — Python SDK with agent primitives
- [Model Context Protocol Docs](https://modelcontextprotocol.io/docs) — MCP spec, server/client setup
- [LangGraph Docs](https://langchain-ai.github.io/langgraph/) — stateful agents, checkpointing, human-in-the-loop
- [Voyage AI Embeddings](https://docs.voyageai.com) — embedding models for retrieval
