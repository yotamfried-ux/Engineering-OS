# Web Application Template

## Overview
Use this template for full-stack web applications with a React/Next.js frontend, an API backend, and a relational or document database. Suitable for dashboards, marketplaces, SaaS UIs, and content-driven sites where SEO, auth, and CRUD operations are central concerns.

## Recommended Architecture Options

| Option | Pros | Cons |
|---|---|---|
| Next.js monorepo (App Router + API routes) | Single deploy, SSR/SSG built-in, fast iteration | Tight coupling, harder to scale backend independently |
| Next.js frontend + separate Node/Python API | Clear separation, independent scaling | Two deploys, more infra overhead |
| Next.js + Supabase (BaaS) | Auth, DB, storage out of the box, minimal backend code | Vendor lock-in, limited custom server logic |
| Remix + Prisma + PostgreSQL | Web-standard form actions, progressive enhancement | Smaller ecosystem than Next.js |

## Recommended Frameworks & Platforms

- **Frontend:** Next.js 14+ (App Router), React 18+
- **Styling:** Tailwind CSS + shadcn/ui or Radix UI
- **State management:** Zustand (client state), TanStack Query (server state)
- **Backend:** Next.js API routes, or Express/Fastify/Hono for a separate service
- **Database:** PostgreSQL (via Supabase, Neon, or RDS) + Prisma ORM
- **Auth:** NextAuth.js / Auth.js, or Supabase Auth, or Clerk
- **File storage:** Supabase Storage, AWS S3, or Cloudflare R2
- **Hosting:** Vercel (frontend/edge), Railway or Render (dedicated API), Supabase (DB)
- **Email:** Resend + React Email

## Required Components

- Authentication (sign-up, login, session management, password reset)
- Role-based access control (RBAC) or permission layer
- Database schema with migrations (Prisma or Drizzle)
- Environment variable management (`.env.local`, production secrets)
- Error boundary and global error handling
- API input validation (Zod)
- Rate limiting on public endpoints
- Logging (structured JSON logs)

## Security Checklist

- [ ] All API routes validate input with Zod or equivalent schema validator
- [ ] Authentication tokens stored in httpOnly cookies, not localStorage
- [ ] CSRF protection enabled for state-mutating endpoints
- [ ] SQL injection impossible — ORM used for all queries; raw SQL parameterized
- [ ] Sensitive env vars absent from client bundle (`NEXT_PUBLIC_` prefix audit)
- [ ] Content Security Policy (CSP) headers configured
- [ ] Rate limiting applied to auth and public write endpoints
- [ ] Dependency audit run (`npm audit`) before first deploy

## Testing Checklist

- [ ] Unit tests for utility functions and business logic (Vitest)
- [ ] Integration tests for API route handlers with a test database
- [ ] Component tests for critical UI flows (React Testing Library)
- [ ] E2E tests for auth flow, core user journey (Playwright)
- [ ] Accessibility smoke test on primary views (axe-core / Playwright accessibility)
- [ ] Performance budget checked (Core Web Vitals via Lighthouse CI)

## Deployment Checklist

- [ ] All environment variables set in production environment
- [ ] Database migrations run before deployment (`prisma migrate deploy`)
- [ ] CI pipeline: lint → type-check → unit tests → build → E2E tests
- [ ] Preview deployments enabled for pull requests
- [ ] Error monitoring connected (Sentry)
- [ ] Uptime monitoring configured (Better Uptime, or Vercel analytics)
- [ ] `robots.txt` and `sitemap.xml` correct for production domain

## Reference Repositories

- [vercel/next.js/examples](https://github.com/vercel/next.js/tree/canary/examples) — official patterns for auth, DB, API routes
- [shadcn-ui/taxonomy](https://github.com/shadcn-ui/taxonomy) — production Next.js + Prisma + Auth.js reference
- [planetscale/beam](https://github.com/planetscale/beam) — Next.js full-stack app with Prisma, good auth pattern

## Official Documentation

- [Next.js Docs](https://nextjs.org/docs) — App Router, data fetching, deployment
- [Prisma Docs](https://www.prisma.io/docs) — schema, migrations, queries
- [Auth.js Docs](https://authjs.dev) — providers, sessions, adapters
- [Tailwind CSS Docs](https://tailwindcss.com/docs) — utility classes, configuration
- [Zod Docs](https://zod.dev) — schema validation, TypeScript inference
