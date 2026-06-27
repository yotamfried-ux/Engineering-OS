# Evals

`evals/` owns repeatable readiness and behavior checks that are not yet enforced as hooks or CI gates.

## Ownership boundary

- Evals verify behavior; they do **not** replace deterministic hooks, GitHub Actions, or `scripts/enforcement/`.
- Once an eval becomes a required blocker, promote it to `scripts/enforcement/tests/` or a workflow gate.
- Keep eval prompts/scenarios minimal and evidence-based.

## Use when

- Testing whether Engineering OS behavior matches the desired workflow.
- Proving installer/readiness behavior before hard enforcement.
- Capturing regression scenarios for agents, routing, templates, and evidence collection.
