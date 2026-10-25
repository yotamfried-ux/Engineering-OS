# Roblox quality, security, testing, operations and safety principles

Sources: [Roblox Creator Hub](https://create.roblox.com/docs), [Safety](https://create.roblox.com/docs/safety), [Content maturity](https://create.roblox.com/docs/production/promotion/content-maturity), [TestEZ](https://github.com/Roblox/testez), [Roblox Studio](https://create.roblox.com/docs/studio).

## High-quality security and networking

Server is authoritative for inventory, combat, currencies, trades and purchases. Treat all client remotes as hostile: validate types, ranges, cooldowns, ownership, permissions and replay. Design rate limits and abuse logging. Test adversarial inputs, concurrent trades, disconnects and cross-server flows. Never place secrets in client scripts.

## Persistence and purchase reliability

Use versioned schemas, bounded retries/backoff, DataStore budgets, safe session handling, migration plans and recoverable failures. Verify receipts server-side and idempotently; simulate duplicate delivery and interrupted sessions. ProfileStore is a **candidate**, not a required or audited dependency.

## Test strategy

Use Luau type checks and lint/format; TestEZ for isolated logic; Roblox Studio playtests with multiple simulated players for replication, networking and UX; device emulation for touch and controllers; profile memory, frame-time and network under realistic loads. Track failures by exact revision, device and repro steps. Do not call static lint a successful multiplayer or purchase E2E test.

## Safety and content

Plan moderation, filtering, user-generated content controls, age-appropriate experiences, ads disclosure, content maturity, IP and privacy from the initial design. Check current Roblox rules and applicable law before release; avoid manipulative spending mechanics.

## LiveOps

Monitor crashes, join failures, latency, data-save failures, purchase errors, retention cohorts, abuse and support reports. Roll out updates in controlled stages where supported, maintain rollback procedures, and measure whether new content improves player outcomes. Treat analytics as signals, not proof of causation.

## Release gate

Require a documented matrix: functionality, multiplayer, persistence, receipts, mobile/controller, accessibility, security, policy, performance, observability and rollback. Mark PASS / FAIL / PARTIAL / BLOCKED / NOT TESTED with concrete evidence. Refer to existing `patterns/testing/`, `patterns/security/`, `docs/launch-readiness/` and `docs/legal-compliance/`.
