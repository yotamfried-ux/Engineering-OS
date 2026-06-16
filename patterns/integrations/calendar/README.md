# Calendar Integration Patterns

> Part of [`patterns/integrations/`](../README.md). Covers connecting to external calendar and scheduling systems.
>
> **External system references:** [`external-systems/cal-com/`](../../../external-systems/cal-com/) for Cal.com API reference.
> See [`core/pattern-lifecycle.md`](../../../core/pattern-lifecycle.md) for scoring and lifecycle rules.

---

## Pattern 1: Google Calendar — OAuth + Event Sync

**Problem:** Accessing a user's Google Calendar requires OAuth 2.0 authorization, token persistence, token refresh, and handling push notifications for real-time change detection.

**Architecture:**
```
Authorization flow:
  /auth/google → OAuth consent screen → callback with code
  → exchange code for { access_token, refresh_token }
  → store encrypted tokens per user in DB

Event listing:
  GET /calendars/primary/events
    ?timeMin=<ISO>&timeMax=<ISO>&singleEvents=true&orderBy=startTime

Real-time sync (push notifications):
  POST /calendars/primary/events/watch
    → Google delivers POST to your webhook URL on any change
    → fetch incremental updates using syncToken or nextPageToken
```

**Implementation Notes:**
- Request only the scopes you need. `calendar.readonly` is sufficient for read-only features. `calendar.events` is needed to create/update/delete.
- Store `access_token`, `refresh_token`, `expiry_date` per user. The `googleapis` client refreshes automatically when given a stored `refresh_token`.
- Push notifications (`watch` channel) expire after at most 7 days — set a background job to renew before expiry.
- Store the `syncToken` returned by `events.list` after the initial full sync. On subsequent calls, pass `syncToken` to get only changed events. If the token is invalid (410 response), perform a full sync again.
- Watch channels are scoped to a calendar. For users with multiple calendars, register a watch per calendar.

**Example Code:**
```typescript
import { google, Auth, calendar_v3 } from 'googleapis';

const SCOPES = ['https://www.googleapis.com/auth/calendar.readonly'];

// Build OAuth client with stored tokens
export async function getOAuth2Client(userId: string): Promise<Auth.OAuth2Client> {
  const oauth2Client = new google.auth.OAuth2(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    process.env.GOOGLE_REDIRECT_URI,
  );

  const tokens = await db.oauthTokens.findUnique({ where: { userId, provider: 'google' } });
  if (!tokens) throw new Error(`No Google tokens for user ${userId}`);

  oauth2Client.setCredentials({
    access_token: tokens.accessToken,
    refresh_token: tokens.refreshToken,
    expiry_date: tokens.expiryDate?.getTime(),
  });

  // Auto-refresh on expiry
  oauth2Client.on('tokens', async (newTokens) => {
    await db.oauthTokens.update({
      where: { userId, provider: 'google' },
      data: { accessToken: newTokens.access_token, expiryDate: new Date(newTokens.expiry_date!) },
    });
  });

  return oauth2Client;
}

// List events in a time window
export async function listGoogleCalendarEvents(
  userId: string,
  start: Date,
  end: Date,
): Promise<calendar_v3.Schema$Event[]> {
  const auth = await getOAuth2Client(userId);
  const cal = google.calendar({ version: 'v3', auth });

  const response = await cal.events.list({
    calendarId: 'primary',
    timeMin: start.toISOString(),
    timeMax: end.toISOString(),
    singleEvents: true,
    orderBy: 'startTime',
    maxResults: 250,
  });

  return response.data.items ?? [];
}

// Register a push notification watch channel
export async function registerGoogleCalendarWatch(userId: string): Promise<void> {
  const auth = await getOAuth2Client(userId);
  const cal = google.calendar({ version: 'v3', auth });
  const channelId = `user-${userId}-${Date.now()}`;

  const response = await cal.events.watch({
    calendarId: 'primary',
    requestBody: {
      id: channelId,
      type: 'web_hook',
      address: `${process.env.APP_BASE_URL}/webhooks/google-calendar`,
      expiration: String(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days in ms
    },
  });

  await db.calendarWatchChannels.upsert({
    where: { userId },
    create: { userId, channelId, resourceId: response.data.resourceId!, expiresAt: new Date(Number(response.data.expiration)) },
    update: { channelId, resourceId: response.data.resourceId!, expiresAt: new Date(Number(response.data.expiration)) },
  });
}

declare const db: {
  oauthTokens: {
    findUnique(p: { where: { userId: string; provider: string } }): Promise<{ accessToken: string; refreshToken: string; expiryDate: Date | null } | null>;
    update(p: { where: { userId: string; provider: string }; data: Record<string, unknown> }): Promise<void>;
  };
  calendarWatchChannels: {
    upsert(p: { where: { userId: string }; create: Record<string, unknown>; update: Record<string, unknown> }): Promise<void>;
  };
};
```

**Common Mistakes:**
- Requesting `calendar` (full access) when only `calendar.readonly` is needed — violates principle of least privilege and reduces OAuth consent approval rates.
- Not listening to the `tokens` event on the OAuth client — access tokens expire in 1 hour; failing to persist refreshed tokens causes users to be forced through OAuth consent again.
- Ignoring the `410 Gone` response on `syncToken` — this requires a full re-sync; treating it as an error causes the integration to break silently.
- Not renewing watch channels before the 7-day expiry — real-time updates stop and the application falls back to polling unknowingly.

**Security Considerations:**
- Store access and refresh tokens encrypted at rest (AES-256). A leaked refresh token grants long-term calendar access.
- Validate the `X-Goog-Channel-ID` and `X-Goog-Resource-ID` headers on incoming webhooks against stored values before processing.
- Use `crypto.timingSafeEqual` when comparing channel IDs from webhook headers to prevent timing attacks.

**Testing Strategy:**
Mock `googleapis` client. Test token refresh: simulate an expired token and verify the `tokens` event updates the DB. Test `syncToken` invalidity (410): assert a full re-sync is triggered. Test watch channel registration stores the expiry date correctly.

**Score:** Candidate

---

## Pattern 2: Microsoft Graph Calendar — Delta Sync + Change Notifications

**Problem:** Integrating with Microsoft 365 calendars (Outlook, Teams) requires OAuth via MSAL, incremental (delta) sync to avoid full re-fetches, and change notifications with lifecycle management.

**Architecture:**
```
Auth (MSAL):
  Authorization code flow → access_token + refresh_token (stored per user)

Initial sync:
  GET /me/calendarView?startDateTime=<ISO>&endDateTime=<ISO>
  → stores deltaLink for next sync

Delta sync (incremental):
  GET <deltaLink>
  → returns only changed/deleted events since last sync
  → stores new deltaLink

Change notifications:
  POST /subscriptions { resource: "/me/events", changeType: "created,updated,deleted", notificationUrl }
  → Microsoft POSTs to notificationUrl on any event change
  → subscription expires in ≤4230 minutes (~3 days); must be renewed
  → lifecycle notifications sent to lifecycleNotificationUrl when subscription expires
```

**Implementation Notes:**
- Use MSAL Node (`@azure/msal-node`) for token acquisition and refresh. Store tokens in DB; do not rely on MSAL's in-memory cache in serverless or multi-instance environments.
- Delta sync (`/me/calendarView/delta`) returns a `@odata.deltaLink` after full enumeration. Persist this link per user. On the next sync, call the `deltaLink` directly — it returns only changes. A `410 Gone` on the deltaLink means the sync state is invalidated; perform a full re-sync.
- Change notification subscriptions expire. Subscribe to `lifecycleNotificationUrl` to receive advance warning and renew before expiry using `PATCH /subscriptions/{id}`.
- Microsoft requires validation of the notification URL during subscription creation: it sends a `validationToken` query parameter and expects the raw token echoed back as `text/plain` within 10 seconds.

**Example Code:**
```typescript
import { ConfidentialClientApplication } from '@azure/msal-node';

const msalClient = new ConfidentialClientApplication({
  auth: {
    clientId: process.env.AZURE_CLIENT_ID!,
    clientSecret: process.env.AZURE_CLIENT_SECRET!,
    authority: `https://login.microsoftonline.com/common`,
  },
});

// Acquire token using stored refresh token
export async function getMicrosoftAccessToken(userId: string): Promise<string> {
  const stored = await db.oauthTokens.findUnique({ where: { userId, provider: 'microsoft' } });
  if (!stored) throw new Error(`No Microsoft tokens for user ${userId}`);

  const result = await msalClient.acquireTokenByRefreshToken({
    refreshToken: stored.refreshToken,
    scopes: ['Calendars.Read', 'offline_access'],
  });

  if (!result) throw new Error('Token refresh failed');

  await db.oauthTokens.update({
    where: { userId, provider: 'microsoft' },
    data: { accessToken: result.accessToken, expiryDate: result.expiresOn },
  });

  return result.accessToken;
}

// Delta sync: call deltaLink if stored, else full calendarView
export async function syncMicrosoftCalendar(
  userId: string,
  start: Date,
  end: Date,
): Promise<{ events: MicrosoftEvent[]; deltaLink: string }> {
  const token = await getMicrosoftAccessToken(userId);
  const stored = await db.calendarSyncState.findUnique({ where: { userId, provider: 'microsoft' } });

  const url = stored?.deltaLink
    ?? `https://graph.microsoft.com/v1.0/me/calendarView/delta?startDateTime=${start.toISOString()}&endDateTime=${end.toISOString()}`;

  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (response.status === 410) {
    // deltaLink expired — clear and full re-sync
    await db.calendarSyncState.delete({ where: { userId, provider: 'microsoft' } });
    return syncMicrosoftCalendar(userId, start, end);
  }

  if (!response.ok) throw new Error(`Graph API error: ${response.status}`);

  const data = await response.json() as { value: MicrosoftEvent[]; '@odata.deltaLink'?: string };
  const deltaLink = data['@odata.deltaLink'] ?? stored?.deltaLink ?? '';

  await db.calendarSyncState.upsert({
    where: { userId, provider: 'microsoft' },
    create: { userId, provider: 'microsoft', deltaLink },
    update: { deltaLink },
  });

  return { events: data.value, deltaLink };
}

// Validate notification URL (required during subscription creation)
export function handleGraphNotificationValidation(req: { query: { validationToken?: string } }, res: { status: Function }) {
  if (req.query.validationToken) {
    res.status(200).send(req.query.validationToken); // return as text/plain
    return true;
  }
  return false;
}

interface MicrosoftEvent { id: string; subject?: string; start?: { dateTime: string; timeZone: string }; end?: { dateTime: string; timeZone: string } }
declare const db: {
  oauthTokens: {
    findUnique(p: { where: { userId: string; provider: string } }): Promise<{ refreshToken: string; accessToken: string } | null>;
    update(p: { where: { userId: string; provider: string }; data: Record<string, unknown> }): Promise<void>;
  };
  calendarSyncState: {
    findUnique(p: { where: { userId: string; provider: string } }): Promise<{ deltaLink: string } | null>;
    upsert(p: { where: { userId: string; provider: string }; create: Record<string, unknown>; update: Record<string, unknown> }): Promise<void>;
    delete(p: { where: { userId: string; provider: string } }): Promise<void>;
  };
};
```

**Common Mistakes:**
- Using MSAL's in-memory token cache in a serverless or multi-instance environment — the cache is not shared across instances; tokens must be stored in a DB or distributed cache.
- Not handling `410 Gone` on `deltaLink` — the integration appears to work but stops receiving changes after the sync state expires.
- Not validating the `validationToken` during subscription creation — Microsoft requires this echo within 10 seconds or the subscription is rejected.
- Not renewing subscriptions before expiry — after expiry, change notifications stop silently with no error surfaced to the application.

**Security Considerations:**
- Validate the `ClientState` field on incoming Graph change notifications against a stored secret per subscription. Microsoft does not sign notification payloads; `ClientState` is the only authenticity signal.
- Store Microsoft access and refresh tokens encrypted at rest.
- Use narrowest required scope: `Calendars.Read` for read-only, `Calendars.ReadWrite` only when write access is required.

**Testing Strategy:**
Mock `@azure/msal-node` and `fetch`. Test delta sync: assert `deltaLink` is stored after full sync, used on subsequent calls, and a 410 response triggers full re-sync. Test subscription validation echo. Test subscription renewal is triggered before expiry.

**Score:** Candidate

---

## Pattern 3: Cal.com — Embed + API + Webhooks

**Problem:** Integrating Cal.com scheduling into an application requires choosing between the embed SDK (for in-app booking UIs), the v2 REST API (for programmatic slot queries and booking creation), and webhooks (for reacting to booking lifecycle events). These three surfaces serve different use cases and have different authentication models.

**Architecture:**
```
Embed (client-side):
  <script> Cal("init", { origin: "https://cal.com" })
  Cal("inline", { elementOrSelector: "#cal-embed", calLink: "user/event-type" })
  → user books directly via the Cal.com iframe

API (server-side, v2):
  GET  /v2/slots/available?eventTypeId=<id>&startTime=<ISO>&endTime=<ISO>
  POST /v2/bookings  { eventTypeId, start, attendee }
  GET  /v2/bookings/{uid}

Webhooks (server-side):
  Cal.com POSTs to your endpoint on booking lifecycle events
  Events: BOOKING_CREATED, BOOKING_RESCHEDULED, BOOKING_CANCELLED,
          BOOKING_CONFIRMED, BOOKING_REJECTED, MEETING_ENDED
  Verify: X-Cal-Signature-256 = HMAC-SHA256(rawBody, webhookSecret)
```

**Implementation Notes:**
- The embed SDK and the REST API serve different use cases. Use the embed when you want Cal.com's full booking UI inside your app without building it. Use the API when you need programmatic slot availability checks, headless booking flows, or booking management from your backend.
- For the v2 API, all requests require `Authorization: Bearer <API_KEY>` and the header `cal-api-version: 2024-09-04`. The version header is mandatory; requests without it fail.
- Always verify `X-Cal-Signature-256` before processing webhook payloads. Any public internet caller can POST to your endpoint.
- For self-hosted Cal.com, set `CALCOM_BASE_URL` to your instance URL. The signature verification logic is identical.
- Self-hosted Cal.com requires Redis for background jobs (reminder emails, recurring bookings). Without Redis, these jobs fail silently.

**Example Code:**
```typescript
import crypto from 'crypto';

// 1. Verify the Cal.com webhook signature
export function verifyCalWebhookSignature(
  rawBody: Buffer,
  signatureHeader: string | undefined,
  webhookSecret: string,
): boolean {
  if (!signatureHeader) return false;

  const expected = crypto
    .createHmac('sha256', webhookSecret)
    .update(rawBody)
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signatureHeader),
    Buffer.from(expected),
  );
}

// 2. Webhook handler
export async function handleCalWebhook(
  rawBody: Buffer,
  signatureHeader: string | undefined,
): Promise<void> {
  if (!verifyCalWebhookSignature(rawBody, signatureHeader, process.env.CAL_WEBHOOK_SECRET!)) {
    throw new Error('Invalid Cal.com webhook signature');
  }

  const event = JSON.parse(rawBody.toString()) as { triggerEvent: string; payload: Record<string, unknown> };

  switch (event.triggerEvent) {
    case 'BOOKING_CREATED':
      await handleBookingCreated(event.payload);
      break;
    case 'BOOKING_CANCELLED':
      await handleBookingCancelled(event.payload);
      break;
    case 'BOOKING_RESCHEDULED':
      await handleBookingRescheduled(event.payload);
      break;
  }
}

async function handleBookingCreated(payload: Record<string, unknown>): Promise<void> {
  await db.bookings.create({
    data: {
      calBookingUid: payload.uid as string,
      startTime: new Date(payload.startTime as string),
      endTime: new Date(payload.endTime as string),
      attendeeEmail: (payload.attendees as Array<{ email: string }>)[0]?.email,
      status: 'confirmed',
    },
  });
}

async function handleBookingCancelled(payload: Record<string, unknown>): Promise<void> {
  await db.bookings.updateMany({
    where: { calBookingUid: payload.uid as string },
    data: { status: 'cancelled', cancelledAt: new Date() },
  });
}

async function handleBookingRescheduled(payload: Record<string, unknown>): Promise<void> {
  await db.bookings.updateMany({
    where: { calBookingUid: payload.uid as string },
    data: {
      startTime: new Date(payload.startTime as string),
      endTime: new Date(payload.endTime as string),
    },
  });
}

// 3. Query available slots via v2 API
export async function getAvailableSlots(
  eventTypeId: number,
  startTime: Date,
  endTime: Date,
): Promise<{ start: string }[]> {
  const params = new URLSearchParams({
    eventTypeId: String(eventTypeId),
    startTime: startTime.toISOString(),
    endTime: endTime.toISOString(),
  });

  const response = await fetch(
    `${process.env.CALCOM_BASE_URL}/v2/slots/available?${params}`,
    {
      headers: {
        Authorization: `Bearer ${process.env.CALCOM_API_KEY}`,
        'cal-api-version': '2024-09-04',
      },
    },
  );

  if (!response.ok) {
    throw new Error(`Cal.com slots API error: ${response.status} ${await response.text()}`);
  }

  const data = await response.json();
  return data.data?.slots ?? [];
}

declare const db: {
  bookings: {
    create(p: { data: Record<string, unknown> }): Promise<void>;
    updateMany(p: { where: Record<string, unknown>; data: Record<string, unknown> }): Promise<void>;
  };
};
```

**Common Mistakes:**
- Processing webhook payloads without verifying `X-Cal-Signature-256`. Any caller can POST fake booking events to your endpoint.
- Calling `Cal("floatingButton")` or `Cal("inline")` before `Cal("init")`. The embed silently does nothing.
- Using Cal.com API v1 for new integrations. v1 endpoints are inconsistently maintained and several are undocumented.
- Self-hosting without Redis. Reminder emails and recurring bookings are processed via background jobs that require Redis; they silently fail with no error in the Cal.com UI.

**Security Considerations:**
- Store the webhook secret in an environment variable; never hard-code it in source files.
- Rate-limit your webhook endpoint. Cal.com retries failed deliveries (non-2xx responses) with exponential backoff; without rate limiting, a burst of retries can overwhelm your handler.
- For self-hosted instances: back up `CALENDSO_ENCRYPTION_KEY`. It encrypts all OAuth tokens for calendar providers. Loss of this key requires all users to reconnect their calendars.

**Score:** Candidate

---

## Pattern 4: Calendly Integration

**Problem:** Integrating with Calendly-based scheduling to capture booking events, sync attendee data, and react to scheduling lifecycle events requires understanding Calendly's webhook model and its difference from direct calendar APIs. Calendly's API is read-oriented: it does not support programmatic booking creation or event type modification, and all data is accessed via URIs returned in webhook payloads rather than inline objects.

**Architecture:**
```
Setup:
  POST /webhook_subscriptions { url, events, organization, user, scope }
  → Calendly fires events to your URL on booking activity

Webhook event flow:
  invitee.created  → booking confirmed → fetch full event and invitee → sync to DB / CRM
  invitee.canceled → booking canceled  → extract reason → update downstream systems

Data retrieval (after receiving a webhook):
  GET /scheduled_events/{uuid}          → full event details (time, duration, location)
  GET /scheduled_events/{uuid}/invitees → invitee list with form answers

Other API queries:
  GET /event_types                       → list event types (booking pages) for a user
  GET /users/me                          → current user's URI and organization URI
```

**Implementation Notes:**
- Use OAuth 2.0 for multi-user apps so each Calendly user grants access independently. Personal Access Tokens are for single-user or internal tooling only — a PAT is scoped to the token owner's account and cannot access other users' calendars.
- Webhook payloads contain URIs, not full event objects. After receiving `invitee.created`, extract `event.payload.event.uri` and `event.payload.invitee.uri`, then fetch each resource to get the full details. Do not rely on the webhook payload alone.
- Webhook scope: a subscription can be scoped to a single user (`scope: 'user', user: userUri`) or an entire organization (`scope: 'organization', organization: orgUri`). Organization-scoped subscriptions require the organization owner to grant access.
- Rate limits: 100 requests per minute per integration (OAuth app or PAT). Webhook deliveries do not count toward this limit. Implement exponential backoff on 429 responses.
- Cancellation payload: `invitee.canceled` includes `canceler_type` (`invitee` or `host`) and an optional `cancel_reason` string.

**Example Code:**
```typescript
import crypto from 'crypto';

// 1. Verify the Calendly webhook signature
export function verifyCalendlyWebhook(
  rawBody: Buffer,
  signatureHeader: string | undefined,
  signingKey: string,
): boolean {
  if (!signatureHeader) return false;
  const [version, receivedDigest] = signatureHeader.split('=');
  if (version !== 'v1' || !receivedDigest) return false;

  const expected = crypto
    .createHmac('sha256', signingKey)
    .update(rawBody)
    .digest('hex');

  return crypto.timingSafeEqual(Buffer.from(receivedDigest), Buffer.from(expected));
}

// 2. Handle invitee.created — fetch full resources, sync to DB
export async function handleInviteeCreated(
  payload: CalendlyInviteeCreatedPayload,
): Promise<void> {
  const [event, invitee] = await Promise.all([
    fetchCalendlyResource(payload.event.uri),
    fetchCalendlyResource(payload.invitee.uri),
  ]);

  await db.appointments.create({
    calendlyEventUri: event.resource.uri,
    eventName: event.resource.name,
    startTimeUtc: new Date(event.resource.start_time),
    endTimeUtc: new Date(event.resource.end_time),
    inviteeName: invitee.resource.name,
    inviteeEmail: invitee.resource.email,
    status: 'confirmed',
  });
}

// 3. Handle invitee.canceled
export async function handleInviteeCanceled(
  payload: CalendlyInviteeCanceledPayload,
): Promise<void> {
  await db.appointments.updateByEventUri(payload.event.uri, {
    status: 'cancelled',
    cancelerType: payload.canceler_type,
    cancelReason: payload.cancel_reason ?? null,
  });
}

async function fetchCalendlyResource(uri: string): Promise<{ resource: Record<string, unknown> }> {
  const response = await fetch(uri, {
    headers: {
      Authorization: `Bearer ${process.env.CALENDLY_ACCESS_TOKEN}`,
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    throw new Error(`Calendly resource fetch failed: ${response.status} ${uri}`);
  }

  return response.json();
}

interface CalendlyInviteeCreatedPayload {
  event: { uri: string };
  invitee: { uri: string };
}
interface CalendlyInviteeCanceledPayload {
  event: { uri: string };
  invitee: { uri: string };
  canceler_type: 'invitee' | 'host';
  cancel_reason?: string;
}

declare const db: {
  appointments: {
    create(data: Record<string, unknown>): Promise<void>;
    updateByEventUri(uri: string, data: Record<string, unknown>): Promise<void>;
  };
};
```

**Common Mistakes:**
- Processing event data from the webhook payload body directly instead of fetching the full resource. Webhook payloads contain URI references, not full event objects.
- Not verifying the `Calendly-Webhook-Signature` header. Any caller can POST fake booking events to your endpoint.
- Using a Personal Access Token for a multi-tenant app. PATs are tied to the token owner's Calendly account and cannot be used to access other users' event data.

**Security Considerations:**
- Verify `Calendly-Webhook-Signature` on every incoming request using HMAC-SHA256 with your organization's signing key. Use `crypto.timingSafeEqual` to prevent timing attacks.
- Store signing keys as environment variables; never commit them to source files.
- For OAuth apps: encrypt access and refresh tokens at rest.

**Score:** Candidate

---

## Pattern 5: Unified Calendar Abstraction Layer

**Problem:** Applications integrating with more than one calendar provider embed provider-specific types, API calls, and normalization logic throughout their codebase. Adding a second provider requires touching every layer. Conflict detection logic written against Google's event schema breaks when a user connects an Outlook account.

**Solution:** Define a provider-agnostic `CalendarProvider` interface with a normalized `CalendarEvent` model. Each concrete provider implements the interface. Business logic depends only on the interface. A `CalendarService` resolves which provider(s) to call for a given user at runtime.

**Architecture:**
```
Business logic
  → CalendarService
       → resolves connected providers for userId
       → delegates to CalendarProvider interface
            ├── GoogleCalendarProvider
            ├── MicrosoftCalendarProvider
            └── CalComProvider

Normalized CalendarEvent model:
  { id, title, startUtc, endUtc, timezone, location, attendees, recurrence, providerMetadata }

Conflict detection (provider-agnostic):
  CalendarService.checkConflicts(userId, start, end)
    → queries all connected providers for that user
    → returns any CalendarEvent where startUtc < end AND endUtc > start
```

**Implementation Notes:**
- Normalize all event times to UTC on ingestion. Store `timezone` separately as a display hint. This makes all conflict detection and ordering queries provider-agnostic.
- `providerMetadata` is a `Record<string, unknown>` field for provider-specific identifiers needed for updates and deletes (`googleEventId`, `outlookEventId`, `calcomBookingUid`). Business logic must never read from this field.
- When a user connects multiple calendars (Google + Microsoft), each connection is stored as a `ConnectedCalendar` record with `providerType` and `providerAccountId`. The `CalendarService` queries all of a user's connections and merges results.
- Conflict detection: does any event satisfy `event.startUtc < proposedEnd AND event.endUtc > proposedStart`? This is a half-open interval overlap check and works identically regardless of provider.
- Build the interface before writing the first provider implementation, not after.

**Example Code:**
```typescript
// Normalized domain model
export interface CalendarEventAttendee {
  email: string;
  responseStatus: 'accepted' | 'declined' | 'tentative' | 'needsAction';
}

export interface CalendarEvent {
  id: string;
  title: string;
  startUtc: Date;
  endUtc: Date;
  timezone: string;                     // IANA timezone string, display only
  location?: string;
  attendees: CalendarEventAttendee[];
  recurrence?: { rule: string; exceptions: Date[] };
  providerMetadata: Record<string, unknown>; // opaque to business logic
}

// Provider interface
export interface CalendarProvider {
  readonly providerType: 'google' | 'microsoft' | 'calcom';
  listEvents(userId: string, start: Date, end: Date): Promise<CalendarEvent[]>;
  createEvent(userId: string, event: Omit<CalendarEvent, 'id' | 'providerMetadata'>): Promise<CalendarEvent>;
  updateEvent(userId: string, eventId: string, updates: Partial<Omit<CalendarEvent, 'id' | 'providerMetadata'>>): Promise<CalendarEvent>;
  deleteEvent(userId: string, eventId: string): Promise<void>;
}

// CalendarService: resolves providers and provides cross-provider operations
export class CalendarService {
  constructor(private readonly providers: Record<string, CalendarProvider>) {}

  private async getProvidersForUser(userId: string): Promise<CalendarProvider[]> {
    const connections = await db.connectedCalendars.findAll(userId);
    return connections
      .map((c) => this.providers[c.providerType])
      .filter((p): p is CalendarProvider => p !== undefined);
  }

  async listEvents(userId: string, start: Date, end: Date): Promise<CalendarEvent[]> {
    const providers = await this.getProvidersForUser(userId);
    const results = await Promise.all(providers.map((p) => p.listEvents(userId, start, end)));
    return results.flat().sort((a, b) => a.startUtc.getTime() - b.startUtc.getTime());
  }

  async checkConflicts(userId: string, start: Date, end: Date): Promise<CalendarEvent[]> {
    const events = await this.listEvents(userId, start, end);
    // Half-open interval overlap
    return events.filter((e) => e.startUtc < end && e.endUtc > start);
  }
}

declare const db: {
  connectedCalendars: {
    findAll(userId: string): Promise<Array<{ providerType: string }>>;
  };
};

// DI wiring example:
// const calendarService = new CalendarService({
//   google: new GoogleCalendarProvider(),
//   microsoft: new MicrosoftCalendarProvider(),
// });
```

**Common Mistakes:**
- Leaking provider-specific types (`calendar_v3.Schema$Event`, `MicrosoftGraph.Event`) into service or controller layers.
- Storing event times in the provider's native timezone format instead of normalizing to UTC — conflict detection across providers produces incorrect results.
- Building the abstraction after writing provider-specific code in many controllers — retrofitting is significantly more expensive than building the interface first.
- Making `checkConflicts` query only the primary calendar provider — users connecting multiple providers expect all conflicts to be detected.

**Security Considerations:**
- The `CalendarService` must validate that the requesting `userId` is authorized to access the calendar being queried. Never accept `userId` from a request body without verifying it matches the authenticated session.
- Ensure event listing responses do not leak data across users.

**Testing Strategy:**
Test with two mock providers; assert `listEvents` merges and sorts by `startUtc`. Test `checkConflicts` with overlapping and non-overlapping events spanning both providers. Test that a user with no connected calendars returns an empty list without error.

**Score:** Candidate

---

## Pattern 6: Booking State Machine

**Problem:** Booking flows with multiple states (pending, confirmed, canceled, rescheduled, completed, no-show) are typically implemented with ad-hoc `if/else` blocks and direct status updates scattered across route handlers, background jobs, and webhook processors. This leads to invalid state transitions, missing side effects (e.g., cancellation email not sent), and audit logs that record the final state but not the transition history.

**Solution:** Model the booking lifecycle as an explicit state machine. Define every valid transition and the side effects that must occur when a transition fires. Route all booking mutations through the state machine. Commit state to the DB before dispatching side effects.

**Architecture:**
```
States:
  PENDING → CONFIRMED → COMPLETED
                     ↓          ↓
                  CANCELED   NO_SHOW
                     ↑
               RESCHEDULED ← CONFIRMED

Transitions and side effects:
  PENDING    → CONFIRMED:    create calendar event; send confirmation email
  CONFIRMED  → CANCELED:     send cancellation email; delete calendar event; release slot
  CONFIRMED  → RESCHEDULED:  update calendar event; send rescheduling confirmation
  RESCHEDULED→ CONFIRMED:    send updated confirmation
  CONFIRMED  → COMPLETED:    send follow-up; record attendance
  CONFIRMED  → NO_SHOW:      record no-show; apply no-show policy

Audit trail:
  booking_transitions { bookingId, fromStatus, toStatus, triggeredBy, metadata, createdAt }
```

**Implementation Notes:**
- Store every transition in a `booking_transitions` audit table. When a booking reaches an unexpected state in production, the transition history is the primary root cause analysis tool.
- Commit the new state to the database before dispatching side effects (emails, calendar API calls). If the DB commit succeeds but a side effect fails, the booking is in a valid state and the side effect can be retried. Reversing this order risks sending false confirmations.
- Idempotency: before applying a transition, check whether it has already been applied by querying `booking_transitions` for the same `(bookingId, toStatus)` pair. Guard against double-processing from concurrent webhook deliveries.
- No-show detection: implement via a background job that checks for `CONFIRMED` bookings past their `endTime` with no attendance signal and fires `CONFIRMED → NO_SHOW` automatically.

**Example Code:**
```typescript
type BookingStatus = 'PENDING' | 'CONFIRMED' | 'CANCELED' | 'RESCHEDULED' | 'COMPLETED' | 'NO_SHOW';

interface TransitionMetadata {
  cancelReason?: string;
  canceledBy?: 'host' | 'attendee';
  rescheduledStartUtc?: Date;
  rescheduledEndUtc?: Date;
}

const VALID_TRANSITIONS: Record<BookingStatus, BookingStatus[]> = {
  PENDING:     ['CONFIRMED', 'CANCELED'],
  CONFIRMED:   ['CANCELED', 'RESCHEDULED', 'COMPLETED', 'NO_SHOW'],
  RESCHEDULED: ['CONFIRMED', 'CANCELED'],
  CANCELED:    [],
  COMPLETED:   [],
  NO_SHOW:     [],
};

export class BookingStateMachine {
  async transition(
    bookingId: string,
    to: BookingStatus,
    triggeredBy: string,
    metadata: TransitionMetadata = {},
  ): Promise<void> {
    const booking = await db.bookings.findById(bookingId);
    if (!booking) throw new Error(`Booking not found: ${bookingId}`);

    const from = booking.status as BookingStatus;

    if (!VALID_TRANSITIONS[from].includes(to)) {
      throw new Error(`Invalid transition: ${from} → ${to} for booking ${bookingId}`);
    }

    // Idempotency guard
    const existing = await db.bookingTransitions.findOne(bookingId, to);
    if (existing) return;

    // Commit state first, then side effects
    await db.bookings.updateStatus(bookingId, to);
    await db.bookingTransitions.create({ bookingId, fromStatus: from, toStatus: to, triggeredBy, metadata });

    await this.dispatchSideEffects(bookingId, from, to, metadata);
  }

  private async dispatchSideEffects(
    bookingId: string,
    from: BookingStatus,
    to: BookingStatus,
    metadata: TransitionMetadata,
  ): Promise<void> {
    const run = async (label: string, fn: () => Promise<void>) => {
      try {
        await fn();
      } catch (err) {
        // Log and queue for retry; booking state is already committed
        console.error(`Side effect failed [${label}] for booking ${bookingId}:`, err);
      }
    };

    if (from === 'PENDING' && to === 'CONFIRMED') {
      await run('createCalendarEvent', () => sideEffects.createCalendarEvent(bookingId));
      await run('sendConfirmationEmail', () => sideEffects.sendConfirmationEmail(bookingId));
    }
    if (to === 'CANCELED') {
      await run('sendCancellationEmail', () => sideEffects.sendCancellationEmail(bookingId, metadata.cancelReason));
      await run('deleteCalendarEvent', () => sideEffects.deleteCalendarEvent(bookingId));
    }
    if (to === 'RESCHEDULED') {
      await run('updateCalendarEvent', () => sideEffects.updateCalendarEvent(bookingId));
      await run('sendReschedulingEmail', () => sideEffects.sendReschedulingEmail(bookingId));
    }
    if (to === 'COMPLETED') {
      await run('sendFollowUpEmail', () => sideEffects.sendFollowUpEmail(bookingId));
    }
    if (to === 'NO_SHOW') {
      await run('applyNoShowPolicy', () => sideEffects.applyNoShowPolicy(bookingId));
    }
  }
}

declare const db: {
  bookings: {
    findById(id: string): Promise<{ status: string } | null>;
    updateStatus(id: string, status: BookingStatus): Promise<void>;
  };
  bookingTransitions: {
    findOne(bookingId: string, toStatus: BookingStatus): Promise<{ id: string } | null>;
    create(data: { bookingId: string; fromStatus: BookingStatus; toStatus: BookingStatus; triggeredBy: string; metadata: TransitionMetadata }): Promise<void>;
  };
};
declare const sideEffects: {
  sendConfirmationEmail(id: string): Promise<void>;
  sendCancellationEmail(id: string, reason?: string): Promise<void>;
  sendReschedulingEmail(id: string): Promise<void>;
  sendFollowUpEmail(id: string): Promise<void>;
  createCalendarEvent(id: string): Promise<void>;
  updateCalendarEvent(id: string): Promise<void>;
  deleteCalendarEvent(id: string): Promise<void>;
  applyNoShowPolicy(id: string): Promise<void>;
};
```

**Common Mistakes:**
- Updating `booking.status` directly in a route handler without going through the state machine — bypasses transition validation and skips side effects.
- Running side effects (email sends, calendar API calls) inside the database transaction — a slow email provider causes the transaction to time out, rolling back the booking status.
- Not recording transition history — makes root cause analysis of unexpected states impossible.
- Making no-show detection manual — automate it with a background job.

**Security Considerations:**
- Validate that the user triggering a transition has permission to do so. An attendee may cancel their own booking but not another's.
- Rate-limit cancellation and rescheduling transitions for attendees to prevent abuse of host availability.

**Testing Strategy:**
Test each valid transition succeeds. Test each invalid transition throws. Test idempotency: applying the same transition twice is a no-op. Test side effect failure does not roll back the committed state. Test background job correctly identifies and fires `CONFIRMED → NO_SHOW` for past-due bookings.

**Score:** Candidate

---

## Official References
- [Google Calendar API v3 Reference](https://developers.google.com/calendar/api/v3/reference)
- [Google OAuth 2.0 for Web Server Applications](https://developers.google.com/identity/protocols/oauth2/web-server)
- [Google Calendar Push Notifications](https://developers.google.com/calendar/api/guides/push)
- [Microsoft Graph Calendar API](https://learn.microsoft.com/en-us/graph/api/resources/calendar)
- [Microsoft Graph Delta Queries](https://learn.microsoft.com/en-us/graph/delta-query-overview)
- [Microsoft Graph Change Notifications](https://learn.microsoft.com/en-us/graph/change-notifications-overview)
- [MSAL for Node.js](https://github.com/AzureAD/microsoft-authentication-library-for-js) — Microsoft Authentication Library
- [Cal.com API v2 Reference](https://cal.com/docs/api-reference/v2/introduction)
- [Cal.com Webhook Events](https://cal.com/docs/developing/webhooks)
- [Calendly Developer Documentation](https://developer.calendly.com/api-docs)
- [Google API Node.js Client](https://github.com/googleapis/google-api-nodejs-client)
- [Microsoft Graph JavaScript SDK](https://github.com/microsoftgraph/msgraph-sdk-javascript)
