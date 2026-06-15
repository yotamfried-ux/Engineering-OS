# OpenAI

## Overview
OpenAI provides state-of-the-art large language models (GPT-4o, o1, o3), image generation (DALL-E 3), speech-to-text (Whisper), text-to-speech, and embeddings via a REST API. It is the most widely adopted LLM API, with extensive ecosystem tooling and the largest prompt engineering knowledge base.

## Capabilities
- Chat completions with GPT-4o, GPT-4o-mini, o1, o1-mini, o3-mini across text, vision, and audio modalities
- Tool/function calling for structured output and agentic workflows
- Structured outputs with JSON Schema enforcement (guaranteed valid JSON matching your schema)
- Assistants API with persistent threads, file search, code interpreter, and tool use
- Embeddings (text-embedding-3-small, text-embedding-3-large) for semantic search and RAG
- Image generation and editing with DALL-E 3
- Speech-to-text (Whisper) and text-to-speech (TTS) with multiple voices
- Fine-tuning for GPT-4o-mini and GPT-3.5-turbo on custom datasets
- Batch API for async bulk inference at 50% cost reduction

## When to Use
- Need the broadest ecosystem compatibility (LangChain, LlamaIndex, Vercel AI SDK, etc. default to OpenAI)
- Building production agentic systems with tool calling and structured outputs
- Require multimodal capabilities (text + vision + audio) in a single API
- Need fine-tuning on domain-specific data to improve accuracy on narrow tasks

## Limitations
- GPT-4o and o1/o3 models are expensive at scale compared to alternatives; monitor token usage carefully
- Context windows top out at 128K tokens (GPT-4o); very long contexts increase latency and cost
- No persistent memory across API calls — application must manage conversation history
- Rate limits (RPM/TPM) require retry logic with exponential backoff, especially on Tier 1 accounts
- Structured Outputs JSON Schema support has constraints (no `additionalProperties: true`, limited `anyOf` patterns)

## Integration Guide
1. Install: `npm install openai` or `pip install openai`
2. Authenticate via `OPENAI_API_KEY` environment variable — never hardcode
3. Basic chat completion:
   ```python
   from openai import OpenAI
   client = OpenAI()
   response = client.chat.completions.create(
       model="gpt-4o",
       messages=[{"role": "user", "content": "Hello"}]
   )
   ```
4. For structured output: use `response_format={"type": "json_schema", "json_schema": {...}}` or the `parse()` method with Pydantic models (Python SDK v1.30+)
5. Tool calling: define tools as JSON Schema in the `tools` parameter; inspect `tool_calls` in the response; call the function; append result as a `tool` role message; re-call the API
6. For streaming: use `stream=True` and iterate over `response` chunks
7. Always implement retry with exponential backoff for `RateLimitError` and `APIConnectionError`

## Setup Guide
```bash
# Python
pip install openai

# Node.js
npm install openai

# Set API key (never commit this)
export OPENAI_API_KEY=sk-...

# Verify connectivity
python -c "from openai import OpenAI; print(OpenAI().models.list().data[0].id)"
```

Key configuration:
- Use `OPENAI_BASE_URL` to point to Azure OpenAI or compatible proxies
- Set `max_tokens` / `max_completion_tokens` to prevent runaway costs
- Use `seed` parameter for deterministic outputs in testing
- Enable `logprobs` for confidence scoring on classification tasks

## Pricing Notes
- **GPT-4o:** $2.50/1M input tokens, $10/1M output tokens (as of mid-2025; check https://openai.com/pricing for current)
- **GPT-4o-mini:** $0.15/1M input, $0.60/1M output — best cost/quality for high-volume tasks
- **o1:** $15/1M input, $60/1M output (reasoning tokens billed separately)
- **text-embedding-3-small:** $0.02/1M tokens
- **Batch API:** 50% discount on all models for async requests with 24h turnaround
- Watch for: prompt caching (automatic for repeated prefixes ≥1024 tokens, 50% discount), context caching with Assistants API

## Reference Repositories
- [openai/openai-cookbook](https://github.com/openai/openai-cookbook) — canonical examples for every API feature
- [openai/openai-python](https://github.com/openai/openai-python) — official Python SDK with typed interfaces
- [openai/openai-node](https://github.com/openai/openai-node) — official Node.js/TypeScript SDK

## Official Documentation
- [OpenAI Platform Docs](https://platform.openai.com/docs) — complete API reference
- [Chat Completions](https://platform.openai.com/docs/guides/chat-completions) — core API guide
- [Function Calling](https://platform.openai.com/docs/guides/function-calling) — tool use patterns
- [Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs) — guaranteed JSON Schema compliance

## Examples
1. **RAG pipeline:** Chunk documents → embed with `text-embedding-3-small` → store in pgvector → at query time, embed the question, retrieve top-K chunks, include in GPT-4o context → stream the answer.
2. **Structured data extraction:** Use Structured Outputs with a Pydantic model to extract invoice fields (vendor, amount, date, line items) from scanned PDF text with guaranteed schema compliance.
3. **Agentic task loop:** Define tools for web search, code execution, and file write → GPT-4o iteratively calls tools → application executes them → feeds results back until the model returns a final answer with no tool calls.
