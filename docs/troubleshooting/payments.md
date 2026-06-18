# Payments — Common Bugs & Fixes

> Sources: Stripe error codes docs, Stripe webhook best practices, Paddle developer docs, LemonSqueezy docs

## Stripe — PaymentIntents

| Symptom | Root Cause | Fix |
|---|---|---|
| Duplicate charges on retry | No idempotency key on create/confirm | Set `Idempotency-Key: <uuid>` header; reuse same key on retries for the same logical operation |
| `card_declined` with no details | Issuer decline; generic error | Log `decline_code` from the error object for specific reason (insufficient_funds, do_not_honor, etc.) |
| 3DS challenge not triggered | Not using Payment Element or not confirming server-side | Use Payment Element or pass `return_url` for automatic 3DS handling |
| PaymentIntent stuck in `requires_action` | Client never confirmed the 3DS challenge | Detect `status: "requires_action"` → call `stripe.handleNextAction()` on client |
| Payment succeeded but order not fulfilled | Relying on client-side redirect, not webhook | Always fulfill orders via `payment_intent.succeeded` webhook; client redirect can be lost |

## Stripe — Webhooks

| Symptom | Root Cause | Fix |
|---|---|---|
| Spoofed events processed | Signature not verified | Use `stripe.webhooks.constructEvent(rawBody, signature, secret)`; never parse body before verifying |
| Duplicate webhook delivery | Stripe retries on non-2xx response | Make handlers idempotent; check if event already processed using `event.id` before acting |
| Webhook times out | Processing is too slow | Return 200 immediately; process event asynchronously in a queue |
| Wrong webhook secret | Using dashboard secret in test mode vs prod | Stripe CLI uses a different secret than the dashboard; check which environment you're running |

## Stripe — Subscriptions

| Symptom | Root Cause | Fix |
|---|---|---|
| User access not revoked on cancel | Only listening to `customer.subscription.deleted`, not `customer.subscription.updated` | Listen to both events; revoke on `status: "canceled"` or `cancel_at_period_end: true` depending on UX |
| Trial upgrade charges immediately | `trial_end` not set or incorrectly calculated | Set `trial_end` as Unix timestamp; verify in Stripe Dashboard before shipping |
| Invoice payment failed — user not notified | Not handling `invoice.payment_failed` event | Subscribe to this event; trigger dunning email and grace period logic |

## Paddle / LemonSqueezy

| Symptom | Root Cause | Fix |
|---|---|---|
| Webhook signature invalid | Verifying against wrong key or using parsed body | Use raw request body for HMAC verification; confirm which key (test vs live) is configured |
| Price not localized | Using hardcoded USD prices | Paddle handles tax/currency localization automatically; don't hardcode prices in your UI |
| Customer portal broken | `customer_portal_url` not generated server-side | Generate portal URL per-session via API; don't cache or share between users |

## General

| Symptom | Root Cause | Fix |
|---|---|---|
| PCI compliance failure | Storing raw card data | Never store card numbers; use tokenization (PaymentMethod ID) from the provider |
| Tax not collected | Tax not configured in payment provider | Enable Stripe Tax or Paddle's automatic tax; don't calculate tax manually |
| Refund not reflected in analytics | Refund event not processed | Subscribe to `charge.refunded` / `refund.created` to update internal records |

## Sources
- [Stripe Error Codes](https://stripe.com/docs/error-codes)
- [Stripe Webhook Best Practices](https://stripe.com/docs/webhooks/best-practices)
- [Stripe Testing](https://stripe.com/docs/testing)
- [Paddle Webhook Verification](https://developer.paddle.com/webhooks/signature-verification)
- [LemonSqueezy Webhooks](https://docs.lemonsqueezy.com/api/webhooks)
