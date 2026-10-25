# User messaging verification, analytics and operational readiness

## Test matrix

| Scenario | Expected evidence |
|---|---|
| Valid event | one intended message per recipient/channel with correct content |
| Duplicate domain event / provider webhook | no duplicate business effect; idempotent state |
| Out-of-order cancellation / reschedule | old reminder suppressed; latest state displayed |
| Invalid recipient / wrong tenant | no send, no data leakage, audit reason |
| User opted out of marketing | marketing suppressed; essential transactional behavior evaluated by policy |
| Quiet hours and timezone/DST | schedule respects local intent and urgency rules |
| Provider outage / rate limit | bounded retry, DLQ, operational alert and no false success |
| Bounce / unsubscribe / invalid phone | suppression and safe re-entry rules |
| Mobile RTL and accessibility | readable localized text, correct focus/live announcements |
| Offline / push disabled | in-app durable state and appropriate fallback |
| Deep link expired / access revoked | authorization enforced and safe landing state |
| High-volume burst | per-tenant caps, queue lag and cost budgets |
| Security alert | no secrets/PII in previews, correct recipient |
| Billing / purchase event | state confirmed before notification |
| Audit / retention request | deletion, minimization and retention controls validated |

## Instrumentation

Track `event_created`, `intent_created`, `suppressed`, `enqueued`, `attempted`, `provider_accepted`, `delivered`, `opened`, `actioned`, `failed` with source and timestamp where supported. Monitor queue latency, send error rate, bounce/complaint rate, template failures, suppression, notification volume per user, delivery cost and actual task completion. Protect sensitive payloads in telemetry.

## Release review

For each critical journey, produce revision-specific PASS / FAIL / PARTIAL / BLOCKED / NOT TESTED, with sample event IDs and redacted provider evidence. Separate sandbox test success from live deliverability. Run staging tests before enabling outbound production sends; obtain approval before enabling paid providers, marketing campaigns or production message blasts.

Reference existing `patterns/testing/`, `patterns/security/`, `docs/launch-readiness/`, `docs/legal-compliance/` and [analytics knowledge](../product-experience/analytics-experimentation-growth.md).
