# Next.js — Official Documentation Index

## Official Documentation
**Primary:** https://nextjs.org/docs
**API Reference:** https://nextjs.org/docs/app/api-reference
**GitHub:** https://github.com/vercel/next.js
**Changelog:** https://nextjs.org/blog/releases (also: GitHub releases)

## Key Sections (Recommended Reading Order)
1. [App Router vs Pages Router](https://nextjs.org/docs/app/building-your-application/routing) — understand which router you're in before reading anything else; most new docs are App Router only
2. [Server Components](https://nextjs.org/docs/app/building-your-application/rendering/server-components) — default in App Router; async by default; cannot use hooks or browser APIs
3. [Client Components](https://nextjs.org/docs/app/building-your-application/rendering/client-components) — `"use client"` directive; when and why to opt in; keep as leaf nodes
4. [Routing](https://nextjs.org/docs/app/building-your-application/routing) — file-system routing: `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx`, `not-found.tsx`, route groups `(folder)`, parallel routes `@slot`
5. [Server Actions](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations) — `"use server"` functions called from Client Components or forms; replaces most API routes for mutations
6. [Route Handlers](https://nextjs.org/docs/app/building-your-application/routing/route-handlers) — `route.ts` files for REST-style endpoints; when to prefer over Server Actions
7. [Caching](https://nextjs.org/docs/app/building-your-application/caching) — four layers: Request Memoization, Data Cache, Full Route Cache, Router Cache; read this before debugging stale data
8. [Data Fetching](https://nextjs.org/docs/app/building-your-application/data-fetching/fetching) — `fetch` with `cache` and `next.revalidate` options in Server Components; patterns for parallel and sequential fetching
9. [Metadata API](https://nextjs.org/docs/app/api-reference/functions/generate-metadata) — `export const metadata` and `generateMetadata()` for SEO; replaces `next/head`
10. [Middleware](https://nextjs.org/docs/app/building-your-application/routing/middleware) — `middleware.ts` at the root; runs on Edge; use for auth redirects and header injection

## Important APIs / Concepts
- **`layout.tsx`** — persistent UI wrapper; shared across child routes; fetches are NOT re-run on navigation within the same layout
- **`loading.tsx`** — automatic Suspense boundary for the route segment; shows while the `page.tsx` async component resolves
- **`error.tsx`** — must be a Client Component; catches errors thrown in the same segment and below
- **`useRouter` (App Router)** — import from `next/navigation`, not `next/router`; `push`, `replace`, `prefetch`
- **`cookies()` / `headers()`** — server-only functions from `next/headers`; accessing them opts the route into dynamic rendering
- **`unstable_cache`** — cache arbitrary async functions (DB queries etc.) the same way `fetch` is cached; tag-based revalidation via `revalidateTag()`
- **`generateStaticParams`** — replaces `getStaticPaths`; return an array of param objects to pre-render dynamic segments at build time

## Common Patterns
- Full-stack Next.js app structure — see [templates/fullstack-saas/README.md](../../templates/fullstack-saas/README.md)
- Auth with middleware — see [patterns/auth/README.md](../../patterns/auth/README.md)
- API route patterns — see [patterns/api/README.md](../../patterns/api/README.md)

## Related External Systems
- see [external-systems/vercel/README.md](../../external-systems/vercel/README.md)

## Gotchas & Version Notes
- **App Router is default since Next.js 13.4; stable since 14.0.** Pages Router still works but receives only maintenance updates — use App Router for new projects.
- **`"use client"` propagates down:** Once a component is a Client Component, all its imports are also client-side. Keep data-fetching in Server Components and pass data as props.
- **Caching is aggressive by default in Next.js 14:** Static routes are fully cached; dynamic APIs (`cookies()`, `headers()`, `searchParams`) opt out. Next.js 15 changed fetch default to `no-store` — verify behavior against your version.
- **Server Actions are not the same as API routes:** They are inlined POST requests; they cannot be called cross-origin and do not replace public APIs.
- **`next/image` requires `sizes` prop** for responsive images; omitting it triggers a warning and may cause layout shift.
- **Turbopack (dev)** is default in Next.js 15 (`next dev --turbo`); most plugins work but some Webpack-specific configs do not — check compatibility.
