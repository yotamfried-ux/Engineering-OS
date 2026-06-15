# Billing Patterns

> Pattern library for subscription billing, webhooks, and usage metering. See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring and lifecycle.

## Overview

Patterns for integrating with Stripe and managing the full subscription lifecycle: provisioning on signup, responding to payment events idempotently, charging based on usage, and managing trial periods. All patterns treat Stripe as the source of truth for subscription state.

---

## Pattern: Subscription Lifecycle (Stripe)

**Problem:** User subscription state (active, past_due, canceled) must stay synchronized between Stripe and the application DB, even when users upgrade, downgrade, or fail to pay.

**Solution:** Treat Stripe webhooks as the single authoritative update path. Never infer subscription state from the checkout response alone — always wait for the webhook to update the DB.

**Architecture:**
```
User clicks Subscribe  →  Stripe Checkout Session  →  payment captured
Stripe fires webhook:  →  customer.subscription.created    → provision access
                       →  invoice.payment_failed           → send dunning email
                       →  customer.subscription.updated    → update plan in DB
                       →  customer.subscription.deleted    → revoke access
```

**Implementation Notes:**
- Store `stripeCustomerId`, `stripeSubscriptionId`, `status`, `currentPeriodEnd`, and `planId` on the user/org.
- Use Stripe's `expand` on the subscription object to avoid extra API calls in the webhook handler.
- Never derive "has active subscription" from a local timestamp alone — `currentPeriodEnd` can drift; use `status === 'active' || status === 'trialing'`.

**Example Code:**
```typescript
async function handleSubscriptionUpdated(subscription: Stripe.Subscription) {
  await db.subscription.upsert({
    where: { stripeSubscriptionId: subscription.id },
    create: {
      stripeSubscriptionId: subscription.id,
      stripeCustomerId: subscription.customer as string,
      status: subscription.status,
      planId: subscription.items.data[0].price.id,
      currentPeriodEnd: new Date(subscription.current_period_end * 1000),
    },
    update: {
      status: subscription.status,
      planId: subscription.items.data[0].price.id,
      currentPeriodEnd: new Date(subscription.current_period_end * 1000),
    },
  });
}
```

**Common Mistakes:**
- Provisioning access based on the checkout session redirect — the redirect fires before payment settles.
- Not handling `past_due` — users in grace period should retain access but receive warnings.
- Updating the DB directly from the Stripe Dashboard without going through the webhook flow.

**Security Considerations:**
- Always verify the Stripe webhook signature before processing (see Webhook Idempotency pattern).
- Never expose `stripeCustomerId` or `stripeSubscriptionId` in client-facing API responses.

**Testing Strategy:**
Use Stripe's webhook CLI to replay events locally. Test all transitions: created → active → past_due → canceled → active (reactivation). Assert DB state after each event.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Webhook Idempotency

**Problem:** Stripe (and other providers) deliver webhooks at-least-once. Processing the same event twice can double-charge users, send duplicate emails, or create duplicate records.

**Solution:** Store processed event IDs in the DB. On each incoming webhook, check if the event ID was already processed — if so, return 200 immediately without re-processing.

**Architecture:**
```
POST /webhooks/stripe
  → verify signature
  → check DB: SELECT id FROM processed_events WHERE event_id = ?
    → found:    return 200 (already processed)
    → not found: process event → INSERT processed_event → return 200
```

**Implementation Notes:**
- Insert the event ID before processing (not after) to handle crashes mid-processing — use a status column (`processing`, `done`, `failed`).
- Set a TTL on processed event records — 30 days is enough for Stripe's retry window.
- Return HTTP 200 even for duplicate events — a non-200 causes Stripe to retry again.

**Example Code:**
```typescript
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export async function stripeWebhook(req: Request, res: Response) {
  const sig = req.headers['stripe-signature'] as string;
  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, process.env.STRIPE_WEBHOOK_SECRET!);
  } catch {
    return res.status(400).json({ error: 'Invalid signature' });
  }

  // Idempotency check
  const existing = await db.processedEvent.findUnique({ where: { eventId: event.id } });
  if (existing) return res.status(200).json({ received: true, duplicate: true });

  await db.processedEvent.create({ data: { eventId: event.id, status: 'processing' } });

  try {
    await processEvent(event);
    await db.processedEvent.update({ where: { eventId: event.id }, data: { status: 'done' } });
  } catch (err) {
    await db.processedEvent.update({ where: { eventId: event.id }, data: { status: 'failed', error: String(err) } });
    // Still return 200 so Stripe stops retrying — handle in dead-letter queue
  }

  return res.status(200).json({ received: true });
}
```

**Common Mistakes:**
- Processing the event then inserting the ID — a crash between the two causes double-processing on retry.
- Returning non-200 on processing errors — causes Stripe to retry indefinitely.
- Not verifying the signature — any caller can POST fake events.

**Security Considerations:**
- Use `req.rawBody` (the raw buffer) for signature verification — parsed JSON won't match.
- Rotate webhook signing secrets via Stripe's rollover mechanism without downtime.

**Testing Strategy:**
Send the same event ID twice and assert only one DB record is created and one email sent. Test signature validation with a tampered payload. Test the `failed` status path.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Metered Billing

**Problem:** Usage-based pricing requires tracking how much each customer uses each month and charging accordingly — without accumulating errors or missing usage events.

**Solution:** Record usage events to a local ledger as they occur. A nightly job (or real-time) reports aggregated usage to Stripe's metered billing API. Use Stripe's `action: 'set'` (not `'increment'`) to make reporting idempotent.

**Architecture:**
```
API call  →  record UsageEvent { orgId, metric, quantity, timestamp }
Cron job  →  aggregate usage per org per billing period
           →  POST stripe.subscriptionItems.createUsageRecord(itemId, { quantity, action: 'set' })
```

**Implementation Notes:**
- Use `action: 'set'` when reporting cumulative totals — idempotent on retry. Use `action: 'increment'` only for fire-and-forget event streams.
- Report usage before the billing period ends, not at midnight of the last day — Stripe needs time to finalize.
- Store the Stripe usage record ID in your DB to correlate with invoices.

**Example Code:**
```typescript
async function reportUsage(orgId: string, billingPeriodEnd: Date) {
  const subscription = await db.subscription.findUnique({ where: { orgId } });
  const total = await db.usageEvent.aggregate({
    where: { orgId, createdAt: { lte: billingPeriodEnd } },
    _sum: { quantity: true },
  });

  await stripe.subscriptionItems.createUsageRecord(
    subscription!.stripeItemId,
    {
      quantity: total._sum.quantity ?? 0,
      timestamp: Math.floor(billingPeriodEnd.getTime() / 1000),
      action: 'set', // idempotent
    }
  );
}
```

**Common Mistakes:**
- Using `action: 'increment'` for batch reporting — double-counts on retry.
- Not recording usage locally first — if the Stripe call fails, usage is lost.
- Reporting usage after the billing period closes — missed charges.

**Security Considerations:**
- Validate that the `orgId` in the usage event matches the authenticated org — prevent reporting usage under another org's subscription.

**Testing Strategy:**
Test aggregate query returns correct total. Mock Stripe and assert `action: 'set'` is used. Test that running the job twice in the same period does not double-count.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Trial Period Management

**Problem:** Free trials need clear start/end tracking, automatic conversion (or cancellation), and communication to users as their trial approaches expiry.

**Solution:** Set trial end in Stripe at subscription creation. Stripe fires `customer.subscription.trial_will_end` 3 days before and `customer.subscription.updated` when the trial converts or ends. Handle both webhooks to update local state and send emails.

**Architecture:**
```
Signup  →  stripe.subscriptions.create({ trial_period_days: 14 })
         →  subscription.status = 'trialing', trialEnd = now + 14 days
Day 11  →  webhook: trial_will_end → send "3 days left" email
Day 14  →  webhook: subscription.updated (status: 'active')   → provision paid plan
        OR  webhook: subscription.deleted (no payment method)  → downgrade to free
```

**Implementation Notes:**
- Store `trialEndsAt` locally for UI display (show countdown, CTA to add payment method).
- Do not require a payment method at trial start for low-friction signups — collect it before trial ends via a Stripe Checkout link.
- Use Stripe's `trial_settings.end_behavior` to control what happens when a trial ends without payment: `pause` vs. `cancel`.

**Example Code:**
```typescript
async function startTrial(customerId: string, priceId: string) {
  const subscription = await stripe.subscriptions.create({
    customer: customerId,
    items: [{ price: priceId }],
    trial_period_days: 14,
    trial_settings: { end_behavior: { missing_payment_method: 'cancel' } },
    payment_settings: { save_default_payment_method: 'on_subscription' },
  });

  await db.subscription.update({
    where: { stripeCustomerId: customerId },
    data: {
      status: 'trialing',
      trialEndsAt: new Date(subscription.trial_end! * 1000),
    },
  });

  return subscription;
}
```

**Common Mistakes:**
- Granting trial access based on a local date check rather than Stripe's `status: 'trialing'` — clocks drift.
- Not handling the `trial_will_end` webhook — users churn because they forgot to add a card.
- Extending trials by modifying `trialEndsAt` locally without updating Stripe.

**Security Considerations:**
- Do not allow users to self-extend trials via the API; only extend via support workflows with audit logging.

**Testing Strategy:**
Use Stripe test clock to simulate time advancing. Test trial creation, `trial_will_end` email trigger, and both end-of-trial paths (payment success and no card on file).

**Score:** TBD (see pattern-lifecycle.md)
