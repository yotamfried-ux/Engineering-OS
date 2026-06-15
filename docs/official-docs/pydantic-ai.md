# Pydantic AI — Official Documentation Index

## Official Documentation

**Primary:** https://ai.pydantic.dev
**API Reference:** https://ai.pydantic.dev/api/agent/
**GitHub:** https://github.com/pydantic/pydantic-ai
**PyPI:** https://pypi.org/project/pydantic-ai/
**Changelog:** https://github.com/pydantic/pydantic-ai/releases

---

## Key Sections (Recommended Reading Order)

1. [Introduction](https://ai.pydantic.dev/) — Overview of the library's design philosophy; clarifies the relationship between Pydantic AI, Pydantic v2, and the underlying model clients; read before writing any agent code
2. [Agents](https://ai.pydantic.dev/agents/) — Core `Agent` class: how to define an agent, set a system prompt, choose a model, and run it; the entry point for all usage
3. [Tools](https://ai.pydantic.dev/tools/) — How to define tools the agent can call; the `@agent.tool` and `@agent.tool_plain` decorators; how arguments are validated with Pydantic before the tool is called
4. [Results](https://ai.pydantic.dev/results/) — Controlling what the agent returns; `result_type` for structured outputs; accessing `RunResult` data and usage statistics
5. [Dependencies](https://ai.pydantic.dev/dependencies/) — Dependency injection pattern; how to pass database connections, HTTP clients, or configuration into tools and system prompts via `RunContext[Deps]`
6. [Models](https://ai.pydantic.dev/models/) — Supported model backends; how to configure each; switching models without changing agent logic
7. [Testing and Evals](https://ai.pydantic.dev/testing-evals/) — How to write unit tests for agents; `TestModel` for deterministic test runs; `FunctionModel` for custom test logic without API calls
8. [Streaming](https://ai.pydantic.dev/results/#streamed-results) — `agent.run_stream()` for incremental results; how to stream both text and structured outputs
9. [Multi-Agent](https://ai.pydantic.dev/multi-agent-applications/) — Patterns for orchestrating multiple agents; calling one agent from inside another agent's tool
10. [Logfire Integration](https://ai.pydantic.dev/logfire/) — Built-in observability via Pydantic Logfire; automatic tracing of agent runs, tool calls, and model requests

---

## Important APIs / Concepts

- **`Agent[Deps, ResultType]`** — The central class. Parameterized by a dependency type and a result type. Instantiated once; run many times. Thread-safe for concurrent runs.
- **`agent.run(user_prompt, deps=...)`** — Synchronous entry point. Returns `RunResult[ResultType]`. Use `agent.run_sync()` inside synchronous code.
- **`agent.run_stream(user_prompt, deps=...)`** — Async generator entry point for streaming. Returns `StreamedRunResult`; call `.stream_text()` or `.stream_structured()`.
- **`RunContext[Deps]`** — Passed as the first argument to tools and dynamic system prompts. Exposes `ctx.deps` (injected dependencies), `ctx.usage` (tokens so far), and `ctx.messages` (conversation history).
- **`@agent.tool`** — Decorator that registers a function as a callable tool. The function's type annotations define the JSON schema sent to the model. Pydantic validates arguments before the function is called — type errors are surfaced to the model for self-correction.
- **`@agent.tool_plain`** — Like `@agent.tool` but the function does not receive `RunContext`; use when the tool needs no access to deps or conversation state.
- **`@agent.system_prompt`** — Decorator to define a dynamic system prompt function. Called once per run with `RunContext`, can use deps to personalize the system message.
- **`result_type`** — Any Pydantic model or primitive. When set, the agent is instructed to return structured output and the response is validated against the schema. If validation fails, the model is asked to retry.
- **`ModelRetry`** — Exception raised from within a tool to signal the model should try again (optionally with a message explaining why). Respects `max_retries` on the agent.
- **`UsageLimits`** — Passed to `agent.run()` to cap total tokens or requests in a single run. Raises `UsageLimitExceeded` if the limit is hit.
- **Model-agnostic design** — The same agent code runs against OpenAI, Anthropic, Gemini, Groq, Ollama, and others by changing the `model=` parameter. Models are referenced by string identifier (e.g., `"openai:gpt-4o"`, `"anthropic:claude-3-5-sonnet-latest"`, `"google-gla:gemini-2.0-flash"`).

---

## Common Patterns

- Typed agent with structured output — define a Pydantic model as `result_type`; the agent returns a validated instance, never raw text
- Tool-calling agent with external APIs — use `@agent.tool` with `httpx.AsyncClient` injected via `RunContext[Deps]`; see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md)
- Dependency injection for database access — pass an async database session as the `Deps` type; tools call `ctx.deps.session.execute(...)` without global state
- Unit-testing agents without API calls — instantiate `TestModel` and assert on the messages the agent sends, not on LLM output; see [patterns/testing/README.md](../../patterns/testing/README.md)
- Streaming structured output — use `run_stream()` with `.stream_structured()` to yield partial Pydantic models as they are generated
- Multi-agent orchestration — define a "coordinator" agent whose tool calls `sub_agent.run(ctx.deps)` synchronously; the coordinator assembles sub-agent results into a final response

---

## Gotchas & Version Notes

- **Pydantic AI requires Pydantic v2** — it is not compatible with Pydantic v1. If the project mixes libraries that pin Pydantic v1, use a separate virtual environment or resolve the conflict before adopting Pydantic AI.
- **`agent.run()` is async; `agent.run_sync()` is the blocking wrapper** — calling `agent.run()` without `await` in an async context silently returns a coroutine object, not a result.
- **Tool argument names matter** — the model sees the parameter names from the function signature. Use descriptive names (`document_text` instead of `text`) because the model uses them to decide how to call the tool.
- **`result_type` validation failures trigger retries** — if the model returns output that does not match the schema, Pydantic AI sends a retry message automatically. Set `max_retries` (default 1) appropriately; each retry costs tokens.
- **`RunContext` must be the first parameter** of a tool decorated with `@agent.tool`. Placing it elsewhere raises a registration error.
- **Message history is not persisted between `run()` calls** — each call starts fresh. Pass `message_history=result.new_messages()` from a previous run to continue a conversation.
- **Streaming structured output uses the model's streaming JSON mode** — not all models support this equally well; test streaming structured output with your target model before relying on it in production.
- **`FunctionModel` in tests** — when the tool under test makes network calls, mock the network at the `httpx` transport level, not by replacing the entire tool. This keeps test fidelity high.
- **Logfire tracing is opt-in** — call `logfire.configure()` before running agents to activate tracing. Without it, no observability data is emitted. It does not affect correctness.
- **Library is pre-1.0 as of mid-2025** — APIs may change between minor versions. Pin to a specific version in production and review the changelog before upgrading.
