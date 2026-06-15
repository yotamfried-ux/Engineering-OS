# RAG System Template

## Overview
Use this template for Retrieval-Augmented Generation systems that answer questions over a private document corpus. Suited for enterprise knowledge bases, customer support bots, legal/compliance assistants, and developer documentation search. The quality of answers depends heavily on chunking strategy, embedding model choice, retrieval precision, and how well the LLM is instructed to cite and stay grounded in retrieved content.

## Recommended Architecture Options
- **Naive RAG (embed → index → retrieve → generate)** — Fastest to ship; sufficient for small corpora (< 10 K chunks) with clear, well-structured documents; quality degrades on ambiguous queries.
- **Advanced RAG with reranking** — Adds a cross-encoder reranker after initial retrieval to re-score top-N candidates; significantly improves precision; adds ~100–300 ms latency.
- **Agentic RAG (tool-calling retrieval loop)** — LLM decides when and what to retrieve; handles multi-step reasoning; highest quality and latency; use when queries require combining information from multiple documents.

## Recommended Frameworks & Platforms
| Layer | Options |
|---|---|
| Orchestration | LangChain, LlamaIndex, custom pipeline |
| Embedding model | text-embedding-3-small / text-embedding-3-large (OpenAI), Cohere embed-v3, BAAI/bge-m3 (open) |
| Vector store | pgvector (PostgreSQL), Pinecone, Qdrant, Weaviate, Chroma |
| Reranker | Cohere Rerank, cross-encoder/ms-marco (HuggingFace), Jina Reranker |
| LLM | Claude 3.5 Sonnet, GPT-4o, Gemini 1.5 Pro |
| Document parsing | Unstructured.io, LlamaParse, PyMuPDF, Docling |
| Chunking | LangChain RecursiveCharacterTextSplitter, semantic chunker, markdown-aware splitter |
| Storage (raw docs) | AWS S3, Cloudflare R2, PostgreSQL (bytea) |
| API layer | FastAPI, Node.js Fastify |
| Evaluation | RAGAS, TruLens, custom golden dataset |

## Required Components
- Document ingestion pipeline:
  1. Extract text from source (PDF, DOCX, HTML, Markdown, Confluence, Notion)
  2. Clean and normalize (remove headers/footers, fix encoding)
  3. Chunk with overlap; preserve document metadata (source URL, title, section, page number)
  4. Embed each chunk; upsert into vector store with metadata
- Incremental ingestion: detect changed/deleted documents; update or remove affected chunks
- Query pipeline:
  1. Embed user query with same model used for indexing
  2. Vector similarity search (top-K, typically K=10–20)
  3. (Optional) Rerank top-K; take top-N (typically N=3–5) for context
  4. Construct prompt: system instruction + retrieved chunks with citations + user query
  5. LLM generates answer with inline citations `[doc_title, page N]`
- Citation enforcement: system prompt instructs LLM to cite every factual claim; answer includes source links
- Confidence signal: if no retrieved chunk has similarity above a threshold, respond "I don't have information on this" rather than hallucinating
- Metadata filtering: filter by document type, date range, department, or access group before vector search
- Feedback loop: thumbs up/down per answer stored for evaluation and fine-tuning signal
- Admin ingestion UI: upload document, trigger re-index, view ingestion status and chunk count per doc

## Security Checklist
- [ ] Document access control: user's role/group checked before including a chunk in context; vector store query filtered by allowed document IDs
- [ ] LLM API key stored in secret manager; never in source or client-side code
- [ ] Prompt injection mitigation: user input sanitized; system prompt uses clear delimiters (`<context>`, `<question>`)
- [ ] PII in documents: flag or redact SSNs, emails, phone numbers before indexing if not needed for retrieval
- [ ] Audit log: every query, retrieved chunks, and generated answer stored for compliance review
- [ ] Rate limiting on the query endpoint (per-user and global)
- [ ] Chunk metadata does not leak document existence to users without access

## Testing Checklist
- [ ] Golden dataset: 50+ question-answer pairs covering diverse query types; track answer correctness across versions
- [ ] RAGAS metrics baseline: faithfulness ≥ 0.85, answer relevance ≥ 0.80, context precision ≥ 0.75
- [ ] Chunking regression: re-indexing produces the same chunk boundaries for the same document version
- [ ] Access control: user A cannot retrieve chunks from documents user A cannot read
- [ ] Incremental update: modified document produces updated chunks without duplicates
- [ ] Hallucination guard: query with no relevant documents returns "I don't know" response, not a fabricated answer
- [ ] Latency test: p95 end-to-end (query → answer) ≤ 3 s for standard queries
- [ ] Reranker ablation: compare answer quality with and without reranker on golden dataset

## Deployment Checklist
- [ ] Embedding model version pinned; re-index all documents if model version changes
- [ ] Vector store index backed up before bulk re-index
- [ ] Ingestion pipeline runs as idempotent job: re-running does not create duplicate chunks
- [ ] LLM API costs monitored per query; alert if daily spend exceeds budget
- [ ] Token budget enforced per query: retrieved context + query + response ≤ model context limit
- [ ] Async ingestion for large document uploads; user notified when indexing completes
- [ ] Evaluation run in CI on golden dataset; fail build if RAGAS metrics drop below baseline
- [ ] Monitoring: retrieval latency, LLM latency, answer rejection rate, feedback score trend

## Starter Templates

| Option | Description | Recommended |
|---|---|---|
| [langchain-ai/rag-from-scratch](https://github.com/langchain-ai/rag-from-scratch) | LangChain's step-by-step RAG implementation notebooks | ✅ Best pick |
| [anthropics/anthropic-cookbook](https://github.com/anthropics/anthropic-cookbook) | Anthropic RAG patterns and embeddings cookbook | |
| [run-llama/llama_index/examples](https://github.com/run-llama/llama_index/tree/main/examples) | LlamaIndex RAG examples with multiple vector stores | |

**Best Pick:** [langchain-ai/rag-from-scratch](https://github.com/langchain-ai/rag-from-scratch) — comprehensive, covers naive to advanced RAG patterns step-by-step with runnable notebooks

## Reference Repositories
- [langchain-ai/rag-from-scratch](https://github.com/langchain-ai/rag-from-scratch) — LangChain's official RAG tutorial notebooks covering naive to advanced patterns
- [run-llama/llama_index](https://github.com/run-llama/llama_index) — LlamaIndex framework; strong on document parsing and query pipeline composition
- [explodinggradients/ragas](https://github.com/explodinggradients/ragas) — RAG evaluation framework with faithfulness, relevance, and context metrics

## Official Documentation
- [LangChain RAG Docs](https://python.langchain.com/docs/tutorials/rag/) — retrieval-augmented generation tutorial
- [Anthropic Embeddings Docs](https://docs.anthropic.com/en/docs/build-with-claude/embeddings) — using embeddings with Claude
- [OpenAI Embeddings Guide](https://platform.openai.com/docs/guides/embeddings) — Embedding models, dimensions, use cases, chunking recommendations
- [pgvector README](https://github.com/pgvector/pgvector) — PostgreSQL vector extension: index types, distance functions, approximate search
- [Qdrant Documentation](https://qdrant.tech/documentation/) — Vector store with payload filtering, collections, snapshots
- [RAGAS Documentation](https://docs.ragas.io/) — Metrics, evaluation datasets, CI integration for RAG quality
- [Unstructured.io Docs](https://docs.unstructured.io/) — Document parsing for PDFs, DOCX, HTML, tables
