# Route Plan: docs-architecture-cleanup

PR: #95 · Branch: claude/docs-architecture-cleanup-a1ck9a · Created: 2026-06-27

## Route Plan

| Field | Value |
|---|---|
| Task type | docs / governance / Engineering OS maintenance |
| Domain tags | governance, docs |
| Task-router evidence | core/task-router.md read (routing matrix §7 governance) |
| Workflow evidence | core/workflow.md consulted via engineering-route skill |
| Templates | Not required (governance change) |
| Patterns | Not required (no application code) |
| Skills | engineering-route |
| External systems/connectors | GitHub (PR read/write) |
| Validation gates | validate-orphans.sh, enforcement test suite, workflow-evidence, connector-evidence |

## Source of Truth Checks

- core/task-router.md — read (routing matrix §7 governance)
- core/workflow.md — consulted via engineering-route skill
- scripts/enforcement/MANIFEST.tsv — read (md↔enforcer source for the nav table)
- scripts/validate-orphans.sh — read (existing ownership gate)
- CLAUDE.md, core/documentation-policy.md, core/capability-registry.yaml — read

## Connector Evidence

- [x] GitHub: read repo state via `mcp__github__*`, opened draft PR #95, polled CI check runs
- [x] Not required: no other external connector needed for a docs/governance change

## Skill Evidence

- [x] engineering-route: executed before edits; produced this Route Plan

## Template Gap Waiver

No template required: this is an Engineering OS governance/documentation change, not a new
project scaffold. task-router.md §7 covers this task class.

## Scope

Make CLAUDE.md the canonical central index (navigation + concept-ownership tables covering all
`core/*` files). Delete duplicate placeholder dirs, move misplaced decision records to ADRs,
merge the orphaned policy fragment into its canonical owner, dedupe plan/runbook copies, align
MANIFEST + skills registry. Fix workflow-evidence + connector-evidence gates to ignore deleted
plan files (they previously validated deleted paths).

## Completed Work

- [x] CLAUDE.md `<navigation>` section: nav table (all 18 core entries) + concept-ownership map
- [x] Deleted `docs/official/` and `docs/reference-repos/` placeholder dirs
- [x] Moved 2 decision records to ADR-2026-001 / ADR-2026-002; indexed them
- [x] Merged `connector-enforcement-step1` into `core/connector-policy.md`
- [x] Removed 13 stale plans + 2 plan/runbook twins
- [x] `frontend-design` marked DEPRECATED consistently (registry + policy.md)
- [x] MANIFEST.tsv completeness rows
- [x] Gate fix: workflow-evidence + connector-evidence skip deleted plan files

## Remaining Validation Outside This Plan

- CI green on PR #95 after force-push (workflow-evidence, connector-evidence, enforcement-tests)
