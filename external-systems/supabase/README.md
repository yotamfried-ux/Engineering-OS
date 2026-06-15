# Supabase

## Overview
Supabase is an open-source Firebase alternative built on PostgreSQL, providing a managed database, authentication, storage, realtime subscriptions, and edge functions in a single platform. It gives teams a full backend without managing infrastructure, while retaining the full power of Postgres and SQL.

## Capabilities
- Fully managed PostgreSQL with extensions (pgvector, PostGIS, pg_cron, pg_net, etc.)
- Row Level Security (RLS) for fine-grained, policy-based data access control
- Auth with email/password, magic links, OAuth providers, phone OTP, and SSO (SAML)
- Realtime subscriptions via WebSockets (postgres_changes, broadcast, presence)
- Storage for files and media with per-bucket RLS policies
- Edge Functions (Deno-based) for server-side logic and webhooks
- Auto-generated REST (PostgREST) and GraphQL APIs from your schema
- Database migrations via CLI and version-controlled SQL files

## When to Use
- Need a full Postgres backend (auth + DB + storage + API) without managing infrastructure
- Building realtime features (live dashboards, collaborative editing, presence indicators)
- Want to leverage Postgres extensions like `pgvector` for AI/vector search alongside relational data
- Team is comfortable with SQL and wants direct database access alongside the managed API

## Limitations
- **RLS must always be enabled on every public table** — tables without RLS policies are accessible to anyone with the `anon` key
- **`service_role` key bypasses RLS entirely** — it must be used server-side only (backend/edge functions), never exposed to the client
- Supabase's managed Postgres version may lag behind upstream PostgreSQL releases
- Edge Functions (Deno) have a different runtime than Node.js; not all npm packages work without compatibility shims
- Free-tier projects pause after 1 week of inactivity; production workloads require a paid plan

## Integration Guide
1. Install client: `npm install @supabase/supabase-js`
2. Initialize with the **anon key** on the client — never the service_role key:
   ```ts
   const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
   ```
3. Enable RLS on every table: `ALTER TABLE my_table ENABLE ROW LEVEL SECURITY;`
4. Write RLS policies using `auth.uid()` to restrict access to the authenticated user's rows
5. For server-side operations that need to bypass RLS (admin tasks, background jobs), use the service_role key only in backend code or Edge Functions
6. Use the Supabase CLI for local development: `supabase start` spins up a local stack with Studio
7. Manage schema changes via migration files: `supabase migration new <name>` → edit SQL → `supabase db push`
8. For realtime: subscribe with `supabase.channel('room').on('postgres_changes', {...}, handler).subscribe()`

RLS policy example (user can only see their own rows):
```sql
CREATE POLICY "Users see own rows" ON profiles
  FOR SELECT USING (auth.uid() = user_id);
```

## Setup Guide
```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Login and link to project
supabase login
supabase link --project-ref <project-id>

# Start local development stack
supabase start

# Create and apply a migration
supabase migration new add_profiles_table
supabase db push

# Install JS client
npm install @supabase/supabase-js
```

Key environment variables:
```
NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...          # safe to expose to client
SUPABASE_SERVICE_ROLE_KEY=eyJ...              # SERVER-SIDE ONLY — bypasses RLS
```

## Pricing Notes
- **Free tier:** 2 projects, 500 MB database, 5 GB bandwidth, 1 GB file storage; projects pause after 1 week inactive
- **Pro:** $25/month per project; 8 GB database, 250 GB bandwidth, no pausing, daily backups
- **Team:** $599/month; HIPAA compliance, priority support, SSO, advanced logging
- **Compute add-ons:** Default instance (2 vCPU / 1 GB RAM) is shared; dedicated compute from $10/month
- Watch for: egress bandwidth overages, storage beyond included limits, Realtime concurrent connections

## Reference Repositories
- [supabase/supabase](https://github.com/supabase/supabase) — monorepo; study `examples/` for patterns
- [supabase/supabase/tree/master/examples/todo-list](https://github.com/supabase/supabase/tree/master/examples) — canonical CRUD + auth example
- [supabase/auth-helpers](https://github.com/supabase/auth-helpers) — Next.js / SvelteKit auth integration patterns

## Official Documentation
- [Supabase Docs](https://supabase.com/docs) — complete reference
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security) — RLS patterns and examples
- [Local Development](https://supabase.com/docs/guides/local-development) — CLI-based workflow
- [pgvector Guide](https://supabase.com/docs/guides/ai/vector-columns) — vector embeddings and similarity search

## Common Pitfalls
- **`service_role` key on the client:** Using the service role key in browser/client code bypasses RLS entirely, exposing all data to any user. Use the anon key on the client; reserve `service_role` exclusively for server-side code and Edge Functions.
- **RLS enabled but no policies created:** Enabling RLS on a table without adding policies blocks all access (SELECT, INSERT, UPDATE, DELETE) for non-service-role callers. Every table needs at least one policy per operation you want to permit.
- **`getSession()` called before auth listener is ready:** Calling `supabase.auth.getSession()` at module load time may return `null` if the auth state hasn't hydrated yet. Subscribe to `supabase.auth.onAuthStateChange()` instead and read the session from the event callback.
- **Realtime not enabled per table:** Subscribing to `postgres_changes` silently receives no events if the table isn't added to the replication publication. Fix: run `ALTER PUBLICATION supabase_realtime ADD TABLE tablename;` or enable Realtime in the Table Editor.
- **Connection pool exhaustion from serverless functions:** Each serverless invocation that opens a direct Postgres connection can exhaust `max_connections` under load. Use the pgBouncer connection string (port 6543) and append `?pgbouncer=true` to the connection string; set pool mode to transaction for serverless workloads.
- **Edge Function cold start on first request:** Deno Edge Functions can take up to ~1 second on first invocation after inactivity. Pre-warm critical functions with scheduled pings, or design the caller to handle the latency for the first request.

## Examples
1. **Auth-gated user data:** Enable RLS on `notes` table → policy `USING (auth.uid() = user_id)` → client reads `supabase.from('notes').select('*')` and only gets their own rows automatically.
2. **Realtime collaboration:** Two users subscribe to the same Supabase channel with `presence` — each sees who else is viewing the document and their cursor positions with <100ms latency.
3. **AI semantic search:** Store OpenAI embeddings in a `vector(1536)` column using pgvector → query with `<->` cosine distance operator → combine with RLS so users only search their own documents.
