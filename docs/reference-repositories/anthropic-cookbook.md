# Anthropic Cookbook

## Repository

**URL:** https://github.com/anthropics/anthropic-cookbook
**Owner:** Anthropic
**Purpose:** Official collection of practical Jupyter notebook examples demonstrating how to use the Claude API effectively — covering tool use, vision, prompt caching, computer use, multi-agent coordination, MCP integration, and advanced prompting techniques.

---

## What to Learn from It

- How to define and call tools (function calling) with the Claude API and handle multi-step tool loops
- Structured output extraction using tool use as a schema-enforcement mechanism
- Prompt caching: which content types are cacheable, how to set `cache_control`, and how to read cache hit statistics from response usage
- Vision and document understanding: passing base64-encoded images and PDFs in `content` blocks
- Computer use: controlling desktop GUIs with the `computer` tool type and interpreting screenshot responses
- Multi-agent patterns: building orchestrator/subagent systems where one Claude call delegates to another
- Model Context Protocol (MCP) integration: connecting Claude to external tools and data sources via MCP servers
- Embeddings and retrieval-augmented generation using third-party vector stores alongside Claude
- Evaluation frameworks: using Claude as a judge to score outputs from another Claude call
- Token counting and cost estimation before sending large requests

---

## Recommended Sections / Examples

- `misc/how_to_use_system_prompts.ipynb` — System prompt structure, role assignment, and instruction precedence; foundational before writing any production prompt
- `tool_use/` — Full directory covering basic tool definitions, parallel tool calls, error handling, and chaining tool results; the canonical reference for the Claude tool-use loop
- `tool_use/tool_use_for_structured_outputs.ipynb` — Using tool use as a reliable schema enforcement mechanism instead of asking for JSON in the prompt
- `multimodal/reading_charts_graphs_powerpoints.ipynb` — Passing images and slide decks to Claude for visual understanding
- `multimodal/best_practices_for_vision.ipynb` — Image sizing, format tradeoffs (PNG vs. JPEG), and prompting strategies for accurate visual analysis
- `skills/pdf_upload.ipynb` — Uploading and querying PDFs using the Files API with Claude
- `misc/how_to_enable_prompt_caching.ipynb` — Step-by-step guide to `cache_control` blocks; demonstrates reading `cache_read_input_tokens` from the response to verify cache hits
- `misc/how_to_count_tokens.ipynb` — Using the token counting endpoint before sending large requests; important for cost management
- `multiagent_orchestration/` — Patterns for chaining Claude agents: sequential pipelines, parallel fan-out, and human-in-the-loop checkpoints
- `computer_use/` — Computer use reference implementation: setting up the `computer` tool, handling `tool_use` blocks with screenshot results, and the event loop structure
- `skills/` — Standalone skill demonstrations: citations, summarization, classification, code generation, and data extraction

---

## Related Patterns

- see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md)
- see [patterns/ai/README.md](../../patterns/ai/README.md)

## Related Anthropic Repositories

- [anthropics/anthropic-quickstarts](https://github.com/anthropics/anthropic-quickstarts) — full starter apps (customer support agent, computer use, financial analyst) → [reference-repositories/anthropic-quickstarts.md](./anthropic-quickstarts.md)
- [anthropics/courses](https://github.com/anthropics/courses) — structured 5-course curriculum (fundamentals → agents) → [reference-repositories/anthropic-courses.md](./anthropic-courses.md)
- [anthropics/prompt-eng-interactive-tutorial](https://github.com/anthropics/prompt-eng-interactive-tutorial) — 10-chapter interactive prompt engineering course

## Related Architectures

- see [docs/architecture-guides/ai/](../architecture-guides/ai/)
- see [docs/official-docs/anthropic.md](../official-docs/anthropic.md)
