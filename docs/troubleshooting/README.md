# Troubleshooting Guides

Common bugs, error messages, and fixes organized by domain. Each guide covers: symptom → root cause → fix, with sources from official documentation.

## Guides

| Domain | File | Covers |
|---|---|---|
| AI / LLM | [ai-llm.md](./ai-llm.md) | Tool use loops, streaming, caching, token limits, structured output, agent loops |
| Auth | [auth.md](./auth.md) | OAuth redirects, JWT bugs, session management, protected routes, webhooks |
| Payments | [payments.md](./payments.md) | Stripe PaymentIntents, webhooks, subscriptions, Paddle/LemonSqueezy |
| Database | [database.md](./database.md) | RLS, connection pooling, migrations, ORM, Supabase realtime |
| Search & Vector | [search-vector.md](./search-vector.md) | Vector search, full-text search, embeddings pipeline |
| Observability | [observability.md](./observability.md) | Metrics, logs, APM traces, alerting |
| Web / Frontend | [web.md](./web.md) | Hydration, SSR/SSG, caching, CORS, performance |
| API | [api.md](./api.md) | Rate limits, auth errors, validation, error handling, versioning |
| Realtime | [realtime.md](./realtime.md) | WebSocket, Ably, Liveblocks, connection state |
| MCP Servers | [mcp.md](./mcp.md) | stdio/HTTP transport, JSON-RPC, tool registration, debugging |

## How to Use

1. Identify the domain of the bug (auth, payment, database, etc.)
2. Open the relevant guide
3. Match by symptom in the tables
4. Apply the fix; cross-check with the linked official source

## Related

- [`lessons-learned/`](../../lessons-learned/) — project-specific post-mortems and regression notes
- [`failed-solutions/`](../../failed-solutions/) — approaches that were tried and discarded
- [`core/debugging-policy.md`](../../core/debugging-policy.md) — the systematic debug loop to follow before guessing
