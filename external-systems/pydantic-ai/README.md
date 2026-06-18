# Pydantic AI

## Overview
Pydantic AI is a Python agent framework by the Pydantic team that brings the type-safety and validation patterns of Pydantic to LLM-powered applications. It provides a clean, Pythonic API for building agents with structured outputs, dependency injection, and tool use, with first-class support for testing and type checking.

## Capabilities
- Type-safe structured outputs using Pydantic models — validated at runtime with descriptive errors
- Dependency injection system for injecting services (DB connections, HTTP clients, config) into agent tools
- Tool registration via Python decorators (`@agent.tool`, `@agent.tool_plain`) with automatic schema generation from type hints
- Multi-model support: OpenAI, Anthropic, Google Gemini, Groq, Mistral, Ollama, and custom providers
- Streaming with structured output validation as the stream arrives
- `TestModel` and `FunctionModel` for deterministic unit testing without API calls
- `RunContext` for accessing injected dependencies and the current message history within tools
- Result validators for post-generation validation and retry logic
- Logfire integration for first-class observability

## When to Use
- Building Python agents where type safety, IDE autocompletion, and Pydantic validation patterns matter
- Need clean dependency injection for testability — avoid global state in agent tools
- Want minimal boilerplate for structured LLM outputs without a heavy framework
- Teams already using Pydantic for data models who want natural continuity into agent code

## Limitations
- Python-only — no TypeScript/JavaScript support
- Younger project (released late 2024); fewer production case studies than LangGraph or AutoGen
- Graph/workflow orchestration is not built-in — for complex multi-step graphs, combine with LangGraph or write your own loop
- Smaller community and fewer third-party integrations compared to LangChain ecosystem

## Integration Guide
1. Install: `pip install pydantic-ai`
2. Install a model provider: `pip install pydantic-ai[openai]` or `pip install pydantic-ai[anthropic]`
3. Define the output type as a Pydantic model
4. Create an agent with `Agent(model, result_type=MyModel, system_prompt="...")`
5. Register tools with `@agent.tool` — the function signature (with `RunContext` as first arg) defines the tool schema automatically
6. Define dependencies as a dataclass or Pydantic model; pass at runtime via `deps=MyDeps(...)`
7. Run synchronously with `agent.run_sync(prompt, deps=deps)` or asynchronously with `await agent.run(prompt, deps=deps)`
8. For testing: use `with agent.override(model=TestModel(...)):` to inject deterministic responses

```python
from pydantic import BaseModel
from pydantic_ai import Agent, RunContext
from dataclasses import dataclass

@dataclass
class Deps:
    db: DatabaseConn

class ExtractedData(BaseModel):
    name: str
    value: float

agent = Agent("anthropic:claude-opus-4-5", result_type=ExtractedData, deps_type=Deps)

@agent.tool
async def lookup_record(ctx: RunContext[Deps], record_id: str) -> str:
    return await ctx.deps.db.fetch(record_id)

result = agent.run_sync("Extract data from record 42", deps=Deps(db=conn))
print(result.data.name)  # type: ExtractedData
```

## Setup Guide
```bash
# Core install
pip install pydantic-ai

# With specific provider
pip install "pydantic-ai[openai]"
pip install "pydantic-ai[anthropic]"
pip install "pydantic-ai[gemini]"

# With Logfire observability
pip install "pydantic-ai[logfire]"
import logfire; logfire.configure()

# Set provider API key
export OPENAI_API_KEY=sk-...
export ANTHROPIC_API_KEY=sk-ant-...
```

Configuration notes:
- Models are specified as strings: `"openai:gpt-4o"`, `"anthropic:claude-opus-4-5"`, `"google-gla:gemini-1.5-pro"`
- `result_type=str` for plain text output; any Pydantic model for structured output
- Set `retries=3` on the agent for automatic retry when the model returns invalid structured output
- Use `model_settings=ModelSettings(temperature=0)` for deterministic outputs in testing

## Pricing Notes
- **Pydantic AI:** Free and open-source (MIT license)
- **Model costs:** Passed through directly to the underlying model provider (OpenAI, Anthropic, etc.); Pydantic AI adds no markup
- **Logfire (observability):** Free tier with 1M spans/month; paid tiers from $20/month
- No platform fees or additional charges beyond the LLM API you use

## Reference Repositories
- [pydantic/pydantic-ai](https://github.com/pydantic/pydantic-ai) — source code, examples in `examples/` directory
- [pydantic/pydantic-ai/tree/main/examples](https://github.com/pydantic/pydantic-ai/tree/main/examples) — chat app, RAG, SQL generation, code assistant examples

## Official Documentation
- [Pydantic AI Docs](https://ai.pydantic.dev/) — full API reference and guides
- [Agents](https://ai.pydantic.dev/agents/) — agent construction and configuration
- [Tools](https://ai.pydantic.dev/tools/) — tool registration and dependency injection
- [Testing](https://ai.pydantic.dev/testing-evals/) — TestModel and deterministic testing patterns

## Examples
1. **SQL query generator:** Agent with `result_type=SQLQuery` (Pydantic model with `sql: str` and `explanation: str`) → tool `get_schema(ctx)` fetches DB schema from injected connection → agent generates valid SQL validated against a regex before returning.
2. **Customer support agent:** Deps inject a CRM client → tools `lookup_customer`, `create_ticket`, `update_order` use the injected client → `TestModel` in unit tests returns scripted responses without hitting the API.
3. **Document classifier:** `result_type=Classification` with a `Literal["invoice", "contract", "email"]` field → agent reads document text → Pydantic validates the model outputs exactly one of the allowed categories, retrying if the model returns an invalid value.
