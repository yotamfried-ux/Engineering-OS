# Unleash

## Overview
Unleash is an open-source enterprise feature flag platform and the most mature self-hosted option in the category. Originally developed by FINN.no (Norwegian car marketplace), now used by Goldman Sachs, Snyk, and thousands of engineering teams. Provides a feature toggle UI, activation strategies (percentage rollout, user segments, IP-based), variants for A/B testing, and SDKs for 20+ languages. Can be fully self-hosted on any infrastructure with a PostgreSQL database, or used as Unleash Cloud.

## Capabilities
- Feature toggles in four types: release (gradual rollout), experiment (A/B testing), ops (kill-switch), and permission (entitlement)
- Gradual rollout by percentage — sticky per user ID to prevent toggle flicker
- User/group/IP-based targeting strategies for beta programs and internal testing
- Variants for multi-variate feature flags — assign users to named variants with optional payloads
- Metrics dashboard — impression counts, exposure rates, and toggle health per flag
- Custom activation strategies via SDK plugin interface for domain-specific logic
- API-first design — everything in the UI is available via REST API
- SDKs for Node.js, Python, Java, Go, React, .NET, PHP, Ruby, iOS, Android, and 10+ more
- Unleash Edge — a lightweight proxy for CDN/edge deployments that caches flag state locally
- SSO/SAML and fine-grained RBAC on Enterprise plan

## When to Use
- Teams wanting full control over feature flag infrastructure (compliance, air-gapped, on-premise environments)
- Open-source-first engineering cultures that cannot send feature flag data to third-party SaaS
- Enterprises requiring SSO, audit logs, and fine-grained RBAC for flag management
- Production kill switches for critical features — one click to disable a broken code path without a deploy
- Gradual rollouts to user segments without sending behavioral data to an external analytics vendor

## Limitations
- Self-hosted setup requires PostgreSQL and ongoing maintenance of the Unleash server container
- UI is functional but less polished than LaunchDarkly or Statsig
- No built-in A/B test statistical analysis — flags and variants only; bring your own significance calculator
- Enterprise SSO, RBAC, and audit log features require the paid Enterprise license (open-source tier is Apache 2.0)
- Unleash Edge (proxy) requires a separate deployment to avoid direct SDK connections to the Unleash server at scale

## Integration Guide
1. Deploy Unleash via Docker: `docker run -p 4242:4242 unleashorg/unleash-server` with a PostgreSQL connection string
2. Or sign up for Unleash Cloud at https://www.getunleash.io to skip self-hosting
3. Create a frontend token (not admin token) in the Unleash UI under API Access
4. Install the SDK: `npm install unleash-proxy-client` (frontend) or `npm install unleash-client` (Node.js server)
5. Define flags in the UI before referencing them in code — referencing an undefined flag returns `false` by default
6. Never expose the admin API key client-side; use the frontend/proxy API with a frontend token for browser SDKs

## Setup
```bash
# Frontend / React
npm install unleash-proxy-client

# Node.js server-side
npm install unleash-client

# Environment variables
UNLEASH_URL=https://unleash.yourdomain.com/api
UNLEASH_CLIENT_KEY=your_frontend_or_client_key
```

```typescript
import { UnleashClient } from 'unleash-proxy-client';

const unleash = new UnleashClient({
  url: process.env.UNLEASH_URL! + '/frontend',
  clientKey: process.env.UNLEASH_CLIENT_KEY!,
  appName: 'my-app',
});

await unleash.start();

if (unleash.isEnabled('new-checkout-flow')) {
  // render new UI
}

// Multi-variate with variants
const variant = unleash.getVariant('checkout-cta-text');
// variant.name → 'control' | 'variant-a' | 'variant-b'
```

## Pricing Notes
- **Open Source:** Free forever — self-hosted, Apache 2.0 license, unlimited flags and users
- **Pro:** $80/month — Unleash Cloud hosted, 5 team seats, SSO not included
- **Enterprise:** Custom pricing — adds SSO/SAML, RBAC, audit log, and dedicated SLA
- Self-hosting is genuinely zero cost beyond your own PostgreSQL and compute; the open-source tier has no feature limits

## Reference Repositories
- [Unleash/unleash](https://github.com/Unleash/unleash) — core platform monorepo, 12k+ GitHub stars
- [Unleash/unleash-client-node](https://github.com/Unleash/unleash-client-node) — official Node.js server-side SDK
- [Unleash/proxy-client-react](https://github.com/Unleash/proxy-client-react) — React SDK with `useFlag` and `useVariant` hooks

## Official Documentation
- [Unleash Docs](https://docs.getunleash.io) — complete self-hosting, SDK, and API documentation
- [Activation Strategies Reference](https://docs.getunleash.io/reference/activation-strategies) — all targeting and rollout strategy types explained
- [Unleash Edge Docs](https://docs.getunleash.io/reference/unleash-edge) — CDN/edge proxy deployment guide

## Common Pitfalls
- **Cache the client as a singleton** — the Node.js server-side SDK polls Unleash on startup and syncs in the background; instantiating a new client per request causes thundering-herd connections and slow startup times; create once at app initialization.
- **Never use the admin API key in client-side code** — the admin key can create and delete flags; expose only the frontend token (read-only) in browser bundles.
- **Flag names are case-sensitive** — `New-Checkout-Flow` and `new-checkout-flow` are different flags; establish a lowercase-kebab-case naming convention before the first flag reaches production.
- **Default-off is not guaranteed without explicit SDK initialization** — `isEnabled()` returns `false` before `await unleash.start()` resolves; await startup before rendering flag-dependent UI or use the `ready` event.

## Examples
1. **Gradual rollout to 10% of users:** Create a release toggle `new-onboarding-v2` → add a "Gradual rollout" strategy at 10% → sticky by `userId` → monitor error rates for 24 hours → increase to 50%, then 100% → archive the flag once rollout is complete.
2. **Kill switch for a broken third-party integration:** Create an ops toggle `enable-stripe-checkout` enabled by default → wire `isEnabled('enable-stripe-checkout')` before calling Stripe SDK → when Stripe has an outage, disable the flag in Unleash UI within 30 seconds without a deploy.
3. **Beta group targeting:** Create a user segment in Unleash containing internal user IDs → add a "userWithId" strategy to the flag → only those users see the beta feature; everyone else falls through to the disabled code path.
