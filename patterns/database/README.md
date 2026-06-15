# Database Patterns

> Pattern library for database access, data integrity, and schema management. See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring and lifecycle.

## Overview

Patterns for safe, maintainable data access. Covers the abstraction layer between business logic and storage, concurrency control, data lifecycle management, schema evolution, and connection management. Most patterns apply across PostgreSQL, MySQL, and SQLite with minor adaptations.

---

## Pattern: Repository Pattern

**Problem:** Business logic is scattered with raw SQL or ORM queries, making it hard to test, swap data sources, or enforce consistent access rules.

**Solution:** Create a repository class per aggregate root that encapsulates all data access for that entity. Business logic calls repository methods; repositories own the query logic.

**Architecture:**
```
Service Layer  →  UserRepository.findByEmail()
               →  UserRepository.create()
               →  UserRepository.update()
Repository     →  DB / ORM queries
```

**Implementation Notes:**
- Repository interface is defined in the domain layer; implementation lives in the infrastructure layer.
- Constructor-inject the DB client so repositories are easily testable with a mock/in-memory DB.
- Keep repositories focused: one per aggregate root, not one per table.

**Example Code:**
```typescript
interface UserRepository {
  findById(id: string): Promise<User | null>;
  findByEmail(email: string): Promise<User | null>;
  create(data: CreateUserInput): Promise<User>;
  update(id: string, data: Partial<User>): Promise<User>;
}

class PrismaUserRepository implements UserRepository {
  constructor(private db: PrismaClient) {}

  findById(id: string) {
    return this.db.user.findUnique({ where: { id } });
  }

  findByEmail(email: string) {
    return this.db.user.findUnique({ where: { email } });
  }

  create(data: CreateUserInput) {
    return this.db.user.create({ data });
  }

  update(id: string, data: Partial<User>) {
    return this.db.user.update({ where: { id }, data });
  }
}
```

**Common Mistakes:**
- Leaking ORM-specific types (e.g., Prisma's `Prisma.UserWhereInput`) into the service layer.
- Creating "god repositories" that span multiple unrelated entities.
- Bypassing the repository with direct DB calls in service code.

**Security Considerations:**
- All queries go through the repository — a natural place to enforce row-level access checks.
- Avoid building dynamic queries from user input; use parameterized methods.

**Testing Strategy:**
Unit-test services by injecting an in-memory or mock repository. Integration-test the Prisma implementation against a real test DB spun up with Docker Compose.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Optimistic Locking

**Problem:** Two concurrent requests read the same record and both try to update it — the second write silently overwrites the first (lost update problem).

**Solution:** Add a `version` column to the record. On update, include `WHERE version = <read_version>` and increment the version. If the row count is 0, the update was lost — retry or surface an error.

**Architecture:**
```
Thread A reads:  { id: 1, balance: 100, version: 3 }
Thread B reads:  { id: 1, balance: 100, version: 3 }
Thread A writes: UPDATE ... SET balance=80,  version=4 WHERE id=1 AND version=3  → 1 row
Thread B writes: UPDATE ... SET balance=120, version=4 WHERE id=1 AND version=3  → 0 rows → conflict
```

**Implementation Notes:**
- Use `@version` / `rowVersion` columns (integer or timestamp). Integers are more portable.
- Wrap the update in a retry loop with exponential backoff for transient conflicts.
- Surface `409 Conflict` to clients when the retry budget is exhausted.

**Example Code:**
```typescript
async function transferFunds(db: DB, accountId: string, amount: number, maxRetries = 3) {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const account = await db.account.findUnique({ where: { id: accountId } });
    if (!account) throw new Error('Account not found');

    const result = await db.account.updateMany({
      where: { id: accountId, version: account.version },
      data: { balance: account.balance - amount, version: account.version + 1 },
    });

    if (result.count === 1) return; // success
    // count === 0 means concurrent update — retry
    await sleep(Math.pow(2, attempt) * 50);
  }
  throw new ConflictError('Could not update account after retries');
}
```

**Common Mistakes:**
- Using `updatedAt` as the version column — timestamp precision can cause false passes.
- Not retrying — surfaces conflicts to users unnecessarily.
- Applying optimistic locking where pessimistic locking (SELECT FOR UPDATE) is more appropriate (short, high-contention operations).

**Security Considerations:**
- Never let clients supply the version value in a write request without validation.

**Testing Strategy:**
Simulate concurrent updates in integration tests. Assert that exactly one succeeds and the other receives a conflict error. Test retry logic with a mock that fails N-1 times.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Soft Delete

**Problem:** Hard-deleting records breaks foreign key relationships, removes audit history, and makes "undo" impossible.

**Solution:** Add a `deletedAt` (nullable timestamp) column. "Deleting" sets this field; all queries filter `WHERE deleted_at IS NULL`. A background job or archival strategy handles permanent removal later.

**Architecture:**
```
DELETE /users/:id  →  UPDATE users SET deleted_at = NOW() WHERE id = :id
GET    /users      →  SELECT * FROM users WHERE deleted_at IS NULL
Admin  /restore/:id →  UPDATE users SET deleted_at = NULL WHERE id = :id
```

**Implementation Notes:**
- Add a partial/conditional index: `CREATE INDEX ON users (email) WHERE deleted_at IS NULL` to maintain unique constraint on active records.
- Use a global query scope (Prisma middleware, TypeORM global scope) so developers never forget to filter.
- Store who deleted and why in `deletedBy` and `deleteReason` columns for audit purposes.

**Example Code:**
```typescript
// Prisma middleware to auto-filter soft-deleted records
prisma.$use(async (params, next) => {
  if (params.model === 'User') {
    if (params.action === 'findMany' || params.action === 'findFirst') {
      params.args.where = { ...params.args.where, deletedAt: null };
    }
    if (params.action === 'delete') {
      params.action = 'update';
      params.args.data = { deletedAt: new Date() };
    }
  }
  return next(params);
});
```

**Common Mistakes:**
- Forgetting to filter `deleted_at IS NULL` in raw queries or reports — exposing deleted data.
- Not enforcing unique constraints on active records only — duplicate emails appear after "deletion".
- Never permanently purging data — violates GDPR right-to-erasure requirements.

**Security Considerations:**
- Implement a purge policy: permanently delete records where `deletedAt < NOW() - INTERVAL '30 days'` (adjust to compliance requirements).
- Ensure soft-deleted records are excluded from API responses and search indexes.

**Testing Strategy:**
Test that deleted records are invisible to normal queries, visible to admin queries, restorable, and that unique constraints still work after soft deletion.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Database Migrations Strategy

**Problem:** Schema changes deployed without coordination break running instances, cause downtime, or produce irreversible data loss.

**Solution:** Use forward-only, versioned migration files. Apply additive changes first (add nullable column), then deploy code, then tighten constraints. Never modify existing migrations.

**Architecture:**
```
migrations/
  0001_create_users.sql
  0002_add_users_role.sql          ← additive: nullable column first
  0003_backfill_users_role.sql     ← data migration: set defaults
  0004_set_users_role_not_null.sql ← constraint: after all rows have values
```

**Implementation Notes:**
- Each migration file is immutable once merged. New changes = new migration file.
- Separate DDL migrations (schema) from DML migrations (data backfills) — backfills can be slow and should not block schema locks.
- Test rollback path even if you only run forward in production — validates the migration is understood.
- Use advisory locks or migration tool locking (Flyway, Alembic, `migrate`) to prevent concurrent runs.

**Example Code:**
```sql
-- 0002_add_subscription_tier.sql
-- Safe: adding a nullable column is instant on Postgres 11+
ALTER TABLE users ADD COLUMN subscription_tier TEXT;

-- 0003_backfill_subscription_tier.sql
-- Batched to avoid locking the whole table
UPDATE users SET subscription_tier = 'free' WHERE subscription_tier IS NULL AND id BETWEEN 1 AND 10000;
-- (run in batches via application code or a migration script)

-- 0004_set_subscription_tier_not_null.sql
-- Only after backfill is complete
ALTER TABLE users ALTER COLUMN subscription_tier SET NOT NULL;
ALTER TABLE users ALTER COLUMN subscription_tier SET DEFAULT 'free';
```

**Common Mistakes:**
- Adding a NOT NULL column without a default in one step — locks the table for the duration of the backfill on large tables.
- Renaming columns in a single deployment — breaks old instances still reading the old name.
- Editing or deleting past migration files — causes checksum mismatches and breaks other environments.

**Security Considerations:**
- Never put credentials or sensitive data in migration files — they live in version control.
- Restrict migration execution to CI/CD pipelines with a dedicated DB user that has only DDL privileges.

**Testing Strategy:**
Run migrations against a schema-only dump of production in CI. Verify idempotency (run twice without error). Test that the application works after each migration step independently.

**Score:** TBD (see pattern-lifecycle.md)

---

## Pattern: Connection Pooling

**Problem:** Opening a new DB connection per request is slow (TCP handshake + auth) and exhausts the DB's max connection limit under load.

**Solution:** Use a connection pool that maintains a fixed number of persistent connections and lends them to requests. In serverless environments, use an external pooler (PgBouncer, Supabase Pooler).

**Architecture:**
```
App instances (N)  →  PgBouncer (transaction-mode pooling)  →  PostgreSQL (max 100 connections)
                      pool size = 20 per app instance
                      effective connections = 20 (not N × 20)
```

**Implementation Notes:**
- Set `pool.max` to `(DB max_connections - 5 for admin) / number_of_app_instances`.
- Use transaction-mode pooling for serverless / short requests; session-mode for apps using advisory locks or `SET LOCAL`.
- Always set `pool.idleTimeoutMs` and `pool.connectionTimeoutMs` to avoid leaked connections.

**Example Code:**
```typescript
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,                    // max connections in pool
  idleTimeoutMillis: 30_000,  // close idle connections after 30s
  connectionTimeoutMillis: 2_000, // fail fast if pool is exhausted
});

// Always release — use try/finally
async function query(sql: string, params: unknown[]) {
  const client = await pool.connect();
  try {
    return await client.query(sql, params);
  } finally {
    client.release();
  }
}
```

**Common Mistakes:**
- Not releasing connections back to the pool — pool exhaustion under load.
- Setting `max` too high — overwhelms the DB with connections.
- Ignoring `connectionTimeoutMillis` — requests queue indefinitely instead of failing fast.

**Security Considerations:**
- Use a separate DB user with minimal privileges for the application pool.
- Rotate DB credentials without restarting the app by draining and recreating the pool.

**Testing Strategy:**
Load-test with concurrent requests to verify pool exhaustion produces a timeout error (not a hang). Assert that connections are always released by checking `pool.totalCount` after each test.

**Score:** TBD (see pattern-lifecycle.md)
