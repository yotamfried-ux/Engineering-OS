# LangGraph

## Repository
**URL:** https://github.com/langchain-ai/langgraph
**Owner:** LangChain AI
**Purpose:** Graph-based framework for building stateful, multi-actor LLM applications.
The `examples/` directory shows production-grade patterns for agent orchestration,
multi-agent coordination, checkpointing, and human-in-the-loop supervision.

## What to Learn from It
- How to model agent logic as a directed graph of nodes and conditional edges
- State management across turns: defining a TypedDict schema for shared agent state
- Interruption and human-in-the-loop: pausing a graph mid-run and resuming after approval
- Checkpointing: persisting graph state to a store (SQLite, Postgres) for fault tolerance
- Multi-agent patterns: supervisor orchestrator dispatching to specialized sub-agents
- Streaming: emitting intermediate node outputs to the caller in real time
- Tool node integration: connecting LangChain tools and custom functions inside a graph
- Subgraphs: composing modular sub-agents into a parent graph with isolated state
- Retry and error handling within graph edges without restarting the full run

## Recommended Sections / Examples
- `examples/` — Jupyter notebooks grouped by pattern; best starting point
- `examples/multi_agent/` — supervisor, swarm, and hierarchical team patterns
- `examples/human_in_the_loop/` — `interrupt_before`, `interrupt_after`, approval flows
- `examples/persistence/` — SQLite and Postgres checkpointers; memory across sessions
- `examples/streaming/` — streaming tokens, node events, and update diffs to clients
- `examples/subgraphs/` — composing reusable sub-agents within a parent orchestrator
- `examples/tool_calling/` — defining and routing tool calls inside a ReAct-style node
- `examples/customer_support/` — realistic multi-turn task with state handoff
- `libs/langgraph/langgraph/graph/state.py` — core StateGraph API; study before designing state schema

## Related Patterns
- see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md)

## Related Architectures
- see [docs/architecture-guides/](../architecture-guides/)
