# Learning Reuse Gate

This document defines the deterministic reuse layer for `core/learning-loop.md`.

## Lesson metadata

Reusable lessons and failed solutions may declare deterministic matching metadata:

```md
## Applies To Paths
- src/payments
- app/api/stripe

## Domain Tags
- stripe
- payments
- webhooks
```

A lesson is relevant when either:

- the target write path is under one of the `Applies To Paths` prefixes; or
- the active Route Plan `Domain tags` overlap with the lesson `Domain Tags`.

## Route Plan evidence

When a relevant lesson or failed solution exists, the active Route Plan must include:

```md
## Lessons Reused

- `lessons-learned/bugs/stripe-webhook-signature.md`
  - Applied because: this task touches `src/payments`.
  - Prevention: preserve raw-body signature verification.
- `failed-solutions/stripe-json-first.md`
  - Applied because: this failed approach should not be repeated.
  - Prevention: do not parse JSON before signature verification.
```

## Counter update

`Prevented Future Issues` is incremented only when a lesson actually prevents a repeated issue, not every time the lesson is read.

Use:

```bash
bash scripts/enforcement/record-prevented-issue.sh lessons-learned/bugs/<lesson>.md
```

## Enforcement

`check-learning-reuse.sh` blocks a task when relevant knowledge exists but the active Route Plan does not list it under `## Lessons Reused`.

The E2E simulation is `scripts/enforcement/tests/test-learning-reuse.sh`.
