# Google Gemini API — Official Documentation Index

## Official Documentation

**Primary:** https://ai.google.dev/gemini-api/docs
**API Reference:** https://ai.google.dev/api
**GitHub (Cookbook):** https://github.com/google-gemini/cookbook
**GitHub (Python SDK):** https://github.com/google/generative-ai-python
**GitHub (JS/TS SDK):** https://github.com/google/generative-ai-js
**Changelog / Release Notes:** https://ai.google.dev/gemini-api/docs/changelog
**Google AI Studio (playground):** https://aistudio.google.com

---

## Key Sections (Recommended Reading Order)

1. [Quickstart](https://ai.google.dev/gemini-api/docs/quickstart) — API key setup, first request with the Python or Node SDK; confirms credentials and shows the basic request/response shape
2. [Models overview](https://ai.google.dev/gemini-api/docs/models/gemini) — Full list of available models, context window sizes, and capability matrix; read before choosing a model for a project
3. [Text generation](https://ai.google.dev/gemini-api/docs/text-generation) — `generate_content` basics; `GenerationConfig` parameters (temperature, top-p, top-k, candidate count, stop sequences, max output tokens)
4. [Multimodal inputs (Vision)](https://ai.google.dev/gemini-api/docs/vision) — Passing images, video, audio, and documents alongside text; understanding MIME types and file size limits
5. [Function calling](https://ai.google.dev/gemini-api/docs/function-calling) — Defining tools as JSON schemas, parsing `FunctionCall` responses, sending `FunctionResponse` back; the full agent loop pattern
6. [System instructions](https://ai.google.dev/gemini-api/docs/system-instructions) — How to set a persistent system prompt via `system_instruction`; how it differs from a user-turn message
7. [Structured output (JSON mode)](https://ai.google.dev/gemini-api/docs/structured-output) — Forcing the model to return valid JSON matching a schema via `response_mime_type` and `response_schema`; the reliable alternative to prompt-only JSON extraction
8. [Grounding with Google Search](https://ai.google.dev/gemini-api/docs/grounding) — Enabling real-time web search to reduce hallucinations on factual queries; understanding `grounding_metadata` and source citations in responses
9. [Files API](https://ai.google.dev/gemini-api/docs/files) — Uploading large files (video, audio, PDFs) for use across multiple requests; file lifecycle management (upload, list, delete)
10. [Streaming](https://ai.google.dev/gemini-api/docs/streaming) — `generate_content_stream` for incremental text delivery; how to accumulate chunks and detect finish reasons
11. [Long context](https://ai.google.dev/gemini-api/docs/long-context) — Working with Gemini's 1M+ token context window; strategies for document and codebase analysis
12. [Rate limits and quotas](https://ai.google.dev/gemini-api/docs/rate-limit-faq) — Free tier vs. paid tier limits, RPM/TPM caps by model, and backoff strategies for 429 errors
13. [Safety settings](https://ai.google.dev/gemini-api/docs/safety-settings) — `HarmCategory` and `HarmBlockThreshold`; how to configure safety filters and interpret `block_reason` in responses

---

## Important APIs / Concepts

- **`genai.GenerativeModel(model_name, ...)`** — Main entry point in the Python SDK. Create once per model; call `generate_content()` or `start_chat()` on the instance.
- **`generate_content(contents, generation_config=..., safety_settings=..., tools=...)`** — Core completion method. `contents` can be a string, a list of `Part` objects (text + inline data), or a list of `Content` objects (for multi-turn history).
- **`GenerationConfig`** — Controls output shape: `temperature` (creativity, 0–2), `top_p`, `top_k`, `candidate_count`, `stop_sequences`, `max_output_tokens`, `response_mime_type`, `response_schema`.
- **`response_mime_type: "application/json"` + `response_schema`** — The structured output mechanism. `response_schema` accepts a Pydantic model class or a JSON Schema dict. More reliable than instructing JSON output in the prompt.
- **`Tool(function_declarations=[...])`** — Wraps one or more `FunctionDeclaration` objects defining callable tools. Pass as `tools=[tool]` to `GenerativeModel` or `generate_content`.
- **`FunctionCall` / `FunctionResponse`** — When the model decides to call a tool, the response contains a `FunctionCall` part. After executing the tool, send a `FunctionResponse` part back in the next turn to continue the agentic loop.
- **`ChatSession` (`model.start_chat()`)**  — Manages multi-turn conversation history automatically. `send_message()` appends to the internal history and returns the next response.
- **`system_instruction`** — A string or list of `Part` objects passed at model construction time. Applied before any user message; analogous to OpenAI's `system` role.
- **Grounding (`google_search_retrieval=True`)** — Appended to the `tools` list to enable live web search. The response includes `grounding_metadata` with source URLs and supporting quotes.
- **`genai.upload_file(path, mime_type=...)` / `File` API** — Uploads a file to Google's infrastructure for use in multimodal requests. Files persist for 48 hours. Required for files exceeding the inline base64 size limit (~20 MB).
- **`candidate.finish_reason`** — Indicates why generation stopped: `STOP` (natural end), `MAX_TOKENS`, `SAFETY`, `RECITATION`, `OTHER`. Always check this before assuming a complete response.
- **`embed_content(model, content, task_type=...)`** — Generates text embeddings with `text-embedding-004`. `task_type` affects the embedding space: `RETRIEVAL_DOCUMENT`, `RETRIEVAL_QUERY`, `SEMANTIC_SIMILARITY`, etc.

---

## Model Selection Guide

| Model | Best for | Context window |
|---|---|---|
| `gemini-2.0-flash` | High-throughput production tasks; cost-sensitive workloads; real-time applications | 1M tokens |
| `gemini-2.0-flash-lite` | Fastest, cheapest; simple classification or extraction tasks with small inputs | 1M tokens |
| `gemini-2.5-pro` | Complex reasoning, coding, long-context document analysis, nuanced instruction following | 1M tokens |
| `gemini-2.5-flash` | Balanced performance / cost for most agent and RAG workloads | 1M tokens |
| `text-embedding-004` | Text embeddings for semantic search and RAG | 2048 tokens (input) |

**Decision rule:** start with `gemini-2.0-flash` for cost efficiency. Upgrade to `gemini-2.5-pro` only when output quality measurably falls short on the actual task. Check https://ai.google.dev/gemini-api/docs/models/gemini for current model IDs and deprecation dates.

---

## Common Patterns

- Multimodal document analysis — upload a PDF with the Files API and pass the `File` object alongside a text question in `generate_content`
- Structured data extraction — set `response_mime_type="application/json"` and `response_schema=MyPydanticModel` to extract typed data from unstructured text
- Function-calling agent loop — see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md); the Gemini loop is the same three-step pattern: define tools → parse `FunctionCall` → send `FunctionResponse`
- RAG with Gemini embeddings — use `text-embedding-004` to embed documents, store in a vector DB (pgvector, Pinecone), query with `RETRIEVAL_QUERY` task type; see [patterns/database/README.md](../../patterns/database/README.md)
- Long-context codebase analysis — pass an entire repo as files in a single request with `gemini-2.5-pro`; the 1M token context fits most mid-sized codebases without chunking

---

## Gotchas & Version Notes

- **Model IDs change** — Always use the versioned model ID (e.g., `gemini-2.0-flash-001`) rather than the floating alias in production to avoid silent behavior changes when Google updates the alias target.
- **`response_schema` with Pydantic** — Pass the Pydantic model *class* (not an instance) to `response_schema`. The SDK converts it to a JSON Schema automatically. Nested models and `Optional` fields are supported.
- **Safety blocks return a response, not an exception** — a blocked response has `candidates[0].finish_reason == "SAFETY"` and empty `text`. Always check `finish_reason` before accessing `.text` to avoid `AttributeError`.
- **Files API 48-hour TTL** — Uploaded files expire after 48 hours. Do not cache file URIs across sessions without re-uploading. Use `genai.get_file(name)` to check if a file still exists before referencing it.
- **Inline data size limit** — Sending base64-encoded images inline is limited to approximately 20 MB per request. Larger files must go through the Files API.
- **Grounding and structured output cannot be combined** — as of mid-2025, enabling `google_search_retrieval` and `response_mime_type="application/json"` in the same request is not supported. Use grounding for factual questions, structured output for extraction tasks — not both simultaneously.
- **`candidate_count > 1` and streaming** — Requesting multiple candidates is incompatible with streaming. Use one or the other.
- **Token counting before sending** — Use `model.count_tokens(contents)` to estimate cost before sending large requests. This makes a fast, cheap API call and returns `total_tokens`.
- **Free tier rate limits are strict** — The free tier (AI Studio API key) has low RPM limits. Upgrade to a paid Google Cloud project API key before load testing or production deployment.
- **Python SDK package name** — Install as `google-genai` (the newer unified SDK) or `google-generativeai` (the legacy SDK). The two packages have different import paths (`import google.genai` vs. `import google.generativeai`). Check which version the project already uses before installing.
