# Weaviate

## Overview
Weaviate is an open-source AI-native vector database that combines vector search with a structured knowledge graph and built-in vectorizer modules. It supports hybrid search, multi-tenancy, generative search (RAG), and direct integration with embedding and LLM providers through its module system.

## Capabilities
- Vector and keyword (BM25) search with hybrid fusion in a single query
- Built-in vectorizer modules: `text2vec-openai`, `text2vec-cohere`, `text2vec-huggingface`, `multi2vec-clip` — Weaviate calls the embedding API automatically at ingest and query time
- Generative search (RAG) module: Weaviate retrieves objects and passes them to an LLM (OpenAI, Cohere, Anthropic) in a single GraphQL/REST call
- Schema with classes (Collections), properties, cross-references (like foreign keys between vector objects)
- Multi-tenancy with tenant isolation at the storage layer — each tenant's data physically separated
- HNSW and flat index types; product quantization (PQ) and binary quantization (BQ) for memory efficiency
- Batch import API for high-throughput ingestion; dynamic batching manages rate limits automatically
- Weaviate Cloud (managed), embedded mode (in-process), and Kubernetes self-hosting
- GraphQL and REST APIs; gRPC (v4 client) for high-performance querying

## When to Use
- Want built-in vectorization — send raw text and Weaviate calls the embedding model for you
- Need RAG with a simple API: retrieve + generate in one query without custom glue code
- Building knowledge graphs where cross-references between different object types matter
- Multi-tenant SaaS with strong tenant data isolation requirements

## Limitations
- Built-in vectorizer modules add latency and tie you to specific embedding providers at the database layer
- GraphQL API has a learning curve; REST and gRPC v4 client are simpler for basic use cases
- Schema changes (adding cross-references, changing vectorizer) on existing collections require migration
- Self-hosted Weaviate uses more memory than Qdrant for equivalent datasets due to the module infrastructure
- Weaviate Cloud free tier ("Sandbox") clusters are deleted after 14 days of inactivity

## Integration Guide
1. Install client: `pip install weaviate-client` (v4, gRPC-based, recommended)
2. Connect:
   ```python
   import weaviate
   client = weaviate.connect_to_weaviate_cloud(
       cluster_url=os.environ["WEAVIATE_URL"],
       auth_credentials=weaviate.auth.AuthApiKey(os.environ["WEAVIATE_API_KEY"]),
       headers={"X-OpenAI-Api-Key": os.environ["OPENAI_API_KEY"]}  # for vectorizer
   )
   ```
3. Create a collection (with built-in vectorizer):
   ```python
   client.collections.create("Article",
       vectorizer_config=wvc.config.Configure.Vectorizer.text2vec_openai(),
       generative_config=wvc.config.Configure.Generative.openai())
   ```
4. Ingest objects (Weaviate calls OpenAI to vectorize automatically):
   ```python
   articles = client.collections.get("Article")
   articles.data.insert({"title": "AI Safety", "body": "..."})
   ```
5. Hybrid search:
   ```python
   results = articles.query.hybrid("vector databases", limit=5, alpha=0.5)
   ```
6. Generative search (RAG):
   ```python
   results = articles.generate.near_text("What is RAG?", limit=3,
               grouped_task="Summarize these articles in 2 sentences")
   ```
7. For multi-tenancy: enable `multi_tenancy_config=Configure.multi_tenancy(enabled=True)` → create tenants → scope all operations with `.with_tenant("tenant_id")`

## Setup Guide
```bash
# Python v4 client (recommended)
pip install weaviate-client

# Run locally with Docker (no built-in vectorizer)
docker run -p 8080:8080 -p 50051:50051 cr.weaviate.io/semitechnologies/weaviate:latest

# Run with OpenAI vectorizer module enabled
docker run -p 8080:8080 -p 50051:50051 \
  -e ENABLE_MODULES="text2vec-openai,generative-openai" \
  -e DEFAULT_VECTORIZER_MODULE="text2vec-openai" \
  cr.weaviate.io/semitechnologies/weaviate:latest

# Set environment variables
export WEAVIATE_URL=https://your-cluster.weaviate.network
export WEAVIATE_API_KEY=your-key
export OPENAI_API_KEY=sk-...
```

Configuration notes:
- Pass provider API keys as HTTP headers (`X-OpenAI-Api-Key`, `X-Cohere-Api-Key`) per request — they are never stored in Weaviate
- Use v4 client (`weaviate.connect_to_*`) — v3 client (`weaviate.Client`) is deprecated
- Set `PERSISTENCE_DATA_PATH` and mount a volume for self-hosted persistent storage
- `alpha=0.5` in hybrid search weights vector and BM25 equally; 0 = pure BM25, 1 = pure vector

## Pricing Notes
- **Self-hosted:** Free (open-source BSD-3 Clause); you pay only for infrastructure and embedding API calls
- **Weaviate Cloud Sandbox:** Free, 14-day activity timeout; for prototyping
- **Weaviate Cloud Standard:** From ~$25/month for small clusters; scales by resource units
- **Enterprise Cloud:** Custom pricing; dedicated clusters, SLA, BYOC (Bring Your Own Cloud)
- Watch for: built-in vectorizer modules make embedding API calls on your behalf — those costs (OpenAI, Cohere) are billed to your external API key, not Weaviate

## Reference Repositories
- [weaviate/weaviate](https://github.com/weaviate/weaviate) — Weaviate server (Go); study `test/acceptance/` for API behavior
- [weaviate/recipes](https://github.com/weaviate/recipes) — end-to-end notebooks: RAG, hybrid search, multi-modal, agents

## Official Documentation
- [Weaviate Docs](https://weaviate.io/developers/weaviate) — complete reference
- [v4 Python Client](https://weaviate.io/developers/weaviate/client-libraries/python) — migration from v3 and API reference
- [Hybrid Search](https://weaviate.io/developers/weaviate/search/hybrid) — alpha tuning and fusion methods
- [Generative Search](https://weaviate.io/developers/weaviate/search/generative) — built-in RAG module
- [Multi-tenancy](https://weaviate.io/developers/weaviate/manage-data/multi-tenancy) — tenant isolation guide

## Examples
1. **No-code RAG:** Define a collection with `text2vec-openai` and `generative-openai` → insert raw article text → call `generate.near_text("question", grouped_task="Answer based on these articles")` → Weaviate embeds, retrieves, and generates in one API call.
2. **Knowledge graph with cross-references:** `Author` collection cross-references `Article` collection → query `Author` and traverse to their `articles` in a single GraphQL query — no join logic in application code.
3. **Multi-tenant document search:** Each company in a SaaS product is a Weaviate tenant → documents inserted with the company tenant ID → search queries scoped to the tenant → no row-level SQL filters needed; isolation is at the storage layer.
