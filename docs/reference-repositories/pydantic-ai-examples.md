# Pydantic AI Examples

## Repository

**URL:** https://github.com/pydantic/pydantic-ai
**Owner:** Pydantic
**Purpose:** The main Pydantic AI repository contains an `examples/` directory with runnable, self-contained Python scripts that demonstrate the full feature surface of the library — typed agents, dependency injection, streaming, multi-agent workflows, and testing patterns. Each example is minimal enough to read in full and production-shaped enough to adapt directly.

---

## What to Learn from It

- How to define a typed `Agent` with a structured `result_type` and get back validated Pydantic model instances instead of raw text
- How to use the `@agent.tool` decorator to define tools whose arguments are automatically validated with Pydantic before the function runs
- The dependency injection pattern: how to pass database sessions, HTTP clients, or configuration through `RunContext[Deps]` into tools and system prompts without global state
- How to stream text and structured output with `agent.run_stream()` and consume results incrementally
- How to write deterministic unit tests for agents using `TestModel` and `FunctionModel` without making live API calls
- Multi-agent coordination: calling one agent from inside another agent's tool, passing the parent agent's context through
- How to switch between model providers (OpenAI, Anthropic, Gemini, Groq, Ollama) by changing the `model=` string with no other code changes
- Real-world integration patterns: SQL databases, web search, Slack bots, and RAG pipelines

---

## Recommended Sections / Examples

- `examples/pydantic_ai_examples/weather_agent.py` — Entry-level example: a weather agent with two tools (location lookup, weather fetch); shows the full `Agent` + `@agent.tool` + dependency injection pattern in ~80 lines
- `examples/pydantic_ai_examples/bank_support.py` — Customer support agent with a database dependency injected via `RunContext`; shows how tools access shared state (a DB session) cleanly without global variables
- `examples/pydantic_ai_examples/sql_gen.py` — Agent that generates and validates SQL queries; demonstrates `result_type` with a Pydantic model, retry logic via `ModelRetry`, and multi-step validation inside a tool
- `examples/pydantic_ai_examples/rag.py` — Retrieval-augmented generation example: embedding documents, storing in a vector database, and retrieving context inside a tool before answering
- `examples/pydantic_ai_examples/stream_markdown.py` — Streaming text output with `run_stream()` and `result.stream_text()`; shows how to render partial responses incrementally
- `examples/pydantic_ai_examples/stream_whales.py` — Streaming structured output: yields partial Pydantic model instances as the model generates them; demonstrates `stream_structured()` with a list result type
- `examples/pydantic_ai_examples/chat_app.py` — Multi-turn conversation with persistent message history; shows how to pass `message_history=result.new_messages()` between calls to continue a session
- `examples/pydantic_ai_examples/flight_booking.py` — Multi-agent example: an orchestrator agent calls a specialized subagent as a tool; demonstrates how to compose agents and pass dependencies through the call chain
- `examples/pydantic_ai_examples/question_graph.py` — Graph-based agent flow using `pydantic-graph`; relevant when the agent workflow has branching logic that goes beyond a simple loop
- `tests/` — Test suite for Pydantic AI itself; shows advanced usage of `TestModel` and `FunctionModel` for agent unit testing; useful as a reference for writing your own agent tests

---

## Related Patterns

- see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md)
- see [patterns/ai/README.md](../../patterns/ai/README.md)
- see [patterns/testing/README.md](../../patterns/testing/README.md)

## Related Architectures

- see [docs/architecture-guides/ai/](../architecture-guides/ai/)
- see [docs/official-docs/pydantic-ai.md](../official-docs/pydantic-ai.md)
