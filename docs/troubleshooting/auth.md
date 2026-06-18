# Auth — Common Bugs & Fixes

> Sources: Auth0 troubleshooting docs, Clerk docs, NextAuth.js docs, Supabase Auth docs, OWASP Authentication Cheat Sheet

## OAuth / Redirect Flow

| Symptom | Root Cause | Fix |
|---|---|---|
| `redirect_uri_mismatch` error | Callback URL not registered in provider dashboard | Add exact URL (scheme + host + port + path) to allowed callbacks; wildcards not supported in most providers |
| Redirect loop after login | Session not persisting; auth check runs before cookie set | Check cookie `SameSite`/`Secure` settings; ensure middleware reads session correctly on first load |
| Silent auth fails in Safari | ITP blocks 3rd-party cookies used by iframe-based silent refresh | Use refresh token rotation; disable silent auth, rely on refresh tokens |
| `state` mismatch CSRF error | `state` param not stored in session before redirect | Store `state` in session/cookie before initiating OAuth; verify on callback |

## JWT / Token Issues

| Symptom | Root Cause | Fix |
|---|---|---|
| `invalid_token` on API calls | Using `id_token` to call APIs instead of `access_token` | ID tokens are identity proofs only; use `access_token` with correct `audience` |
| Token expired silently | Token not refreshed before expiry | Check `exp` claim; refresh 60s before expiry using refresh token |
| Missing custom claims on token | Post-login hook/action not configured | Add claims via provider Action/Rule; use a namespace (e.g., `https://myapp.com/role`) to avoid conflict |
| `JWT must not be accepted` (Supabase + Clerk) | JWT template not configured correctly | Create a Clerk JWT template named "supabase" matching Supabase's expected claims (`sub`, `role`, `iss`) |

## Session Management

| Symptom | Root Cause | Fix |
|---|---|---|
| User logged out on page refresh | Session stored in memory, not persisted | Use `localStorage` or `httpOnly` cookie for session; not `sessionStorage` (cleared on tab close) |
| Session not invalidated on logout | Only clearing client-side token; server session still valid | Call provider's logout endpoint to revoke server session + clear local token |
| Multiple tabs have different auth state | Auth state not synced across tabs | Use `BroadcastChannel` or `storage` event to sync auth state across tabs |

## Protected Routes / Middleware

| Symptom | Root Cause | Fix |
|---|---|---|
| API routes accessible without auth | Middleware only applied to pages, not API routes | Extend middleware matcher to include `/api/**` routes |
| Auth check passes with expired token | Token expiry not validated server-side | Always verify token signature AND `exp` claim server-side; don't trust client-supplied auth state |
| Role-based access bypassed | Role check in UI only, not in API | Always enforce RBAC in the API layer; client-side role checks are UX-only, never security |

## Webhook Verification

| Symptom | Root Cause | Fix |
|---|---|---|
| Spoofed webhook events processed | Signature not verified | Use HMAC verification with the webhook secret; reject any request where signature doesn't match |
| Webhook fails with 400 | Raw body not used for verification | Most providers (Stripe, Clerk) require the raw unparsed body for HMAC; don't parse JSON before verifying |

## Sources
- [Auth0 Troubleshooting](https://auth0.com/docs/troubleshoot)
- [Clerk Troubleshooting](https://clerk.com/docs/troubleshooting/overview)
- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [NextAuth.js Troubleshooting](https://next-auth.js.org/getting-started/client)
