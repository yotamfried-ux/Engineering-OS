# Readiness audit and Project 8 experiment gates

Plan Scope: standard

## Goal
Update the canonical operational-readiness audit and known-gaps registry with the current enforcement defects and every prerequisite for a valid Project 8 behavioral/telemetry run.

## Plan
1. Reconcile merged Engineering OS state and open gaps.
2. Inspect Project 8 main, open PRs, local guidance, telemetry/runtime policy, CI, and provider-migration state.
3. Add exact end-to-end closure checklists and official-documentation references to the audit.
4. Keep `known-gaps.tsv` synchronized with every non-closed audit gap.
5. Run deterministic audit/registry/documentation tests through GitHub Actions and perform exact-head self-review.

## Alternatives
- Keep the findings only in a chat response: rejected because they would not become canonical or enforceable.
- Add a separate checklist document: rejected because the user requires the checklist in the readiness audit and duplicate ownership would create drift.
- Mix product migration implementation into this PR: rejected; this PR is governance/audit only.

## Affected Surfaces
- `docs/operations/operational-readiness-audit.md`
- `docs/operations/known-gaps.tsv`
- this Route Plan

## Data/State Impact
Documentation and governance registry only. No telemetry bundle, secret, product database, Project 8 runtime, or provider resource is changed.

## Integration Impact
GitHub live PR/CI state is used as evidence. Project 8 remains unchanged. Official references are from Anthropic Claude Code, GitHub Actions, Vercel, Supabase, Prisma, Playwright, and W3C.

## Validation Plan
- `bash scripts/enforcement/check-known-gaps.sh`
- `bash scripts/enforcement/check-readiness-audit.sh`
- `bash scripts/enforcement/check-documentation-hygiene.sh`
- `bash scripts/enforcement/tests/test-known-gaps.sh`
- `bash scripts/enforcement/run-all-tests.sh`
- exact-head GitHub Actions and review-thread inspection

## Open Questions
None for this audit-only change. Merging remains subject to explicit owner approval.

## Source of Truth Checks
- `docs/operations/operational-readiness-audit.md` — canonical readiness map.
- `docs/operations/known-gaps.tsv` — canonical non-closed gap registry.
- `yotamfried-ux/project-8` PR #9 and current `main` guidance files — experiment contamination and preparation state.
- official vendor references embedded in the audit — implementation contracts.

## Connector Usage Evidence
- source: GitHub connector.
- action: inspected Engineering OS `main`, merged PR #253, stale PR #247, Project 8 `main`, merged migration/preparation PRs, open PRs #1/#9, exact-head CI, and review threads.
- result: current audit drift, hard-hook failure semantics, local guidance contamination, telemetry prerequisites, and provider migration boundaries were identified with concrete files/SHAs.
- decision: register each unresolved condition and require executable closure evidence before full-readiness or experiment-ready claims.
- target: the two canonical audit files above.

## DoD
- [ ] Every newly identified gap has one registry row and one audit matrix/checklist entry.
- [ ] Every closure checklist requires code/config evidence, positive and negative tests, exact-head CI, review, merge, and post-merge validation where applicable.
- [ ] Project 8 experiment blockers include prompt/guidance contamination, PR #9 convergence, fresh-session telemetry, exact bundle selection, provider asset preservation, Supabase/Vercel direction, and product E2E evidence.
- [ ] Official documentation URLs and the decision derived from each are embedded in the audit.
- [ ] All deterministic audit and regression checks pass on the exact PR head.
- [ ] Self-review finds no duplicate canonical owner, stale status, unsupported readiness claim, or product-scope change.

## Progress Lifecycle Evidence
- start: this plan is committed before audit/registry edits.
- middle: pending after the first synchronized audit/registry update.
- pre-merge: pending after exact-head CI and review.