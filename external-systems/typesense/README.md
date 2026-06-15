# Typesense

## Overview
Typesense is an open-source, typo-tolerant search engine designed as a fast, self-hostable alternative to Algolia. Built by Typesense, Inc., it is written in C++ for speed and delivers sub-50ms search on modest hardware. A managed cloud offering (Typesense Cloud) is available for teams that prefer not to self-host.

## Capabilities
- Typo-tolerant full-text search with prefix matching, stemming, and synonyms
- Faceted filtering and sorting across multiple fields
- Vector search and hybrid search (keyword + semantic) via built-in embedding support
- Multi-tenant collections with scoped API keys per tenant (no data leakage between users)
- Geo-search with distance filtering and sorting by proximity
- Federated multi-collection search in a single API call
- Real-time indexing — documents are searchable within milliseconds of insertion
- Conversation/RAG mode: pass search results directly into an LLM for Q&A (v0.26+)
- InstantSearch.js adapter (Typesense-InstantSearch-js) for drop-in Algolia UI component compatibility

## When to Use
- Want Algolia-like DX but with control over data residency, infrastructure, and cost
- High query volume where per-search SaaS fees would be prohibitive
- Building a multi-tenant SaaS app that needs per-tenant search isolation via scoped keys
- Self-hosted open-source stack where adding a managed service is a constraint

## Limitations
- Operational burden of running Typesense yourself (upgrades, backups, HA clustering)
- Cluster mode (HA) requires 3+ nodes — adds infrastructure cost for production reliability
- Smaller ecosystem and community than Elasticsearch or Algolia; fewer third-party integrations
- Maximum document size is 4MB; deeply nested objects can be harder to query efficiently
- Typesense Cloud has fewer global PoPs than Algolia's edge network

## Integration Guide
1. Start Typesense (Docker or Typesense Cloud):
   ```bash
   docker run -p 8108:8108 -v /data:/data typesense/typesense:26.0 \
     --data-dir /data --api-key=your_admin_key
   ```
2. Install the client: `npm install typesense` or `pip install typesense`
3. Define a collection schema (field names, types, and which fields are `facet` or `index`):
   ```javascript
   await client.collections().create({
     name: "products",
     fields: [
       { name: "name", type: "string" },
       { name: "price", type: "float", facet: true },
       { name: "category", type: "string", facet: true },
     ],
     default_sorting_field: "price",
   });
   ```
4. Index documents via `collections("products").documents().import(docs)`
5. Search with `collections("products").documents().search({ q: "query", query_by: "name,category" })`
6. Generate scoped API keys server-side to enforce per-tenant data isolation in multi-tenant apps

## Setup
```bash
# Run via Docker (simplest local setup)
docker run -p 8108:8108 -v $(pwd)/typesense-data:/data \
  typesense/typesense:26.0 \
  --data-dir /data \
  --api-key=your_admin_key \
  --enable-cors

# Node.js client
npm install typesense

# Python client
pip install typesense

# For Algolia-compatible UI components
npm install typesense-instantsearch-adapter instantsearch.js

# Environment variables
export TYPESENSE_HOST=localhost
export TYPESENSE_PORT=8108
export TYPESENSE_PROTOCOL=http
export TYPESENSE_API_KEY=your_admin_key
```

## Pricing Notes
- **Self-hosted:** Free (open-source Apache 2.0 license); only pay for your own compute
- **Typesense Cloud:** From ~$0.014/hour (~$10/month) for the smallest RAM1 node; scales to multi-node HA clusters; pricing at https://cloud.typesense.org/pricing
- Watch for: HA clustering on Typesense Cloud requires 3-node setups (~3x the per-node cost); for small projects, a single node with good backups is usually sufficient

## Reference Repositories
- [typesense/typesense](https://github.com/typesense/typesense) — core search engine source code (C++)
- [typesense/typesense-js](https://github.com/typesense/typesense-js) — official JavaScript/TypeScript client
- [typesense/typesense-instantsearch-adapter](https://github.com/typesense/typesense-instantsearch-adapter) — drop-in adapter to use Algolia InstantSearch UI components with Typesense

## Official Documentation
- [Typesense Docs](https://typesense.org/docs/) — complete API reference, guides, and collection schema reference
- [API Reference](https://typesense.org/docs/26.0/api/) — full endpoint and parameter reference
- [Vector Search](https://typesense.org/docs/26.0/api/vector-search.html) — hybrid semantic + keyword search setup
- [Scoped API Keys](https://typesense.org/docs/guide/data-access-control.html) — multi-tenant access control

## Examples
1. **SaaS multi-tenant search:** Each tenant gets a scoped API key with a built-in filter `tenant_id:=<id>` — client-side search calls are automatically scoped without any backend proxy required, preventing cross-tenant data leakage.
2. **E-commerce with facets:** Products indexed with `price`, `brand`, and `category` fields → frontend uses typesense-instantsearch-adapter to wire up Algolia UI components → switching from Algolia to Typesense Cloud required only changing the search client, not the UI components.
3. **Semantic product discovery:** Enable the `embed` field with an OpenAI embedding model in the collection schema → Typesense auto-generates vectors on ingest → at query time, hybrid search ranks results by a weighted blend of BM25 keyword score and cosine vector similarity.
