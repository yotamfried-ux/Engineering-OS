# Prevention Strategies

> Active measures that prevent known failure classes from recurring. See [`learning-loop.md`](../../core/learning-loop.md) for how lessons graduate into prevention strategies.

## What belongs here

A prevention strategy is a systematic, repeatable action that reduces the likelihood of a known failure class. It is distinct from a one-time bug fix — it changes the development process, tooling, or monitoring so that the failure would be caught earlier next time.

Prevention strategies are created when a bug or post-mortem reaches the "Verified" confidence level and the team agrees it could recur.

## Types of prevention strategies

**Automated enforcement (highest value):** lint rules, pre-commit hooks, CI checks, schema validators. These catch the issue before code is deployed. See [`core/hooks-policy.md`](../../core/hooks-policy.md) for how to add hooks.

**Monitoring / alerting:** metrics, log patterns, or SLO burn rate rules that catch the issue in production before users notice. Document in `patterns/observability/`.

**Pattern update:** a "Common Mistake" entry added to the relevant pattern in `patterns/`. The next developer writing similar code is warned at the point of reading.

**Code review checklist item:** when automated enforcement is not feasible, a documented checklist item surfaces the risk during peer review.

## File naming convention

Sequential IDs: `PREV-001.md`, `PREV-002.md`, etc.

---

## Prevention Strategy Template

```markdown
# PREV-XXX: [Short title — what this prevents]

**Date added:** YYYY-MM-DD
**Linked bug / post-mortem:** BUG-XXX or PM-YYYY-NN
**Type:** Automated enforcement / Monitoring / Pattern update / Review checklist
**Status:** Active / Under review / Superseded

## Failure Class

What class of bug or incident does this prevent?
One sentence describing the root cause pattern, not a specific bug.

## Evidence of Recurrence Risk

Why is this likely to recur without intervention?
(e.g., "same structure appears in 4 other modules", "pattern is used in all new webhooks")

## Prevention Mechanism

How does this prevent the failure?

### If Automated:
- Tool: [lint rule / hook / CI check]
- Location: [file path or CI step name]
- What it checks: [specific condition]
- How to test the check itself: [command]

### If Monitoring:
- Metric or log pattern: [exact query or rule]
- Alert threshold: [when it fires]
- Runbook: [link or inline steps]

### If Pattern update:
- Pattern file: `patterns/<domain>/README.md`
- Section added: [Common Mistakes / Security Considerations / other]
- Change: [summary of what was added]

### If Review checklist:
- Checklist item text: [exact text for the reviewer]
- Where to check: [file type, code pattern, PR condition that triggers the check]

## Validation

How do we know this prevention is working?
- Automated: [test command that verifies the check fires on a deliberately broken example]
- Monitoring: [describe a test scenario or drill]
- Review: [describe how reviewers confirm they applied it]

## Maintenance

What would make this prevention strategy obsolete or need updating?
(e.g., "if we switch from Prisma to a different ORM", "if we deprecate webhooks")
```

---

## Active Prevention Strategies

*No prevention strategies recorded yet. Create the first entry after the first bug or post-mortem is resolved and graduated to "Verified" confidence level.*

---

## Strategy Index by Type

| ID | Title | Type | Linked Failure |
|---|---|---|---|
| — | — | — | — |

*Populated as entries are added.*
