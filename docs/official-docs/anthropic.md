# Anthropic (Claude API) — Official Documentation Index

## Official Documentation
**Primary:** https://docs.anthropic.com
**API Reference:** https://docs.anthropic.com/en/api
**GitHub (anthropic-sdk-python):** https://github.com/anthropic/anthropic-sdk-python
**GitHub (anthropic-sdk-typescript):** https://github.com/anthropic/anthropic-sdk-typescript
**Changelog:** https://docs.anthropic.com/en/release-notes/api

## Key Sections (Recommended Reading Order)
1. [Getting Started](https://docs.anthropic.com/en/docs/get-started) — API key setup, first request, SDK install; read before anything else
2. [Messages API](https://docs.anthropic.com/en/api/messages) — core endpoint: system, messages array, roles, content blocks; understand content block types (text, image, tool_use, tool_result)
3. [Tool Use (Function Calling)](https://docs.anthropic.com/en/docs/build-with-claude/tool-use) — tool definitions, tool_use content blocks, tool_result replies, multi-turn tool loops
4. [Prompt Caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching) — `cache_control: { type: "ephemeral" }` on content blocks; read before building any high-frequency or long-context workflow
5. [Streaming](https://docs.anthropic.com/en/docs/build-with-claude/streaming) — SSE event types (content_block_delta, message_delta, input_json_delta for tools); how to reconstruct tool call arguments
6. [Vision](https://docs.anthropic.com/en/docs/build-with-claude/vision) — image source types: base64 and URL; supported formats and size limits
7. [Model Context Protocol (MCP)](https://docs.anthropic.com/en/docs/mcp) — how Claude connects to external tools via MCP servers; server and client architecture
8. [Extended Thinking](https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking) — `thinking` content blocks; budget_tokens; when reasoning traces are visible vs. hidden
9. [Token Counting](https://docs.anthropic.com/en/docs/build-with-claude/count-tokens) — count tokens before sending to avoid context overflows in agentic loops
10. [Rate Limits & Errors](https://docs.anthropic.com/en/api/errors) — error types, 429 handling, per-model tier limits

## Important APIs / Concepts
- **Content blocks** — responses are arrays of typed blocks (`text`, `tool_use`, `thinking`); never assume a single text string
- **`tool_choice`** — `{ type: "auto" | "any" | "tool", name?: "..." }`; `"any"` forces at least one tool call
- **`cache_control`** — attach to the last message in a long static prefix (system prompt, docs, examples) to cache it; reduces latency and cost on repeated calls
- **`betas` header** — some features (e.g., extended output lengths, interleaved thinking) require opt-in via `anthropic-beta` request header
- **`max_tokens`** — required field (no default); set explicitly on every request
- **`stop_sequences`** — array of strings; generation halts at first match; useful for structured agent loops
- **Input/output token tracking** — `usage` object on every response; monitor for prompt caching hit rates via `cache_read_input_tokens`

## Common Patterns
- Tool-calling agent loop — see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md)
- Prompt caching with long system prompts — see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md)

## Related External Systems
- see [external-systems/anthropic/README.md](../../external-systems/anthropic/README.md)

## Gotchas & Version Notes
- **Model IDs change:** Always check https://docs.anthropic.com/en/docs/about-claude/models for the current recommended model ID; hardcoded IDs go stale.
- **No streaming + prompt caching together on all models:** Verify compatibility in the caching docs before combining both features.
- **Tool result content** — `tool_result` content must be a string or an array of content blocks; it is NOT a bare JSON object.
- **System prompt is a top-level field** — not a message with `role: "system"` (unlike OpenAI); passing it as a message will cause a validation error.
- **`stop_reason: "tool_use"`** — when the model calls a tool the stop reason is `tool_use`, not `end_turn`; your agent loop must branch on this.
- **Extended output (128k tokens)** — requires `anthropic-beta: output-128k-2025-02-19` header and is only available on select models.
