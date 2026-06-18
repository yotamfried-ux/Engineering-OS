# Resend

## Overview
Resend is a developer-first transactional email API built by former Vercel engineers. It sends emails via REST API or SMTP, provides React Email integration for designing templates in JSX, and includes real-time delivery logs, bounce tracking, and domain management. Designed for developer experience: TypeScript SDK, simple API, and instant setup without navigating complex dashboards. The core premise is that email should be as easy to integrate as a third-party API call.

## Capabilities
- Send transactional emails via REST API or SMTP relay
- React Email integration — design HTML emails using JSX components with live preview
- Custom domain sending with DNS management and DKIM/SPF/DMARC verification
- Delivery analytics: open tracking, click tracking, bounce and complaint tracking
- Email scheduling — send at a future timestamp via the API
- Batch sending — send to multiple recipients in a single API call
- Webhooks for delivery events (delivered, bounced, complained, opened, clicked)
- Team management with role-based API key scopes
- Email logs with real-time delivery status per message

## When to Use
- Modern SaaS or web apps sending transactional emails (welcome, password reset, invoice, notification)
- Teams already using React who want to write email templates in JSX instead of raw HTML or MJML
- Projects wanting the simplest transactional email API with minimal dashboard overhead and best developer experience
- Switching away from SendGrid or Mailgun due to complex pricing, poor DX, or unreliable deliverability

## Limitations
- No marketing or bulk email features — no list management, unsubscribes, or campaign tooling; use Mailchimp or Klaviyo for those use cases
- Free tier is limited: 3,000 emails/month and 100 emails/day — insufficient for high-volume sends without upgrading
- Newer service with a smaller ecosystem and fewer third-party integrations compared to SendGrid's decade-old ecosystem
- No built-in email editor for non-technical teammates — templates are JSX code, not drag-and-drop

## Integration Guide
1. Sign up at https://resend.com and create an API key at resend.com/api-keys
2. Add and verify your sending domain (DNS panel → add TXT/MX/DKIM records Resend provides)
3. Install the SDK: `npm install resend`
4. Send your first email using the code example below
5. Set up a webhook endpoint to receive delivery events if you need bounce handling

## Setup
```bash
npm install resend

# React Email (optional but recommended)
npm install react-email @react-email/components

# Environment variable
RESEND_API_KEY=re_your_api_key_here
```

```typescript
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

await resend.emails.send({
  from: 'noreply@yourdomain.com',
  to: 'user@example.com',
  subject: 'Welcome!',
  react: <WelcomeEmail name="Yotam" />,
});
```

## Pricing Notes
- **Free:** 3,000 emails/month, 100/day max, 1 custom domain — sufficient for early-stage products
- **Pro:** $20/month for 50,000 emails/month; additional sends at $0.40/1,000 emails
- **Scale:** Volume pricing above 50k/month — contact sales
- Watch for: the 100 emails/day hard cap on the free tier will block production sends if you exceed it; upgrade to Pro before launch

## Reference Repositories
- [resend/resend-node](https://github.com/resend/resend-node) — official Node.js/TypeScript SDK with full API coverage
- [resend/react-email](https://github.com/resend/react-email) — JSX email template framework with pre-built components and live preview server

## Official Documentation
- [Resend Docs](https://resend.com/docs) — API reference, domain setup, webhooks, and SDK guides
- [React Email Docs](https://react.email/docs) — component library, preview server, and rendering guide
- [Resend Webhooks](https://resend.com/docs/dashboard/webhooks/introduction) — event types and payload schemas

## Common Pitfalls
- **DNS propagation takes 24–48h** — adding domain DNS records does not mean they are immediately verifiable; do not attempt to send production emails until all DKIM/SPF/DMARC records show as verified in the Resend dashboard.
- **Sending from unverified domains routes to spam** — test with the default `onboarding@resend.dev` address during development; never send production emails from it.
- **Free tier daily limit is strict** — 100 emails/day is a hard cap, not a soft one; exceeding it returns a 429 error; instrument error handling for this response code even in staging.
- **React Email requires a server-side render** — the `react` field in the send call renders JSX to HTML on your server, not in the browser; ensure the rendering environment (Node.js ≥ 18) supports React Server Components or use `renderAsync` from `@react-email/render`.

## Examples
1. **Password reset email:** User triggers reset → backend calls `resend.emails.send()` with a `PasswordResetEmail` React component containing a time-limited token link → Resend returns a message ID → webhook confirms delivery or logs bounce for retry logic.
2. **Batch invoice send:** At end of billing cycle, build an array of `{ to, subject, react }` objects for each customer → call `resend.batch.send(emails)` → single API call dispatches all invoices; use webhook events to track per-invoice delivery status.
3. **Domain setup validation:** After adding DNS records, poll `resend.domains.get(domainId)` in a CI check → assert `status === 'verified'` before deploying the email-sending service to production.
