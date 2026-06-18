# Bug Tracking

> Part of the Engineering OS learning loop. See [`learning-loop.md`](../../core/learning-loop.md) for the full lifecycle: Observation → Repeated → Verified → Best Practice.

## When to create a bug record

Create a record here when:
- A bug reached production and caused user-visible impact
- A bug required more than one hour to diagnose
- A bug reveals a weakness in a pattern documented in `patterns/`
- A bug could recur in other parts of the codebase if not documented

Do not create a record for typos, trivial one-line fixes caught immediately in development, or bugs with no learning value beyond the fix itself.

## File naming convention

Sequential IDs: `BUG-001.md`, `BUG-002.md`, etc.

Use the template below. Copy it, fill it in, and commit it in the same PR as the fix.

---

## Bug Record Template

```markdown
# BUG-XXX: [Short descriptive title]

**Date:** YYYY-MM-DD
**Severity:** Critical / High / Medium / Low
**Status:** Open / Fixed / Learning Extracted
**Confidence:** Low / Medium / High (see learning-loop.md › confidence levels)
**Affected Service:** [service name]
**Linked PR:** [link to fix PR]

## Symptom
What was observed? Include logs, error messages, or alert text verbatim.

## Root Cause
The underlying reason this bug existed — not the symptom, not the immediate trigger.
Be specific: "missing null check" is too generic; "webhook handler assumed Stripe always
sends `customer.id` but trial subscriptions omit it in the test event" is the right level.

## Hypotheses Tested
List what was ruled out before confirming the root cause.
- [ ] Hypothesis A — ruled out because [evidence]
- [ ] Hypothesis B — ruled out because [evidence]
- [x] Hypothesis C — confirmed root cause because [evidence]

## Evidence
What logs, traces, DB queries, or reproduction steps proved the root cause?
Paste the key excerpt or link to the Sentry issue.

## Fix Applied
What change was made? One paragraph + link to commit or PR.

## Regression Test
File path and test name of the regression test added alongside the fix.
Must be red before the fix, green after.

## Prevention Strategy
Could this class of bug be caught earlier?
- Lint rule? (link to rule or PR)
- Pre-commit hook? (link to hooks-policy.md if applicable)
- Monitoring alert? (what metric or condition would fire earlier?)
- Pattern update? (which pattern needs a new "Common Mistake" entry?)

## Pattern Impact
If this bug was caused or enabled by a documented pattern in `patterns/`, record:
- Pattern: `patterns/<domain>/README.md` — [pattern name]
- Impact: should the score be adjusted? should a Common Mistake be added?
- Action taken: [description or link]

## Learning Status
Current maturation level per learning-loop.md:
- [ ] Observation (single occurrence)
- [ ] Repeated (seen in ≥2 contexts)
- [ ] Verified (root cause confirmed, regression test in place)
- [ ] Best Practice (prevention strategy active, pattern updated)
```

---

## Index

*No bugs recorded yet. Add the first record when the first qualifying bug occurs.*
