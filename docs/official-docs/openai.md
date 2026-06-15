# OpenAI — Official Documentation Index

## Official Documentation
**Primary:** https://platform.openai.com/docs
**API Reference:** https://platform.openai.com/docs/api-reference
**GitHub (openai-python):** https://github.com/openai/openai-python
**GitHub (openai-node):** https://github.com/openai/openai-node
**Changelog:** https://platform.openai.com/docs/changelog

## Key Sections (Recommended Reading Order)

1. [Quickstart](https://platform.openai.com/docs/quickstart) — Hello World with the API; confirms your key works and teaches the request/response shape before diving into specifics
2. [Chat Completions](https://platform.openai.com/docs/guides/chat-completions) — Core endpoint; read the `messages` array structure, role semantics, and `stop_reason` before writing any prompt logic
3. [Function Calling / Tools](https://platform.openai.com/docs/guides/function-calling) — How to define tools, parse `tool_calls` in responses, and return results; the full agent loop pattern lives here
4. [Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs) — JSON Schema enforcement via `response_format`; always prefer `json_schema` with `strict: true` over prompt-only JSON enforcement
5. [Streaming](https://platform.openai.com/docs/guides/streaming) — Server-Sent Events for incremental responses; how to accumulate `tool_calls` argument deltas across chunks
6. [Embeddings](https://platform.openai.com/docs/guides/embeddings) — `text-embedding-3-*` models, `dimensions` param, cosine similarity conventions
7. [Vision (Image Inputs)](https://platform.openai.com/docs/guides/vision) — Passing `image_url` or base64 in message content; `detail` param (low/high/auto) controls token cost
8. [Assistants API](https://platform.openai.com/docs/assistants/overview) — Persistent threads, file search, code interpreter; understand the run/polling model before using — heavier than Chat Completions
9. [Batch API](https://platform.openai.com/docs/guides/batch) — Async bulk completions at 50 % cost reduction; useful for offline eval pipelines
10. [Rate Limits & Error Codes](https://platform.openai.com/docs/guides/rate-limits) — Tier-based TPM/RPM caps, 429 backoff strategy, error codes

## Important APIs / Concepts

- **`response_format: { type: "json_schema" }`** — Strict mode that enforces a JSON Schema; eliminates unparseable responses; set `strict: true` inside the schema definition
- **`tool_choice`** — Force a specific tool with `{ type: "function", function: { name: "..." } }` or `"required"` to guarantee a tool call
- **`parallel_tool_calls`** — Default `true`; model may emit multiple tool calls in one turn; your executor must handle an array of `tool_calls`
- **`seed` + `system_fingerprint`** — Near-deterministic outputs for testing; track `system_fingerprint` to detect silent model changes
- **`logprobs`** — Token-level log probabilities; useful for classification confidence and calibration
- **`stream_options: { include_usage: true }`** — Required to get token counts in streaming mode; not included by default
- **`max_completion_tokens`** — Replaces the deprecated `max_tokens` for o-series models; controls output length only, not total context

## Common Patterns

- Function-calling agent loop — see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md)
- Embedding + vector search — see [patterns/database/README.md](../../patterns/database/README.md)

## Related External Systems

- see [external-systems/openai/README.md](../../external-systems/openai/README.md)

## Gotchas & Version Notes

- **Model IDs are aliases that roll forward** — pin to a dated snapshot (e.g. `gpt-4o-2024-08-06`) in production; always check https://platform.openai.com/docs/models for the current list
- **`max_tokens` is deprecated for o-series models** — use `max_completion_tokens` instead; mixing them silently uses the wrong field
- **Structured Outputs require `strict: true`** inside the tool or `response_format` definition — omitting it falls back to best-effort JSON mode
- **Tool call accumulation in streaming** — deltas arrive in `tool_calls[i].function.arguments` fragments; accumulate across chunks before parsing JSON
- **Assistants v2 vs v1** — file handling changed completely in v2 (April 2024); use `tool_resources` not `file_ids` on the assistant object
- **Organization vs project API keys** — project-scoped keys (`sk-proj-…`) are preferred for production; they respect project-level limits
- **Context window ≠ output limit** — `max_completion_tokens` controls output only; exceeding the model's context window throws a 400 error
