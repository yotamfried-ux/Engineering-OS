# Vercel Platforms Starter Kit

## Repository
**URL:** https://github.com/vercel/platforms
**Owner:** Vercel
**Purpose:** Production-grade reference implementation for multi-tenant SaaS with custom
domains. Demonstrates per-tenant subdomains and CNAME-mapped custom domains, Next.js
App Router, Vercel Domains API, Prisma + PlanetScale (or Postgres), and Vercel deployment
configuration for dynamic edge routing.

## What to Learn from It
- Multi-tenant architecture: routing requests to the correct tenant by hostname at the edge
- Custom domain provisioning: adding, verifying, and managing user-supplied CNAME domains
- Middleware-based tenant resolution: extracting tenant context from the request hostname
- Per-tenant data isolation using a single shared database with tenant-scoped queries
- Next.js App Router with dynamic segments for tenant-aware layouts and pages
- Vercel Domains API integration: programmatic domain add/remove/verify via REST
- Image and asset namespacing per tenant using Vercel Blob or a CDN prefix strategy
- Role-based access within a tenant: owner, member, and viewer permission checks
- Subdomain preview deployments and how to configure wildcard DNS on Vercel

## Recommended Sections / Examples
- `app/` — App Router directory; study `[domain]/` and `app/[domain]/layout.tsx` for tenant routing
- `middleware.ts` — hostname parsing, tenant lookup, and rewrite logic; most important file to read first
- `lib/actions.ts` — Server Actions for domain add/remove and site CRUD
- `lib/auth.ts` — NextAuth session setup with tenant-scoped authorization checks
- `prisma/schema.prisma` — multi-tenant data model: Site, Post, and User relations
- `components/` — tenant-aware UI components shared across the platform shell
- `app/api/` — Route Handlers for Vercel Domains API proxying and webhook ingestion
- `vercel.json` — wildcard domain and edge config settings for production deployment

## Related Patterns
- see [patterns/ui/README.md](../../patterns/ui/README.md)
- see [patterns/auth/README.md](../../patterns/auth/README.md)
- see [patterns/api/README.md](../../patterns/api/README.md)

## Related Architectures
- see [docs/architecture-guides/](../architecture-guides/)
