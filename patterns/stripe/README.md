# Stripe Integration Patterns

> Pattern library for Stripe integrations beyond subscription billing. See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring and lifecycle.
>
> **Scope:** This file covers Stripe Connect (marketplace payments), Stripe Elements (custom checkout UI), Stripe Customer Portal (self-service plan management), and Stripe Radar (fraud). For subscription lifecycle, webhook idempotency, metered billing, and trial periods, see [`../billing/README.md`](../billing/README.md).

## Overview

Patterns for Stripe integrations where you need more than a standard checkout flow. Connect enables marketplace and platform payment splitting. Elements gives full control over the checkout UI without building PCI-compliant card handling. Customer Portal offloads plan management to Stripe's hosted UI. Radar applies rule-based and ML fraud screening before charge attempt.

---

## Pattern: Stripe Connect — Marketplace Payments

**Problem:** A marketplace platform collects payment from a buyer and must route a portion to the seller, retaining a platform fee, without the platform ever handling funds directly.

**Solution:** Use Stripe Connect with `destination charges`. The platform collects the full charge on the platform account and pushes a portion to the connected seller account in the same API call.

**Architecture:**
```
Buyer pays platform  →  stripe.paymentIntents.create(
                           amount: 10000,                 // £100
                           transfer_data: {
                             destination: seller.stripeAccountId,
                             amount: 9000,               // £90 to seller
                           }                             // £10 platform fee
                         )
```

**Implementation Notes:**
- Onboard sellers with Stripe Connect Express (fastest) or Custom (most control). Express handles identity verification; Custom requires you to build the KYC flow.
- Store the seller's `stripe_account_id` on your platform's seller record.
- Use `on_behalf_of` to set the seller as the merchant of record — their name appears on the buyer's bank statement.
- For payouts, Connect handles the seller's bank transfer automatically based on their payout schedule. Do not build a payout system yourself.
- Apply `application_fee_amount` instead of `transfer_data.amount` when you want Stripe to calculate the split automatically.

**Example:**
```typescript
import Stripe from "stripe";
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

async function createMarketplaceCharge({
  amount,
  currency,
  paymentMethodId,
  sellerStripeAccountId,
  platformFeePercent,
}: {
  amount: number; // in smallest currency unit (pence, cents)
  currency: string;
  paymentMethodId: string;
  sellerStripeAccountId: string;
  platformFeePercent: number; // e.g. 0.10 for 10%
}) {
  const platformFee = Math.round(amount * platformFeePercent);

  return stripe.paymentIntents.create({
    amount,
    currency,
    payment_method: paymentMethodId,
    confirm: true,
    application_fee_amount: platformFee,
    transfer_data: {
      destination: sellerStripeAccountId,
    },
    on_behalf_of: sellerStripeAccountId,
  });
}
```

**Common Mistakes:**
- Transferring money as a separate step after the charge — use `transfer_data` in the same PaymentIntent to keep it atomic.
- Not handling `account.updated` webhooks — seller payout schedules and verification status change; update your DB.
- Building your own payout splitting logic outside Stripe — creates reconciliation hell and potential regulatory issues.

**Security Considerations:**
- Never expose the seller's `stripe_account_id` to buyers — it is internal platform state.
- Validate that the seller account belongs to your platform before charging on their behalf. A compromised buyer could inject a different `destination`.
- Require seller identity verification to be complete before enabling payouts (`payouts_enabled: true` on the Account object).

**Testing:**
Use Stripe test mode with test Connect accounts. Create a platform charge, verify the transfer appears on the connected account, and check the platform fee. Test the failure path: a charge where the connected account is not enabled for payouts.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Stripe Elements — Custom Checkout UI

**Problem:** Stripe Checkout's hosted page covers most cases but you need the checkout embedded in your own UI — different layout, multi-step flow, or branded experience — without building PCI-compliant card handling yourself.

**Solution:** Use Stripe Elements to render the card input as a Stripe-hosted iframe within your own page. You collect a `PaymentMethod` from Elements and send only the ID to your server, which creates the charge. Card data never touches your server.

**Architecture:**
```
Frontend:
  loadStripe(publishableKey)
  → elements.create('card')
  → stripe.createPaymentMethod({ type: 'card', card })
  → POST /api/checkout { paymentMethodId }

Backend:
  stripe.paymentIntents.create({ payment_method: id, confirm: true })
  → return { clientSecret } if 3DS required
  → stripe.confirmCardPayment(clientSecret) on frontend
```

**Implementation Notes:**
- Use `stripe.confirmCardPayment` for Strong Customer Authentication (3DS) — do not skip it; required in the EU.
- Use `appearance` API to match your design system — font, colors, border radius. Do not override Element CSS directly.
- Use `PaymentElement` (newer, handles all payment methods) rather than `CardElement` (card-only) for new integrations.
- Always handle `payment_intent.status === 'requires_action'` on the server — not all 3DS completions happen synchronously.

**Example:**
```tsx
// Frontend — React with Stripe.js
import { Elements, PaymentElement, useStripe, useElements } from "@stripe/react-stripe-js";
import { loadStripe } from "@stripe/stripe-js";

const stripePromise = loadStripe(process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!);

function CheckoutForm({ clientSecret }: { clientSecret: string }) {
  const stripe = useStripe();
  const elements = useElements();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!stripe || !elements) return;

    const { error } = await stripe.confirmPayment({
      elements,
      confirmParams: { return_url: `${window.location.origin}/order-complete` },
    });

    if (error) {
      // Show error to user; error.message is safe to display
      console.error(error.message);
    }
    // On success, Stripe redirects to return_url
  }

  return (
    <form onSubmit={handleSubmit}>
      <PaymentElement />
      <button type="submit">Pay now</button>
    </form>
  );
}

export function StripeCheckout({ clientSecret }: { clientSecret: string }) {
  return (
    <Elements stripe={stripePromise} options={{ clientSecret, appearance: { theme: "stripe" } }}>
      <CheckoutForm clientSecret={clientSecret} />
    </Elements>
  );
}
```

```typescript
// Backend — create PaymentIntent, return clientSecret
export async function POST(req: Request) {
  const { amount, currency } = await req.json();
  const paymentIntent = await stripe.paymentIntents.create({
    amount,
    currency,
    automatic_payment_methods: { enabled: true },
  });
  return Response.json({ clientSecret: paymentIntent.client_secret });
}
```

**Common Mistakes:**
- Returning the PaymentIntent `id` (not `client_secret`) to the frontend — Elements requires the `client_secret`.
- Not supporting `requires_action` state — payments requiring 3DS appear to succeed server-side but are not captured.
- Injecting `process.env.STRIPE_SECRET_KEY` into a client bundle — server key must never reach the browser.

**Security Considerations:**
- The `client_secret` authorizes payment confirmation for one specific PaymentIntent. Treat it like a short-lived token — do not cache or reuse it.
- Always verify the final payment status server-side via webhook (`payment_intent.succeeded`) before fulfilling an order. Do not trust only the client-side redirect.

**Testing:**
Use Stripe's test card numbers (`4242 4242 4242 4242`, `4000 0025 0000 3155` for 3DS). Assert that a 3DS card triggers the authentication modal and that the order is not fulfilled until the `payment_intent.succeeded` webhook fires.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Stripe Customer Portal

**Problem:** Users need to upgrade, downgrade, cancel, or update their payment method. Building these flows is repetitive and must match Stripe's subscription state exactly.

**Solution:** Use Stripe's hosted Billing Portal. Create a portal session from your backend and redirect the user. All plan changes fire webhooks that you already handle in the subscription lifecycle pattern.

**Implementation Notes:**
- Configure the portal in the Stripe Dashboard: which plans users can switch to, whether cancellation is allowed, and how to handle proration.
- Portal sessions expire after a short window (typically 5 minutes). Always create a fresh session immediately before redirecting.
- The portal fires the same webhooks as any subscription update — `customer.subscription.updated`, `customer.subscription.deleted` — so no additional handling is needed if the subscription lifecycle pattern is already implemented.

**Example:**
```typescript
export async function POST(req: Request) {
  const session = await auth(); // get current user
  const user = await db.user.findUnique({ where: { id: session.userId } });

  const portalSession = await stripe.billingPortal.sessions.create({
    customer: user.stripeCustomerId,
    return_url: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard`,
  });

  return Response.json({ url: portalSession.url });
}
```

```tsx
// Client
async function openBillingPortal() {
  const { url } = await fetch("/api/billing/portal", { method: "POST" }).then((r) => r.json());
  window.location.href = url;
}
```

**Common Mistakes:**
- Caching the portal URL — it expires. Generate a new session on each click.
- Assuming portal changes take effect immediately — they fire webhooks asynchronously. Do not re-read the subscription from Stripe immediately after redirect.
- Not configuring the portal in the Dashboard before going live — it defaults to showing all plans.

**Security Considerations:**
- Authenticate the request before creating a portal session. The portal gives full billing control. Never create a session for a `stripeCustomerId` that is not the authenticated user's.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Stripe Radar — Fraud Prevention

**Problem:** Card testing attacks (trying stolen cards in small amounts) and fraudulent purchases create chargebacks, fee increases, and Stripe account risk.

**Solution:** Use Stripe Radar's built-in ML scoring combined with custom rules. Radar scores every charge automatically; add rules to block or review high-risk patterns specific to your business.

**Implementation Notes:**
- Enable Radar for Fraud Teams (requires Stripe Dashboard configuration).
- Add custom Radar rules for patterns specific to your business: unusual purchase amounts, new accounts buying high-value items, multiple cards on one IP.
- Use `metadata` on PaymentIntents to pass signals to Radar: user account age, previous order count, verified email flag.
- Set up a `radar.early_fraud_warning.created` webhook to automatically refund flagged charges before they escalate to chargebacks.
- Review blocked charges in the Radar dashboard before adding rules to allowlists.

**Example:**
```typescript
// Pass metadata signals to Radar
const paymentIntent = await stripe.paymentIntents.create({
  amount,
  currency,
  payment_method: paymentMethodId,
  confirm: true,
  metadata: {
    user_id: userId,
    account_age_days: String(accountAgeDays),
    previous_order_count: String(previousOrders),
    email_verified: String(emailVerified),
  },
  radar_options: {
    // Pass a session token if using Stripe.js on the frontend for device fingerprinting
    session: radarSessionToken,
  },
});
```

```typescript
// Webhook: auto-refund early fraud warnings
async function handleEarlyFraudWarning(warning: Stripe.Radar.EarlyFraudWarning) {
  if (warning.actionable) {
    await stripe.refunds.create({ payment_intent: warning.payment_intent as string });
    await db.order.update({
      where: { stripePaymentIntentId: warning.payment_intent as string },
      data: { status: "refunded_fraud" },
    });
  }
}
```

**Common Mistakes:**
- Not passing metadata signals — Radar's ML has less signal and scores less accurately.
- Ignoring early fraud warnings — they convert to chargebacks if not refunded within 24 hours.
- Writing overly broad block rules — blocks legitimate customers; start with "review" rules before "block".

**Security Considerations:**
- Use Stripe.js `stripe.createRadarSession()` to collect device fingerprinting on the frontend. This signal significantly improves fraud detection and requires no PII.
- Do not expose Radar review decisions or fraud scores in API responses — this information could be used to tune around your rules.

**Score:** TBD (see pattern-lifecycle.md)

## Official References
- [Stripe Connect Docs](https://stripe.com/docs/connect) — marketplace and platform payments
- [Stripe Elements Docs](https://stripe.com/docs/elements) — custom payment UI
- [Stripe Billing Portal Docs](https://stripe.com/docs/customer-management) — self-service portal
- [Stripe Radar Docs](https://stripe.com/docs/radar) — fraud prevention
- [Stripe Testing Docs](https://stripe.com/docs/testing) — test cards and scenarios
