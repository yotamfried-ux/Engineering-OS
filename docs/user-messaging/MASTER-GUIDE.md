# User messaging — end-to-end agent master guide

## Message design workflow

1. Identify **actor, recipient, business/tenant, event, channel, urgency, intent, consent/legal basis, sensitivity and action**.
2. Inventory states: initiated, pending, success, failure, retry, canceled, expired, reversed and conflicting changes.
3. Decide if the message is needed. Choose inline UI, toast, banner, dialog, activity inbox, push, email, SMS, WhatsApp or in-game message based on urgency and user context.
4. Define a **message contract**: event ID, schema/version, tenant ID, recipient ID, resource ID, trigger timestamp, locale/timezone, category, priority, deduplication key, template version, CTA, expiration and correlation ID. Minimize payload PII.
5. Specify recipient eligibility, authorization, user preferences, quiet hours, throttling, legal opt-out/consent, frequency caps and channel fallback.
6. Design reliable dispatch: transactional outbox or equivalent, idempotency, queue/worker, retries/backoff, dead-letter queue, cancellation and provider callbacks.
7. Write contextual content: what happened, what it affects, when, who initiated it when appropriate, what to do next and how to get help. Avoid invented certainty.
8. Validate accessibility, translation, security, provider deliverability, concurrency, failure and analytics.
9. Observe queued/sent/provider-accepted/delivered/opened/actioned/failed separately, where the channel supports these states.
10. Review with product owners and applicable legal/privacy requirements before production release.

## Notification decision table

| Condition | Default | Avoid |
|---|---|---|
| Immediate validation error | inline field feedback and summary | generic modal or remote push |
| Background save succeeds | subtle toast or inline saved status | interrupting dialog |
| Destructive irreversible action | clear confirmation before action; outcome afterward | vague “Are you sure?” |
| Time-sensitive schedule change | in-app state plus appropriate transactional outbound notice | assuming email alone is sufficient |
| Security-critical access event | durable audit entry and relevant security notice | revealing secrets in previews |
| Nonurgent product news | opt-in digest or inbox | unsolicited urgent push |
| Transient outage | status banner with recovery path | repeating toasts |
| Game achievement | in-game contextual feedback | interrupting core gameplay |

## Cross-product coverage matrix

- **Account:** registration, email verification, invite, password reset, MFA, login anomaly, role change, account restriction, deletion.
- **Operations:** queued, processing, success, partial success, failed, timed out, retrying, duplicate request, degraded service, maintenance, offline/online, sync conflict.
- **Data:** unsaved changes, save failure, import/export, validation, permission denied, quota, storage, restore, archive.
- **Collaboration:** assignment, mention, approval, rejection, escalation, comment, task due, SLA breach, owner handoff.
- **Commerce:** trial start/end, subscription renewal, payment failure, invoice, refund, entitlement, cancellation.
- **Scheduling:** booking requested/confirmed, waitlist, reminder, reschedule, cancellation, no-show, late arrival, staff reassignment, capacity or location change.
- **Gaming:** matchmaking, party invite, round start/end, reward, inventory, server restart, moderation, safe social messaging.
- **Marketing:** onboarding, feature announcement, re-engagement, digest, campaign — subject to separate consent and frequency controls.

## Design quality

No message without an explicit user benefit, delivery rule, owner, privacy classification and testable expected result. Prefer one source-of-truth for event state across all channels; avoid inconsistent messages when state changes. Never assume a “sent” API response proves user receipt.
