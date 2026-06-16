# Stripe Patterns

> **Navigation note:** Stripe knowledge in Engineering OS is split intentionally across three locations. Use this guide to find the right place.

---

## Where to find Stripe knowledge

### `patterns/billing/README.md` — Implementation patterns (start here)

The primary source for Stripe code patterns. Contains:
- Subscription lifecycle (webhook-as-source-of-truth)
- Webhook idempotency (event ID deduplication, signature verification)
- Metered billing (usage ledger, `action: 'set'`)
- Trial period management (Stripe test clock, `trial_will_end`)

Use this when writing code that integrates with Stripe.

### `external-systems/stripe/README.md` — Integration reference

API overview, key objects (Customer, Subscription, PaymentIntent, Invoice), SDK setup, environment configuration, and Stripe Dashboard workflow. Also covers Stripe CLI for local webhook testing.

Use this when setting up Stripe for the first time or looking up API object structure.

### `external-systems/connectors/stripe/README.md` — Composio connector

Configuration for the Composio-managed Stripe connector. Used when Stripe actions need to be triggered via the MCP connector layer rather than direct SDK calls.

Use this when integrating Stripe into an AI agent or automation workflow via Composio.

---

## When to use which alternative billing provider

If Stripe is not the right fit, see:
- `external-systems/paddle/` — EU VAT as merchant of record; better for global SaaS
- `external-systems/lemonsqueezy/` — simple creator/indie billing; no custom VAT handling needed

The trade-off guide is in each provider's README under "When to use this instead of Stripe."

---

## Adding new Stripe patterns

New code patterns (webhook event types, payment flow variants, Stripe Connect) belong in `patterns/billing/README.md`, not here. This file exists only to clarify the split between locations.
