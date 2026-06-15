# Pinecone

## Overview
Pinecone is a fully managed vector database service optimized for production ML applications. It provides high-performance approximate nearest neighbor (ANN) search at scale, with a serverless architecture that eliminates infrastructure management while delivering low-latency similarity search.

## Capabilities
- Serverless and pod-based index deployment; serverless scales to zero and charges per usage
- Dense vector search with cosine, dot product, and Euclidean distance metrics
- Sparse vector support (BM25/SPLADE) and hybrid search combining dense + sparse in a single query
- Metadata filtering alongside vector search (filter by tags, user_id, date ranges, etc.)
- Namespaces for multi-tenancy: logically separate data within a single index without performance penalty
- Upsert, query, fetch, update, and delete operations; batch upsert up to 1,000 vectors per request
- Pinecone Inference API for generating embeddings directly (OpenAI, Cohere models) without a separate embedding service
- REST and gRPC APIs; SDKs for Python, Node.js, Java, Go, and REST clients

## When to Use
- Need a fully managed, zero-ops vector database for production RAG or semantic search
- Working at scale (millions to billions of vectors) where self-hosting Qdrant/Weaviate adds operational burden
- Need hybrid dense+sparse search without combining two separate systems
- Multi-tenant SaaS where namespace isolation per customer is required

## Limitations
- Serverless indexes have cold-start latency for infrequently accessed data; pod-based indexes avoid this
- No BYO (bring your own) infrastructure — entirely cloud-hosted; data leaves your environment
- Metadata filtering requires all metadata to be stored with the vector at upsert time; schema changes mean re-upserting
- No native full-text search or SQL-style aggregations — pure vector + metadata filter only
- Pricing can be unpredictable at scale on serverless due to read unit (RU) pricing model

## Integration Guide
1. Install: `pip install pinecone` or `npm install @pinecone-database/pinecone`
2. Initialize client:
   ```python
   from pinecone import Pinecone
   pc = Pinecone(api_key=os.environ["PINECONE_API_KEY"])
   ```
3. Create a serverless index (one-time):
   ```python
   pc.create_index(name="my-index", dimension=1536, metric="cosine",
                   spec=ServerlessSpec(cloud="aws", region="us-east-1"))
   ```
4. Connect to the index: `index = pc.Index("my-index")`
5. Upsert vectors: `index.upsert(vectors=[{"id": "doc1", "values": embedding, "metadata": {"text": "...", "user_id": "u1"}}])`
6. Query: `results = index.query(vector=query_embedding, top_k=5, filter={"user_id": {"$eq": "u1"}}, include_metadata=True)`
7. Use namespaces for multi-tenancy: add `namespace="user_u1"` to all upsert and query calls
8. For hybrid search: upsert with both `values` (dense) and `sparse_values`; query with both fields and set `alpha` for weighting

## Setup Guide
```bash
# Python SDK
pip install pinecone

# Node.js SDK
npm install @pinecone-database/pinecone

# Set API key
export PINECONE_API_KEY=pcsk_...

# Verify connectivity
python -c "from pinecone import Pinecone; print(Pinecone().list_indexes())"
```

Configuration notes:
- `dimension` must match the embedding model output (OpenAI text-embedding-3-small → 1536, or custom dimensions down to 256)
- Choose `metric` at index creation time — cannot change later without re-creating the index
- Serverless indexes in `us-east-1` (AWS) and `us-central1` (GCP) have the lowest latency from most cloud regions
- Use `batch_size=100` when upserting large datasets to stay within API limits and manage memory

## Pricing Notes
- **Free tier (Starter):** 1 serverless index, 2 GB storage, limited reads/writes per month
- **Serverless:** Pay-per-use — ~$0.04 per 1M read units (queries), ~$2.00 per 1M write units (upserts); storage ~$0.33/GB/month
- **Pod-based:** Fixed cost per pod-hour (p1.x1 ≈ $0.096/hr); more predictable for steady-state workloads
- Watch for: read units spike with high `top_k` values; filter-heavy queries scan more vectors; estimate costs with the Pinecone pricing calculator

## Reference Repositories
- [pinecone-io/examples](https://github.com/pinecone-io/examples) — Jupyter notebooks for RAG, semantic search, recommendations
- [pinecone-io/canopy](https://github.com/pinecone-io/canopy) — production-ready RAG framework built on Pinecone

## Official Documentation
- [Pinecone Docs](https://docs.pinecone.io/) — full reference
- [Serverless Indexes](https://docs.pinecone.io/guides/indexes/understanding-indexes) — index types and tradeoffs
- [Metadata Filtering](https://docs.pinecone.io/guides/data/filter-with-metadata) — filter syntax and best practices
- [Hybrid Search](https://docs.pinecone.io/guides/data/understanding-hybrid-search) — dense+sparse configuration

## Examples
1. **RAG document store:** Chunk documents → embed with OpenAI → upsert with `doc_id` and `user_id` metadata → at query time, embed user question, filter by `user_id`, retrieve top-5 → pass retrieved text chunks to Claude as context.
2. **Multi-tenant SaaS search:** Each customer's vectors stored in a dedicated namespace → queries always include the customer's namespace → complete data isolation with no separate index per customer.
3. **E-commerce product recommendation:** Product catalog embedded with image+text models → user's viewed items are averaged into a query vector → Pinecone returns top-20 similar products filtered by `{"in_stock": true}` and `{"category": "shoes"}`.
