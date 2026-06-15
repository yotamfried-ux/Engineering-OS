# LangGraph — Official Documentation Index

## Official Documentation
**Primary:** https://langchain-ai.github.io/langgraph/
**Python API Reference:** https://langchain-ai.github.io/langgraph/reference/graphs/
**GitHub:** https://github.com/langchain-ai/langgraph
**Changelog:** https://github.com/langchain-ai/langgraph/releases

## Key Sections (Recommended Reading Order)

1. [Concepts / High-Level Overview](https://langchain-ai.github.io/langgraph/concepts/high_level/) — Nodes, edges, state, reducers, and the state-machine mental model; read before touching any graph code
2. [Quickstart](https://langchain-ai.github.io/langgraph/tutorials/introduction/) — Build a minimal ReAct agent end-to-end; shows the full `compile → invoke` cycle in one place
3. [State & Reducers](https://langchain-ai.github.io/langgraph/concepts/low_level/#state) — `TypedDict` vs. Pydantic schemas, `Annotated` reducer fields (e.g. `add_messages`); get this wrong and nothing else works correctly
4. [Checkpointers & Persistence](https://langchain-ai.github.io/langgraph/concepts/persistence/) — `MemorySaver`, `SqliteSaver`, `PostgresSaver`; required for any multi-turn or resumable agent; `thread_id` as the conversation key
5. [Human-in-the-Loop](https://langchain-ai.github.io/langgraph/concepts/human_in_the_loop/) — `interrupt()`, `interrupt_before`, approving/rejecting tool calls, editing state mid-run; critical for production agents
6. [Streaming](https://langchain-ai.github.io/langgraph/concepts/streaming/) — `stream_mode` options (`values`, `updates`, `messages`, `events`); choose the right mode for your UI before building it
7. [Multi-Agent Architectures](https://langchain-ai.github.io/langgraph/concepts/multi_agent/) — Supervisor pattern, subgraph pattern, agent handoffs via `Command(goto=...)`
8. [Subgraphs](https://langchain-ai.github.io/langgraph/how-tos/subgraph/) — Composing graphs as nodes inside parent graphs; state key mapping between parent and child namespaces
9. [LangGraph Platform](https://langchain-ai.github.io/langgraph/concepts/langgraph_platform/) — Managed deployment, `langgraph.json` config, LangGraph Studio debugger; read when moving beyond local dev
10. [How-To Guides](https://langchain-ai.github.io/langgraph/how-tos/) — Practical recipes for branching, map-reduce, dynamic tool selection, time-travel debugging

## Important APIs / Concepts

- **`StateGraph`** — Core class, parameterised over a state schema; call `.compile(checkpointer=...)` once at startup to get a runnable graph
- **`MessagesState`** — Built-in state subclass with a `messages` key using `add_messages` reducer; the default starting point for chat agents
- **Reducers** — Functions that merge node output into existing state; defined via `Annotated[list, operator.add]` or custom callables
- **`Command`** — Return type that combines a state update with a routing decision: `Command(update={...}, goto="node_name")`; cleaner than separate edge logic
- **`interrupt()`** — Pauses graph execution inside a node and surfaces a value to the caller; resume with `graph.invoke(Command(resume=value), config)`
- **`thread_id`** — Key in `config["configurable"]` that identifies a conversation thread across runs; required for checkpointing
- **`get_state` / `update_state`** — Inspect or patch graph state externally without re-running nodes; useful for testing and manual correction
- **`Send`** — Fan-out primitive for dynamic parallel node execution; used in map-reduce patterns

## Common Patterns

- ReAct tool-calling agent — see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md)
- Multi-agent supervisor — see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md)

## Related External Systems

- see [external-systems/langchain/README.md](../../external-systems/langchain/README.md)

## Gotchas & Version Notes

- **LangGraph ≠ LangChain** — `langgraph` is a separate package; it does not require `langchain` but can use it; do not conflate the two in dependencies
- **`add_messages` deduplicates by `id`** — returning a message with the same `id` replaces the existing one rather than appending; useful for streaming token-by-token updates
- **Compile once, invoke many times** — `.compile()` is not cheap; call it once at startup and pass different `thread_id` configs per conversation
- **`interrupt()` requires a checkpointer** — calling it on a graph compiled without one raises an error at runtime, not at compile time
- **`interrupt_before` vs `interrupt()`** — `interrupt_before` is a compile-time list of node names to pause before; `interrupt()` is a runtime call inside a node for dynamic pausing; they are different mechanisms
- **Subgraph state isolation** — subgraphs have their own state namespace; only keys explicitly mapped in `input`/`output` flow between parent and child
- **LangGraph Platform requires `langgraph-cli`** — local dev server runs via `langgraph dev`; the `langgraph.json` manifest controls which graphs are exposed
- **`MessageGraph` was removed in v0.3** — migrate to `StateGraph` with `MessagesState`
