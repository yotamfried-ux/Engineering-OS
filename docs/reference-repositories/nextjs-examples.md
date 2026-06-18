# Next.js Examples

## Repository
**URL:** https://github.com/vercel/next.js
**Owner:** Vercel
**Purpose:** Official Next.js monorepo. The `examples/` directory contains 200+ standalone
starter projects covering App Router patterns, authentication integrations, database
connections, internationalization, edge runtime, and third-party service integrations.

## What to Learn from It
- App Router conventions: layouts, loading UI, error boundaries, and parallel routes
- Server Components vs. Client Components: when to use each and how to compose them
- Server Actions: form submissions and mutations without an API route
- Authentication patterns: session management with cookies, middleware-based route protection
- Edge runtime: running logic at the CDN edge with minimal cold start
- API routes and Route Handlers: REST and streaming responses from the App Router
- Internationalization (i18n): locale routing, translation loading, and RTL support
- Image and font optimization built into Next.js
- Incremental Static Regeneration (ISR) and on-demand revalidation strategies
- Middleware: request interception for auth, geolocation, A/B testing, and redirects

## Recommended Sections / Examples
- `examples/app-dir-mdx/` — App Router with MDX for content-driven sites
- `examples/with-supabase/` — Next.js + Supabase Auth with App Router middleware
- `examples/with-prisma/` — Prisma ORM integration with connection pooling best practices
- `examples/with-iron-session/` — cookie-based session auth without a third-party service
- `examples/i18n-routing/` — locale-aware routing and content localization
- `examples/with-stripe-typescript/` — Stripe Checkout and webhook handling in TypeScript
- `examples/api-routes-middleware/` — middleware chaining on API routes
- `examples/with-turbopack/` — Turbopack dev server configuration
- `packages/next/src/server/` — study App Router internals when debugging rendering behavior

## Related Patterns
- see [patterns/ui/README.md](../../patterns/ui/README.md)
- see [patterns/auth/README.md](../../patterns/auth/README.md)

## Related Architectures
- see [docs/architecture-guides/](../architecture-guides/)
