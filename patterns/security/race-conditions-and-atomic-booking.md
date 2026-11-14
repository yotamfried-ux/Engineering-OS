# Race conditions and atomic reservation invariants

**Knowledge type:** Engineering security and correctness pattern, not an installable skill.
**Sources:** official PostgreSQL and OWASP documentation. **No social-media content is used as evidence.**

## When to use

Use this guide whenever two or more concurrent requests can modify the same limited resource or state: appointment slots, tickets, inventory, quotas, coupons, account balances, approval state, webhook delivery or job execution. Review the invariant before writing code.

**Example invariant:** at most one confirmed booking may occupy a given exclusive slot; occupied seats must never exceed capacity; a single-use redemption must happen at most once.

## Failure mode: check-then-act (TOCTOU)

1. Request A reads `available=true`.
2. Request B reads `available=true` before A commits.
3. Both independently insert a booking or increment a counter.
4. The final state violates the business invariant even though each request appeared valid in isolation.

An application-layer `if (available)` check, a frontend disabled button, or an ordinary transaction containing an unprotected read does **not** by itself guarantee correctness.

## Defenses (choose based on the invariant)

1. **Database constraints:** prefer unique/exclusion constraints where the rule is expressible in the schema (e.g., a unique active reservation for a specific discrete slot). Check that the constraint covers the actual business definition, including statuses and overlapping intervals.
2. **Atomic conditional mutation:** when a resource has a single authoritative capacity row, update it with a predicate and check the affected-row count. For example:
   ```sql
   UPDATE events
      SET seats_taken = seats_taken + 1
    WHERE id = $1 AND seats_taken < capacity
   RETURNING id;
   ```
   If no row is returned, reject the reservation. The subsequent booking insert must be in the **same transaction**; roll back the increment on insert failure. This is a pattern, not drop-in application code.
3. **Row-level locking:** in a transaction, lock the relevant authoritative row using `SELECT ... FOR UPDATE`, check current state, then mutate before commit. For interval scheduling, locking only existing bookings may not protect against a concurrent insert of a previously nonexistent overlapping interval: use an appropriate exclusion constraint, shared parent-row lock, or suitable serializable design.
4. **Serializable isolation:** PostgreSQL can detect some serialization anomalies, but the application must retry the **entire transaction** on serialization failures with bounded backoff and idempotency awareness.
5. **Idempotency:** use stable request keys and a unique database-backed record for payment, webhook and retryable workflows; do not confuse idempotency with capacity control.
6. **Lock scope:** avoid long transactions, use a consistent lock acquisition order, and monitor contention/deadlocks. Never assume `SKIP LOCKED` is appropriate for booking decisions; PostgreSQL describes its inconsistent view as suitable mainly for queue-like consumers.

## Required adversarial tests

- Start 2, 10, and 100 requests concurrently against the same final slot; assert **exactly one** succeeds, no duplicate confirmed booking exists, and capacity never exceeds its limit.
- Race overlapping time intervals, cancellation versus booking, reschedule versus booking, payment retries and webhook duplicates; assert final database state, not just HTTP statuses.
- Inject a failure after capacity decrement but before booking insert; assert full rollback.
- Exercise transaction serialization failures and retries; verify no double charges or double side effects.
- Run tests against the actual database engine and isolation settings; mocks alone cannot qualify concurrency correctness.

## Sources and authority

- [PostgreSQL — Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)
- [PostgreSQL — Explicit Locking](https://www.postgresql.org/docs/current/explicit-locking.html)
- [PostgreSQL — Data Consistency Checks at the Application Level](https://www.postgresql.org/docs/current/applevel-consistency.html)
- [PostgreSQL — SELECT locking clauses](https://www.postgresql.org/docs/current/sql-select.html)
- [OWASP — Business Logic Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Business_Logic_Security_Cheat_Sheet.html)
- [OWASP — Race Conditions](https://community.owasp.org/pages/vulnerabilities/race_conditions)

**Evidence boundary:** these sources establish the documented mechanisms and testing principles; this guide does not assert that any specific application is vulnerable or fixed. Production readiness requires a repository-specific threat model and executed concurrent tests.
