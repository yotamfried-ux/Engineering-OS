# Supabase Examples

## Repository
**URL:** https://github.com/supabase/supabase
**Owner:** Supabase
**Purpose:** Monorepo for the Supabase platform. The `examples/` directory contains
production-quality reference integrations covering auth flows, Row-Level Security policies,
realtime subscriptions, edge functions, and Next.js integration patterns.

## What to Learn from It
- Email/password, magic link, OAuth, and SSO auth flows with Supabase Auth
- Row-Level Security (RLS) policy design: per-user access, team-scoped rules, admin bypass
- Realtime subscriptions: listening to INSERT/UPDATE/DELETE events on a table
- Next.js App Router integration: server components, server actions, and middleware for session refresh
- Edge Functions: TypeScript Deno functions deployed to Supabase for custom backend logic
- Storage: bucket creation, public/private file access, and signed URL generation
- Vector search: pgvector setup, embedding insertion, and similarity queries
- Multi-tenant data isolation patterns using RLS + JWT claims

## Recommended Sections / Examples
- `examples/auth/` — all supported auth methods with working code in multiple frameworks
- `examples/auth/nextjs/` — Next.js App Router auth with middleware session management
- `examples/realtime/` — realtime presence, broadcast, and Postgres changes
- `examples/edge-functions/` — Deno edge function patterns: auth guards, webhook handlers, CORS
- `examples/storage/` — file upload, signed URLs, image transformation
- `examples/ai/` — pgvector setup, embedding generation, and semantic search
- `examples/with-stripe/` — Supabase Auth + Stripe subscription integration
- `examples/todo-list/` — simple end-to-end CRUD with RLS; good first read for RLS mechanics
- `supabase/migrations/` (within each example) — study migration files for RLS policy SQL syntax

## Related Patterns
- see [patterns/auth/README.md](../../patterns/auth/README.md)
- see [patterns/database/README.md](../../patterns/database/README.md)

## Related Architectures
- see [docs/architecture-guides/](../architecture-guides/)
