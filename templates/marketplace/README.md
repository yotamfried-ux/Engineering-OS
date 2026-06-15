# Marketplace Template

## Overview
Use this template for a two-sided platform connecting buyers and sellers (or providers and consumers). Suited for product teams building commerce, freelance, rental, or service-booking platforms that need multi-party payments, trust mechanisms, and seller onboarding. The core complexity lies in payment splitting, commission accounting, dispute resolution, and making both sides of the market feel safe.

## Recommended Architecture Options
- **Monolith with vertical slices (buyer / seller / payment / search)** — Fastest to ship, easiest to deploy; refactor to services later once traffic patterns are known.
- **Microservices: catalog, orders, payments, messaging, search** — Independent scaling per domain; higher operational cost; recommended after product-market fit.
- **Event-driven order lifecycle** — Order state machine emits events (created, paid, fulfilled, disputed); decouples payment from fulfillment; adds replay/audit capability.

## Recommended Frameworks & Platforms
| Layer | Options |
|---|---|
| Backend | Node.js (Fastify/NestJS), Python (Django/FastAPI), Ruby on Rails |
| Frontend | Next.js, Remix, Nuxt |
| Payments | Stripe Connect (Express or Custom accounts) |
| Search | Algolia, Elasticsearch, Meilisearch, pgvector |
| Database | PostgreSQL (primary), Redis (sessions, rate limiting, queues) |
| File storage | AWS S3 / Cloudflare R2 (product images, ID docs) |
| Email / notifications | Resend, SendGrid, Twilio (SMS) |
| Background jobs | BullMQ, Sidekiq, Celery |
| Hosting | Vercel + Railway, AWS, Render |

## Required Components
- Seller onboarding: Stripe Connect OAuth or hosted onboarding link; KYC/identity verification
- Buyer checkout: Stripe Payment Intents with `application_fee_amount` or `transfer_data`
- Commission engine: configurable take-rate per category/seller tier; stored on every order
- Escrow / hold: funds captured at checkout, transferred to seller after fulfillment window
- Dispute / refund flow: buyer opens dispute, admin adjudicates, partial or full refund issued
- Review and rating system: bidirectional (buyer rates seller, seller rates buyer) with moderation
- Search with filters: category, price range, location, rating, availability; faceted
- Seller dashboard: earnings, payouts, listings CRUD, order management
- Buyer dashboard: order history, saved listings, messaging, refund requests
- Messaging / inbox: threaded conversation per listing or order; no PII leakage before booking
- Trust and safety: ID verification hook (Stripe Identity / Persona), listing moderation queue
- Payout schedule: configurable delay (e.g., T+7 days) with Stripe Connect payouts

## Security Checklist
- [ ] Stripe webhook signature verified (`stripe.webhooks.constructEvent`) before processing
- [ ] Seller can only read/write their own listings and orders — row-level security enforced
- [ ] Buyer cannot access seller bank details or personal identifiers
- [ ] Admin panel behind separate auth domain with MFA required
- [ ] PII (name, address, payment method) never logged or exposed in error messages
- [ ] File uploads scanned for malware before serving; content-type validated server-side
- [ ] Rate limiting on listing creation, messaging, and checkout endpoints
- [ ] CSRF protection on all state-changing endpoints
- [ ] Audit log: every payout, refund, and dispute action logged with actor and timestamp

## Testing Checklist
- [ ] Stripe integration tested with Stripe CLI webhook forwarding and test card suite
- [ ] Commission calculation unit-tested for edge cases (zero-value orders, 100% refunds)
- [ ] Order state machine tested for all valid and invalid transitions
- [ ] Search relevance tested with a golden dataset (expected top-N results)
- [ ] Seller onboarding flow tested end-to-end in Stripe test mode
- [ ] Dispute/refund flow tested: full refund, partial refund, no refund outcomes
- [ ] Role-based access: buyer cannot access seller admin routes (and vice versa)
- [ ] Load test: search and listing pages at 10× expected peak traffic

## Deployment Checklist
- [ ] Stripe Connect webhook endpoint registered and secret stored in secret manager
- [ ] Stripe restricted API key used (only permissions needed — no delete on live data)
- [ ] `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` in environment, not source
- [ ] Search index populated and synonym/ranking config reviewed before go-live
- [ ] CDN configured for product images (cache, resize on-the-fly via Cloudflare / imgix)
- [ ] Email domain authenticated (SPF, DKIM, DMARC) to avoid transactional email spam
- [ ] Terms of Service and refund/cancellation policy pages live and linked at checkout
- [ ] Payout schedule and commission rate confirmed in Stripe dashboard
- [ ] Monitoring alert: failed payouts, dispute spike, checkout error rate > 0.5%

## Reference Repositories
- [vercel/commerce](https://github.com/vercel/commerce) — Next.js commerce starter with multi-provider support; study the cart and checkout patterns
- [medusajs/medusa](https://github.com/medusajs/medusa) — Open-source commerce engine; well-structured order and payment abstractions
- [stripe-samples/connect-onboarding-for-standard](https://github.com/stripe-samples/connect-onboarding-for-standard) — Stripe Connect Express onboarding reference implementation

## Official Documentation
- [Stripe Connect Overview](https://stripe.com/docs/connect) — Multi-party payments, accounts, transfers, payouts
- [Stripe Connect Charges Guide](https://stripe.com/docs/connect/charges) — Destination charges vs. separate charges and transfers
- [Stripe Identity](https://stripe.com/docs/identity) — User identity verification for KYC
- [Algolia InstantSearch](https://www.algolia.com/doc/guides/building-search-ui/what-is-instantsearch/js/) — Faceted search UI components
