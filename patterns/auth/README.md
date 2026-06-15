# Auth Patterns

> Pattern library for authentication and authorization. See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring and lifecycle.

## Overview

Patterns for verifying identity (authn) and enforcing access control (authz). Covers stateless tokens, delegated login via OAuth, server-side sessions, and machine-to-machine API keys. Choose the right pattern based on client type (browser, mobile, server), trust model, and session lifetime requirements.

---

## Pattern: JWT Authentication

**Problem:** Stateless API servers need to verify a caller's identity on every request without hitting the database each time.

**Solution:** Issue a signed JWT on login. The client sends it in the `Authorization: Bearer` header. The server verifies the signature locally — no DB lookup required.

**Architecture:**
```
POST /auth/login  →  Server signs JWT (HS256 or RS256)  →  { accessToken, refreshToken }
GET  /api/resource (Authorization: Bearer <token>)  →  Server verifies sig  →  allow/deny
POST /auth/refresh (refreshToken cookie)  →  new accessToken
```

**Implementation Notes:**
- Access token TTL: 15 minutes. Refresh token TTL: 7–30 days stored in an HttpOnly cookie.
- Store refresh tokens in the DB so they can be revoked individually.
- Include only non-sensitive claims in payload (userId, role). Never include passwords or secrets.
- Use RS256 (asymmetric) when multiple services need to verify tokens without sharing a secret.

**Example Code:**
```typescript
import jwt from 'jsonwebtoken';

const ACCESS_SECRET = process.env.JWT_ACCESS_SECRET!;

export function signAccessToken(userId: string, role: string) {
  return jwt.sign({ sub: userId, role }, ACCESS_SECRET, { expiresIn: '15m' });
}

export function verifyAccessToken(token: string) {
  return jwt.verify(token, ACCESS_SECRET) as { sub: string; role: string };
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Missing token' });
  try {
    req.user = verifyAccessToken(token);
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}
```

**Common Mistakes:**
- Setting access token TTL to hours or days — revocation becomes impossible without a blocklist.
- Storing JWTs in localStorage — vulnerable to XSS; use HttpOnly cookies for refresh tokens.
- Not rotating refresh tokens on each use — replay attacks steal long-lived tokens.
- Trusting `alg: none` — always specify the expected algorithm explicitly on verification.

**Security Considerations:**
- Validate `exp`, `iss`, and `aud` claims on every verification.
- Rotate signing secrets on a schedule; support key IDs (`kid`) for zero-downtime rotation.
- Maintain a short-lived token blocklist (Redis) for immediate revocation when needed.

**Testing Strategy:**
Unit-test `sign` and `verify`. Integration-test middleware with expired, tampered, and missing tokens. Test refresh flow including DB revocation lookup and token rotation.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: OAuth 2.0 / Social Login

**Problem:** Users want to sign in with an existing identity provider (Google, GitHub) without creating another password.

**Solution:** Implement the OAuth 2.0 Authorization Code flow with PKCE. Redirect to the provider, exchange the code server-side, and upsert the user record.

**Architecture:**
```
Browser  →  GET /auth/google  →  redirect to Google (state, code_challenge)
Google   →  redirect /auth/callback?code=...&state=...
Server   →  verify state  →  exchange code → id_token  →  upsert user  →  issue session/JWT
```

**Implementation Notes:**
- Always use PKCE, even for server-side flows — defends against authorization code interception.
- Validate the `state` parameter to prevent CSRF on the callback.
- Upsert users by `provider:subject` (`google:1234567`) — allows one account to link multiple providers.
- Store `providerAccountId`, not the provider's access token, unless you need to call provider APIs.

**Example Code:**
```typescript
import { google } from 'googleapis';

const oauth2Client = new google.auth.OAuth2(
  process.env.GOOGLE_CLIENT_ID,
  process.env.GOOGLE_CLIENT_SECRET,
  `${process.env.APP_URL}/auth/google/callback`
);

export function getAuthUrl(state: string) {
  return oauth2Client.generateAuthUrl({
    scope: ['openid', 'email', 'profile'],
    state,
    access_type: 'offline',
  });
}

export async function handleCallback(code: string) {
  const { tokens } = await oauth2Client.getToken(code);
  oauth2Client.setCredentials(tokens);
  const { data } = await google.oauth2({ version: 'v2', auth: oauth2Client }).userinfo.get();
  return { email: data.email!, name: data.name!, googleId: data.id! };
}
```

**Common Mistakes:**
- Skipping `state` validation — opens CSRF attack on the callback endpoint.
- Trusting a client-supplied email without checking `email_verified` from the provider.
- Using the implicit flow — deprecated; Authorization Code + PKCE is the current standard.

**Security Considerations:**
- `state` values must be short-lived (store in session, expire in 10 minutes).
- Never log authorization codes or access tokens.
- Verify the ID token signature if you parse it directly rather than calling the userinfo endpoint.

**Testing Strategy:**
Mock the OAuth provider. Test state mismatch rejection, successful user upsert, duplicate-email handling when provider differs, and token exchange failure paths.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Session-based Auth

**Problem:** Server-rendered web apps need server-controlled sessions where the server can instantly invalidate login state without waiting for a token to expire.

**Solution:** On login, create a server-side session record in Redis and send the session ID in a signed, HttpOnly cookie. Each request looks up the session in Redis.

**Architecture:**
```
POST /login   →  validate credentials  →  create session in Redis (TTL 24h)  →  Set-Cookie: sid=<signed>
GET  /page    →  server reads cookie  →  Redis lookup  →  attach user to request
DELETE /logout  →  delete Redis key  →  clear cookie
```

**Implementation Notes:**
- Use Redis as the session store for multi-instance deployments (not in-memory).
- Cookie flags: `httpOnly: true`, `secure: true`, `sameSite: 'lax'`.
- Regenerate the session ID after login to prevent session fixation attacks.

**Example Code:**
```typescript
import session from 'express-session';
import RedisStore from 'connect-redis';
import { createClient } from 'redis';

const redis = createClient({ url: process.env.REDIS_URL });
await redis.connect();

app.use(session({
  store: new RedisStore({ client: redis }),
  secret: process.env.SESSION_SECRET!,
  resave: false,
  saveUninitialized: false,
  cookie: { httpOnly: true, secure: true, sameSite: 'lax', maxAge: 86_400_000 },
}));

// After credential validation:
req.session.regenerate(() => {
  req.session.userId = user.id;
  res.redirect('/dashboard');
});
```

**Common Mistakes:**
- Not calling `regenerate()` after login — session fixation vulnerability.
- Using in-memory store in production — sessions lost on restart and not shared across instances.
- Setting `saveUninitialized: true` — creates a session for every anonymous visitor.

**Security Considerations:**
- `Secure` flag ensures the cookie is only sent over HTTPS.
- Implement idle timeout: track `lastSeen` and expire sessions inactive for more than N hours.
- Rate-limit login attempts per IP and per username.

**Testing Strategy:**
Verify login sets cookie, protected routes reject requests without valid sessions, logout deletes the Redis key, and regeneration changes the session ID while preserving user data.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: API Key Auth

**Problem:** Server-to-server integrations need long-lived credentials that are simple to use (no token refresh) and easy to revoke per key.

**Solution:** Generate random API keys with a recognizable prefix, store only a SHA-256 hash in the DB, and validate by hashing the incoming key and comparing.

**Architecture:**
```
POST /api/keys      →  generate key  →  store hash in DB  →  return raw key once
GET  /api/resource (X-API-Key: sk_live_xxx)  →  hash incoming key  →  DB lookup  →  allow/deny
DELETE /api/keys/:id  →  set revokedAt  →  future requests denied
```

**Implementation Notes:**
- Use a recognizable prefix (`sk_live_`, `sk_test_`) so keys can be identified in logs and code.
- Return the raw key exactly once. Store only `SHA-256(key)`.
- Support multiple keys per org with metadata: name, scopes, expiry, last-used timestamp.

**Example Code:**
```typescript
import crypto from 'crypto';

export function generateApiKey(prefix = 'sk_live') {
  const raw = `${prefix}_${crypto.randomBytes(32).toString('base64url')}`;
  const hash = crypto.createHash('sha256').update(raw).digest('hex');
  return { raw, hash };
}

export async function validateApiKey(raw: string, db: DB) {
  const hash = crypto.createHash('sha256').update(raw).digest('hex');
  const key = await db.apiKey.findUnique({ where: { hash } });
  if (!key || key.revokedAt) return null;
  // fire-and-forget update
  db.apiKey.update({ where: { id: key.id }, data: { lastUsedAt: new Date() } });
  return key;
}
```

**Common Mistakes:**
- Storing raw API keys in the DB — a DB dump exposes every key.
- Using sequential or short keys — easily brute-forced.
- Not logging key usage — impossible to audit or detect compromised keys.

**Security Considerations:**
- Never log the full API key; log only the prefix + first 8 characters as an identifier.
- Rate-limit requests per key. Alert on anomalous usage spikes.
- Support scope restrictions (read-only vs. write) and mandatory expiry for high-privilege keys.

**Testing Strategy:**
Test that generation produces unique values, validation rejects tampered and revoked keys, `lastUsedAt` is updated on success, and the raw key is not stored or returned after initial creation.

**Score:** TBD (see pattern-lifecycle.md)

## Official References
- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749) — authorization framework standard
- [PKCE RFC 7636](https://tools.ietf.org/html/rfc7636) — proof key for code exchange
- [JWT RFC 7519](https://tools.ietf.org/html/rfc7519) — JSON Web Token standard
- [Auth0 Docs](https://auth0.com/docs) — identity platform documentation
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html) — security best practices
