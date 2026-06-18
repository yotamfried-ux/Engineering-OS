# external-systems

Integration guides for third-party services. Each subdirectory contains setup
instructions, authentication details, key objects/concepts, and usage patterns.

Before choosing a service, check `../core/connector-policy.md` for selection criteria
and fallback procedures.

---

## LLM Providers & AI APIs

| Service | Path | Notes |
|---|---|---|
| Anthropic (Claude) | `anthropic/` | Primary LLM; Claude API, tool use, streaming |
| OpenAI | `openai/` | GPT-4o, embeddings, assistants API |
| Google Gemini | `google-gemini/` | Gemini Pro/Ultra, multimodal |
| Mistral | `mistral/` | Mistral Large/Medium, function calling |
| Cohere | `cohere/` | Command R+, reranking, embeddings |
| NVIDIA NIM | `nvidia/` | OpenAI-compatible inference API (llama, nemotron, etc.) |

## AI Agent Frameworks

| Service | Path | Notes |
|---|---|---|
| LangGraph | `langgraph/` | Stateful multi-agent graphs |
| CrewAI | `crewai/` | Role-based agent crews |
| AutoGen | `autogen/` | Conversational multi-agent |
| Pydantic AI | `pydantic-ai/` | Structured output, type-safe agents |
| MCP SDK | `mcp-sdk/` | Build and consume MCP servers |

## Vector Databases & Search

| Service | Path | Notes |
|---|---|---|
| Pinecone | `pinecone/` | Managed vector DB, serverless |
| Weaviate | `weaviate/` | Vector DB with hybrid search |
| Qdrant | `qdrant/` | Self-hosted or cloud vector DB |
| Chroma | `chroma/` | Lightweight local vector store |
| Meilisearch | `meilisearch/` | Full-text + vector search |
| Typesense | `typesense/` | Fast typo-tolerant search |
| Algolia | `algolia/` | Managed search with analytics |

## Databases & Data Pipelines

| Service | Path | Notes |
|---|---|---|
| Supabase | `supabase/` | Postgres + Auth + Storage + RLS |
| dlt | `dlt/` | Data load tool — ETL pipelines |
| Meltano | `meltano/` | Singer-based ELT platform |

## Authentication & Identity

| Service | Path | Notes |
|---|---|---|
| Auth0 | `auth0/` | Enterprise auth, SSO, MFA |
| Clerk | `clerk/` | Next.js-first auth, user management |
| Firebase Auth | `firebase-auth/` | Google Firebase auth |

## Payments & Commerce

| Service | Path | Notes |
|---|---|---|
| Stripe | `stripe/` | Subscriptions, webhooks, metered billing |
| Paddle | `paddle/` | B2B SaaS billing, tax handling |
| LemonSqueezy | `lemonsqueezy/` | Simple SaaS billing |

## Observability & Analytics

| Service | Path | Notes |
|---|---|---|
| Datadog | `datadog/` | APM, logs, metrics, dashboards |
| Grafana | `grafana/` | OSS observability stack |
| LangSmith | `langsmith/` | LLM observability and tracing |
| DeepEval | `deepeval/` | LLM evaluation framework |
| PostHog | `posthog/` | Product analytics, feature flags |
| Amplitude | `amplitude/` | Product analytics |
| Mixpanel | `mixpanel/` | Event-based analytics |

## Feature Flags & Experimentation

| Service | Path | Notes |
|---|---|---|
| GrowthBook | `growthbook/` | OSS feature flags + A/B testing |
| LaunchDarkly | `launchdarkly/` | Enterprise feature management |
| Unleash | `unleash/` | Self-hosted feature toggles |

## Communication & Media

| Service | Path | Notes |
|---|---|---|
| Resend | `resend/` | Transactional email API |
| Ably | `ably/` | Realtime pub/sub, websockets |
| Cloudinary | `cloudinary/` | Image/video CDN and transforms |
| Mux | `mux/` | Video hosting and streaming |
| Mapbox | `mapbox/` | Maps, geocoding, routing |

## Scheduling & Events

| Service | Path | Notes |
|---|---|---|
| Cal.com | `cal-com/` | Open-source scheduling |
| Inngest | `inngest/` | Durable functions and event queues |
| Liveblocks | `liveblocks/` | Collaborative real-time features |

## CRM

| Service | Path | Notes |
|---|---|---|
| Twenty CRM | `twenty-crm/` | Open-source CRM |

## MCP Connectors

Pre-built MCP server wrappers for common services (use with `claude mcp add`):

| Connector | Path |
|---|---|
| GitHub | `connectors/github/` |
| Notion | `connectors/notion/` |
| Slack | `connectors/slack/` |
| Linear | `connectors/linear/` |
| Jira | `connectors/jira/` |
| Stripe | `connectors/stripe/` |
| Supabase | `connectors/supabase/` |
| Postgres | `connectors/postgres/` |
| Google Drive | `connectors/google-drive/` |
| Google Sheets | `connectors/google-sheets/` |
| Figma | `connectors/figma/` |
| Discord | `connectors/discord/` |
