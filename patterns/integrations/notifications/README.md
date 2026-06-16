# Notification Integration Patterns

> Part of [`patterns/integrations/`](../README.md). Covers push notifications (APNs/FCM) and in-app notification feeds.
>
> **Related:** [`external-systems/`](../../../external-systems/) for provider-specific API references (Firebase, APNs).
> See [`core/pattern-lifecycle.md`](../../../core/pattern-lifecycle.md) for scoring and lifecycle rules.

---

## Pattern: Push Notifications

**Problem:** Mobile apps need to deliver timely alerts even when the app is not in the foreground, without managing the complexity of APNs and FCM directly.

**Solution:** Store device tokens in the DB (one user can have many devices). Send via a unified provider (Firebase FCM, which handles both APNs and Android). Handle token refresh and expired-token cleanup.

**Architecture:**
```
App launches  →  request permission  →  get FCM token  →  POST /devices { token, platform }
Server event  →  retrieve tokens for userId  →  fcm.sendMulticast({ tokens, notification })
FCM           →  delivers to APNs (iOS) or directly (Android)
Response      →  remove expired tokens from DB (error code: messaging/registration-token-not-registered)
```

**Implementation Notes:**
- Store `{ userId, token, platform, createdAt }` — one user can have multiple devices.
- Use `sendEachForMulticast` for bulk sends; process the response to remove failed tokens immediately — accumulation of stale tokens slows every subsequent batch send.
- Include a `data` payload alongside the `notification` payload so the app can navigate to the right screen on tap.
- Separate the notification payload (visible in tray) from the data payload (invisible, for routing). Never put PII in the notification payload.

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

  // Remove invalid tokens to prevent accumulation
  const expiredTokens = response.responses
    .map((r, i) =>
      r.error?.code === 'messaging/registration-token-not-registered'
        ? devices[i].token
        : null
    )
    .filter((t): t is string => t !== null);

  if (expiredTokens.length) {
    await db.device.deleteMany({ where: { token: { in: expiredTokens } } });
  }
}

declare const db: {
  device: {
    findMany(params: { where: { userId: string } }): Promise<Array<{ token: string }>>;
    deleteMany(params: { where: { token: { in: string[] } } }): Promise<void>;
  };
};
```

**Common Mistakes:**
- Not removing expired tokens — causes failed sends to accumulate and slows batch delivery over time.
- Sending PII (email, name, account details) in the `notification` payload — visible in the OS notification tray and system logs.
- Relying only on push notifications without a fallback (in-app or email) for critical alerts — push delivery is not guaranteed.
- Using a single shared FCM service account across environments — production tokens and staging tokens must be managed separately.

**Security Considerations:**
- Never include PII (email, name, account details) in the `notification` payload — it appears in the OS notification tray and may be visible on a locked screen.
- Verify that the `userId` in the device registration request matches the authenticated session — prevent a user from registering another user's device token.
- Rotate Firebase service account credentials on a schedule; revoke immediately on suspected compromise.

**Testing Strategy:**
Mock Firebase Admin SDK. Test `sendEachForMulticast` with mixed valid/invalid tokens and assert invalid tokens are removed from the DB. Test that a user with zero registered devices does not cause errors or exceptions.

**Score:** Candidate

---

## Pattern: In-App Notifications

**Problem:** Users need to see activity alerts (mentions, approvals, comments) inside the app in real time, with a persistent read/unread feed they can access later.

**Solution:** Store notifications in a DB table with `userId`, `type`, `payload`, and `readAt`. Deliver real-time updates via Server-Sent Events (SSE). Mark as read on explicit user action.

**Architecture:**
```
Event occurs    →  INSERT notification { userId, type, payload }
                →  emit SSE event to connected user (if online)
User opens feed →  GET /notifications (cursor-paginated, unread first)
User clicks     →  PATCH /notifications/:id/read
Badge count     →  Redis counter (INCR on create, DECR on read-all)
                   (not a COUNT(*) query on every request)
```

**Implementation Notes:**
- Use cursor-based pagination on `createdAt DESC` for the feed — see `patterns/api/` Pagination pattern.
- Maintain a cached unread counter in Redis (`INCR` on create, `DECR` on mark-as-read, `DEL` on mark-all-as-read). A `COUNT(*)` query on every badge render does not scale.
- SSE is simpler than WebSockets for one-way server-to-client delivery — no bidirectional protocol needed.
- For multi-instance deployments, SSE listeners must be backed by a pub/sub layer (Redis `SUBSCRIBE`) so an event emitted on instance A reaches a client connected to instance B.

**Example Code:**
```typescript
import { EventEmitter } from 'events';

// In a single-instance context; for multi-instance, replace with Redis pub/sub
const notificationEmitter = new EventEmitter();
notificationEmitter.setMaxListeners(0); // allow many concurrent SSE connections

// SSE endpoint
app.get('/notifications/stream', requireAuth, (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  const userId = (req as any).user.id;
  const listener = (event: { userId: string }) => {
    if (event.userId === userId) {
      res.write(`data: ${JSON.stringify(event)}\n\n`);
    }
  };

  notificationEmitter.on('notification', listener);
  req.on('close', () => notificationEmitter.off('notification', listener));
});

// Create and broadcast
export async function createNotification(
  userId: string,
  type: string,
  payload: object,
) {
  const notification = await db.notification.create({
    data: { userId, type, payload: JSON.stringify(payload) },
  });

  // Increment badge counter
  await redis.incr(`notifications:unread:${userId}`);

  notificationEmitter.emit('notification', { userId, ...notification });
  return notification;
}

// Mark as read
export async function markAsRead(userId: string, notificationId: string) {
  await db.notification.updateMany({
    where: { id: notificationId, userId, readAt: null },
    data: { readAt: new Date() },
  });
  await redis.decr(`notifications:unread:${userId}`);
}

declare const db: {
  notification: {
    create(params: { data: Record<string, unknown> }): Promise<Record<string, unknown>>;
    updateMany(params: { where: Record<string, unknown>; data: Record<string, unknown> }): Promise<void>;
  };
};
declare const redis: {
  incr(key: string): Promise<void>;
  decr(key: string): Promise<void>;
};
declare const app: { get: Function };
declare function requireAuth(req: unknown, res: unknown, next: Function): void;
```

**Common Mistakes:**
- Polling the DB for new notifications on a timer — generates unsustainable query load at scale. Use SSE or WebSockets instead.
- Not paginating the notification feed — the initial load fetches thousands of historical notifications.
- Missing a `markAllAsRead` endpoint — users must individually dismiss every notification.
- Using an in-process `EventEmitter` in a multi-instance deployment — events emitted on one instance do not reach clients connected to a different instance. Requires Redis pub/sub.

**Security Considerations:**
- Verify that the `userId` in the SSE connection matches the authenticated session — an unauthenticated or mismatched user must not subscribe to another user's feed.
- Do not include data in `payload` that the recipient is not authorized to see. Apply authorization checks before creating the notification, not at read time.

**Testing Strategy:**
Test notification creation inserts a DB record and increments the Redis counter. Test the SSE stream delivers events only to the correct user. Test badge count decrements correctly on mark-as-read. Test mark-all-as-read sets all `readAt` values and resets the counter to zero.

**Score:** Candidate

---

## Official References
- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging) — FCM reference for Android and iOS
- [Apple Push Notification Service (APNs)](https://developer.apple.com/documentation/usernotifications) — APNs reference
- [MDN: Server-Sent Events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events) — SSE specification and browser API
- [Firebase Admin Node.js SDK](https://firebase.google.com/docs/admin/setup) — server-side FCM SDK
