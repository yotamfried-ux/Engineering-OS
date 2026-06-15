# Supabase — Official Documentation Index

## Official Documentation
**Primary:** https://supabase.com/docs
**GitHub:** https://github.com/supabase/supabase
**Changelog:** https://supabase.com/changelog
**API Reference:** https://supabase.com/docs/reference/javascript/introduction

---

## Key Sections (Recommended Reading Order)

1. [Architecture Overview](https://supabase.com/docs/guides/getting-started/architecture) — Understand how PostgREST, GoTrue, and Realtime sit on top of Postgres before building.
2. [Database (PostgreSQL)](https://supabase.com/docs/guides/database/overview) — Tables, schemas, functions, and triggers; Supabase is a thin layer over standard Postgres.
3. [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security) — Critical read before exposing any table; RLS must be enabled and policies written for every table accessed by clients.
4. [Auth Overview](https://supabase.com/docs/guides/auth) — Social OAuth, magic links, and password flows; understand `auth.users` vs. your own `profiles` table.
5. [Auth Helpers (Server-Side)](https://supabase.com/docs/guides/auth/server-side) — How to create a Supabase client in SSR frameworks (Next.js, SvelteKit) using cookies, not `localStorage`.
6. [Storage](https://supabase.com/docs/guides/storage) — Buckets, RLS policies on storage objects, and signed URLs for private files.
7. [Realtime](https://supabase.com/docs/guides/realtime) — Postgres Changes, Broadcast, and Presence; choose the right channel type for your use case.
8. [Edge Functions](https://supabase.com/docs/guides/functions) — Deno-based serverless functions; use for webhooks, custom auth logic, and third-party integrations.
9. [Local Development](https://supabase.com/docs/guides/local-development) — `supabase start` / `supabase db diff` / `supabase db push` workflow for migration-based development.

---

## Important APIs / Concepts

- **`createClient()`** — Initialize the JS client with `SUPABASE_URL` and `SUPABASE_ANON_KEY`; use `SUPABASE_SERVICE_ROLE_KEY` only in trusted server contexts.
- **RLS (Row Level Security)** — Postgres policies that filter rows based on `auth.uid()` or JWT claims; disabled by default on new tables.
- **`auth.users`** — Supabase-managed auth table; never write to it directly. Create a `profiles` table in `public` schema linked by user ID.
- **`supabase.from('table').select()`** — The PostgREST client; supports joins, filters, pagination, and column selection in one call.
- **Service Role Key** — Bypasses RLS entirely; never expose in client-side code or public repos.
- **Storage RLS** — Bucket-level and object-level policies are separate; a public bucket still needs an INSERT policy for uploads.
- **`supabase.channel()`** — Subscribe to Realtime events; always clean up subscriptions on component unmount.
- **Edge Function secrets** — Set via `supabase secrets set KEY=VALUE`; access via `Deno.env.get('KEY')` inside the function.

---

## Common Patterns

- Auth with RLS — see [patterns/auth/README.md](../../patterns/auth/README.md)
- Database access patterns — see [patterns/database/README.md](../../patterns/database/README.md)

---

## Related External Systems

- see [external-systems/supabase/README.md](../../external-systems/supabase/README.md)

---

## Gotchas & Version Notes

- **RLS is opt-in:** New tables have RLS disabled — any authenticated or anonymous user can read/write. Always enable RLS immediately after table creation.
- **`anon` vs `authenticated` roles:** Policies must explicitly grant access to the `authenticated` role; `anon` gets unauthenticated access only.
- **SSR cookie handling:** In Next.js App Router, use `@supabase/ssr` (not `@supabase/auth-helpers-nextjs`, which is deprecated).
- **Realtime row filter requires RLS:** Postgres Changes subscriptions respect RLS — the user only receives changes to rows they can `SELECT`.
- **Edge Function cold starts:** Deno isolates have cold starts of ~300ms; avoid using Edge Functions for latency-critical hot paths.
- **`supabase db push` vs migrations:** `db push` is for local dev only; use `supabase migration new` + `db push` for tracked, reviewable migrations.
- **Storage CDN caching:** Public bucket objects are cached by Supabase CDN; use versioned filenames or cache-busting paths if content changes.
