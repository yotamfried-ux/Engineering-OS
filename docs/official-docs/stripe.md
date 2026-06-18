# Stripe — Official Documentation Index

## Official Documentation
**Primary:** https://stripe.com/docs
**GitHub:** https://github.com/stripe
**Changelog:** https://stripe.com/docs/changelog
**API Reference:** https://stripe.com/docs/api

---

## Key Sections (Recommended Reading Order)

1. [How Stripe Works](https://stripe.com/docs/payments/accept-a-payment) — Start here to understand the Payment Intent lifecycle before touching any code.
2. [Payment Intents](https://stripe.com/docs/api/payment_intents) — The core object for all modern card flows; replaces the deprecated Charges API.
3. [Stripe Checkout](https://stripe.com/docs/payments/checkout) — Hosted page for fast integration; covers one-time and subscription modes.
4. [Webhooks](https://stripe.com/docs/webhooks) — How to receive events reliably; covers signature verification, retries, and idempotency.
5. [Subscriptions & Billing](https://stripe.com/docs/billing/subscriptions/overview) — Products, Prices, and the subscription lifecycle (trial, past_due, canceled).
6. [Customer Portal](https://stripe.com/docs/billing/subscriptions/customer-portal) — Self-service portal for subscription management; avoid building your own.
7. [Stripe Connect](https://stripe.com/docs/connect) — Multi-party payments; understand account types (Standard, Express, Custom) before designing your flow.
8. [Testing](https://stripe.com/docs/testing) — Test card numbers, webhook forwarding with Stripe CLI, and event simulation.

---

## Important APIs / Concepts

- **PaymentIntent** — Represents a single payment attempt; tracks status through `requires_payment_method` → `succeeded`.
- **SetupIntent** — Save payment methods for future use without charging immediately.
- **Customer** — Attach payment methods and subscriptions to a persistent customer object.
- **Price / Product** — `Product` is the good or service; `Price` defines the amount and billing cadence.
- **Subscription** — Recurring billing object; emits events like `customer.subscription.updated` and `invoice.payment_failed`.
- **Invoice** — Auto-generated for subscriptions; can also be created manually.
- **idempotency key** — Pass `Idempotency-Key` header on all mutating API calls to safely retry on network failures.
- **Webhook signature** — Always verify `stripe-signature` header using `stripe.webhooks.constructEvent()` before processing.
- **Stripe CLI** — `stripe listen --forward-to localhost:3000/webhook` for local webhook development.

---

## Common Patterns

- Payment flow with Checkout — see [patterns/stripe/README.md](../../patterns/stripe/README.md)
- Subscription billing with portal — see [patterns/stripe/README.md](../../patterns/stripe/README.md)
- Webhook handler setup — see [patterns/stripe/README.md](../../patterns/stripe/README.md)

---

## Related External Systems

- see [external-systems/stripe/README.md](../../external-systems/stripe/README.md)

---

## Gotchas & Version Notes

- **API versioning:** Pin your Stripe API version in the dashboard and in code; upgrades are opt-in but breaking changes accumulate.
- **Charges API is legacy:** Do not use `stripe.charges.create()` for new integrations — use Payment Intents instead.
- **Webhook raw body:** You must pass the raw (unparsed) request body to `constructEvent()`; JSON-parsed bodies will fail signature verification.
- **`payment_intent.succeeded` is not the only success event:** Also handle `charge.succeeded` and `invoice.payment_succeeded` depending on your flow.
- **Connect fee timing:** For Connect platforms, fees are taken at charge time — not at payout. Understand the difference before building.
- **Test mode vs. live mode:** Webhooks, API keys, and products are separate between modes; use separate env vars for each.
- **SCA / 3D Secure:** European regulations require 3D Secure for many card payments — Checkout and Payment Intents handle this automatically.
