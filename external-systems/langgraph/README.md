# LangGraph

## Overview
LangGraph is an open-source framework by LangChain, Inc. for building stateful, multi-actor AI applications as explicit directed graphs. It models agent logic as nodes (functions or LLM calls) connected by conditional edges, giving developers fine-grained control over state, branching, looping, and human-in-the-loop workflows.

## Capabilities
- Graph-based agent architecture: nodes are Python functions, edges define control flow including conditionals
- Persistent state via checkpointers (in-memory, SQLite, Postgres, Redis) enabling pause, resume, and time-travel debugging
- Human-in-the-loop: interrupt execution at any node, await human input, then resume from the exact saved state
- Multi-agent coordination: build supervisor agents that route tasks to specialized sub-agents
- Streaming of intermediate node outputs, token-by-token LLM output, and custom events
- First-class tool calling integration with LangChain tools and any LLM that supports function calling
- LangGraph Platform (cloud) for deployment with built-in queuing, observability, and horizontal scaling
- Subgraph composition for modular, reusable agent components

## When to Use
- Need explicit, debuggable control flow in an agent (cycles, branching, multi-step loops)
- Building human-in-the-loop workflows where a human must approve or correct before the agent continues
- Implementing long-running stateful agents that must survive restarts or be paused for days
- Orchestrating multiple specialized sub-agents under a supervisor architecture

## Limitations
- Steeper learning curve than simple LLM chains — requires understanding graph construction, state schemas, and checkpointing
- LangGraph Platform (managed hosting) adds cost; self-hosting requires managing the server infrastructure
- Debugging complex graphs with many nodes requires good observability tooling (LangSmith recommended)
- Python-first; the JavaScript/TypeScript version (`@langchain/langgraph`) lags Python in features

## Integration Guide
1. Install: `pip install langgraph langchain-anthropic` (or `langchain-openai`)
2. Define a `TypedDict` or Pydantic model as the graph state schema
3. Write node functions that take state and return a partial state update dict
4. Build the graph with `StateGraph(StateSchema)`, add nodes via `.add_node()`, add edges via `.add_edge()` and `.add_conditional_edges()`
5. Compile with `.compile(checkpointer=MemorySaver())` for persistence
6. Invoke with `graph.invoke(input, config={"configurable": {"thread_id": "..."}})` — `thread_id` scopes state to a conversation
7. For streaming: use `graph.stream(input, config, stream_mode="values")` or `"updates"` or `"messages"`
8. For human-in-the-loop: add `interrupt_before=["node_name"]` to `.compile()`; resume with `graph.invoke(Command(resume=human_response), config)`

```python
from langgraph.graph import StateGraph, END
from langgraph.checkpoint.memory import MemorySaver

graph = StateGraph(MyState)
graph.add_node("agent", agent_node)
graph.add_node("tools", tool_node)
graph.add_conditional_edges("agent", should_continue, {"tools": "tools", "end": END})
graph.add_edge("tools", "agent")
graph.set_entry_point("agent")
app = graph.compile(checkpointer=MemorySaver())
```

## Setup Guide
```bash
# Core install
pip install langgraph

# With Anthropic
pip install langgraph langchain-anthropic

# With OpenAI
pip install langgraph langchain-openai

# LangGraph CLI (for LangGraph Platform)
pip install langgraph-cli
langgraph up  # starts local development server

# Postgres checkpointer for production persistence
pip install langgraph-checkpoint-postgres
```

Configuration notes:
- Set `LANGCHAIN_TRACING_V2=true` and `LANGCHAIN_API_KEY` to enable LangSmith tracing (highly recommended for debugging)
- Use `thread_id` in `config["configurable"]` to scope memory per conversation or user session
- For production, replace `MemorySaver` with `PostgresSaver` using your database connection string

## Pricing Notes
- **LangGraph (library):** Free and open-source (MIT license)
- **LangGraph Platform:** Hosted deployment service; pricing based on compute usage (check https://langchain.com/langgraph-platform for current rates)
- **LangSmith (observability):** Developer plan free up to 5K traces/month; Plus $39/month; Team pricing on request
- Self-hosting LangGraph Server is free; requires your own infrastructure

## Reference Repositories
- [langchain-ai/langgraph](https://github.com/langchain-ai/langgraph) — source + `examples/` directory with canonical patterns
- [langchain-ai/langgraph/tree/main/examples](https://github.com/langchain-ai/langgraph/tree/main/examples) — agent, RAG, multi-agent, HITL notebooks

## Official Documentation
- [LangGraph Docs](https://langchain-ai.github.io/langgraph/) — concepts, tutorials, API reference
- [Human-in-the-Loop](https://langchain-ai.github.io/langgraph/concepts/human_in_the_loop/) — interrupt and resume patterns
- [Multi-Agent Systems](https://langchain-ai.github.io/langgraph/concepts/multi_agent/) — supervisor and hierarchical architectures
- [Persistence](https://langchain-ai.github.io/langgraph/concepts/persistence/) — checkpointing and memory

## Common Pitfalls

- **Missing `END` node causes `GraphRecursionError`:** If every conditional branch in your graph loops back to a previous node without ever routing to `END`, the graph runs until it hits the `recursion_limit` (default 25) and raises `GraphRecursionError`. Every conditional edges map must have at least one branch that returns `END`; verify with `graph.get_graph().print_ascii()` before running.
- **State schema mismatch between node output and declared `TypedDict`:** Node functions must return a dict whose keys are a subset of the state schema. Returning keys that are not declared in the `TypedDict` causes silent data loss — the extra keys are dropped without an error. Define all state fields upfront and annotate them; use LangSmith traces to inspect what each node actually writes to state.
- **`interrupt_before`/`interrupt_after` without a checkpointer:** Human-in-the-loop interrupts only work when the graph is compiled with a checkpointer (e.g., `MemorySaver` or `PostgresSaver`). Without a checkpointer, the interrupt fires but state is not persisted, so calling `graph.invoke` again with `Command(resume=...)` starts a fresh run instead of resuming from the paused point. Always compile with `checkpointer=` when using interrupts.
- **Parallel branches writing to the same state key without a reducer:** When using `Send` or parallel branches that both update the same key, the last writer silently wins — earlier values are overwritten without warning. Define a reducer function (e.g., `Annotated[list[str], operator.add]`) on any state key that multiple branches may write to concurrently.
- **`recursion_limit` too low for complex multi-agent graphs:** The default `recursion_limit=25` counts every node invocation, including repeated passes through hub nodes in multi-agent architectures. Deep graphs or long tool-call chains exhaust the limit and raise `GraphRecursionError` prematurely. Increase via `graph.invoke(input, config={"recursion_limit": 100})` and tune based on your graph's actual maximum depth.

## Examples
1. **Code review agent:** Graph has nodes: `analyze_pr` → `run_linter` (tool) → `check_tests` (tool) → `write_review`; conditional edge after `analyze_pr` skips tools if the PR is too small; full audit trail in LangSmith.
2. **Human-approval workflow:** Research agent gathers data → interrupts at `human_review` node → human reads summary and types "approve" or "revise: [feedback]" → agent resumes with the feedback in state.
3. **Multi-agent pipeline:** Supervisor LLM routes incoming tasks to specialized sub-graphs (web_search_agent, code_agent, data_analysis_agent) based on task type; each sub-graph reports back to the supervisor which synthesizes the final answer.
