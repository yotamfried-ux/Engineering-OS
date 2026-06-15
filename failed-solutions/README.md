# Failed Solutions

> A record of approaches that were attempted and abandoned. Reading this before starting implementation prevents repeating failed experiments and explains why the current approach was chosen.
>
> See [`core/debugging-policy.md`](../core/debugging-policy.md) › `<debug_loop>` for when to create a record here.

## Why this directory exists

Engineering knowledge includes knowing what does not work. A failed solution documented here is worth as much as a successful pattern: it saves the next person from spending days on an approach that was already proven unworkable.

This is not a hall of shame. Attempting and documenting a failure is better than never documenting the attempt.

## When to create a record

Create a record when:
- An approach was implemented (not just considered) and then abandoned
- The reason for abandonment is non-obvious and could mislead a future engineer
- The failure produced a useful negative constraint on the solution space
- The approach might seem attractive to future engineers unfamiliar with the context

Do not create a record for:
- Options that were briefly considered and ruled out during planning (document those in the relevant ADR)
- Obvious dead-ends with no learning value
- Failed attempts that were already covered by an existing bug record

## File naming convention

Sequential IDs: `FAIL-001.md`, `FAIL-002.md`, etc.

Optionally include a domain prefix: `FAIL-auth-001.md`, `FAIL-billing-001.md`.

---

## Failed Solution Template

```markdown
# FAIL-XXX: [What was tried — one line]

**Date:** YYYY-MM-DD
**Domain:** [auth / billing / database / api / infrastructure / other]
**Time invested:** [rough estimate]
**Linked task / PR / issue:** [link if available]

## Problem Being Solved

What were we trying to accomplish?

## Approach Attempted

What did we build or configure? Be specific enough that someone could recreate it.

## Why It Failed

What went wrong? Be precise about the failure mode:
- Performance issue (add benchmark numbers)
- Correctness issue (describe the incorrect behavior)
- Incompatibility (describe what it conflicted with)
- Operational issue (describe the operational burden)
- Security issue (describe the vulnerability introduced)

## Evidence

What logs, benchmarks, errors, or tests demonstrated the failure?
Paste the key evidence directly — do not rely on links that may go stale.

## What We Tried to Fix It

List the modifications attempted before abandoning:
1. Tried X → still failed because Y
2. Tried Z → introduced a different problem

## Alternative Chosen

What approach replaced this one, and why does it avoid the failure mode?
Link to the relevant pattern or ADR if documented.

## Warning for Future Engineers

In one sentence: what should someone looking at this problem know before they consider this approach again?
(e.g., "Library X does not support multi-tenant isolation without forking the source.")
```

---

## Index

*No failed solutions recorded yet. Add the first record when an approach is abandoned after implementation.*

| ID | Title | Domain | Date |
|---|---|---|---|
| — | — | — | — |
