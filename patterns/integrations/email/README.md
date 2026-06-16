# Email Integration Patterns

> Part of [`patterns/integrations/`](../README.md). Covers transactional email: provider abstraction, template management, queuing, and delivery tracking.
>
> **Related:** [`external-systems/`](../../../external-systems/) for provider-specific API references.
> See [`core/pattern-lifecycle.md`](../../../core/pattern-lifecycle.md) for scoring and lifecycle rules.

---

## Pattern: Transactional Email

**Problem:** Application code is directly coupled to an email provider's SDK, making it hard to switch providers, test email-sending logic, or ensure consistent formatting across the app.

**Solution:** Define a provider-agnostic `Mailer` interface and a template-per-event model. Inject the provider implementation. Queue emails asynchronously so a slow provider doesn't block API responses.

**Architecture:**
```
Service  →  mailer.send(WelcomeEmail({ user }))
Mailer   →  renders template  →  enqueues job
Worker   →  sends via Resend / SendGrid / SES
Provider →  fires delivery webhook  →  update delivery status in DB
```

**Implementation Notes:**
- Render email templates server-side using React Email or Handlebars — keep templates in version control.
- Always send via a background job — email delivery can take seconds.
- Track `messageId` from the provider so you can correlate delivery webhooks.
- Implement unsubscribe links using signed tokens, not raw user IDs.
- Define a `Mailer` interface (`send(template, recipient): Promise<{ messageId: string }>`). Each provider (`ResendMailer`, `SendGridMailer`, `SESMailer`) implements it. The DI layer decides which is active; all application code depends only on the interface.

**Example Code:**
```typescript
import { Resend } from 'resend';
import { WelcomeEmailTemplate } from './templates/welcome';

// Provider-agnostic interface
export interface Mailer {
  send(params: {
    to: string;
    subject: string;
    html: string;
    from?: string;
  }): Promise<{ messageId: string }>;
}

// Resend implementation
export class ResendMailer implements Mailer {
  private client: Resend;

  constructor() {
    this.client = new Resend(process.env.RESEND_API_KEY!);
  }

  async send(params: { to: string; subject: string; html: string; from?: string }) {
    const { data, error } = await this.client.emails.send({
      from: params.from ?? 'Acme <noreply@acme.com>',
      to: params.to,
      subject: params.subject,
      html: params.html,
    });

    if (error) throw new Error(`Email send failed: ${error.message}`);
    return { messageId: data!.id };
  }
}

// Application usage — depends on Mailer interface, not the concrete class
export async function sendWelcomeEmail(
  mailer: Mailer,
  user: { name: string; email: string },
) {
  const html = WelcomeEmailTemplate({ name: user.name });

  const { messageId } = await mailer.send({
    to: user.email,
    subject: `Welcome to Acme, ${user.name}!`,
    html,
  });

  await db.emailLog.create({
    data: { to: user.email, type: 'welcome', externalId: messageId },
  });
}

declare const db: {
  emailLog: { create(params: { data: Record<string, unknown> }): Promise<void> };
};
```

**Common Mistakes:**
- Sending emails synchronously in request handlers — a provider timeout causes API timeouts.
- Hard-coding provider credentials in templates or controllers.
- Not logging sent emails — impossible to debug delivery issues or audit communications.
- Coupling directly to a provider SDK (`new Resend(...)`) in business logic instead of injecting a `Mailer` interface — forces a rewrite when switching providers.

**Security Considerations:**
- Validate email addresses before sending to prevent email injection.
- Use signed, time-limited unsubscribe tokens (`hmac(userId, secret)`) — never expose raw user IDs in unsubscribe links.
- Honor unsubscribe requests within 10 business days (CAN-SPAM / GDPR requirement).
- Never log full email bodies — they may contain PII or sensitive content.

**Testing Strategy:**
Unit-test template rendering with snapshot tests. Integration-test the mailer with a mock `Mailer` implementation. For local e2e testing, use Mailpit or MailHog as a local SMTP catcher — never send real emails in test environments.

**Score:** Candidate

---

## Official References
- [Resend Docs](https://resend.com/docs) — developer-first transactional email API
- [React Email](https://react.email) — component-based email templates
- [SendGrid Node.js Client](https://github.com/sendgrid/sendgrid-nodejs) — SendGrid official SDK
- [AWS SES Developer Guide](https://docs.aws.amazon.com/ses/latest/dg/Welcome.html) — Amazon Simple Email Service
- [Postmark Docs](https://postmarkapp.com/developer) — transactional email with delivery analytics
