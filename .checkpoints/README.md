# Checkpoints

`.checkpoints/` is for temporary snapshots of work state.

## Ownership boundary

- Checkpoints are **not** policy, runbooks, plans, or source of truth.
- Do not use checkpoints to replace `.claude/plans/`, ADRs, tests, or Git history.
- A checkpoint may help resume work, but any durable rule must move to the canonical owner.

## Use when

- Capturing temporary state before a risky refactor.
- Recording resumable context that should not become a policy document.
- Comparing before/after state during manual review.
