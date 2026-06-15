# Booking System Template

## Overview
Use this template for reservation and scheduling platforms — appointment booking, room/resource reservations, class registrations, or any system where a finite resource is claimed for a time slot. The central challenge is preventing double-booking under concurrent load while keeping availability queries fast. Secondary concerns are calendar sync, automated reminders, and graceful cancellation/refund handling.

## Recommended Architecture Options
- **PostgreSQL advisory locks or SELECT FOR UPDATE** — Simple, no extra infrastructure; sufficient for moderate load (< 1,000 concurrent bookings/s); locks held for the duration of the write transaction.
- **Optimistic concurrency with version column** — Lower contention; booking fails if slot was claimed between read and write; client retries; good when conflicts are rare.
- **Event-sourced availability ledger** — Immutable log of reservations; replay to compute availability; highest complexity; use only when audit trail is a hard requirement (e.g., legal/medical).

## Recommended Frameworks & Platforms
| Layer | Options |
|---|---|
| Backend | Node.js (Fastify), Python (FastAPI), Go, Ruby on Rails |
| Frontend | Next.js, React + Vite |
| Database | PostgreSQL (SKIP LOCKED for queue-safe slot claiming) |
| Cache | Redis (availability cache, distributed lock with Redlock) |
| Calendar sync | Google Calendar API, Microsoft Graph API, iCal (RFC 5545) |
| Reminders | Resend / SendGrid (email), Twilio (SMS), BullMQ / Celery (scheduling) |
| Payments | Stripe Payment Intents (deposit at booking, capture on confirmation) |
| Background jobs | BullMQ, Sidekiq, Temporal |
| Hosting | Railway, Render, AWS ECS, Fly.io |

## Required Components
- Availability engine: returns open slots for a resource/provider over a date range; invalidates cache on booking
- Conflict guard: atomic slot claim using `SELECT ... FOR UPDATE SKIP LOCKED` or a distributed lock; returns 409 on conflict
- Booking state machine: `pending → confirmed → completed | cancelled | no-show`
- Calendar export: generate `.ics` file per booking; subscribe URL for iCal feed
- Google / Outlook calendar sync: write booking to provider calendar; handle event updates and deletions via push notifications / delta polling
- Reminder scheduler: configurable (e.g., 24 h and 1 h before); retry on transient failure
- Cancellation engine: respects policy (free cancel window, partial refund, no refund); triggers Stripe refund via API
- Waitlist: ordered queue per slot; auto-promote first waiter when booking is cancelled
- Admin schedule management: block-out dates, recurring availability rules (e.g., Mon–Fri 09:00–17:00)
- Reporting: utilization rate, revenue per period, cancellation rate, no-show rate

## Security Checklist
- [ ] Slot-claim endpoint is idempotent: duplicate request with same idempotency key returns existing booking, not a second charge
- [ ] User can only cancel/modify their own bookings; admin role required for others
- [ ] Calendar OAuth tokens stored encrypted; refresh token rotation handled
- [ ] Stripe webhook signature verified before processing payment events
- [ ] Personally identifiable information (name, phone) not logged at DEBUG level
- [ ] Rate limit on availability queries to prevent scraping of business schedules
- [ ] CSRF protection on booking form submission
- [ ] Admin panel behind MFA-enforced login

## Testing Checklist
- [ ] Concurrent booking test: 50 simultaneous requests for the same slot → exactly one succeeds, rest receive 409
- [ ] State machine transition tests: assert invalid transitions (e.g., `completed → confirmed`) are rejected
- [ ] Cancellation + refund: full refund within window, partial outside window, none after cutoff
- [ ] iCal feed: parsed by Thunderbird and Apple Calendar without errors
- [ ] Google Calendar sync: booking creates event; cancellation deletes it; update propagates
- [ ] Reminder job: fires at correct time; does not fire twice on retry; does not fire for cancelled bookings
- [ ] Waitlist: cancellation promotes first waiter and sends notification within 60 s
- [ ] Availability cache invalidated immediately after successful booking

## Deployment Checklist
- [ ] Database `bookings` table has a unique partial index on `(resource_id, start_time, status)` where `status != 'cancelled'`
- [ ] Redis Redlock TTL shorter than maximum expected transaction time
- [ ] Reminder job worker scaled independently from API; separate queue
- [ ] Google Calendar API credentials (OAuth app) reviewed and approved for production use
- [ ] Stripe restricted key with only Payment Intents and Refunds permissions
- [ ] Timezone handling audited: all datetimes stored as UTC; display converted client-side
- [ ] Cancellation policy page live and linked from booking confirmation email
- [ ] Alert: booking failure rate > 1%, reminder job error rate > 0

## Starter Templates

| Option | Description | Recommended |
|---|---|---|
| [calcom/cal.com](https://github.com/calcom/cal.com) | Open-source scheduling platform (Calendly alternative), 35k+ stars | ✅ Best pick |
| [calcom/cal.com/packages](https://github.com/calcom/cal.com/tree/main/packages) | Cal.com packages for embedding scheduling in your app | |
| [schedule-x/schedule-x](https://github.com/schedule-x/schedule-x) | Framework-agnostic calendar and scheduling UI component | |

**Best Pick:** [calcom/cal.com](https://github.com/calcom/cal.com) — Production SaaS reference with availability engine, team scheduling, webhooks, and calendar integrations

## Reference Repositories
- [calcom/cal.com](https://github.com/calcom/cal.com) — Open-source scheduling platform; excellent reference for availability engine, calendar integrations, and booking state machine
- [jitsi/jitsi-meet](https://github.com/jitsi/jitsi-meet) — Video conferencing scheduling integration patterns
- [temporalio/samples-typescript](https://github.com/temporalio/samples-typescript) — Durable workflow patterns applicable to booking state machines with retries
- [calcom/cal.com](https://github.com/calcom/cal.com) — open-source scheduling platform (Calendly alternative), 35k+ stars — **best pick**
- [BolajiAyodeji/cal.com-api-tutorial](https://github.com/calcom/cal.com/tree/main/packages/embeds) — Cal.com embed SDK for adding scheduling to any app

## Official Documentation
- [Google Calendar API](https://developers.google.com/calendar/api/guides/overview) — Events, push notifications, OAuth scopes
- [Cal.com Docs](https://cal.com/docs) — Scheduling platform documentation
- [Microsoft Graph Calendar API](https://learn.microsoft.com/en-us/graph/api/resources/calendar) — Outlook calendar integration
- [RFC 5545 — iCalendar](https://datatracker.ietf.org/doc/html/rfc5545) — iCal format specification for `.ics` generation
- [Stripe Payment Intents](https://stripe.com/docs/payments/payment-intents) — Two-step capture for deposits and confirmations
- [BullMQ Docs](https://docs.bullmq.io/) — Job scheduling, delayed jobs, repeatable jobs for reminders
