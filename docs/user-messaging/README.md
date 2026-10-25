# User messaging & notification systems — knowledge index

**Scope:** in-product alerts, banners, toasts, dialogs, inline errors, inboxes, push, email, SMS, WhatsApp, game notifications and transactional/lifecycle communication for SaaS, CRM, appointment scheduling, mobile and Roblox. **Status:** advisory knowledge, not an executable system or mandatory gate.

## Route by task

| User intent | First read | Adjacent knowledge |
|---|---|---|
| Design notification architecture | [Architecture and delivery](ARCHITECTURE-AND-DELIVERY.md) | security, privacy, observability |
| Choose when/where to notify | [Experience and content](UX-CONTENT-AND-ACCESSIBILITY.md) | existing [human-centered UX writing](../product-experience/human-centered-ux-writing.md) |
| Booking / calendar / reminders | [Appointment scheduling](APPOINTMENTS-AND-CRM.md) | timezone, calendar, consent, operations |
| CRM or B2B SaaS messages | [Appointment scheduling and CRM](APPOINTMENTS-AND-CRM.md) | multi-tenant roles and permissions |
| Game / Roblox messages | [Games and Roblox](GAMES-AND-ROBLOX.md) | Roblox safety, economy, performance |
| Test and release notification flows | [Verification and operations](VERIFICATION-AND-OPERATIONS.md) | existing testing and launch guides |
| Compare notification providers / protocols | [Source catalog](SOURCES-AND-TOOLS.md) | vendor-specific current docs |

## Principles

1. Notify only when useful, relevant, timely and permitted; classify critical, transactional, service and promotional separately.
2. Prefer the least intrusive surface that meets urgency; allow meaningful preferences and quiet hours.
3. Deliver **truthful state**: sending a message does not prove delivery, reading, or business outcome.
4. Secure tenant boundaries and recipient identity; never leak another business's customers or appointments.
5. Treat duplication, retries, out-of-order events, provider downtime and timezone changes as expected.
6. Localize and test Hebrew RTL, accessibility, mobile widths, dynamic values and time/date formatting.
7. Instrument lifecycle and failure states while minimizing personal data.
8. Keep message templates versioned, reviewed and tied to event contracts.

Use [the master guide](MASTER-GUIDE.md) for a cross-domain decision process; open only the guides relevant to the task. Do not create a second knowledge router.
