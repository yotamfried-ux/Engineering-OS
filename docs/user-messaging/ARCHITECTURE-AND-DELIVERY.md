# Notification system architecture and delivery reliability

Reference sources: [CloudEvents specification](https://cloudevents.io/), [OpenTelemetry](https://opentelemetry.io/docs/), [Resend docs](https://resend.com/docs), [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging), [Apple UserNotifications](https://developer.apple.com/documentation/usernotifications), [Twilio Messaging](https://www.twilio.com/docs/messaging), [Meta WhatsApp Cloud API](https://developers.facebook.com/docs/whatsapp/cloud-api/), [PostgreSQL](https://www.postgresql.org/docs/).

## Suggested architecture (adapt to scale)

Domain event → durable outbox → dispatch worker → eligibility/consent/authorization → preference + template resolver → channel adapter → provider response → delivery status callbacks → observability and support tools.

**Contracts:** `event_id`, `event_type`, `schema_version`, `tenant_id`, `recipient_id`, `resource_id`, `occurred_at`, `idempotency_key`, `correlation_id`, `locale`, `timezone`, `priority`, `expires_at`, `template_key/version`, `channel`. Do not put full appointment notes, tokens or private details into event logs.

## Reliability rules

- Commit business change and outbox atomically when possible; do not dispatch directly inside a database transaction that may roll back.
- Delivery is usually **at least once**: deduplicate by stable business event + recipient + channel + semantic template, and make downstream effects idempotent.
- Retry transient failures with exponential backoff/jitter; classify permanent failures, suppression and invalid recipients separately. Use dead-letter handling and operator requeue controls.
- Handle out-of-order and superseded events. For example, suppress an old appointment reminder after cancellation or reschedule by checking current appointment version just before sending.
- Keep `queued`, `attempted`, `provider_accepted`, `delivered`, `opened`, `actioned`, `failed`, `suppressed` distinct; not every provider supports all transitions.
- Enforce per-tenant rate limits, global caps, provider budgets and blast-radius controls. Never allow one tenant to query another tenant's notification payload.
- Support safe deep links with authorization and expiration, provider signature verification, webhook replay protection, secret rotation and safe redacted logs.
- Separate security/transactional/service/marketing categories. Consent, unsubscribe and suppression rules differ by purpose, channel and jurisdiction.
- Build a template registry, preview fixtures, localization keys, feature flags and versioned rollout; avoid writing text directly into business logic.

## Data model (conceptual)

`notification_events` (immutable event envelope), `notification_intents` (recipient/channel/template decision), `notification_deliveries` (attempts and provider IDs), `notification_preferences`, `notification_templates`, `notification_inbox` (if needed), `notification_audit` (sensitive operator actions). Store only needed PII, apply tenant-scoped RLS/authorization, retention and deletion rules.

## Provider selection

Compare delivery SLA, local coverage, consent tooling, webhook semantics, price, lock-in, localization, bounce management, rate limits, sandbox support and observability. A vendor SDK is not itself a notification architecture. Verify current API versions and vendor terms.
