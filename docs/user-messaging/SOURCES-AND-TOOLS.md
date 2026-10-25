# Authoritative sources and notification tools

**Trust:** prefer platform/vendor official documentation for API semantics, security and deliverability; use established design systems and standards for UX. Links are references, not proof of installation, availability or legal compliance.

| Domain | Source | Reason |
|---|---|---|
| Content design | [GOV.UK Design System](https://design-system.service.gov.uk/), [GOV.UK content](https://www.gov.uk/guidance/content-design), [Microsoft style](https://learn.microsoft.com/en-us/style-guide/welcome/) | plain language, forms, errors |
| Accessibility | [WCAG 2.2](https://www.w3.org/TR/WCAG22/), [WAI-ARIA](https://www.w3.org/WAI/ARIA/apg/) | status announcements, semantics |
| Mobile UI | [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/), [Material 3](https://m3.material.io/) | alerts, notifications, platform behavior |
| Event contracts | [CloudEvents](https://cloudevents.io/) | structured event envelopes |
| Observability | [OpenTelemetry](https://opentelemetry.io/docs/) | traces and lifecycle measurement |
| Email | [Resend](https://resend.com/docs), [Amazon SES](https://docs.aws.amazon.com/ses/), [SendGrid](https://www.twilio.com/docs/sendgrid) | provider integration, webhooks, bounce |
| Push | [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging), [Apple UserNotifications](https://developer.apple.com/documentation/usernotifications), [Web Push API](https://developer.mozilla.org/en-US/docs/Web/API/Push_API) | platform permissions and delivery |
| SMS / WhatsApp | [Twilio Messaging](https://www.twilio.com/docs/messaging), [WhatsApp Cloud API](https://developers.facebook.com/docs/whatsapp/cloud-api/) | opt-in, templates, delivery |
| Backend and jobs | [PostgreSQL](https://www.postgresql.org/docs/), [Supabase](https://supabase.com/docs), [Vercel Cron](https://vercel.com/docs/cron-jobs) | outbox, jobs, RLS, scheduling |
| Games | [Roblox Creator Hub](https://create.roblox.com/docs), [Roblox safety](https://create.roblox.com/docs/safety) | in-game UX and policy |
| Privacy/legal | [Israel Privacy Protection Authority](https://www.gov.il/he/departments/the_privacy_protection_authority/govil-landing-page), [ICO](https://ico.org.uk/), [FTC](https://www.ftc.gov/) | jurisdiction-specific research starting points |

## MCP versus API versus documentation

These are mostly **official docs and service APIs**, not MCP servers. A vendor may expose an MCP integration, but verify that separately and do not assume connection or write permission. Prefer the already-qualified Engineering-OS connector inventory before adding a new tool.

## Source review criteria

Verify URL, current API version, regional availability, consent obligations, provider fees, template approval rules, unsubscribe and retention behavior. Recheck before deployment; this knowledge library does not install providers or configure production credentials.
