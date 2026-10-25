# Appointment booking, CRM and SaaS notification scenarios

## Booking system: canonical scenarios

| Event | Recipient | Typical channel | Guardrail |
|---|---|---|---|
| Booking requested, pending approval | customer; business operator | in-app + transactional email where needed | do not say “confirmed” |
| Booking confirmed | customer; relevant staff | in-app + optional email/SMS | only after committed state |
| Booking declined | customer | in-app + permitted outbound | give next steps without invented reason |
| Upcoming appointment | customer; staff | reminder by preference | timezone, quiet hours, dedup and current booking version |
| Customer cancels | business/staff; customer receipt | in-app + transactional | avoid stale reminder |
| Business cancels | customer; assigned staff | timely outbound + in-app | clearly state refund/reschedule implications if known |
| Rescheduled / location changed | all affected participants | transactional | identify new date, timezone, location and previous version |
| Waitlist slot opens | eligible waitlisted customers | time-bounded notice | capacity race, expiry, no false reservation |
| Staff reassigned / unavailable | affected customers and staff | context-dependent | minimize employee private information |
| Late arrival / no-show | staff/customer as relevant | in-app or service notice | don't accuse until status verified |
| Recurring booking changed | affected series/occurrences | targeted notifications | precise scope and idempotency |
| Booking conflict / double-booking | operator + affected parties | urgent actionable alert | prevent privacy leakage |
| Calendar sync failure | account owner/staff | persistent in-app + support path | do not imply sync succeeded |
| Customer review request | customer | preference/marketing policy | respect consent and frequency |
| Reminder sending failed | operator/admin | operational inbox | avoid repeated spam to customer |

## CRM / multi-tenant SaaS scenarios

New lead, assignment, follow-up due, task mention, pipeline stage, owner handoff, SLA deadline, quote approval, invoice/payment state, trial expiry, usage limit, permission changes, failed integration, import/export completion, security alert, organization invite and account suspension.

**Audience segmentation:** business owner vs staff vs end customer vs platform admin; role and tenant checks must occur at delivery and when opening a deep link. Avoid emailing all staff by default. Never include another tenant's client identity in a shared notification.

## Product decisions

- Configure channels and templates per business where permitted, with safe platform defaults and restrictions for legal/security copy.
- Respect business hours, customer timezone, appointment timezone and daylight-saving transitions; store canonical UTC and timezone IDs.
- Use reminder schedule anchored to the **current** appointment version, not stale timestamps; cancel or invalidate superseded jobs.
- Support rescheduling/cancellation policies, language preferences and message budgets.
- Keep audit evidence of who initiated booking changes; do not expose private operator notes to customers.
- Model operator notification inbox separately from customer messaging where different access rules apply.

## Tori / scheduling SaaS implementation checklist

Map existing booking lifecycle and staff roles before adding triggers. Define event names, recipient matrix, template fixtures in Hebrew/English, Resend delivery callbacks if email is adopted, Supabase tenant RLS and webhook signature verification, and Vercel worker/scheduler constraints. Test duplicate webhooks, rapid reschedules, cancellation after reminder enqueue, DST and staff reassignment. Do **not** assume these services or features are configured in the target project.
