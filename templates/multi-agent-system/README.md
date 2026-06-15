# Multi-Agent System Template

## Overview
Use this template for systems where multiple specialized AI agents collaborate to complete complex, multi-step tasks that exceed a single model's context or capabilities. Suited for autonomous research pipelines, code generation suites, customer support escalation trees, and workflow automation where different agents own distinct domains (planning, retrieval, execution, validation). The central challenges are orchestration correctness, shared state consistency, and making the system observable and safe to operate.

## Recommended Architecture Options
- **Hierarchical orchestrator + worker agents** — A planner/orchestrator decomposes the task and dispatches subtasks to specialized workers; workers return results; orchestrator synthesizes; most common and debuggable pattern.
- **Graph-based workflow (LangGraph / Prefect)** — Explicit state machine with typed nodes and edges; rollback and branching are first-class; best when the workflow is well-defined and needs deterministic control flow.
- **Swarm / peer-to-peer agents** — Agents self-select tasks from a shared queue; highly parallel; harder to trace; suited for embarrassingly parallel workloads (e.g., batch document processing).

## Recommended Frameworks & Platforms
| Layer | Options |
|---|---|
| Orchestration | LangGraph, AutoGen (Microsoft), CrewAI, custom orchestrator |
| LLM provider | Anthropic Claude (claude-sonnet-4-5 / claude-opus-4), OpenAI GPT-4o, Gemini 1.5 Pro |
| Tool / function calling | Claude tool use, OpenAI function calling, LangChain tools |
| Agent memory | Short-term: conversation history; Long-term: pgvector, Mem0, Zep |
| Shared state | Redis (ephemeral), PostgreSQL (persistent), LangGraph State |
| Observability | LangSmith, LangFuse, Arize Phoenix, OpenTelemetry |
| Task queue | BullMQ, Celery, Temporal (for durable long-running agents) |
| Human-in-the-loop | LangGraph interrupt nodes, Temporal signals, custom approval endpoint |
| Backend API | FastAPI, Node.js Fastify |

## Required Components
- Orchestrator agent: receives high-level goal; breaks into subtasks; assigns to specialist agents; aggregates results; handles retries on agent failure
- Specialist agents (examples): researcher (RAG/web search), coder (code generation + execution), validator (test runner, fact-checker), writer (final output synthesis)
- Agent communication protocol: typed message schema between agents (task request, result, error); versioned to allow independent agent upgrades
- Shared state store: agents read/write typed state object; optimistic locking prevents concurrent overwrites; full history retained for replay
- Tool registry: centralized list of available tools (web search, code interpreter, file I/O, DB query); each agent declares which tools it may use; tools sandboxed
- Human escalation node: agent pauses and emits a structured approval request when confidence is below threshold or action is irreversible; resumes on human approval or rejection
- Execution sandbox: code execution agent runs in an isolated container (e2b.dev, Docker) with no network or filesystem access outside designated paths
- Observability: every agent invocation logged with input, output, model used, token count, latency, tool calls; trace ID propagated across all agents
- Budget guard: total token spend and wall-clock time tracked per task; task cancelled and user notified if budget exceeded
- Replay and audit: full trace stored; can re-run any subtask with same inputs for debugging

## Security Checklist
- [ ] Each agent has the minimum set of tools declared; no agent has write access to tools not in its declared scope
- [ ] Code execution sandbox: no network access; filesystem access limited to `/tmp`; CPU and memory limits enforced
- [ ] Human escalation is mandatory before any irreversible action (send email, modify DB record, charge payment)
- [ ] Prompt injection defense: user-supplied content always wrapped in `<user_input>` delimiters and mentioned as untrusted in system prompt
- [ ] Agent-to-agent messages validated against schema; free-form agent output not trusted as executable instruction without validation
- [ ] LLM API keys scoped per agent in secret manager; logs never contain key values
- [ ] Rate limits on orchestrator endpoint; one active task per user to prevent runaway cost
- [ ] Budget cap enforced server-side; client cannot increase it without a privileged role

## Testing Checklist
- [ ] Unit test each agent in isolation: mock LLM and tool calls; assert correct tool selection for given input
- [ ] Integration test: orchestrator decomposes a known task; correct specialist agents invoked in correct order
- [ ] Human escalation: agent reaches low-confidence branch; confirm escalation event emitted; task resumes correctly after approval
- [ ] Budget exceeded: task with forced high token usage hits cap; cancelled cleanly; partial results returned with status "cancelled"
- [ ] Replay: re-run a stored trace with same inputs; output is deterministic (temperature=0 in tests)
- [ ] Sandbox escape test: code execution agent instructed to read `/etc/passwd`; confirm blocked
- [ ] Observability: every trace appears in LangSmith/LangFuse; no orphaned spans

## Deployment Checklist
- [ ] Each agent type deployed as an independent service or worker (separate scaling, separate crash domain)
- [ ] Temporal or BullMQ workers have idempotent task handlers; safe to retry on worker crash
- [ ] LLM model version pinned per agent; upgrade one agent at a time with A/B comparison
- [ ] Observability pipeline connected before go-live; verify traces appear end-to-end
- [ ] Cost alert: daily LLM spend > budget threshold triggers PagerDuty / Slack alert
- [ ] Sandbox container images rebuilt weekly for security patches; CVE scan in CI
- [ ] Runbook: how to pause the orchestrator, drain active tasks, roll back an agent version
- [ ] Load test: 10 concurrent tasks; verify no shared state corruption; trace all tasks independently

## Reference Repositories
- [langchain-ai/langgraph](https://github.com/langchain-ai/langgraph) — Graph-based agent orchestration with typed state, interrupt nodes, and streaming
- [microsoft/autogen](https://github.com/microsoft/autogen) — Multi-agent conversation framework with human-in-the-loop support
- [crewAIInc/crewAI](https://github.com/crewAIInc/crewAI) — Role-based multi-agent framework with task delegation and tool sharing

## Official Documentation
- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/) — State graphs, interrupt/resume, persistence, streaming
- [Anthropic Tool Use Guide](https://docs.anthropic.com/en/docs/build-with-claude/tool-use) — Structured tool calling, parallel tool use, tool result handling
- [e2b.dev Sandbox Docs](https://e2b.dev/docs) — Secure code execution sandbox for AI agents
- [LangSmith Tracing](https://docs.smith.langchain.com/) — Agent observability, trace inspection, dataset creation for evaluation
- [Temporal Documentation](https://docs.temporal.io/) — Durable workflows for long-running, fault-tolerant agent tasks
