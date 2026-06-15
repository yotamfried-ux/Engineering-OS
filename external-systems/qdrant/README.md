# Qdrant

## Overview
Qdrant is an open-source, high-performance vector database and similarity search engine written in Rust. It offers both a self-hosted deployment option and a managed cloud service (Qdrant Cloud), making it a strong choice when data sovereignty, on-premise deployment, or open-source flexibility matters.

## Capabilities
- Dense and sparse vector storage with cosine, dot product, and Euclidean distance metrics
- Hybrid search: combine dense vectors with sparse vectors (BM42 built-in) in a single query with Reciprocal Rank Fusion (RRF)
- Rich payload filtering: filter on nested JSON payloads with `$match`, `$range`, `$geo`, `$is_null` operators
- Collections with multiple named vectors per point (e.g., title embedding + body embedding on the same document)
- Quantization (scalar, product, binary) to reduce memory usage by 4-32x with tunable accuracy trade-offs
- Payload indexing for fast filtering without scanning all vectors
- Snapshots and collections for backup, migration, and multi-region replication
- gRPC and REST APIs; official clients for Python, Rust, Go, TypeScript, Java, C#, and more
- Qdrant Cloud managed service with free tier and vertical/horizontal scaling

## When to Use
- Need self-hosted or on-premise vector storage for data privacy or compliance reasons
- Want rich filtering on complex nested payloads without rebuilding metadata in a separate database
- Working with multiple vector types per record (multi-vector search)
- Cost-conscious at scale — open-source self-hosting has no per-query or storage licensing fees

## Limitations
- Self-hosting requires managing Kubernetes or Docker deployments, upgrades, and backups
- Binary quantization (best compression) can noticeably reduce recall on some embedding models — benchmark before production use
- Qdrant Cloud free tier is limited; production workloads need a paid cluster
- No native BM25/full-text search beyond the BM42 sparse vectors approach — true full-text search needs a separate Elasticsearch/OpenSearch layer
- Writes during heavy indexing can cause temporary latency spikes; use `optimizers_config` tuning for write-heavy workloads

## Integration Guide
1. Install client: `pip install qdrant-client` or `npm install @qdrant/js-client-rest`
2. Connect to local or cloud:
   ```python
   from qdrant_client import QdrantClient
   client = QdrantClient(url="http://localhost:6333")
   # or cloud:
   client = QdrantClient(url="https://xyz.qdrant.io", api_key=os.environ["QDRANT_API_KEY"])
   ```
3. Create a collection:
   ```python
   from qdrant_client.models import VectorParams, Distance
   client.create_collection("docs", vectors_config=VectorParams(size=1536, distance=Distance.COSINE))
   ```
4. Upsert points:
   ```python
   from qdrant_client.models import PointStruct
   client.upsert("docs", points=[PointStruct(id=1, vector=embedding, payload={"text": "...", "user_id": "u1"})])
   ```
5. Query with filter:
   ```python
   from qdrant_client.models import Filter, FieldCondition, MatchValue
   results = client.search("docs", query_vector=query_embedding, limit=5,
                           query_filter=Filter(must=[FieldCondition(key="user_id", match=MatchValue(value="u1"))]))
   ```
6. Create payload index for filter performance: `client.create_payload_index("docs", "user_id", "keyword")`
7. For hybrid search: define a sparse vector config alongside dense; use `client.query_points()` with fusion

## Setup Guide
```bash
# Run locally with Docker
docker pull qdrant/qdrant
docker run -p 6333:6333 -p 6334:6334 \
  -v $(pwd)/qdrant_storage:/qdrant/storage:z \
  qdrant/qdrant

# Python client
pip install qdrant-client

# TypeScript client
npm install @qdrant/js-client-rest

# Qdrant Cloud: set env var
export QDRANT_API_KEY=your-cloud-key
export QDRANT_URL=https://your-cluster.qdrant.io
```

Configuration notes:
- Persist data by mounting a volume to `/qdrant/storage` in Docker
- For production self-hosting, use the Helm chart: `helm install qdrant qdrant/qdrant`
- Enable `hnsw_config.on_disk: true` for very large collections to reduce RAM usage (with latency trade-off)
- Set `indexing_threshold: 0` during bulk upserts to defer indexing; then set back to default (`20000`) when done

## Pricing Notes
- **Self-hosted:** Free (open-source Apache 2.0); you pay only for your own infrastructure
- **Qdrant Cloud Free tier:** 1 cluster, 1 GB RAM, 0.5 vCPU, 4 GB disk — enough for ~1M 1536-dim vectors
- **Qdrant Cloud Starter:** From ~$9/month for 2 GB RAM; scales to dedicated clusters
- **Enterprise self-hosted:** Commercial license for support, SLA, and enterprise features
- Watch for: RAM is the dominant cost driver; use quantization to fit 10x more vectors in the same memory

## Reference Repositories
- [qdrant/qdrant](https://github.com/qdrant/qdrant) — Rust source; study `docs/` for configuration reference
- [qdrant/qdrant-client](https://github.com/qdrant/qdrant-client) — Python client with typed models
- [qdrant/examples](https://github.com/qdrant/examples) — RAG, semantic search, and recommendation notebooks

## Official Documentation
- [Qdrant Docs](https://qdrant.tech/documentation/) — complete reference
- [Filtering](https://qdrant.tech/documentation/concepts/filtering/) — payload filter operators and indexing
- [Quantization](https://qdrant.tech/documentation/guides/quantization/) — memory reduction strategies
- [Hybrid Search](https://qdrant.tech/documentation/concepts/hybrid-queries/) — dense + sparse fusion

## Examples
1. **Per-user RAG:** Create payload index on `user_id` → at query time, filter `must: [{key: "user_id", match: {value: current_user}}]` → ensures users never see each other's documents without a separate collection per user.
2. **Multi-lingual semantic search:** Store two named vectors per document — `en_embedding` and `native_embedding` — query against the named vector matching the user's language; single collection serves all languages.
3. **Memory-efficient deployment:** Enable scalar quantization (`QuantizationConfig(scalar=ScalarQuantization(type=ScalarType.INT8))`) to reduce a 1536-dim float32 index from 6 GB to ~1.5 GB RAM for 1M vectors, with ~5% recall loss.
