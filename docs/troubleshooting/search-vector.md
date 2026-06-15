# Search & Vector DBs — Common Bugs & Fixes

> Sources: Algolia docs, Typesense troubleshooting, Pinecone docs, Qdrant docs, Weaviate FAQ, Meilisearch docs

## Vector Search

| Symptom | Root Cause | Fix |
|---|---|---|
| Similarity scores all ~0 or ~1 | Embedding dimension mismatch — querying with wrong model | Always use the same embedding model for indexing and querying |
| Top-k returns too few results | Namespace/collection has fewer vectors than top_k | Check `describe_index_stats()` / collection count before querying |
| Relevant results at bottom | Wrong similarity metric | Match metric to embedding model: OpenAI → cosine, some models → dot product |
| Filter not applied | Metadata field not indexed / no payload index | Create index on filterable fields before using them in filters |
| Stale results after update | Vectors updated but index not refreshed | Upsert with the same ID to overwrite; check that vector store confirms the update |

## Full-Text Search (Algolia / Typesense / Meilisearch)

| Symptom | Root Cause | Fix |
|---|---|---|
| Indexed documents not searchable | Field not in `searchableAttributes` / `schema` | Explicitly list searchable fields; reindex if you change schema |
| Typo tolerance returns wrong results | `num_typos` too high for short/exact fields | Set `num_typos: 0` for IDs, SKUs, codes; only enable for prose fields |
| Facet counts wrong | Attribute not in `attributesForFaceting` (Algolia) | Add field to faceting config and reindex |
| Search latency high | Large response payload (`hits`) not paginated | Use `hitsPerPage` / `limit` + `offset`; only request needed attributes |
| Records not updating | Sync job using wrong primary key | Set `objectID` (Algolia) / `id` explicitly; avoid auto-generated IDs that change |

## Embeddings Pipeline

| Symptom | Root Cause | Fix |
|---|---|---|
| Embedding API rate limit during bulk index | Sending all docs in one loop | Batch in parallel with rate limit backoff; use embedding batch endpoints |
| Inconsistent chunk quality | Chunking at fixed character count splits sentences | Use semantic chunking or sentence-boundary chunking |
| RAG retrieval returns wrong context | Top-k too low or chunk size too large | Start with top_k=5, chunk size ~512 tokens; tune based on evaluation |
| High embedding cost | Re-embedding unchanged documents | Cache embeddings; only re-embed on content change (hash check) |

## Sources
- [Algolia Troubleshooting](https://www.algolia.com/doc/guides/building-search-ui/troubleshooting/faq/js/)
- [Typesense Troubleshooting](https://typesense.org/docs/guide/troubleshooting.html)
- [Pinecone Troubleshooting](https://docs.pinecone.io/troubleshooting)
- [Qdrant FAQ](https://qdrant.tech/documentation/troubleshooting/)
- [Weaviate FAQ](https://weaviate.io/developers/weaviate/more-resources/faq)
- [Meilisearch Debugging](https://www.meilisearch.com/docs/learn/debugging/search_bugs)
