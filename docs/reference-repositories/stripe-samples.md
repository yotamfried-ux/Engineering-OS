# Stripe Samples

## Repository
**URL:** https://github.com/stripe-samples
**Owner:** Stripe
**Purpose:** Official collection of integration samples across multiple languages
demonstrating payment flows, subscription billing, webhook handling, Connect platform
patterns, and customer portal setup. Each sample is a standalone, runnable project.

## What to Learn from It
- Checkout Session creation and redirect flow (hosted vs. embedded)
- Subscription lifecycle: create, upgrade, downgrade, cancel, reactivate
- Webhook signature verification and idempotent event handling
- PaymentIntent confirmation flow with 3DS / SCA support
- Stripe Connect: account creation, onboarding links, and transfer flows
- Customer portal integration for self-serve billing management
- Trial periods, metered billing, and usage-based pricing setup
- Save and reuse payment methods with SetupIntent
- Handling failed payments: retry logic and dunning flows

## Recommended Sections / Examples
- `accept-a-payment` — canonical PaymentIntent + Checkout integration in multiple languages
- `subscription-use-cases` — subscription create/update/cancel with proration handling
- `connect-onboarding` — Express and Standard Connect account onboarding flow
- `billing-portal` — customer-facing self-serve billing portal setup
- `per-seat-subscriptions` — quantity-based subscription with seat management
- `usage-based-subscriptions` — metered billing with usage record reporting
- `set-up-subscriptions-with-checkout` — free trial → paid subscription via Checkout
- `stripe-webhooks` — webhook endpoint setup, signature verification, and event routing
- `identity` — Stripe Identity for document-based user verification

## Related Patterns
- see [patterns/api/README.md](../../patterns/api/README.md)

## Related Architectures
- see [docs/architecture-guides/](../architecture-guides/)
