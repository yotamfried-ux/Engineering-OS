# API Design Library

## Overview

Consult this guide whenever you are designing, reviewing, or extending an API — REST or GraphQL — or when you need a reference for authentication patterns, versioning strategy, and documentation tooling. It applies to new endpoints, breaking-change reviews, and onboarding decisions about which OAuth flow to use.

This document covers URL and HTTP method conventions, status-code semantics, error-response schemas, GraphQL schema and naming rules, OpenAPI tooling, authentication standards (JWT, API keys, OAuth 2.0), versioning approaches, and a curated list of common pitfalls. It is intentionally prescriptive: when in doubt, follow the rule here rather than improvising.

---

## REST Standards

### URL Structure

- Use lowercase, hyphen-separated path segments: `/user-profiles`, not `/UserProfiles` or `/user_profiles`.
- Use nouns for resources, not verbs: `/orders`, not `/getOrders`.
- Use plural nouns for collections: `/invoices`, `/products`.
- Nest resources only when the child is always accessed in the context of the parent, and limit nesting to two levels: `/users/{userId}/addresses`.
- Never put actions in the path. Use HTTP methods to express intent: `DELETE /sessions/{id}` instead of `POST /logout-session`.
- Keep query parameters for filtering, sorting, and pagination: `GET /products?status=active&sort=created_at&page=2&per_page=25`.
- Avoid file extensions in paths (`.json`, `.xml`). Use the `Accept` header for content negotiation instead.

### HTTP Methods

| Method  | Semantics                         | Idempotent | Request Body |
|---------|-----------------------------------|------------|--------------|
| GET     | Retrieve a resource or collection | Yes        | No           |
| POST    | Create a new resource             | No         | Yes          |
| PUT     | Replace a resource entirely       | Yes        | Yes          |
| PATCH   | Partially update a resource       | No*        | Yes          |
| DELETE  | Remove a resource                 | Yes        | Rarely       |

\* PATCH is not guaranteed idempotent by the spec; design accordingly (e.g., use conditional requests with `If-Match`).

### Status Codes

| Code | Name                  | When to use                                                                 |
|------|-----------------------|-----------------------------------------------------------------------------|
| 200  | OK                    | Successful GET, PATCH, or PUT that returns a body.                          |
| 201  | Created               | Successful POST that created a resource. Include `Location` header.         |
| 204  | No Content            | Successful DELETE or action that returns no body.                           |
| 400  | Bad Request           | Malformed syntax, missing required fields, type errors.                     |
| 401  | Unauthorized          | Missing or invalid credentials (authentication failure).                    |
| 403  | Forbidden             | Valid credentials, but the caller lacks permission (authorization failure). |
| 404  | Not Found             | Resource does not exist (or is hidden for security reasons).                |
| 409  | Conflict              | State conflict — e.g., duplicate unique key, optimistic-lock mismatch.     |
| 422  | Unprocessable Entity  | Syntactically valid body but semantically invalid (business rule violation).|
| 429  | Too Many Requests     | Rate limit exceeded. Include `Retry-After` header.                         |
| 500  | Internal Server Error | Unexpected server-side failure. Never expose stack traces.                  |
| 503  | Service Unavailable   | Dependency down or overloaded. Include `Retry-After` when known.           |

### Error Response Format

All error responses must use a consistent JSON envelope. Never return a plain string or an HTML error page from an API endpoint.

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable description",
    "details": [
      { "field": "email", "message": "Invalid email format" }
    ],
    "request_id": "req_abc123",
    "docs_url": "https://docs.example.com/errors/VALIDATION_ERROR"
  }
}
```

Rules:
- `code` is a stable machine-readable string (SCREAMING_SNAKE_CASE). Never change it once published.
- `message` is for developers, not end users. Do not expose internal system details.
- `details` is optional but required for validation errors — one entry per invalid field.
- `request_id` must be present in every error response to enable log correlation.
- `docs_url` is optional but strongly recommended for public APIs.

### Versioning Strategy

URL versioning (`/v1/`) is the default approach for public and partner APIs. See the **Versioning** section below for header-based alternatives and the full deprecation policy.

---

## GraphQL Standards

### Schema Design

- Design the schema around the domain model, not the database schema. Expose concepts, not tables.
- Prefer nullable fields over non-null unless the absence of a value is truly a schema error. Non-null fields create stricter contracts that are harder to evolve.
- Use interfaces and unions to represent polymorphic types explicitly rather than encoding type information in string fields.
- Co-locate input types with the mutations that use them: `CreateOrderInput` lives next to `createOrder`.
- Keep the schema additive: adding fields and types is safe; removing or renaming is a breaking change.

### Naming Conventions

| Element       | Convention                           | Example                          |
|---------------|--------------------------------------|----------------------------------|
| Types         | PascalCase                           | `UserProfile`, `OrderLineItem`   |
| Fields        | camelCase                            | `createdAt`, `totalAmount`       |
| Queries       | camelCase, noun or noun phrase       | `user`, `ordersByStatus`         |
| Mutations     | camelCase, verb + noun               | `createOrder`, `cancelInvoice`   |
| Subscriptions | camelCase, event past-tense          | `orderShipped`, `paymentFailed`  |
| Enums         | SCREAMING_SNAKE_CASE values          | `ORDER_STATUS`, `PENDING`        |
| Input types   | PascalCase with `Input` suffix       | `UpdateUserInput`                |

### Error Handling

GraphQL always returns HTTP 200 for well-formed requests. Errors appear in the top-level `errors` array, not via HTTP status codes. This means clients must check both `data` and `errors`.

For partial success (some fields resolved, others failed), the `data` object contains the resolved fields and `errors` contains the failures. Clients must handle this case explicitly.

For domain/business errors (e.g., "item out of stock"), prefer encoding them in the schema as union result types rather than relying on the `errors` array, which is designed for execution errors:

```graphql
union CreateOrderResult = Order | OutOfStockError | ValidationError
```

### Pagination (Relay Connection Spec)

Use the Relay Connection specification for all list fields that may grow unbounded.

```graphql
type OrderConnection {
  edges: [OrderEdge!]!
  pageInfo: PageInfo!
  totalCount: Int
}

type OrderEdge {
  node: Order!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```

Arguments follow the Relay pattern: `first`, `after`, `last`, `before`. Do not invent offset-based pagination for GraphQL lists.

---

## OpenAPI / Documentation

### Spec-First vs Code-First

| Approach   | Pros                                                          | Cons                                                       |
|------------|---------------------------------------------------------------|------------------------------------------------------------|
| Spec-first | Contract is the source of truth; enables parallel work; SDK generation from day one | Requires discipline to keep spec and implementation in sync |
| Code-first | Spec always reflects implementation; less ceremony           | Spec quality depends on annotation quality; harder to review API shape before building |

Prefer spec-first for public and partner APIs where the contract is stable and external consumers exist. Code-first is acceptable for internal APIs in fast-moving services, provided automated sync (e.g., via tests) is in place.

### Tools

- **Swagger UI** — interactive documentation browser for OpenAPI specs: https://swagger.io/tools/swagger-ui/
- **Redoc** — clean, three-panel documentation renderer; well-suited for public developer portals: https://redocly.com/redoc/
- **Scalar** — modern API reference UI with built-in request playground: https://scalar.com/

### SDK Generation

- **openapi-generator** — polyglot generator supporting 50+ languages and frameworks: https://openapi-generator.tech/
- **oapi-codegen** (Go) — generates idiomatic Go server stubs and clients from OpenAPI 3.x specs: https://github.com/oapi-codegen/oapi-codegen

Always pin the generator version in CI to prevent spec-incompatible output from a generator upgrade.

---

## Authentication Standards

### Bearer Token (JWT)

Send the token in the `Authorization` header using the `Bearer` scheme:

```
Authorization: Bearer <token>
```

Validation rules:
- Verify the signature using the correct algorithm (reject `alg: none`).
- Validate `exp` (expiry), `iss` (issuer), and `aud` (audience) on every request.
- Keep access token TTL short (15 minutes to 1 hour). Use refresh tokens for long-lived sessions.
- Never log the full token value.

### API Keys

- Prefer the `Authorization` header with a custom scheme: `Authorization: ApiKey <key>`. This keeps secrets out of server logs that capture URLs.
- Avoid query-parameter API keys (`?api_key=...`) — they appear in access logs, browser history, and referrer headers.
- Store only a hashed representation of the key server-side; show the plaintext value only once at creation.
- Support key rotation: allow multiple active keys per account so callers can rotate without downtime.
- Scope keys to the minimum required permissions.

### OAuth 2.0 Flows for APIs

| Flow                         | Use case                                           | Notes                                          |
|------------------------------|----------------------------------------------------|------------------------------------------------|
| Authorization Code + PKCE    | User-facing apps (web, mobile, SPA)               | Always use PKCE; never use the implicit flow.  |
| Client Credentials           | Service-to-service (no user context)              | Store `client_secret` in a secrets manager.    |
| Device Code                  | CLI tools, smart TVs, headless environments       | User completes auth on a secondary device.     |

Do not use the Resource Owner Password Credentials (ROPC) flow for new integrations. It requires the client to handle user credentials directly and cannot support MFA.

---

## Versioning

### URL Versioning (/v1/, /v2/)

Place the version as the first path segment after the base URL: `https://api.example.com/v1/orders`.

- This is the most discoverable approach: the version is visible in logs, network traces, and bookmarks.
- Route versions at the gateway or load-balancer level so each version can be served by different backend deployments.
- Increment the version only for breaking changes. Additive changes (new optional fields, new endpoints) do not require a version bump.

### Header Versioning

Accept the version via a custom request header:

```
Accept-Version: 2024-11-01
```

Date-based versioning (as used by Stripe and Paddle) is appropriate for APIs with frequent, fine-grained changes. Each version string maps to a snapshot of the API behavior. Keep a changelog mapping version strings to behavioral differences.

Header versioning is less visible than URL versioning and requires more explicit client configuration, but it keeps URLs stable across versions.

### Deprecation Policy

- Set the `Sunset` header on deprecated endpoints with the removal date: `Sunset: Sat, 01 Mar 2026 00:00:00 GMT`.
- Set the `Deprecation` header to the date deprecation was announced: `Deprecation: Mon, 01 Sep 2025 00:00:00 GMT`.
- Maintain deprecated versions for a minimum of 6 months after the announcement (12 months for public APIs with external consumers).
- Notify registered consumers via email at announcement, at 3 months, at 1 month, and 1 week before removal.
- Document the migration path in the API changelog before the deprecation announcement goes out.

---

## Common Pitfalls

- **Using GET for state-changing operations.** GET requests may be cached, prefetched, or retried by infrastructure. Any operation with side effects must use POST, PUT, PATCH, or DELETE.

- **Returning 200 with an error body.** A 200 status signals success to HTTP clients, proxies, and monitoring tools. If the request failed, use the appropriate 4xx or 5xx code. Wrapping errors in `{ "success": false }` inside a 200 breaks every standard HTTP client and alerting system.

- **Exposing internal error details in production responses.** Stack traces, SQL query text, internal hostnames, and library version numbers in error responses give attackers free reconnaissance. Log the details server-side; return only a `request_id` and a stable error code to the caller.

- **Not implementing pagination on list endpoints.** Returning an unbounded array from `GET /orders` will eventually cause timeouts, OOM errors, and client-side rendering failures. All collection endpoints must be paginated from day one.

- **Breaking changes without a version bump.** Removing a field, renaming a field, changing a field's type, and making an optional field required are all breaking changes. Consumers do not control when they upgrade. Deploy breaking changes only behind a new version identifier.

- **Inconsistent plurality in URL paths.** Mixing `/user/{id}` with `/orders` and `/invoice/{id}` forces clients to memorize per-resource conventions. Pick one rule — plural for all collections — and apply it uniformly across every resource in the API.

- **Conflating authentication and authorization in error codes.** Returning 401 when the caller is authenticated but lacks permission (which is a 403) causes clients to incorrectly retry with different credentials rather than treating it as a permission problem. 401 means "prove who you are"; 403 means "I know who you are, but no."

- **Not setting `Content-Type` headers correctly.** Omitting or misconfiguring `Content-Type: application/json` causes some clients and gateways to misparse the body. Always set it explicitly on every response that includes a body, including error responses.

- **Leaking sensitive data in error messages or logs.** Echoing user-supplied input (email addresses, phone numbers, tokens) verbatim into error messages or structured logs creates a data-exposure risk. Sanitize before logging; reference fields by name, not value.

- **Ignoring idempotency for non-idempotent operations.** POST endpoints that create resources should accept an idempotency key (e.g., `Idempotency-Key` header) so clients can safely retry on network failure without creating duplicate records. Without this, a timeout leaves the client unable to know whether the operation succeeded.
