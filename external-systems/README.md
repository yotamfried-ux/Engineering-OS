# external-systems

Inventory of third-party services and connectors known to Engineering-OS. This directory is **knowledge/reference**, not proof that a service is connected in the current host.

## Live routing owners

| Question | Source of truth |
|---|---|
| Which external system is documented? | This README |
| Which connector/capability should the agent try first? | `../capability-registry/connectors.md` and `../capability-registry/ROUTING-MAP.md` |
| How should source authority/freshness be judged? | `../capability-registry/SOURCE-POLICY.md` |
| Practical connector notes | `connectors/<name>/README.md` |
| Project integration patterns | `../patterns/integrations/` |

Do not infer connection/authorization from the presence of a folder. Verify the current host and current official provider documentation before depending on exact API/auth behavior.

## LLM Providers & AI APIs

Anthropic (`anthropic/`), OpenAI (`openai/`), Google Gemini (`google-gemini/`), Mistral (`mistral/`), Cohere (`cohere/`), NVIDIA (`nvidia/`).

## AI Agent Frameworks

LangGraph, CrewAI, AutoGen, Pydantic AI, and MCP SDK are documented in their matching folders.

## Computer Vision & Media AI

Supervision is documented under `supervision/`.

## Vector Databases & Search

Pinecone, Weaviate, Qdrant, Chroma, Meilisearch, Typesense and Algolia.

## Databases & Data Pipelines

Supabase, dlt and Meltano.

## Authentication & Identity

Auth0, Clerk and Firebase Auth.

## Payments & Commerce

Stripe, Paddle and LemonSqueezy.

## Observability & Analytics

Datadog, Grafana, LangSmith, DeepEval, PostHog, Amplitude and Mixpanel.

## Feature Flags & Experimentation

GrowthBook, LaunchDarkly and Unleash.

## Communication, Media & Maps

Resend, Ably, Cloudinary, Mux and Mapbox.

## Scheduling, Events & Collaboration

Cal.com, Inngest and Liveblocks.

## CRM

Twenty CRM.

## Additional cataloged systems

OmniRoute, OpenViking, open-wa and Scrapling are also cataloged here. Treat community projects according to the source policy rather than as official platform guidance.

## Connector knowledge

GitHub, Notion, Slack, Linear, Jira, Stripe, Supabase, PostgreSQL, Google Drive, Google Sheets, Figma and Discord have connector notes under `connectors/`.

Connector notes describe known integration surfaces. They do **not** promise that the current ChatGPT/Claude/Codex account has that connector installed, authorized or writable.
