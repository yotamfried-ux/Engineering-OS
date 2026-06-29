# Operational Readiness Coverage Loop

## Goal

Close the first operational-readiness gap: Engineering OS needs a complete, CI-validated coverage inventory while preserving the `CLAUDE.md` to `core/` structure.

## Requirements

- Keep `CLAUDE.md` as the thin entrypoint.
- Reuse `docs/operations/operational-readiness-audit.md` as the coverage inventory.
- Do not create a new Markdown policy file for the coverage matrix.
- Add CI validation so the audit cannot omit policies, skills, templates, connectors, RTK, graphify, learning, progress tracking, run trace, review, post-merge, or cleanup areas.
- Keep statuses honest: enforced, partially enforced, manual, waiver-gated, missing enforcement, or not applicable.
- Do not merge to `main` without explicit user approval.

## Route Plan

Task type: Engineering OS governance / enforcement
Task class: engineering_os_governance
Domain tags: governance, documentation, workflow, testing, hooks, rtk, connectors, skills
Templates: existing enforcement workflow pattern
Architecture guides: none applicable
Patterns: `.github/workflows/enforcement-tests.yml` CI contract and existing audit structure
External systems / connectors: GitHub connector used to read and write repo state; fallback plan file is used for progress tracking in this runtime
Skills: manual self-review; PR review required before merge per policy
Validation gates: CI audit coverage step, workflow syntax review, audit row and status validation, self-review

## Capability Evidence

- `routing.task-router-read` — `core/task-router.md` read before writing.
- `workflow.workflow-read` — `core/workflow.md` read before writing.
- `plan.route-plan-before-write` — this plan exists before repo changes.
- `source.github-repo-read` — repo metadata and relevant files read through GitHub connector.
- `validation.policy-change-has-validator` — add CI validation for the existing audit inventory.
- `validation.coderabbit-policy` — branch is dedicated; merge requires PR, review, and user approval.

## Alternatives

1. Create a new coverage matrix Markdown file. Rejected because the project should avoid new files where an existing owner can be strengthened.
2. Put the full matrix in `CLAUDE.md`. Rejected because `CLAUDE.md` must stay a thin entrypoint.
3. Reuse `docs/operations/operational-readiness-audit.md` and add CI validation. Selected.

## Claude Run Trace

- goal: make the enforcement coverage inventory complete and test-backed.
- hypothesis: the existing audit document is the right canonical place; the gap is CI coverage validation.
- connectors: GitHub connector read repo metadata and files; fallback plan file is used for progress tracking.
- steps: read the entrypoint, workflow, task router, hooks policy, operational audit, and CI workflow; update audit; add CI coverage validation.
- evidence: GitHub file reads and branch changes; CI will validate required audit rows and statuses.
- rejected: new Markdown coverage file; duplicating matrix into `CLAUDE.md`.
- result: PR 127 was behind main, so a clean branch was created from current main and PR 128 opened.
- follow-up: if CI fails, fix the audit or validator and rerun until green.
- progress_validated: fallback plan file updated in this branch.

## Merge-Fix Experiment

- goal: make the first readiness PR safe for merge review.
- hypothesis: replacing the stale branch with a new branch from current `main` is safer than force-updating the old branch.
- connectors: GitHub connector used for compare, branch, file updates, and PR creation.
- steps: compared old branch, confirmed it was behind `main`, created `ops/readiness-coverage-audit` from current `main`, re-applied the audit and CI changes, opened PR 128, and restored this plan after an accidental placeholder commit.
- evidence: compare now reports `behind_by: 0` and only three effective changed files.
- rejected: force-updating `ops/capability-registry-enforcer` after the tool blocked the unsafe ref update.
- result: PR 128 is the clean replacement; PR 127 should not be merged.
- follow-up: check CI, CodeRabbit, review threads, and mergeability before any merge.
- progress_validated: plan updated after the repair step.

## Definition of Done

- [x] Existing audit file becomes the operational readiness coverage inventory.
- [x] Audit covers policies, skills, templates, connectors, RTK, graphify, learning, progress tracking, run trace, cleanup, review, post-merge, documentation hygiene, and known gaps.
- [x] CI validates required audit rows and allowed readiness statuses.
- [x] No new Markdown policy file is created.
- [x] RTK is explicitly retained in the coverage map and priority gaps.
- [x] Self-review confirms no merge to `main` and no silent bypass introduced.
