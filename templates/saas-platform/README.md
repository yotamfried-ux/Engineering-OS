# Multi-Tenant SaaS Platform Template

## Overview
Use this template for B2B or B2C SaaS products with subscription billing, multiple tenants, and an admin layer. Covers tenant isolation, subscription lifecycle management, usage metering, and the operational concerns (admin tooling, churn signals, audit logs) that distinguish a SaaS product from a simple web app.

## Recommended Architecture Options

| Option | Pros | Cons |
|---|---|---|
| Single database, row-level tenant isolation (RLS) | Simple infra, low cost, easy joins across tables | One misconfigured query can leak cross-tenant data |
| Schema-per-tenant (PostgreSQL schemas) | Strong isolation, easy per-tenant backups | Schema sprawl at high tenant counts; migration complexity |
| Database-per-tenant | Maximum isolation, independent scaling | High cost and infra overhead; complex provisioning |
| Hybrid: shared DB for small tenants, dedicated for enterprise | Cost-effective and enterprise-ready | Two code paths to maintain |

## Recommended Frameworks & Platforms

- **Frontend:** Next.js 14+ (App Router) with per-tenant theming support
- **Backend:** Next.js API routes or Fastify/Hono for a separate API service
- **Database:** PostgreSQL with Row-Level Security (RLS) via Supabase, or Neon
- **ORM:** Prisma (with tenant context middleware) or Drizzle
- **Auth:** Clerk (organizations + RBAC built-in), or Auth.js + custom org model
- **Billing:** Stripe (subscriptions, usage metering, customer portal)
- **Email:** Resend + React Email (transactional) + Loops or Customer.io (lifecycle)
- **Feature flags:** LaunchDarkly, Unleash, or Statsig (per-tenant rollouts)
- **Admin:** Custom internal dashboard or Retool/Metabase for ops visibility
- **Hosting:** Vercel (frontend), Railway or Fly.io (API), Supabase/Neon (DB)

## Required Components

- Tenant provisioning flow: sign-up → org creation → plan selection → billing setup
- Tenant context injected into every DB query (RLS policy or Prisma middleware)
- Subscription state machine: trial → active → past_due → canceled
- Stripe webhook handler for subscription lifecycle events
- Usage metering if on a usage-based plan
- Tenant-scoped RBAC: owner, admin, member roles minimum
- Audit log: who did what, when, in which tenant
- Admin panel: impersonate tenant, modify subscription, view usage
- Tenant offboarding: data export and deletion (GDPR Article 17)

## Security Checklist

- [ ] Row-Level Security policies tested: a query with one tenant's context cannot return another tenant's rows
- [ ] Tenant ID derived from the authenticated session — never trusted from request body or query param
- [ ] Stripe webhook endpoint verifies `Stripe-Signature` header before processing
- [ ] Admin impersonation logged in audit log with impersonator identity and reason
- [ ] PII (email, billing info) encrypted at rest and excluded from application logs
- [ ] API keys / tokens scoped to tenant: one tenant's key cannot access another's resources
- [ ] Dependency audit in CI; secrets never in source code or Docker image layers
- [ ] GDPR/CCPA compliance: data deletion and export endpoints implemented and tested

## Testing Checklist

- [ ] Tenant isolation test: authenticated as Tenant A, cannot read or write Tenant B's data
- [ ] Subscription lifecycle tests: trial expiry, upgrade, downgrade, cancellation, reactivation
- [ ] Stripe webhook tests for each relevant event type (payment_succeeded, payment_failed, subscription canceled)
- [ ] RBAC tests: member cannot perform admin-only actions; owner can
- [ ] Billing portal test: customer can update payment method and view invoices
- [ ] Data export test: export contains only the requesting tenant's data
- [ ] Load test: tenant isolation holds under concurrent requests from multiple tenants

## Deployment Checklist

- [ ] Stripe live mode keys separate from test keys; only live keys in production secrets
- [ ] Database RLS policies enabled and verified in production (not just dev)
- [ ] All Stripe webhook events registered in Stripe dashboard with correct production URL
- [ ] Admin access to production requires MFA; admin actions logged
- [ ] Feature flag system configured for per-tenant and per-plan rollouts
- [ ] Churn alerting: notify ops when a tenant cancels or downgrades
- [ ] Backup and point-in-time recovery enabled on production database
- [ ] Status page configured (statuspage.io or BetterUptime) for customer communication

## Reference Repositories

- [vercel/nextjs-subscription-payments](https://github.com/vercel/nextjs-subscription-payments) — Stripe + Supabase subscription pattern
- [boxyhq/saas-starter-kit](https://github.com/boxyhq/saas-starter-kit) — multi-tenant Next.js with teams, RBAC, and SSO
- [calcom/cal.com](https://github.com/calcom/cal.com) — large-scale real-world SaaS with multi-tenancy patterns

## Official Documentation

- [Stripe Docs — Subscriptions](https://stripe.com/docs/billing/subscriptions/overview) — lifecycle, webhooks, customer portal
- [Supabase Row Level Security](https://supabase.com/docs/guides/database/row-level-security) — RLS policies for multi-tenancy
- [Clerk Docs — Organizations](https://clerk.com/docs/organizations/overview) — tenant model, roles, invitations
- [Next.js Docs](https://nextjs.org/docs) — App Router, middleware for tenant routing
- [Stripe Metered Billing](https://stripe.com/docs/billing/subscriptions/usage-based) — usage-based pricing implementation
