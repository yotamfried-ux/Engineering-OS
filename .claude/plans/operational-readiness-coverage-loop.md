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
- result: pending CI after branch update.
- follow-up: if CI fails, fix the audit or validator and rerun until green.
- progress_validated: fallback plan file updated in this branch.

## Definition of Done

- [ ] Existing audit file becomes the operational readiness coverage inventory.
- [ ] Audit covers policies, skills, templates, connectors, RTK, graphify, learning, progress tracking, run trace, cleanup, review, post-merge, documentation hygiene, and known gaps.
- [ ] CI validates required audit rows and allowed readiness statuses.
- [ ] No new Markdown policy file is created.
- [ ] RTK is explicitly retained in the coverage map and priority gaps.
- [ ] Self-review confirms no merge to `main` and no silent bypass introduced.
