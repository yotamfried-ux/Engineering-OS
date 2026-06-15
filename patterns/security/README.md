# Security Patterns
> See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring.

## Overview
Apply these patterns at every trust boundary: API endpoints, form inputs, background jobs that consume external data, and any service-to-service call. Security patterns are not optional hardening — they define the baseline. Add them during initial implementation, not as a retrofit.

---

## Pattern: Input Validation & Sanitization

**Problem:** Unvalidated user input is the root cause of injection attacks, data corruption, and unexpected application states.

**Solution:** Validate structure and types at the boundary where data enters the system, reject early with a clear error, and never pass raw input deeper into the stack.

**Implementation Notes:**
- Use a schema library (Zod, Joi, Pydantic) — do not hand-roll validation logic.
- Validate shape, type, length, and format before any business logic runs.
- Sanitize for the output context (HTML-encode for the DOM, parameterize for SQL). These are separate steps.
- Allowlists beat blocklists: define what is permitted, reject everything else.

**Example:**
```typescript
import { z } from "zod";

const CreateUserSchema = z.object({
  email: z.string().email().max(254),
  username: z.string().min(3).max(30).regex(/^[a-zA-Z0-9_]+$/),
  age: z.number().int().min(13).max(120),
});

// At the API boundary — before any DB call
export async function createUser(raw: unknown) {
  const data = CreateUserSchema.parse(raw); // throws ZodError on failure
  return db.users.create({ data });
}
```

**Common Mistakes:**
- Validating only on the client side and trusting the payload on the server.
- Mixing sanitization (output escaping) with validation (input acceptance) — they solve different problems.
- Using regex blocklists to filter "bad" characters instead of allowlisting valid ones.

**Security Considerations:**
- Never log raw input before validation — it may contain secrets or PII.
- Deeply nested objects can bypass shallow validators; validate recursively.

**Testing:**
For each field, test: valid value passes, empty/null rejects, over-length rejects, wrong type rejects, and at least one injection payload (SQL fragment, `<script>` tag) rejects.

---

## Pattern: CSRF Protection

**Problem:** A malicious site can trigger state-changing requests to your API using the victim's authenticated session cookie.

**Solution:** Combine `SameSite=Strict` (or `Lax`) cookies with a per-session CSRF token validated on every mutating request.

**Implementation Notes:**
- Set `SameSite=Strict` on session cookies — this is the first line of defence and sufficient for most apps.
- For APIs consumed by third-party frontends, use the double-submit cookie pattern: send a random token in both a cookie and a request header; the server verifies they match.
- CSRF protection applies to state-changing methods (POST, PUT, PATCH, DELETE). GET must be side-effect-free.
- Stateless JWT-in-header auth is not vulnerable to classic CSRF — no cookie means no automatic credential attachment.

**Example:**
```typescript
import crypto from "crypto";
import { serialize } from "cookie";

// Middleware: generate and attach CSRF token
export function csrfMiddleware(req, res, next) {
  if (!req.cookies["csrf-token"]) {
    const token = crypto.randomBytes(32).toString("hex");
    res.setHeader("Set-Cookie", serialize("csrf-token", token, {
      httpOnly: false,   // must be readable by JS to put in header
      sameSite: "strict",
      secure: true,
      path: "/",
    }));
    req.csrfToken = token;
  }

  if (["POST", "PUT", "PATCH", "DELETE"].includes(req.method)) {
    const headerToken = req.headers["x-csrf-token"];
    const cookieToken = req.cookies["csrf-token"];
    if (!headerToken || headerToken !== cookieToken) {
      return res.status(403).json({ error: "Invalid CSRF token" });
    }
  }
  next();
}
```

**Common Mistakes:**
- Making the CSRF cookie `HttpOnly` — the JS layer needs to read it to send it as a header.
- Skipping CSRF protection on "internal" admin routes.
- Accepting tokens via query string instead of a header (referer leakage).

**Security Considerations:**
- Rotate the CSRF token on privilege escalation (login, role change).
- The token must be unpredictable — use `crypto.randomBytes`, not `Math.random()`.

**Testing:**
Verify that a POST without the `x-csrf-token` header returns 403. Verify that a mismatched token also returns 403. Verify a valid matching token succeeds.

---

## Pattern: Secret Management

**Problem:** Secrets committed to version control, written to logs, or embedded in build artifacts are exposed to everyone who can read those artifacts — permanently.

**Solution:** Load secrets exclusively from environment variables or a secrets manager at runtime; never reference them as literals in code, config files, or log statements.

**Implementation Notes:**
- Local development: use `.env` files (git-ignored). Production: use the platform's secret store (Vercel env vars, AWS Secrets Manager, Supabase vault).
- Add `.env*` to `.gitignore` before the first commit — re-writing history is painful and incomplete.
- Rotate secrets on a schedule and immediately after suspected exposure.
- Audit access: every secret should have one owner service; avoid sharing secrets between services.

**Example:**
```typescript
// config/secrets.ts — fail fast if a required secret is missing
function requireEnv(key: string): string {
  const val = process.env[key];
  if (!val) throw new Error(`Missing required environment variable: ${key}`);
  return val;
}

export const secrets = {
  databaseUrl: requireEnv("DATABASE_URL"),
  jwtSecret:   requireEnv("JWT_SECRET"),
  stripeKey:   requireEnv("STRIPE_SECRET_KEY"),
} as const;

// NEVER do this:
// const stripeKey = "sk_live_abc123...";
```

**Common Mistakes:**
- Logging `process.env` dumps for debugging.
- Passing secrets as CLI arguments (visible in `ps aux`).
- Using the same secret across staging and production environments.

**Security Considerations:**
- Secrets in environment variables are visible to all processes in that environment — use a secrets manager with per-process access control for high-sensitivity values.
- In CI, mask secret values in log output using the platform's secret masking feature.

**Testing:**
Assert that the app throws or exits on startup when a required env var is absent. Grep the codebase for known secret patterns (`sk_live_`, `AKIA`, etc.) as part of CI.

---

## Pattern: Row-Level Security (RLS)

**Problem:** Application-layer tenant isolation is easily bypassed by a bug in the query layer, exposing one tenant's data to another.

**Solution:** Enforce data access policies in the database using Postgres RLS — every query is filtered by the authenticated user's identity, regardless of what the application layer requests.

**Implementation Notes:**
- In Supabase, RLS is off by default — enable it on every table that holds user or tenant data.
- Always define both a SELECT and a mutating (INSERT/UPDATE/DELETE) policy; an enabled table with no policy denies all access.
- Policies reference `auth.uid()` (Supabase) or a session variable you set for each connection.
- Test policies with a separate DB role that has no superuser privileges — superusers bypass RLS.

**Example:**
```sql
-- Enable RLS on the table
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Users can only read their own documents
CREATE POLICY "select_own_documents"
  ON documents FOR SELECT
  USING (owner_id = auth.uid());

-- Users can only insert documents they own
CREATE POLICY "insert_own_documents"
  ON documents FOR INSERT
  WITH CHECK (owner_id = auth.uid());

-- Users can only update or delete their own documents
CREATE POLICY "mutate_own_documents"
  ON documents FOR UPDATE USING (owner_id = auth.uid());

CREATE POLICY "delete_own_documents"
  ON documents FOR DELETE USING (owner_id = auth.uid());
```

**Common Mistakes:**
- Forgetting to enable RLS on a new table — it defaults to off.
- Writing a permissive catch-all policy (`USING (true)`) while developing and shipping it to production.
- Testing only with the service role (bypasses RLS) and assuming policies work.

**Security Considerations:**
- The service role bypasses RLS — never expose service role credentials to the client.
- Verify policies cover all access patterns: direct table access and any view or function that queries the table.

**Testing:**
Write integration tests that authenticate as user A, create a record, then authenticate as user B and assert the record is not visible or mutable.

---

## Pattern: Rate Limiting

**Problem:** Without request throttling, a single IP or account can exhaust server resources, enumerate data, or brute-force credentials.

**Solution:** Apply a sliding-window or token-bucket rate limit per IP (unauthenticated) and per user ID (authenticated), returning 429 with a `Retry-After` header when exceeded.

**Implementation Notes:**
- Layer limits: strict per-IP limits for auth endpoints, looser per-user limits for general API usage.
- Store counters in Redis for accuracy across multiple server instances — in-memory counters do not work with horizontal scaling.
- Return `Retry-After` and `X-RateLimit-*` headers so clients can back off gracefully.
- Exempt internal health check and monitoring paths.

**Example:**
```typescript
import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(100, "1 m"), // 100 requests per minute
});

export async function rateLimitMiddleware(req, res, next) {
  const identifier = req.user?.id ?? req.ip;
  const { success, limit, remaining, reset } = await ratelimit.limit(identifier);

  res.setHeader("X-RateLimit-Limit", limit);
  res.setHeader("X-RateLimit-Remaining", remaining);
  res.setHeader("X-RateLimit-Reset", reset);

  if (!success) {
    res.setHeader("Retry-After", Math.ceil((reset - Date.now()) / 1000));
    return res.status(429).json({ error: "Too many requests" });
  }
  next();
}
```

**Common Mistakes:**
- Rate limiting only by IP — easily bypassed with rotating proxies. Always add per-user limits once authenticated.
- Using in-memory counters in a multi-instance deployment — counts are not shared.
- Not rate limiting password reset and account enumeration endpoints.

**Security Considerations:**
- Apply stricter limits on auth endpoints (login, password reset, OTP verify) — 5–10 requests per minute is typical.
- Log rate-limit events for anomaly detection; repeated 429s from the same user may indicate an attack.

**Testing:**
Write a test that fires N+1 requests within the window and asserts the N+1th returns 429. Assert that the counter resets after the window elapses.
