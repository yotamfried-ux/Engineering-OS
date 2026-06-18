# Twenty CRM

## Overview
Twenty is an open-source CRM built with React, NestJS, and PostgreSQL — a modern alternative to Salesforce and HubSpot. Built around a flexible metadata-driven data model where every object (People, Companies, Deals, Tasks) is customizable without writing code. 7k+ GitHub stars, active development. The metadata engine stores the schema as runtime data, which drives both the UI and GraphQL API dynamically. Best reference architecture for building a CRM-like system or for self-hosting a modern, customizable CRM.

## Capabilities
- Contact (People) and Company management with fully customizable fields and relationships
- Deal pipeline with drag-and-drop kanban board and custom deal stages
- Activity feed and task management tied to any CRM object
- Custom fields and custom objects — add arbitrary fields or entire new object types without code
- GraphQL API — auto-generated at runtime from the metadata engine; schema reflects current object definitions
- REST API for standard CRUD operations on all CRM objects
- Webhooks for object lifecycle events (record created, updated, deleted)
- Email integration — Gmail and Outlook sync to attach emails to People and Company records
- Chrome extension for importing contacts from LinkedIn profiles
- Full-text search across all CRM records
- Workspace-level data isolation for multi-tenant or multi-team deployments
- RBAC — role-based access control for team members
- Self-hostable via Docker Compose with PostgreSQL and Redis

## When to Use
- Teams wanting a self-hosted CRM with full data ownership (GDPR compliance, data residency, no third-party SaaS)
- Engineers studying metadata-driven architecture — Twenty's schema-as-data approach is an excellent reference implementation
- Startups needing a customizable CRM without Salesforce licensing costs or HubSpot's per-seat pricing
- Building a vertical SaaS product with CRM-like features — study Twenty's architecture before designing your own entity/relationship system

## Limitations
- Younger project (started 2023) — some enterprise features (SSO, advanced reporting, mobile app) are still in active development
- Metadata-driven architecture adds runtime complexity compared to a traditional static ORM approach; schema changes regenerate the GraphQL API at runtime
- Smaller plugin and integration ecosystem compared to HubSpot or Pipedrive; most integrations require custom webhook or API work
- No mobile app yet — web-only interface
- Self-hosting requires understanding Docker Compose networking; the metadata and main data PostgreSQL schemas must both be backed up

## Integration Guide
1. Clone the repo and copy `.env.example` to `.env`; set `APP_SECRET`, `PG_DATABASE_URL`, and `REDIS_URL`
2. Run `docker compose up -d` — the server starts on port 3000 by default
3. Access the admin UI at `http://localhost:3000` to configure the workspace and invite team members
4. Use the GraphQL API at `/api` for programmatic access — authenticate with a workspace API key from Settings → API
5. For custom objects, define them in Settings → Data Model; the GraphQL schema reflects the change immediately
6. Register webhooks in Settings → API → Webhooks to receive real-time notifications on record changes

## Setup
```bash
# Self-hosted via Docker Compose
git clone https://github.com/twentyhq/twenty.git
cd twenty
cp .env.example .env
# Required: APP_SECRET (random 64-char string), PG_DATABASE_URL, REDIS_URL
# Optional: email SMTP settings, storage (S3 or local)
docker compose up -d
# Access at http://localhost:3000

# Environment variables
APP_SECRET=your_random_64_char_secret
PG_DATABASE_URL=postgresql://user:pass@localhost:5432/twenty
REDIS_URL=redis://localhost:6379
```

```typescript
// GraphQL API — list all People in the CRM
const query = `
  query { people(first: 10) { edges { node { id name { firstName lastName } emails { primaryEmail } } } } }
`;
const res = await fetch('https://your-twenty-instance.com/api', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${process.env.TWENTY_API_KEY}`,
  },
  body: JSON.stringify({ query }),
}).then(r => r.json());
```

## Pricing Notes
- **Self-hosted:** Free forever — AGPL-3.0 license; all features including custom objects, API, and webhooks
- **Twenty Cloud:** Under development as of mid-2025; pricing not yet publicly announced
- Operational cost for self-hosting: a single PostgreSQL instance and a Redis instance; the Twenty server is stateless and horizontally scalable

## Reference Repositories
- [twentyhq/twenty](https://github.com/twentyhq/twenty) — full CRM monorepo, 7k+ GitHub stars; React frontend, NestJS backend, PostgreSQL
- [twentyhq/twenty/packages/twenty-server](https://github.com/twentyhq/twenty/tree/main/packages/twenty-server) — NestJS backend with the metadata engine and auto-generated GraphQL resolvers

## Official Documentation
- [Twenty Developer Docs](https://twenty.com/developers) — self-hosting guide, Docker Compose setup, and configuration reference
- [Twenty API Reference](https://twenty.com/developers/api-reference) — auto-generated GraphQL and REST API documentation reflecting current schema
- [Twenty Contributing Guide](https://github.com/twentyhq/twenty/blob/main/CONTRIBUTING.md) — architecture overview and local development setup for contributors

## Common Pitfalls
- **Regenerate types after metadata schema changes** — the metadata engine generates GraphQL types at runtime; if you maintain a TypeScript client with generated types, re-run `yarn graphql:generate` after adding or modifying custom fields to keep client types in sync.
- **Back up the metadata schema separately** — Twenty uses two PostgreSQL schemas: `public` for CRM data and `metadata` for the object definitions; losing the `metadata` schema makes existing records in `public` unreadable because the field definitions no longer exist.
- **Set `APP_SECRET` before the first run** — `APP_SECRET` signs authentication tokens and encrypts sensitive config; changing it after the workspace is created invalidates all existing user sessions and connected integration tokens.
- **Use workspace API keys, not user tokens, for server-to-server integrations** — user tokens expire and are tied to a specific user's permissions; workspace API keys are scoped to the workspace and do not expire.

## Examples
1. **Custom vertical CRM (legal):** Add a custom object "Cases" via Settings → Data Model → add fields for `caseType`, `status`, `hearingDate` → relate Cases to People (clients) and Companies (firms) → the GraphQL API immediately exposes `cases` queries with filtering and pagination.
2. **Inbound lead automation:** Register a webhook for `person.created` → when a new contact is created, send a Slack message to the sales channel with the person's name and email → the sales team sees new leads in real time without logging into the CRM.
3. **Architecture study — metadata-driven schema:** Read `packages/twenty-server/src/metadata` to understand how object definitions stored in PostgreSQL drive NestJS resolver generation at startup — apply the same pattern to build a user-configurable schema in your own multi-tenant product.
