# Communication Patterns

> **Content migrated.** The patterns previously in this file have moved to [`patterns/integrations/`](../integrations/README.md).
>
> | Pattern | New location |
> |---|---|
> | Transactional Email | [`patterns/integrations/email/`](../integrations/email/README.md) |
> | Push Notifications | [`patterns/integrations/notifications/`](../integrations/notifications/README.md) |
> | In-App Notifications | [`patterns/integrations/notifications/`](../integrations/notifications/README.md) |
> | SMS Verification (OTP) | [`patterns/integrations/messaging/`](../integrations/messaging/README.md) |

This file is kept as a redirect. Do not add new patterns here.

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

**Example Code:**
```typescript
import { Resend } from 'resend';
import { WelcomeEmailTemplate } from './templates/welcome';

const resend = new Resend(process.env.RESEND_API_KEY);

export async function sendWelcomeEmail(user: { name: string; email: string }) {
  const { data, error } = await resend.emails.send({
    from: 'Acme <noreply@acme.com>',
    to: user.email,
    subject: `Welcome to Acme, ${user.name}!`,
    react: WelcomeEmailTemplate({ name: user.name }),
  });

  if (error) throw new Error(`Email failed: ${error.message}`);

  await db.emailLog.create({
    data: { to: user.email, type: 'welcome', externalId: data!.id },
  });
}
```

**Common Mistakes:**
- Sending emails synchronously in request handlers — a provider timeout causes API timeouts.
- Hard-coding provider credentials in templates or controllers.
- Not logging sent emails — impossible to debug delivery issues or audit communications.

**Security Considerations:**
- Validate email addresses before sending to prevent email injection.
- Use signed, time-limited unsubscribe tokens (`hmac(userId, secret)`) — never expose raw user IDs.
- Honor unsubscribe requests within 10 business days (CAN-SPAM / GDPR requirement).

**Testing Strategy:**
Unit-test template rendering with snapshot tests. Integration-test the mailer with a mock provider. E2e test the full flow using Mailpit or similar local SMTP catcher.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Push Notifications

**Problem:** Mobile apps need to deliver timely alerts even when the app is not in the foreground, without managing the complexity of APNs and FCM directly.

**Solution:** Store device tokens in the DB (one user can have many devices). Send via a unified provider (Firebase FCM, which handles both APNs and Android). Handle token refresh and expired-token cleanup.

**Architecture:**
```
App launches  →  request permission  →  get FCM token  →  POST /devices { token, platform }
Server event  →  retrieve tokens for userId  →  fcm.sendMulticast({ tokens, notification })
FCM           →  delivers to APNs (iOS) or directly (Android)
Response      →  remove expired tokens from DB (error code: UNREGISTERED)
```

**Implementation Notes:**
- Store `{ userId, token, platform, createdAt }` — one user can have multiple devices.
- Use `sendMulticast` for bulk sends; process the response to remove failed tokens.
- Include a `data` payload alongside the `notification` payload so the app can navigate to the right screen on tap.

**Example Code:**
```typescript
import * as admin from 'firebase-admin';

const messaging = admin.messaging();

export async function sendPushNotification(
  userId: string,
  { title, body, data }: { title: string; body: string; data?: Record<string, string> }
) {
  const devices = await db.device.findMany({ where: { userId } });
  if (!devices.length) return;

  const response = await messaging.sendEachForMulticast({
    tokens: devices.map(d => d.token),
    notification: { title, body },
    data,
    apns: { payload: { aps: { badge: 1 } } },
  });

  // Clean up invalid tokens
  const expiredTokens = response.responses
    .map((r, i) => r.error?.code === 'messaging/registration-token-not-registered' ? devices[i].token : null)
    .filter(Boolean);

  if (expiredTokens.length) {
    await db.device.deleteMany({ where: { token: { in: expiredTokens as string[] } } });
  }
}
```

**Common Mistakes:**
- Not removing expired tokens — causes failed sends to accumulate and slows down batch delivery.
- Sending sensitive data in the `notification` payload — visible in the notification tray and system logs.
- Relying only on push notifications without a fallback (in-app or email) for critical alerts.

**Security Considerations:**
- Store FCM tokens encrypted at rest — they are not credentials but can fingerprint users.
- Never include PII (email, name, account details) in the push payload.
- Verify that the `userId` in the device registration request matches the authenticated user.

**Testing Strategy:**
Mock Firebase Admin SDK. Test multicast with mixed valid/invalid tokens and assert invalid tokens are removed. Test that zero-device users do not cause errors.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: In-App Notifications

**Problem:** Users need to see activity alerts (mentions, approvals, comments) inside the app in real time, with a persistent read/unread feed they can access later.

**Solution:** Store notifications in a DB table with `userId`, `type`, `payload`, and `readAt`. Deliver real-time updates via Server-Sent Events or WebSockets. Mark as read on explicit action.

**Architecture:**
```
Event occurs  →  INSERT notification { userId, type, payload }
              →  emit SSE/WebSocket event to connected user
User opens feed  →  GET /notifications (paginated, unread first)
User clicks      →  PATCH /notifications/:id/read
Badge count      →  SELECT COUNT(*) WHERE userId = ? AND readAt IS NULL
```

**Implementation Notes:**
- Use cursor-based pagination on `createdAt DESC` for the feed.
- Aggregate counts with a cached counter (Redis INCR/DECR) rather than a COUNT query on every poll.
- SSE is simpler than WebSockets for one-way server-to-client delivery — no bidirectional protocol needed.

**Example Code:**
```typescript
// SSE endpoint
app.get('/notifications/stream', requireAuth, (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  const userId = req.user.id;
  const listener = (event: NotificationEvent) => {
    if (event.userId === userId) {
      res.write(`data: ${JSON.stringify(event)}\n\n`);
    }
  };

  notificationEmitter.on('notification', listener);
  req.on('close', () => notificationEmitter.off('notification', listener));
});

// Create and broadcast
async function createNotification(userId: string, type: string, payload: object) {
  const notification = await db.notification.create({
    data: { userId, type, payload: JSON.stringify(payload) },
  });
  notificationEmitter.emit('notification', { userId, ...notification });
  return notification;
}
```

**Common Mistakes:**
- Polling the DB for new notifications every few seconds — generates enormous query load at scale.
- Not paginating the notification feed — initial load fetches thousands of old notifications.
- Missing a `readAll` endpoint — users must individually click every notification.

**Security Considerations:**
- Verify that the `userId` in the SSE connection matches the authenticated user — prevent subscribing to another user's feed.
- Do not include sensitive data in `payload` that the recipient should not see.

**Testing Strategy:**
Test notification creation inserts a DB record. Test SSE stream delivers the event to the right user only. Test badge count decrements on mark-as-read. Test `readAll` marks all as read.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: SMS Verification

**Problem:** Phone number verification (and 2FA) requires sending a one-time passcode via SMS and validating it within a short window — without leaking the code or allowing brute force.

**Solution:** Generate a cryptographically random OTP, store a hash of it in Redis with a TTL, send the raw OTP via an SMS provider (Twilio, AWS SNS), and validate on submission.

**Architecture:**
```
POST /auth/phone/send   → generate OTP → store SHA256(OTP) in Redis (TTL 10min) → SMS user
POST /auth/phone/verify → SHA256(input) == Redis value? → verify → delete key → mark phone as verified
```

**Implementation Notes:**
- Store the hash, not the raw OTP, in Redis — a Redis dump doesn't expose active OTPs.
- Rate-limit the send endpoint by phone number: max 3 sends per 10 minutes.
- Rate-limit the verify endpoint: max 5 attempts per OTP; delete the key after 3 failures to force resend.
- OTP should be 6 digits numeric for usability (not alphanumeric) — users type it on mobile.

**Example Code:**
```typescript
import twilio from 'twilio';
import crypto from 'crypto';

const client = twilio(process.env.TWILIO_SID, process.env.TWILIO_TOKEN);

function hashOtp(otp: string) {
  return crypto.createHash('sha256').update(otp).digest('hex');
}

export async function sendVerification(phone: string) {
  const otp = String(Math.floor(100_000 + Math.random() * 900_000)); // 6-digit
  await redis.set(`otp:${phone}`, hashOtp(otp), { EX: 600 }); // 10 min TTL
  await client.messages.create({
    to: phone,
    from: process.env.TWILIO_PHONE,
    body: `Your verification code is ${otp}. Expires in 10 minutes.`,
  });
}

export async function verifyCode(phone: string, code: string): Promise<boolean> {
  const stored = await redis.get(`otp:${phone}`);
  if (!stored || stored !== hashOtp(code)) return false;
  await redis.del(`otp:${phone}`);
  return true;
}
```

**Common Mistakes:**
- Storing raw OTPs in Redis or the DB — exposure compromises active verification codes.
- Not deleting the OTP after successful verification — allows the same code to be reused.
- Using predictable OTPs (e.g., sequential) — trivially guessable.

**Security Considerations:**
- Use E.164 format for phone numbers and validate them before sending.
- Never log OTP values — only log that a send was initiated and to which number (masked).
- Implement account lockout after repeated failed verifications.

**Testing Strategy:**
Test successful verification deletes the Redis key. Test expired OTP returns false. Test wrong code increments failure counter. Test rate limiting blocks after N sends.

**Score:** TBD (see pattern-lifecycle.md)

## Official References
- [Resend Docs](https://resend.com/docs) — developer-first transactional email API
- [Twilio Docs](https://www.twilio.com/docs) — SMS, voice, WhatsApp messaging API
- [Pusher Docs](https://pusher.com/docs) — real-time WebSocket messaging
- [Web Push RFC 8030](https://tools.ietf.org/html/rfc8030) — push notification standard
- [Postmark Docs](https://postmarkapp.com/developer) — transactional email with delivery guarantees
