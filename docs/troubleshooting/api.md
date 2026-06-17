# API — Common Bugs & Fixes

> Sources: HTTP RFC 9110, Stripe API error design, Google API design guide, OWASP API Security Top 10

## Rate Limiting

| Symptom | Root Cause | Fix |
|---|---|---|
| 429 errors spike under load | No backoff; retrying immediately on 429 | Implement exponential backoff with jitter; respect `Retry-After` header |
| Rate limit hit by a single user | Per-user quota not enforced; shared limit exhausted by one actor | Implement per-user/per-IP rate limits using sliding window (e.g., Redis + token bucket) |
| Burst traffic bypasses rate limit | Fixed window counter resets cause burst at window boundary | Use sliding window algorithm instead of fixed window |

## Authentication / Authorization

| Symptom | Root Cause | Fix |
|---|---|---|
| 401 on valid token | Token expired or wrong `audience` claim | Verify `exp`, `iss`, `aud` claims; refresh token before expiry |
| 403 despite correct role | Authorization check uses stale cached role | Always fetch fresh role/permission from DB on sensitive operations; don't cache RBAC data long-term |
| BOLA / IDOR vulnerability | Authorization only checks auth, not object ownership | Always verify: "does this authenticated user own this resource?" on every request |

## Request Validation

| Symptom | Root Cause | Fix |
|---|---|---|
| Invalid data stored in DB | No server-side validation; trusting client | Validate all inputs with Zod/Joi/Pydantic server-side; never trust client data |
| 400 error with no useful message | Validation error not surfaced to client | Return structured error body: `{ error: "validation_error", details: [{ field, message }] }` |
| Large payload causes OOM | No max body size limit | Set `body-parser` limit (Express) or `next.config.js` body size limit; return 413 for oversized requests |

## Error Handling

| Symptom | Root Cause | Fix |
|---|---|---|
| Stack traces exposed in production | `NODE_ENV` not set to `production`; raw error returned | Catch all errors; return generic 500 message to client; log full error server-side only |
| Error not retried by client | 5xx returned for transient errors without `Retry-After` | For transient errors, return 503 with `Retry-After: <seconds>`; use 500 only for permanent failures |
| Inconsistent error format | Each endpoint returns errors in different shape | Standardize error envelope: `{ error: string, code: string, details?: any }` across all endpoints |

## Versioning / Breaking Changes

| Symptom | Root Cause | Fix |
|---|---|---|
| Clients break on API update | Field removed or renamed without version bump | Use `/v1/`, `/v2/` URL versioning or `API-Version` header; never change field semantics in-place |
| Deprecated endpoint still called | No deprecation header sent | Add `Deprecation: true` and `Sunset: <date>` headers; log deprecated endpoint usage |

## Idempotency

| Symptom | Root Cause | Fix |
|---|---|---|
| Duplicate records on network retry | POST endpoint not idempotent; client retried | Accept `Idempotency-Key` header; store key → result mapping for 24h; return cached result on duplicate |
| DELETE not idempotent | Returns 404 on second call, breaking retry logic | Return 200/204 on DELETE even if resource already gone |

## Sources
- [HTTP Semantics RFC 9110](https://httpwg.org/specs/rfc9110.html)
- [Google API Design Guide](https://cloud.google.com/apis/design/errors)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [Stripe API Error Design](https://stripe.com/docs/api/errors)
- [RFC 7807 Problem Details](https://datatracker.ietf.org/doc/html/rfc7807)
