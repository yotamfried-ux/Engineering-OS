# Learning Capture Gate

The Learning Capture Gate closes a gap in the learning loop: before this gate, Engineering OS enforced lesson schema and lesson reuse, but did not require a new lesson or failed-solution record after work that should create learning.

## What the gate enforces

For implementation commits whose active Route Plan is classified as bug/debug/incident/rollback-style work, the staged diff must include one of:

1. a new or modified `lessons-learned/bugs/*.md` file;
2. a new or modified `failed-solutions/*.md` file; or
3. a `## Learning Capture Waiver` section in the active Route Plan.

If none is present, the pre-commit hook blocks.

## Why a waiver is allowed

`core/learning-loop.md` intentionally says not every fix becomes a verified lesson. A trivial typo or one-line fix with no reusable root cause should not pollute the lesson corpus.

The waiver makes that decision explicit instead of silently skipping the learning loop.

## Active plan selection

The gate uses this order:

1. `EOS_ACTIVE_PLAN`, if set and readable;
2. `.claude/plans/active.md`, if present;
3. newest `.claude/plans/*.md`, excluding `README.md` and `_TEMPLATE.md`.

## Trigger conditions

The gate triggers when:

- staged implementation files are present; and
- the active Route Plan task class or domain tags contain one of: `bug`, `debug`, `incident`, `rollback`, `hotfix`, `regression`, `production failure`, `production bug`, `production incident`, or `post-mortem`.

## Relationship to existing learning enforcement

This gate does not replace existing learning enforcement:

- `enforce-learning.sh` still validates the schema of staged lessons and failed-solutions.
- `check-learning-reuse.sh` still requires reuse of relevant existing lessons before writing in known areas.
- `enforce-learning-capture.sh` only enforces that bug/debug/incident work creates learning output or an explicit waiver.
