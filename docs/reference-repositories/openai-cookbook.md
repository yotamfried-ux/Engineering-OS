# OpenAI Cookbook

## Repository
**URL:** https://github.com/openai/openai-cookbook
**Owner:** OpenAI
**Purpose:** Official collection of practical examples and best-practice recipes for building
with OpenAI APIs — covering embeddings, RAG pipelines, function calling, structured outputs,
fine-tuning, and multimodal workflows.

## What to Learn from It
- How to implement semantic search using text embeddings and cosine similarity
- Retrieval-Augmented Generation (RAG) pipeline structure from chunking through answer synthesis
- Function calling patterns: defining tools, parsing model responses, and chaining calls
- Structured output extraction using response_format and JSON schema enforcement
- Fine-tuning data preparation, upload, and evaluation workflow
- Token cost management: counting tokens before requests, batching, and caching strategies
- Multimodal input handling: images in chat completions, vision prompting techniques
- Async concurrency patterns for high-throughput API usage
- Evaluation frameworks for measuring output quality across prompt variants

## Recommended Sections / Examples
- `examples/` — top-level notebooks; start here for a breadth-first orientation
- `examples/embeddings/` — embedding generation, dimensionality reduction, clustering, and search
- `examples/question_answering_using_embeddings.ipynb` — canonical RAG reference implementation
- `examples/how_to_call_functions_with_chat_models.ipynb` — function calling end-to-end
- `examples/structured_outputs_introduction.ipynb` — JSON schema enforcement with structured outputs
- `examples/fine-tuned_qa/` — fine-tuning data prep, training run, and evaluation loop
- `examples/batch_processing/` — OpenAI Batch API for async, high-volume workloads
- `examples/multimodal/` — vision-capable models: image inputs and document understanding
- `examples/how_to_count_tokens_with_tiktoken.ipynb` — token counting before sending requests
- `articles/` — longer written guides on topics like prompt caching and latency optimization

## Related Patterns
- see [patterns/ai-agents/README.md](../../patterns/ai-agents/README.md)

## Related Architectures
- see [docs/architecture-guides/](../architecture-guides/)
