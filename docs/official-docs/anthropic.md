# Anthropic (Claude API) — Official Documentation Index

## Official Documentation
**Primary:** https://docs.anthropic.com
**API Reference:** https://docs.anthropic.com/en/api
**GitHub (anthropic-sdk-python):** https://github.com/anthropic-ai/anthropic-sdk-python
**GitHub (anthropic-sdk-typescript):** https://github.com/anthropic-ai/anthropic-sdk-typescript
**Changelog:** https://docs.anthropic.com/en/release-notes/api

## Key Sections (Recommended Reading Order)

1. [Get Started](https://docs.anthropic.com/en/docs/get-started) — API key setup, first request, SDK install; run this before writing any production code
2. [Models Overview](https://docs.anthropic.com/en/docs/about-claude/models/overview) — Current model IDs, context windows, and capability tiers; always verify IDs here — hardcoded names go stale
3. [Messages API](https://docs.anthropic.com/en/api/messages) — Core `POST /v1/messages`; understand `role`, content block types (`text`, `image`, `tool_use`, `tool_result`), and `stop_reason`
4. [Tool Use](https://docs.anthropic.com/en/docs/build-with-claude/tool-use) — Tool definitions, `tool_use` content blocks, `tool_result` replies, multi-turn loops; the full agentic pattern lives here
5. [Prompt Caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching) — `cache_control: { type: "ephemeral" }` breakpoints; reduces repeated long-context costs by up to 90 %; read before any high-frequency workflow
6. [Streaming](https://docs.anthropic.com/en/docs/build-with-claude/streaming) — SSE event types (`content_block_delta`, `message_delta`, `input_json_delta` for tools); how to reconstruct tool call arguments
7. [Vision (Image Input)](https://docs.anthropic.com/en/docs/build-with-claude/vision) — `image` content blocks (base64 or URL); supported formats, size limits, and resolution pricing
8. [Extended Thinking](https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking) — `thinking` content blocks; `budget_tokens` controls reasoning depth; when traces are visible vs. hidden
9. [Model Context Protocol (MCP)](https://docs.anthropic.com/en/docs/build-with-claude/mcp) — How Claude connects to external tools via MCP servers; read before `core/mcp-servers.md`
10. [Batch API](https://docs.anthropic.com/en/docs/build-with-claude/batch-processing) — Async batch requests processed within 24h at 50% cost reduction; use for evaluation runs, bulk classification, nightly jobs
11. [Files API](https://docs.anthropic.com/en/docs/build-with-claude/files) — Upload a PDF or file once, get back a `file_id`, reference it across multiple requests without re-uploading; 30-day TTL
12. [Embeddings (Voyage AI)](https://docs.anthropic.com/en/docs/build-with-claude/embeddings) — Anthropic's recommended embedding provider (Voyage AI); model IDs, dimension sizes, and RAG integration patterns
13. [Text Editor Tool](https://docs.anthropic.com/en/docs/build-with-claude/tool-use/text-editor-tool) — Built-in tool (`text_editor_20250124`) for reading and editing files; use in agentic coding workflows instead of building a custom file tool
14. [Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code) — Complete reference for Claude Code CLI: hooks, MCP server configuration, slash commands, settings, IDE integrations
15. [Rate Limits & Errors](https://docs.anthropic.com/en/api/errors) — Error types, 429 handling, `overloaded_error`, per-model tier limits

## Important APIs / Concepts

- **Content block array** — Responses are typed block arrays (`text`, `tool_use`, `thinking`); never assume a single text string
- **`stop_reason: "tool_use"`** — When the model wants to call a tool; your agent loop must branch on this until `"end_turn"`
- **`tool_choice`** — `{ type: "auto" | "any" | "tool", name?: "..." }`; `"any"` forces at least one tool call
- **`cache_control`** — Attach to the last content block in a long static prefix (system prompt, docs, examples) to cache everything above it
- **`betas` header (`anthropic-beta`)** — Gates preview features (e.g. extended output, interleaved thinking); check per-feature docs for the required value
- **`max_tokens`** — Required field with no default; set explicitly on every request
- **`cache_read_input_tokens`** — Field in `usage` response object; monitor this to verify caching is actually hitting

## Official Learning Resources

| Resource | Format | What You Learn |
|---|---|---|
| [anthropics/courses](https://github.com/anthropics/courses) | Jupyter notebooks (5 courses) | API fundamentals → prompt engineering → tool use → multi-agent → real-world prompting |
| [anthropics/prompt-eng-interactive-tutorial](https://github.com/anthropics/prompt-eng-interactive-tutorial) | 10-chapter interactive notebooks | Basic prompts → CoT → few-shot → role prompting → avoiding hallucinations → tool prompting |
| [anthropics/anthropic-cookbook](https://github.com/anthropics/anthropic-cookbook) | Jupyter notebooks | Tool use, vision, caching, computer use, multi-agent, evaluation, MCP |
| [anthropics/anthropic-quickstarts](https://github.com/anthropics/anthropic-quickstarts) | Full starter apps | Customer support agent, computer use demo, financial data analyst |
| [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) | Engineering blog post | When to use agents vs. simple prompts, orchestration patterns, safety |

## Common Patterns

- Tool-calling agent loop — see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md)
- Prompt caching for long system prompts — see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md)

## Related External Systems

- see [external-systems/anthropic/README.md](../../external-systems/anthropic/README.md)

## Gotchas & Version Notes

- **`system` is a top-level field, not a message role** — sending it as `{"role": "system", ...}` inside `messages` causes a validation error (unlike OpenAI)
- **Model IDs roll forward** — pin to a dated snapshot (e.g. `claude-opus-4-5-20251101`) in production; the alias `claude-opus-4-5` moves to newer versions
- **Tool results must go in the next user turn** — all `tool_result` blocks for a parallel call go in a single `user` message; you cannot spread them across turns
- **Prompt caching minimum block length** — blocks under ~2048 tokens are not eligible; shorter blocks are silently not cached
- **`thinking` blocks cannot be passed back as input** — strip them when constructing the next turn's messages array
- **Vision URLs must be publicly accessible** — private URLs are not fetched by Anthropic servers; use base64 for private assets
- **Extended output (128k tokens) requires a beta header** — `anthropic-beta: output-128k-2025-02-19`; only available on select models
