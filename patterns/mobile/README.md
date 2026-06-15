# Mobile Patterns
> See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring.

## Overview

Patterns for React Native / Expo applications. Covers the four most operationally critical concerns: working offline and syncing cleanly, routing users through deep links, handling push notifications across all app lifecycle states, and shipping code updates over-the-air without a full App Store release. Apply these patterns early — retrofitting them onto an existing app is expensive.

---

## Pattern: Offline-First with Sync

**Problem:** Mobile networks are unreliable; an app that requires connectivity to function loses user trust and data on every subway ride or flight.

**Solution:** Write all user actions to local storage first (SQLite via Expo SQLite or WatermelonDB), then sync to the server in the background when connectivity returns. Use timestamps and a last-write-wins or CRDT strategy to resolve conflicts.

**Implementation Notes:**
- Assign a client-generated UUID to every record at creation time so the server can detect duplicates.
- Tag every local write with `syncStatus: "pending" | "synced" | "conflict"`.
- Use `NetInfo` from `@react-native-community/netinfo` to detect connectivity and trigger sync.
- Sync in a background task (Expo `TaskManager` + `BackgroundFetch`) so data uploads even when the app is backgrounded.
- For conflict resolution: simple apps can use last-write-wins on `updatedAt`; collaborative apps need vector clocks or CRDTs.

**Example:**
```typescript
import * as SQLite from "expo-sqlite";
import NetInfo from "@react-native-community/netinfo";

const db = SQLite.openDatabaseSync("app.db");

export async function createNote(text: string) {
  const id = crypto.randomUUID();
  const now = new Date().toISOString();
  db.runSync(
    "INSERT INTO notes (id, text, updated_at, sync_status) VALUES (?, ?, ?, ?)",
    [id, text, now, "pending"]
  );
  triggerSync(); // fire-and-forget
  return id;
}

async function triggerSync() {
  const { isConnected } = await NetInfo.fetch();
  if (!isConnected) return;

  const pending = db.getAllSync<Note>(
    "SELECT * FROM notes WHERE sync_status = 'pending'"
  );
  for (const note of pending) {
    try {
      await api.upsertNote(note);
      db.runSync("UPDATE notes SET sync_status = 'synced' WHERE id = ?", [note.id]);
    } catch {
      // leave as pending; next sync attempt will retry
    }
  }
}
```

**Common Mistakes:**
- Generating sequential integer IDs on the client — collides with server-generated IDs on first sync.
- Marking records as `synced` before the API call confirms success.
- Syncing the entire table on every reconnect — use a `last_synced_at` watermark to diff.

**Security Considerations:**
- Encrypt the local SQLite database with SQLCipher (Expo SQLite supports encryption keys) if the data is sensitive.
- Validate ownership server-side on every upsert — clients can tamper with `id` fields.

**Testing:**
Write integration tests that create records while mocking `NetInfo` as offline, then trigger sync after switching to online. Assert that the server API was called exactly once per pending record and that `sync_status` transitions to `synced`. Test the conflict path by seeding a server record with a newer `updated_at` and asserting the local record is not overwritten.

---

## Pattern: Deep Linking

**Problem:** Users clicking links in emails, SMS, or other apps need to land on the correct in-app screen; iOS Universal Links and Android App Links must be configured correctly or the OS falls back to the browser.

**Solution:** Use Expo Router's file-based routing with `expo-linking` for scheme-based links. Register Universal Links (iOS) and App Links (Android) with an `apple-app-site-association` and `assetlinks.json` served from your domain.

**Implementation Notes:**
- Expo Router maps URL paths to file routes automatically — `/posts/[id]` renders `app/posts/[id].tsx`.
- Configure `scheme` in `app.json` for `myapp://` deep links (works in development and standalone).
- For Universal Links (`https://myapp.com/posts/123`): host `apple-app-site-association` at `/.well-known/apple-app-site-association` and `assetlinks.json` at `/.well-known/assetlinks.json`.
- Handle **deferred deep links** (user clicks link → installs app → should land on original link) via Branch.io or Adjust, or by storing the link in a Firebase Dynamic Link before install.
- Always validate route params (e.g., `postId` is a valid UUID) before using them in an API call.

**Example:**
```typescript
// app/posts/[id].tsx  — Expo Router file-based deep link target
import { useLocalSearchParams } from "expo-router";
import { z } from "zod";

const params = z.object({ id: z.string().uuid() });

export default function PostScreen() {
  const raw = useLocalSearchParams<{ id: string }>();
  const parsed = params.safeParse(raw);

  if (!parsed.success) return <ErrorScreen message="Invalid post link" />;

  const { id } = parsed.data;
  // fetch post by id...
}
```

```json
// app.json (excerpt)
{
  "expo": {
    "scheme": "myapp",
    "ios": { "associatedDomains": ["applinks:myapp.com"] },
    "android": { "intentFilters": [{ "action": "VIEW", "autoVerify": true,
      "data": [{ "scheme": "https", "host": "myapp.com" }],
      "category": ["BROWSABLE", "DEFAULT"] }] }
  }
}
```

**Common Mistakes:**
- Using `Linking.getInitialURL()` only at mount — misses links received while the app is running; subscribe with `Linking.addEventListener` too.
- Forgetting to handle the unauthenticated case: a deep link that requires auth should redirect to login and then continue to the intended screen after sign-in.
- Serving `apple-app-site-association` with the wrong `Content-Type` (`application/json` required, not `text/plain`).

**Security Considerations:**
- Never trust URL parameters as authorization proof. Always verify the user has permission to access the resource server-side.
- Sanitize all deep link parameters before use to prevent injection attacks.

**Testing:**
Test with `npx uri-scheme open myapp://posts/some-uuid --ios` in the simulator. In CI, use Detox or Maestro to open a URI and assert the correct screen renders. Test the invalid-param path and the unauthenticated redirect.

---

## Pattern: Push Notification Handling

**Problem:** Push notifications behave differently depending on whether the app is in the foreground, background, or killed state; a single handler placed in the wrong lifecycle hook silently drops notifications.

**Solution:** Use `expo-notifications` with three distinct handlers: a foreground handler (`setNotificationHandler`), a response handler for taps (`addNotificationResponseReceivedListener`), and `getLastNotificationResponseAsync` for the killed-state case checked at app boot.

**Implementation Notes:**
- Request permission early in the onboarding flow with context ("We'll notify you when your order ships") — cold permission prompts get denied more often.
- Store the Expo Push Token in your backend associated with the user's account; rotate it when it changes (listen to `addPushTokenListener`).
- Background notifications on iOS require the `remote-notification` background mode in `app.json`.
- For data-only (silent) notifications, set `content-available: 1` and handle in a background task; do not rely on them to update UI directly.

**Example:**
```typescript
import * as Notifications from "expo-notifications";
import { useEffect } from "react";
import { router } from "expo-router";

// Configure foreground behavior (call once at app root)
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
    shouldShowList: true,
  }),
});

export function useNotificationSetup() {
  useEffect(() => {
    // Handle tap while app is running (foreground / background)
    const sub = Notifications.addNotificationResponseReceivedListener((response) => {
      const screen = response.notification.request.content.data?.screen as string;
      if (screen) router.push(screen);
    });

    // Handle tap that cold-launched the app (killed state)
    Notifications.getLastNotificationResponseAsync().then((response) => {
      if (!response) return;
      const screen = response.notification.request.content.data?.screen as string;
      if (screen) router.push(screen);
    });

    return () => sub.remove();
  }, []);
}
```

**Common Mistakes:**
- Registering `addNotificationResponseReceivedListener` inside a screen component — it unmounts, so taps on notifications while on other screens are lost.
- Not calling `getLastNotificationResponseAsync` at boot — killed-state taps are never handled.
- Re-registering for push tokens on every launch without checking if the token changed — floods the backend.

**Security Considerations:**
- Validate notification payloads server-side before acting on `data` fields; clients must not trust arbitrary screen names or IDs from push payloads without authorization checks.
- Never include sensitive user data (PII, session tokens) in the notification payload — it is stored in plain text on the device notification tray.

**Testing:**
Use the Expo Push Notification tool (`https://expo.dev/notifications`) or `expo-notifications`'s `scheduleNotificationAsync` to test locally. Write unit tests for the handler logic by calling the listener callback directly with a mock `NotificationResponse`. Test all three states (foreground, background, killed) manually on physical devices before each release.

---

## Pattern: OTA Updates (Expo EAS Update)

**Problem:** App Store review cycles (1–3 days) block shipping bug fixes and content changes to users; publishing a bad update can be unrecoverable without another review cycle.

**Solution:** Use Expo EAS Update to push JavaScript bundle updates over-the-air. Maintain `production`, `staging`, and `rollback` channels; pin critical releases with update groups so you can instantly revert.

**Implementation Notes:**
- OTA updates can only change JavaScript and assets — not native modules, permissions, or `app.json` config; native changes still require a full store submission.
- Configure channels in `eas.json`: `production` (auto-update on launch), `staging` (manual trigger in TestFlight / internal track).
- Use `expo-updates`' `checkForUpdateAsync` + `fetchUpdateAsync` + `reloadAsync` for in-app update prompts instead of silent background updates — users trust visible prompts.
- Set a `rolloutPercentage` when publishing to canary-test on 5–10% of users before full rollout.
- Keep the previous update pinned as a named rollback target with `eas update --rollback-to-embedded`.

**Example:**
```typescript
import * as Updates from "expo-updates";

export async function checkAndPromptUpdate() {
  if (!Updates.isEnabled) return; // dev client or bare workflow without updates

  try {
    const update = await Updates.checkForUpdateAsync();
    if (!update.isAvailable) return;

    await Updates.fetchUpdateAsync();
    // Show a prompt before reloading — never reload silently mid-session
    Alert.alert(
      "Update available",
      "A new version is ready. Reload now?",
      [
        { text: "Later" },
        { text: "Reload", onPress: () => Updates.reloadAsync() },
      ]
    );
  } catch (e) {
    // Never crash the app because an OTA check failed
    console.error("OTA check failed", e);
  }
}
```

```jsonc
// eas.json (excerpt)
{
  "build": {
    "production": { "channel": "production" },
    "staging":    { "channel": "staging" }
  }
}
```

**Common Mistakes:**
- Calling `reloadAsync()` silently in the middle of a user action — loses unsaved state and confuses users.
- Shipping a broken update to `production` without testing on `staging` first.
- Not catching errors from `checkForUpdateAsync` — network failures crash the update check and can crash the app.

**Security Considerations:**
- EAS Update bundles are signed by Expo; verify Code Signing is enabled (`expo.updates.codeSigningCertificate` in `app.json`) so devices reject tampered bundles.
- Never embed secrets in JS bundles shipped via OTA — they are readable from the downloaded bundle.

**Testing:**
Publish to the `staging` channel and install via TestFlight / internal track. Verify the update banner appears and reloading lands on the correct version (`Updates.updateId`). Test the rollback path by publishing a known-good update to the `rollback` channel and promoting it to `production`.
