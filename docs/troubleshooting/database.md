# Database — Common Bugs & Fixes

> Sources: Supabase troubleshooting docs, PostgreSQL official docs, Prisma error reference

## Row-Level Security (RLS)

| Symptom | Root Cause | Fix |
|---|---|---|
| All users see all rows | RLS enabled but no policies created | Create at least one SELECT policy per table; `ENABLE ROW LEVEL SECURITY` alone blocks all without policies |
| Admin operations fail from server | Using anon key server-side | Use `service_role` key only on server; anon key applies RLS, service_role bypasses it |
| Policy works in SQL editor but not in app | Auth context not passed | Ensure `Authorization: Bearer <jwt>` header is sent; Supabase client handles this automatically |
| New table not protected | RLS disabled by default on new tables | Always run `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` on every new table |

## Connection Pooling

| Symptom | Root Cause | Fix |
|---|---|---|
| `too many connections` error | Serverless functions each opening a direct connection | Use pgBouncer (port 5432 → 6543 in Supabase); set `?pgbouncer=true` in connection string |
| Prepared statements fail with pgBouncer | pgBouncer in transaction mode doesn't support named prepared statements | Use simple query mode or session mode for prepared statements |
| Connection pool exhausted on deploy | ORM connection pool size × replicas > DB max_connections | Set `pool_size` to `max_connections / (num_replicas + 1)` |

## Migrations

| Symptom | Root Cause | Fix |
|---|---|---|
| Migration runs in dev but fails in prod | Different Postgres versions or extensions missing | Test migrations against a prod-equivalent environment; check extension availability |
| Lock timeout during migration | `ALTER TABLE` on large table takes an exclusive lock | Use `pg_repack` or `ADD COLUMN ... DEFAULT NULL` (no lock for nullable columns) |
| Migration rolled back but data lost | Non-transactional DDL in migration (e.g., `DROP TABLE`) | Wrap all DDL in transactions; add a backup step before destructive operations |

## ORM / Query Issues

| Symptom | Root Cause | Fix |
|---|---|---|
| N+1 queries degrading performance | ORM lazy-loading relations without join | Use eager loading (`include` in Prisma, `joinedload` in SQLAlchemy) |
| Stale data after write | Query cache not invalidated | Disable query caching for write-heavy paths; use `findUnique` after writes |
| JSON column not queryable | JSON stored as `text` instead of `jsonb` | Use `jsonb` type; enables `->`, `->>` operators and GIN indexes |

## Realtime / Subscriptions

| Symptom | Root Cause | Fix |
|---|---|---|
| Subscription receives no events | Table not added to replication publication | `ALTER PUBLICATION supabase_realtime ADD TABLE tablename;` |
| Realtime events delayed | Logical replication slot lag | Monitor `pg_replication_slots`; avoid large transactions that hold the slot |

## Sources
- [Supabase Troubleshooting](https://supabase.com/docs/guides/troubleshooting)
- [PostgreSQL Connection Management](https://www.postgresql.org/docs/current/runtime-config-connection.html)
- [Prisma Error Reference](https://www.prisma.io/docs/reference/api-reference/error-reference)
- [pgBouncer Config](https://www.pgbouncer.org/config.html)
