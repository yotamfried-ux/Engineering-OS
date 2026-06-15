# API Patterns

> Pattern library for HTTP API design and implementation. See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring and lifecycle.

## Overview

Patterns for building predictable, safe, and scalable APIs. Covers how to page through large datasets without inconsistency, protect endpoints from abuse, evolve APIs without breaking clients, validate incoming data at the boundary, and return errors in a machine-readable format.

---

## Pattern: Pagination (Cursor-based)

**Problem:** Offset-based pagination (`LIMIT 20 OFFSET 100`) becomes slow on large tables and produces inconsistent results when rows are inserted or deleted between pages.

**Solution:** Use a stable cursor (typically a composite of `createdAt` + `id`) to mark position. Each response includes a `nextCursor`; the client passes it back to get the next page.

**Architecture:**
```
GET /api/posts?limit=20
← { data: [...], nextCursor: "2024-01-15T10:00:00Z_abc123" }

GET /api/posts?limit=20&cursor=2024-01-15T10:00:00Z_abc123
← { data: [...], nextCursor: "2024-01-14T08:30:00Z_xyz789" }
← { data: [], nextCursor: null }  // last page
```

**Implementation Notes:**
- Encode the cursor as base64 to hide implementation details and prevent client manipulation.
- Index on `(createdAt DESC, id DESC)` for the query to be efficient.
- Use `WHERE (created_at, id) < (cursor_ts, cursor_id)` for composite cursor comparison.

**Example Code:**
```typescript
type Cursor = { createdAt: string; id: string };

function encodeCursor(c: Cursor) {
  return Buffer.from(JSON.stringify(c)).toString('base64url');
}

function decodeCursor(raw: string): Cursor {
  return JSON.parse(Buffer.from(raw, 'base64url').toString());
}

async function listPosts(limit: number, cursor?: string) {
  const where = cursor ? (() => {
    const { createdAt, id } = decodeCursor(cursor);
    return { OR: [
      { createdAt: { lt: new Date(createdAt) } },
      { createdAt: new Date(createdAt), id: { lt: id } },
    ]};
  })() : {};

  const rows = await db.post.findMany({ where, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], take: limit + 1 });
  const hasMore = rows.length > limit;
  const data = hasMore ? rows.slice(0, limit) : rows;
  const next = hasMore ? encodeCursor({ createdAt: data.at(-1)!.createdAt.toISOString(), id: data.at(-1)!.id }) : null;
  return { data, nextCursor: next };
}
```

**Common Mistakes:**
- Using a non-unique cursor field (e.g., `createdAt` alone) — records with the same timestamp are skipped or duplicated.
- Exposing raw DB IDs or timestamps in the cursor — leaks schema details.
- Not fetching `limit + 1` rows to determine if there is a next page.

**Security Considerations:**
- Treat cursor values as untrusted input — validate and parse defensively; reject malformed cursors with 400.
- Do not include sensitive data in cursors even when encoded.

**Testing Strategy:**
Test with a dataset that has ties on the cursor field. Verify that paginating through all pages returns every item exactly once. Test that inserting or deleting rows between pages does not cause duplicates or gaps.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Rate Limiting

**Problem:** Without request throttling, a single abusive client (or a misconfigured internal service) can exhaust server resources and degrade service for everyone.

**Solution:** Track request counts per identifier (IP, user ID, API key) in a sliding window stored in Redis. Return `429 Too Many Requests` with a `Retry-After` header when the limit is exceeded.

**Architecture:**
```
Request → Rate Limiter middleware → check Redis counter
  → under limit: increment counter, set TTL, pass through
  → over limit:  return 429 with Retry-After header
```

**Implementation Notes:**
- Use different limits for different endpoint classes: auth endpoints (5/min), read APIs (100/min), write APIs (20/min).
- Use the Redis sliding window log or token bucket algorithm for smooth throttling.
- Identify by `userId` when authenticated, by IP when anonymous; combine both to prevent sharing limits.

**Example Code:**
```typescript
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(100, '1 m'),
  analytics: true,
});

export async function rateLimitMiddleware(req: Request, res: Response, next: NextFunction) {
  const identifier = req.user?.id ?? req.ip;
  const { success, limit, remaining, reset } = await ratelimit.limit(identifier);

  res.setHeader('X-RateLimit-Limit', limit);
  res.setHeader('X-RateLimit-Remaining', remaining);
  res.setHeader('X-RateLimit-Reset', reset);

  if (!success) {
    return res.status(429).json({
      error: 'Too Many Requests',
      retryAfter: Math.ceil((reset - Date.now()) / 1000),
    });
  }
  next();
}
```

**Common Mistakes:**
- Rate-limiting only by IP — proxies and NAT share IPs; authenticated endpoints should limit by user.
- Not returning `Retry-After` — clients cannot implement polite backoff.
- Using in-memory counters — state is lost on restart and not shared across instances.

**Security Considerations:**
- Apply stricter limits to authentication endpoints to slow brute force attacks.
- Log and alert on clients that consistently hit rate limits.
- Consider a short-duration ban for clients that repeatedly exceed limits.

**Testing Strategy:**
Send requests in rapid succession and assert the 101st returns 429. Verify headers are correct. Test that limits reset after the window expires.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: API Versioning

**Problem:** Evolving an API breaks existing clients that depend on the current contract.

**Solution:** Version the API in the URL path (`/v1/`, `/v2/`). Run old and new versions in parallel during a deprecation window. Announce deprecation via headers before removing a version.

**Architecture:**
```
/v1/users  →  v1 router  →  v1 controller (legacy behavior)
/v2/users  →  v2 router  →  v2 controller (new behavior)

Deprecation header: Deprecation: true, Sunset: Sat, 31 Dec 2026 00:00:00 GMT
```

**Implementation Notes:**
- URL path versioning (`/v1/`) is the most client-friendly — visible in logs, bookmarks, and SDK docs.
- Extract shared business logic into a service layer; only the controller/serializer differs between versions.
- Set a minimum deprecation window of 6 months for public APIs.
- Track version usage with analytics before removing any version.

**Example Code:**
```typescript
// Express router composition
import v1Router from './v1/routes';
import v2Router from './v2/routes';

app.use('/v1', deprecationMiddleware('2026-12-31'), v1Router);
app.use('/v2', v2Router);

function deprecationMiddleware(sunsetDate: string) {
  return (_req: Request, res: Response, next: NextFunction) => {
    res.setHeader('Deprecation', 'true');
    res.setHeader('Sunset', new Date(sunsetDate).toUTCString());
    res.setHeader('Link', '</v2/docs>; rel="successor-version"');
    next();
  };
}
```

**Common Mistakes:**
- Versioning too granularly (per endpoint) — creates a maintenance nightmare.
- Never removing old versions — perpetually maintaining legacy code paths.
- Breaking v1 while it is still in the deprecation window.

**Security Considerations:**
- Apply the same auth and security middleware to all active versions.
- Do not back-port new security fixes only to the latest version — patch all supported versions.

**Testing Strategy:**
Run the full test suite against each active version. Add a canary test that calls v1 and asserts the `Deprecation` header is present once it enters sunset.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Request Validation

**Problem:** Invalid or malicious input reaches business logic, causing unexpected errors, data corruption, or security vulnerabilities.

**Solution:** Validate and parse all incoming data at the API boundary using a schema library (Zod, Joi, Yup). Reject invalid requests with structured 400 errors before any business logic runs.

**Architecture:**
```
Request → Validation middleware (parse schema) → typed, validated data → Controller
                                               → 400 Bad Request on failure
```

**Implementation Notes:**
- Validate path params, query strings, headers, and body — not just the body.
- Use `parse` (throw on error) rather than `safeParse` in middleware so you get consistent error handling.
- Strip unknown fields by default (`strict` / `strip`) to prevent mass-assignment vulnerabilities.

**Example Code:**
```typescript
import { z } from 'zod';

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['user', 'admin']).default('user'),
});

function validate<T>(schema: z.ZodType<T>) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({
        error: 'Validation failed',
        details: result.error.issues.map(i => ({ field: i.path.join('.'), message: i.message })),
      });
    }
    req.body = result.data; // replace with parsed, typed data
    next();
  };
}

app.post('/users', validate(CreateUserSchema), createUser);
```

**Common Mistakes:**
- Validating only in the frontend — server must validate independently.
- Returning raw Zod error objects — leaks internal schema details to clients.
- Allowing extra fields through — enables mass-assignment if the ORM persists unknown fields.

**Security Considerations:**
- Validate content length and set body size limits (`express.json({ limit: '1mb' })`).
- Sanitize string fields that will be rendered in HTML downstream (even if your API is not the renderer).

**Testing Strategy:**
Test with valid input (passes), missing required fields (400), wrong types (400), extra fields (stripped), and boundary values (min/max string length, numeric ranges).

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Error Response Format

**Problem:** Each endpoint returns errors differently — some as strings, some as objects, some with HTTP 200 — making client error handling inconsistent and fragile.

**Solution:** Define a single error response schema used across the entire API. Use a centralized error handler that maps internal errors to the schema and appropriate HTTP status codes.

**Architecture:**
```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Human-readable description",
    "details": [{ "field": "email", "message": "Invalid email address" }],
    "requestId": "req_abc123"
  }
}
```

**Implementation Notes:**
- `code` is a machine-readable constant (snake_case or SCREAMING_SNAKE_CASE) — clients branch on this, not the message.
- `message` is for developers, not end users. Keep it factual.
- Include `requestId` (correlation ID) in every error so support can trace logs.
- Map domain errors to HTTP status codes in one place — not scattered across controllers.

**Example Code:**
```typescript
class AppError extends Error {
  constructor(
    public code: string,
    message: string,
    public statusCode = 500,
    public details?: unknown
  ) { super(message); }
}

// Centralized error handler (Express)
app.use((err: unknown, req: Request, res: Response, _next: NextFunction) => {
  const requestId = req.headers['x-request-id'] ?? crypto.randomUUID();
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: { code: err.code, message: err.message, details: err.details, requestId },
    });
  }
  // Unexpected errors: don't leak internals
  console.error({ requestId, err });
  res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred', requestId },
  });
});

// Usage:
throw new AppError('NOT_FOUND', 'User not found', 404);
throw new AppError('VALIDATION_FAILED', 'Invalid input', 400, validationDetails);
```

**Common Mistakes:**
- Returning `{ error: "something went wrong" }` as a string — clients cannot branch on it reliably.
- Leaking stack traces or internal error messages in production responses.
- Using HTTP 200 for errors — breaks any middleware or monitoring that inspects status codes.

**Security Considerations:**
- Never include stack traces, file paths, or DB query details in production error responses.
- Log the full error internally but return only the sanitized version to the client.

**Testing Strategy:**
Assert every error path returns the expected `code` and `statusCode`. Verify that unhandled exceptions return `INTERNAL_ERROR` without leaking details. Confirm `requestId` is always present.

**Score:** TBD (see pattern-lifecycle.md)
