# LangGraph — Official Documentation Index

## Official Documentation
**Primary:** https://langchain-ai.github.io/langgraph/
**Python API Reference:** https://langchain-ai.github.io/langgraph/reference/graphs/
**GitHub:** https://github.com/langchain-ai/langgraph
**Changelog:** https://github.com/langchain-ai/langgraph/releases

## Key Sections (Recommended Reading Order)
1. [Introduction / Concepts](https://langchain-ai.github.io/langgraph/concepts/) — read the mental model first: nodes, edges, state, reducers; don't skip this
2. [Quickstart](https://langchain-ai.github.io/langgraph/tutorials/introduction/) — build a minimal ReAct agent; shows the full compile → invoke cycle
3. [State Management](https://langchain-ai.github.io/langgraph/concepts/low_level/#state) — TypedDict vs. Pydantic state schemas, reducer functions (Annotated fields), state channels
4. [Checkpointers & Persistence](https://langchain-ai.github.io/langgraph/concepts/persistence/) — how to resume runs; MemorySaver vs. SqliteSaver vs. PostgresSaver; `thread_id` as the conversation key
5. [Human-in-the-Loop](https://langchain-ai.github.io/langgraph/concepts/human_in_the_loop/) — `interrupt_before`, `interrupt_after`, `Command` with `resume`; how to pause and resume a graph mid-run
6. [Multi-Agent Architectures](https://langchain-ai.github.io/langgraph/concepts/multi_agent/) — supervisor pattern, subgraph pattern, handoff via `Command(goto=...)`
7. [Streaming](https://langchain-ai.github.io/langgraph/concepts/streaming/) — stream modes: `values`, `updates`, `messages`, `events`; pick the right mode for your UI
8. [Subgraphs](https://langchain-ai.github.io/langgraph/how-tos/subgraph/) — composing graphs as nodes inside parent graphs; state key mapping between parent and child
9. [LangGraph Platform / Cloud](https://langchain-ai.github.io/langgraph/concepts/langgraph_platform/) — hosted deployment; `langgraph.json` config; cron jobs and webhooks
10. [How-To Guides](https://langchain-ai.github.io/langgraph/how-tos/) — practical recipes for branching, map-reduce, dynamic tool selection, time-travel debugging

## Important APIs / Concepts
- **`StateGraph`** — the main graph class; parameterized with a state schema; call `.compile()` to get a runnable
- **`MessagesState`** — built-in state subclass with a `messages` key using `add_messages` reducer; use as the default for chat agents
- **Reducers** — functions that merge incoming node output into existing state; defined via `Annotated[list, operator.add]` or custom functions
- **`Command`** — return from a node to both update state and control routing in a single object: `Command(update={...}, goto="node_name")`
- **`interrupt()`** — call inside a node to pause execution and surface a value to the caller; resume with `graph.invoke(Command(resume=value), config)`
- **Checkpointer** — pluggable persistence layer; must be passed at `compile()` time; required for human-in-the-loop and time-travel
- **`thread_id`** — config key that identifies a conversation thread across runs; `config={"configurable": {"thread_id": "..."}}`
- **`get_state` / `update_state`** — inspect or patch graph state externally without re-running nodes; useful for testing and manual correction

## Common Patterns
- ReAct tool-calling agent — see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md)
- Multi-agent supervisor — see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md)

## Related External Systems
- see [external-systems/langchain/README.md](../../external-systems/langchain/README.md)

## Gotchas & Version Notes
- **LangGraph ≠ LangChain:** LangGraph is a separate package (`langgraph`); it does not require `langchain` but can use it. Don't conflate the two in deps.
- **`add_messages` reducer deduplicates by `id`:** Updating a message with the same `id` replaces it rather than appending — useful for streaming token-by-token updates.
- **Compile once, invoke many times:** Call `.compile()` once at startup; it is not cheap. Pass different `thread_id` configs per conversation.
- **Subgraph state isolation:** Subgraphs have their own state namespace; only keys explicitly mapped in `input`/`output` flow between parent and child.
- **`interrupt_before` vs `interrupt()`:** `interrupt_before` is a compile-time list of node names to pause before; `interrupt()` is a runtime call inside a node for dynamic pausing. They are different mechanisms.
- **LangGraph Platform requires `langgraph-cli`:** Local dev server runs via `langgraph dev`; the `langgraph.json` manifest controls which graphs are exposed.
