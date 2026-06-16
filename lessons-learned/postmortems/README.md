# Post-Mortems

> Use this for incidents with significant user-visible or business impact. See [`learning-loop.md`](../../core/learning-loop.md) for the full process.
>
> A post-mortem is blameless. The goal is to understand the system failure, not to assign personal fault.

## When to write a post-mortem

Write a post-mortem when an incident meets at least one of:
- User data was lost or corrupted
- The service was unavailable for more than 15 minutes
- A payment flow failed for one or more customers
- A security boundary was breached or nearly breached
- The incident required waking someone up outside business hours

Do not write a post-mortem for bugs caught in staging, brief blips below the 15-minute threshold, or incidents fully covered by a bug record in `bugs/`.

## File naming convention

Sequential IDs with date prefix: `PM-2026-01.md`, `PM-2026-02.md`, etc.

---

## Post-Mortem Template

```markdown
# PM-YYYY-NN: [Title — what failed and what the user impact was]

**Date of incident:** YYYY-MM-DD HH:MM UTC
**Duration:** X hours Y minutes
**Severity:** SEV-1 (complete outage) / SEV-2 (partial / degraded) / SEV-3 (minor impact)
**Status:** Draft / Under Review / Final
**Author(s):** [name(s)]
**Linked bugs:** [BUG-XXX if a bug record also exists]

---

## Impact

Who was affected and how?
- Users affected: [N users / all users / specific subset]
- Revenue impact: [estimated or "unknown"]
- Data loss: [yes / no / unknown — describe if yes]
- SLO impact: [X minutes of the monthly error budget consumed]

---

## Timeline

All times UTC. Be precise — round to the minute.

| Time | Event |
|---|---|
| 14:32 | Alert fired: p99 latency > 5 s on `/api/checkout` |
| 14:35 | On-call engineer acknowledged |
| 14:41 | Identified elevated DB connection count |
| 14:58 | Root cause confirmed: connection pool exhaustion from missing `release()` |
| 15:10 | Fix deployed to production |
| 15:15 | Latency normalized, incident resolved |

---

## Root Cause

One clear, specific sentence describing the technical root cause.

Then one paragraph explaining why this root cause existed — the systemic factor, not just the proximate cause.

---

## Five Whys (or as many as needed)

1. Why did the service degrade? — Connection pool was exhausted.
2. Why was the pool exhausted? — Connections were not released after DB queries in the webhook handler.
3. Why were connections not released? — The handler used `await db.query()` directly instead of the pooled client with `try/finally`.
4. Why was the pooled client not used? — The webhook handler was written before the connection pooling pattern was established.
5. Why did this go undetected? — No alert on `pool.idleCount` approaching zero.

---

## What went well

Things that helped contain or resolve the incident faster than expected.

---

## What went poorly

Things that slowed diagnosis, worsened impact, or were surprising.

---

## Action Items

| Action | Owner | Due | Status |
|---|---|---|---|
| Add `pool.idleCount` alert | [name] | YYYY-MM-DD | Open |
| Update database connection pooling pattern with `try/finally` note | [name] | YYYY-MM-DD | Open |
| Add regression test for connection release | [name] | YYYY-MM-DD | Open |

---

## Pattern Impact

Did this incident reveal a weakness in a documented pattern?
- Pattern: `patterns/database/README.md` — Connection Pooling
- Change needed: add "Common Mistake" entry about missing `try/finally` release

---

## Learning Status

- [ ] Draft post-mortem complete
- [ ] Action items assigned
- [ ] Pattern updated (if applicable)
- [ ] Learning graduated to prevention strategy (if recurring)
```

---

## Index

*No post-mortems recorded yet. Add the first record when the first qualifying incident occurs.*
