# Architecture Decisions (ADRs)

> Architecture Decision Records document significant technical decisions: why they were made, what alternatives were considered, and what trade-offs were accepted. An ADR is written when a decision is hard to reverse, affects multiple components, or will be questioned by future engineers.
>
> See [`core/workflow.md`](../core/workflow.md) › `<project_scaffold>` for when ADRs are created during project setup.

## When to write an ADR

Write an ADR when:
- Choosing a database, hosting platform, auth provider, or billing system
- Adopting a new framework or replacing an existing one
- Deciding between significantly different architectural approaches (e.g., monolith vs. microservices, REST vs. GraphQL)
- Making a decision that will be questioned in code reviews or onboarding
- Accepting a known trade-off that future engineers should not reverse without reading the rationale

Do not write an ADR for:
- Library version upgrades without architectural implications
- Minor implementation choices (naming, folder structure)
- Decisions that are trivially reversible

## File naming convention

Sequential IDs with date: `ADR-2026-001.md`, `ADR-2026-002.md`, etc.

Include a short title: `ADR-2026-001-database-selection.md`.

## ADR lifecycle

| Status | Meaning |
|---|---|
| **Proposed** | Under discussion; not yet implemented |
| **Accepted** | Decision made and implemented |
| **Superseded** | Replaced by a later ADR (link to replacement) |
| **Deprecated** | No longer relevant (system or context changed) |

---

## ADR Template

```markdown
# ADR-YYYY-NNN: [Decision title]

**Date:** YYYY-MM-DD
**Status:** Proposed / Accepted / Superseded / Deprecated
**Superseded by:** [ADR-YYYY-NNN if applicable]
**Deciders:** [names or roles]
**Related patterns:** [links to patterns/ if this decision shaped a pattern]

## Context

What is the situation that requires a decision?
Include: current system state, constraints, requirements, and what forces are in tension.
Keep this factual — describe the problem, not the solution.

## Decision

What was decided? One clear sentence.

Then one paragraph explaining the reasoning — what was the decisive factor?

## Alternatives Considered

| Option | Pros | Cons | Reason rejected |
|---|---|---|---|
| Option A (chosen) | ... | ... | — |
| Option B | ... | ... | ... |
| Option C | ... | ... | ... |

## Trade-offs Accepted

What are we giving up by choosing this option?
Be honest. A good ADR acknowledges the downsides of the chosen option.

## Consequences

What changes as a result of this decision?
- Immediate: what needs to be done now
- Long-term: what constraints does this impose on future decisions
- Risks: what could go wrong, and how would we know

## Future Review Criteria

Under what conditions should this decision be revisited?
(e.g., "if monthly Stripe fees exceed $X", "if team size exceeds Y engineers", "if latency SLO cannot be met")

## Implementation Notes

Optional: any specifics about how the decision was implemented that future engineers should know.
```

---

## Decision Index

| ID | Title | Status | Date |
|---|---|---|---|
| [ADR-2026-001](./ADR-2026-001-github-readonly-connector.md) | GitHub read-only connector profile | Accepted | 2026-06-27 |
| [ADR-2026-002](./ADR-2026-002-managed-settings-rollout.md) | Claude Code managed settings rollout | Accepted | 2026-06-27 |
