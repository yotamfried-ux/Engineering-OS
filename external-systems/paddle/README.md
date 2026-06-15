# Paddle

## Overview
Paddle is a Merchant of Record (MoR) billing and payments platform designed for B2B SaaS companies selling globally. As the MoR, Paddle owns the legal and financial relationship with the end customer, handling VAT collection and remittance across 200+ countries automatically — removing tax compliance burden entirely. Strong fit for SaaS selling into the EU, UK, Australia, and other VAT-heavy regions.

## Capabilities
- Subscription billing with trials, discounts, proration, and pauses
- One-time and usage-based charges via Paddle Billing (v2 API) or legacy Classic
- Paddle handles VAT, GST, and sales tax collection and remittance in all major jurisdictions as MoR
- Checkout overlay (Paddle.js) embeddable in any page without redirect
- Customer portal for self-service plan management, payment method updates, and cancellations
- Retention tools: cancellation surveys, pause-instead-of-cancel offers, win-back emails
- Webhook events covering the full subscription lifecycle
- Revenue reporting, MRR tracking, and churn analytics built into the dashboard
- Paddle Retain (formerly ProfitWell Retain) for dunning and failed payment recovery

## When to Use
- SaaS product with significant EU/UK customer base where VAT complexity would require registrations in multiple countries
- Want to remove tax compliance entirely rather than managing it via Stripe Tax or Avalara
- Need built-in dunning/retain tooling without wiring up separate services
- Selling digital products or subscriptions internationally at scale

## Limitations
- Higher effective fees than self-managed Stripe (~5% + $0.50 per transaction); worthwhile only if tax savings justify it
- Paddle Billing (v2) is the new API but some features from Paddle Classic are still being migrated — check feature parity before committing
- Less ecosystem tooling than Stripe; fewer native integrations with third-party apps
- Checkout UI is hosted/embedded and less customizable than Stripe Elements for bespoke UIs
- Payout schedule is monthly by default; faster payouts require negotiation

## Integration Guide
1. Create a Paddle account at https://paddle.com and get sandbox + production API credentials from the dashboard
2. Install Paddle.js client library: add `<script src="https://cdn.paddle.com/paddle/v2/paddle.js">` to your page
3. Install the server SDK: `npm install @paddle/paddle-node-sdk` or `pip install paddlepaddle`
4. Initialize Paddle client-side with your client-side token and open a checkout:
   ```javascript
   Paddle.Initialize({ token: "live_..." });
   Paddle.Checkout.open({ items: [{ priceId: "pri_xxx", quantity: 1 }] });
   ```
5. On the server, verify and process webhook events — set up a webhook endpoint in the Paddle dashboard and verify the signature using `paddle.webhooks.unmarshal()`
6. Store `subscription_id` and `customer_id` from the `subscription.created` event to manage the customer going forward

## Setup
```bash
# Node.js SDK (Paddle Billing v2)
npm install @paddle/paddle-node-sdk

# Python SDK
pip install paddle-billing

# Set environment variables
export PADDLE_API_KEY=your_api_key
export PADDLE_WEBHOOK_SECRET=your_webhook_secret
# Use sandbox for testing
export PADDLE_ENVIRONMENT=sandbox  # or production
```

## Pricing Notes
- **Transaction fee:** ~5% + $0.50 per transaction (negotiable at volume; exact rate in your Paddle agreement)
- **No monthly platform fee** on standard plans
- **Paddle Retain** (dunning) is bundled for accounts above a revenue threshold; otherwise available as an add-on
- Watch for: MoR fees are higher than raw Stripe, but eliminate the cost of managing tax registrations in each country — calculate total cost of ownership including tax compliance overhead before comparing
- Payouts are monthly net of Paddle's fees and any tax collected

## Reference Repositories
- [PaddleHQ/paddle-node-sdk](https://github.com/PaddleHQ/paddle-node-sdk) — official Node.js SDK for Paddle Billing
- [PaddleHQ/paddle-python-sdk](https://github.com/PaddleHQ/paddle-python-sdk) — official Python SDK
- [PaddleHQ/paddle-js-wrapper](https://github.com/PaddleHQ/paddle-js-wrapper) — typed React/JS wrapper for Paddle.js checkout

## Official Documentation
- [Paddle Developer Docs](https://developer.paddle.com) — full Paddle Billing API reference
- [Webhooks](https://developer.paddle.com/webhooks/overview) — event types and signature verification
- [Paddle.js Checkout](https://developer.paddle.com/paddlejs/overview) — client-side checkout integration
- [Migration from Classic](https://developer.paddle.com/classic/migration) — guide for moving from Paddle Classic to Billing v2

## Examples
1. **EU SaaS subscription:** User selects a plan → Paddle.js overlay opens with VAT auto-detected from IP/billing address → Paddle collects and remits German VAT on your behalf → `subscription.created` webhook triggers account provisioning — no VAT registration in Germany needed.
2. **Dunning with Paddle Retain:** Payment fails on renewal → Paddle Retain automatically retries on a smart schedule and sends branded recovery emails → if subscriber cancels, cancellation survey data feeds into churn analysis in the dashboard.
3. **Multi-seat B2B billing:** Create a price with a per-seat quantity model → sales creates a checkout link with `quantity` pre-set → on `subscription.updated` webhook (quantity change), sync seat count to your app's permission layer.
