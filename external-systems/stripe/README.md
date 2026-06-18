# Stripe

## Overview
Stripe is a payment infrastructure platform by Stripe, Inc., used by millions of businesses to accept online payments, manage subscriptions, and handle financial operations. It provides developer-first APIs covering the full payment lifecycle — from card tokenization to revenue reporting.

## Capabilities
- Accept payments via cards, bank transfers, wallets (Apple Pay, Google Pay), Buy Now Pay Later, and 135+ local payment methods
- Subscription billing with trials, proration, metered/usage-based billing, and dunning management
- Payment Intents API with built-in SCA/3DS2 compliance for European regulations
- Connect platform to route payments between multiple parties and handle marketplace payouts
- Invoicing, tax calculation (Stripe Tax), and revenue recognition (Stripe Revenue Recognition)
- Fraud detection via Stripe Radar with ML-based rules and manual review queues
- Stripe Elements / Stripe.js for PCI-compliant frontend card capture
- Webhooks with signed payloads for async event processing (payment succeeded, subscription updated, etc.)

## When to Use
- Building any SaaS, e-commerce, or marketplace product that requires real-money payment processing
- Need subscription or usage-based billing with minimal custom backend logic
- Require a single vendor for payments, invoicing, tax, and payout management
- Operating internationally and need multi-currency and local payment method support

## Limitations
- Not available in all countries (check Stripe's supported countries list); competitors like Adyen or Braintree may cover gaps
- Stripe fees (2.9% + 30¢ per successful card charge in the US) add up at high volume; negotiate custom rates above ~$1M/year
- Dispute and chargeback handling can freeze funds; mitigation requires Radar tuning
- Stripe Connect's complex fee structures and onboarding flows require careful architecture planning for marketplaces

## Integration Guide
1. Install the SDK: `npm install stripe` (Node) or `pip install stripe` (Python)
2. Create a Payment Intent server-side with amount + currency; return `client_secret` to the client
3. Use Stripe.js + Elements on the client to collect card details and confirm the PaymentIntent — card data never touches your server
4. Handle `payment_intent.succeeded` webhook to fulfill the order (do not rely on redirect alone)
5. For subscriptions: create a Customer, attach a PaymentMethod, then create a Subscription pointing to a Price object
6. Always test with Stripe's test card numbers (`4242 4242 4242 4242`) and test webhook CLI forwarding

```
stripe listen --forward-to localhost:3000/webhooks
```

Verify webhook signatures using `stripe.webhooks.constructEvent(payload, sig, secret)` before processing.

## Setup Guide
```bash
# Install Stripe CLI (macOS)
brew install stripe/stripe-cli/stripe

# Login and get test API keys
stripe login

# Install Node SDK
npm install stripe

# Install Python SDK
pip install stripe
```

Key configuration:
- Store `STRIPE_SECRET_KEY` (server-side only) and `STRIPE_PUBLISHABLE_KEY` (client-safe) in environment variables
- Set `STRIPE_WEBHOOK_SECRET` from the dashboard or `stripe listen` output
- Use separate key pairs for test and production environments
- Enable only the Stripe products you need in the Dashboard to reduce attack surface

## Pricing Notes
- **Card processing:** 2.9% + $0.30 per successful charge (US); higher for international cards (~1.5% surcharge) and currency conversion (+1%)
- **Subscriptions:** Additional 0.5% on subscription revenue (waivable at volume)
- **Stripe Tax:** 0.5% of transactions where tax is calculated
- **Connect:** 0.25% + $0.25 per active account per month for Express/Custom accounts
- **No monthly platform fees** on standard accounts; volume discounts negotiated directly with Stripe
- Watch for: dispute fees ($15/dispute), radar-for-fraud-teams addon, and data pipeline costs

## Reference Repositories
- [stripe-samples/accept-a-payment](https://github.com/stripe-samples/accept-a-payment) — end-to-end PaymentIntents integration across multiple languages
- [stripe-samples/subscription-use-cases](https://github.com/stripe-samples/subscription-use-cases) — SaaS subscription billing patterns
- [stripe-samples/connect-destination-charge](https://github.com/stripe-samples/connect-destination-charge) — marketplace split-payment flows

## Official Documentation
- [Stripe Docs Home](https://stripe.com/docs) — full API reference and guides
- [Payment Intents Guide](https://stripe.com/docs/payments/payment-intents) — core payment flow
- [Webhooks](https://stripe.com/docs/webhooks) — event handling and signature verification
- [Stripe CLI](https://stripe.com/docs/stripe-cli) — local development and webhook forwarding

## Examples
1. **SaaS subscription:** Create a `Price` (monthly, $49/mo) → user checks out via Stripe Checkout → handle `customer.subscription.created` webhook to provision access → `invoice.payment_failed` triggers dunning emails.
2. **E-commerce one-time payment:** Server creates PaymentIntent → client confirms with Elements → `payment_intent.succeeded` webhook triggers order fulfillment and shipping label generation.
3. **Marketplace payout:** Seller onboards via Stripe Connect Express → buyer charges go to platform → platform uses `transfer` to route 80% to seller after 7-day delay for disputes.
