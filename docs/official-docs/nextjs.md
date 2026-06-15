# Next.js — Official Documentation Index

## Official Documentation
**Primary:** https://nextjs.org/docs
**API Reference:** https://nextjs.org/docs/app/api-reference
**GitHub:** https://github.com/vercel/next.js
**Changelog:** https://nextjs.org/blog (also: https://github.com/vercel/next.js/releases)

## Key Sections (Recommended Reading Order)

1. [App Router Introduction](https://nextjs.org/docs/app/building-your-application/routing) — File-system conventions: `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`, route groups `(folder)`, parallel routes `@slot`; the mental model everything else builds on
2. [Server Components](https://nextjs.org/docs/app/building-your-application/rendering/server-components) — Default in App Router; `async` by default; cannot use hooks or browser APIs; where data fetching lives
3. [Client Components](https://nextjs.org/docs/app/building-your-application/rendering/client-components) — `"use client"` directive; when and why to opt in; keep as leaf nodes to minimise bundle size
4. [Server Actions](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations) — `"use server"` functions called from forms or Client Components; the primary pattern for mutations
5. [Route Handlers](https://nextjs.org/docs/app/building-your-application/routing/route-handlers) — `app/api/.../route.ts` for REST-style endpoints; when to prefer over Server Actions (public APIs, webhooks, cross-origin)
6. [Caching](https://nextjs.org/docs/app/building-your-application/caching) — Four caching layers: Request Memoization, Data Cache, Full Route Cache, Router Cache; read this before debugging any stale-data issue
7. [Data Fetching](https://nextjs.org/docs/app/building-your-application/data-fetching/fetching) — `fetch` with `cache` and `next.revalidate` options in Server Components; parallel vs. sequential fetching patterns
8. [Metadata API](https://nextjs.org/docs/app/api-reference/functions/generate-metadata) — `export const metadata` and `generateMetadata()`; OG images; replaces `next/head`
9. [Middleware](https://nextjs.org/docs/app/building-your-application/routing/middleware) — `middleware.ts` at project root; runs on Edge before the request hits any route; use for auth redirects and header injection
10. [Optimizing](https://nextjs.org/docs/app/building-your-application/optimizing) — `next/image`, `next/font`, `next/script`; always use these instead of raw HTML equivalents

## Important APIs / Concepts

- **`layout.tsx`** — Persistent UI wrapper shared across child routes; not re-rendered on navigation within the same layout segment
- **`loading.tsx`** — Automatic Suspense boundary for the route segment; shown while `page.tsx` async component resolves
- **`error.tsx`** — Must be a Client Component; catches errors thrown in the same segment and below
- **`cookies()` / `headers()`** — Server-only functions from `next/headers`; accessing either opts the route into dynamic rendering
- **`unstable_cache`** — Caches arbitrary async functions (DB queries, etc.) with the same semantics as `fetch`; tag-based revalidation via `revalidateTag()`
- **`revalidatePath` / `revalidateTag`** — Programmatic cache purge from Server Actions or Route Handlers
- **`generateStaticParams`** — Replaces `getStaticPaths`; returns param objects to pre-render dynamic segments at build time
- **`useRouter` from `next/navigation`** — App Router version; do not import from `next/router` (Pages Router only)

## Common Patterns

- Full-stack Next.js app — see [templates/fullstack-saas/README.md](../../templates/fullstack-saas/README.md)
- Auth with middleware — see [patterns/auth/README.md](../../patterns/auth/README.md)
- API route patterns — see [patterns/api/README.md](../../patterns/api/README.md)

## Related External Systems

- see [external-systems/vercel/README.md](../../external-systems/vercel/README.md)

## Gotchas & Version Notes

- **App Router is default since Next.js 13.4; stable since 14.0** — Pages Router still works but receives only maintenance updates; do not mix both routers in the same app
- **`"use client"` propagates down** — once a component is a Client Component, all its imports are also client-side; keep data-fetching in Server Components and pass data as props
- **Caching defaults differ between Next.js 14 and 15** — in 14, `fetch` defaults to `force-cache`; in 15 it defaults to `no-store`; verify the behaviour against your installed version before debugging
- **Server Actions are not API routes** — they are inlined POST requests; they cannot be called cross-origin and do not replace public APIs or webhooks
- **`params` and `searchParams` in page props are Promises in Next.js 15** — `await params` before destructuring
- **`next/image` requires a `sizes` prop** for responsive images; omitting it triggers a dev warning and may cause layout shift
- **Turbopack is default in Next.js 15 (`next dev`)** — most plugins work but some Webpack-specific configs do not; check compatibility before upgrading
