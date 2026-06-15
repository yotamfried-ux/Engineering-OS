# OpenAI — Official Documentation Index

## Official Documentation
**Primary:** https://platform.openai.com/docs
**API Reference:** https://platform.openai.com/docs/api-reference
**GitHub (openai-node):** https://github.com/openai/openai-node
**GitHub (openai-python):** https://github.com/openai/openai-python
**Changelog:** https://platform.openai.com/docs/changelog

## Key Sections (Recommended Reading Order)
1. [Quickstart](https://platform.openai.com/docs/quickstart) — start here to understand request/response shape before diving into specifics
2. [Chat Completions](https://platform.openai.com/docs/guides/chat-completions) — core API: messages array, roles, temperature, max_tokens
3. [Function Calling / Tools](https://platform.openai.com/docs/guides/function-calling) — how to define tools, handle tool_calls in the response, and loop back results
4. [Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs) — JSON mode vs. response_format with json_schema; prefer json_schema for guaranteed shape
5. [Streaming](https://platform.openai.com/docs/guides/streaming) — SSE chunks, delta fields, how to accumulate tool call arguments incrementally
6. [Embeddings](https://platform.openai.com/docs/guides/embeddings) — text-embedding-3 models, dimensions param, cosine similarity conventions
7. [Vision](https://platform.openai.com/docs/guides/vision) — image_url and base64 in the messages content array; detail param (low/high/auto)
8. [Assistants API](https://platform.openai.com/docs/assistants/overview) — threads, runs, file search, code interpreter; understand the polling/event model before using
9. [Batch API](https://platform.openai.com/docs/guides/batch) — async bulk completions at 50% cost; useful for offline evaluation pipelines
10. [Rate Limits & Error Handling](https://platform.openai.com/docs/guides/rate-limits) — tier limits, 429 backoff strategy, error codes

## Important APIs / Concepts
- **`response_format`** — set to `{ type: "json_schema", json_schema: {...} }` for strict structured output; never rely on prompt-only JSON enforcement
- **`tool_choice`** — force a specific tool call with `{ type: "function", function: { name: "..." } }` or set `"required"` to always call a tool
- **`parallel_tool_calls`** — default true; model may call multiple tools in one turn; your loop must handle an array of tool_calls
- **`seed`** — near-deterministic outputs for testing; combine with `system_fingerprint` tracking
- **`logprobs`** — token-level log probabilities; useful for calibration and classification confidence
- **Moderation API** — https://platform.openai.com/docs/guides/moderation — free endpoint to screen content before/after generation
- **`stream: true` with `usage`** — pass `stream_options: { include_usage: true }` to get token counts in streaming mode

## Common Patterns
- Function calling agent loop — see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md)
- Embedding + vector search — see [patterns/database/README.md](../../patterns/database/README.md)

## Related External Systems
- see [external-systems/openai/README.md](../../external-systems/openai/README.md)

## Gotchas & Version Notes
- **Model naming:** `gpt-4o` is the recommended default; `gpt-4-turbo` is older. Check https://platform.openai.com/docs/models for the current list — names change frequently.
- **Assistants v2 vs v1:** The Assistants API v2 (April 2024) changed file handling — use `tool_resources` not `file_ids` on the assistant object.
- **Structured Outputs vs JSON mode:** JSON mode (`response_format: { type: "json_object" }`) does not validate schema; only `json_schema` with `strict: true` guarantees shape.
- **Tool call accumulation in streaming:** Each chunk carries a `delta.tool_calls[i]` with `index`; you must accumulate `arguments` strings across chunks before parsing JSON.
- **Max context vs max output:** `max_tokens` controls output length only, not the total context window. Exceeding the model's context window throws a 400 error.
- **Organization vs project API keys:** Project-scoped keys (sk-proj-…) are preferred for production; they respect project-level rate limits and usage policies.
