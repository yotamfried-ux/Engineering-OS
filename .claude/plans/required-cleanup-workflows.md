# Required cleanup workflows in merge readiness

Task type: docs / governance / Engineering OS maintenance
Task class: governance_evidence
Domain tags: governance, workflow, cleanup, CI, merge
Plan Scope: standard
Planning Mode: final-for-approval
Templates: none — policy hardening inside existing Engineering OS governance files
Architecture guides: docs/operations/operational-readiness-audit.md, docs/operations/main-required-checks.md
Patterns: none — no application code pattern change
External systems / connectors: GitHub — repo files, PR/workflow evidence; CodeRabbit unavailable, so self-review is required
Skills: superpowers, security-review/self-review fallback
Validation gates: required-workflows contract, operational readiness gate tests, merge readiness missing-workflow negative case
Evidence to check: CLAUDE.md navigation, core/workflow.md, core/task-router.md, core/git-policy.md, docs/operations/operational-readiness-audit.md, docs/operations/main-required-checks.md, scripts/enforcement/check-merge-readiness.sh, scripts/enforcement/tests/test-operational-readiness-gates.sh
User decisions required: none before PR; merge still requires explicit user approval

## Capability Evidence

- `governance_evidence` — selected because this change tightens PR/merge evidence and required CI workflow enforcement.
- `ci_policy_gate` — selected because the defect is a missing required workflow in merge-readiness gating.
- `cleanup_governance` — selected because semantic cleanup workflows are currently advisory unless included in the required merge gate.

## Goal

Prevent Engineering OS from reporting merge readiness when semantic cleanup CI workflows are absent or failing.

## Plan

1. Add `semantic-cleanup-policy` and `import-cleanup-policy` to `REQUIRED_WORKFLOWS_DEFAULT` in `scripts/enforcement/check-merge-readiness.sh`.
2. Update `docs/operations/main-required-checks.md` so the operator-facing branch-protection list and context mapping stay synchronized with the deterministic merge gate.
3. Update the operational readiness gate fixture so the positive case includes the cleanup workflows and the missing-workflow negative case proves they are now required.
4. Run/self-review the changed logic and verify no policy contradiction is introduced.

## DoD

- [x] `check-merge-readiness.sh` requires both cleanup workflows by default.
- [x] `main-required-checks.md` mirrors the same required workflow list and branch-protection contexts.
- [x] `test-operational-readiness-gates.sh` positive fixture includes the cleanup workflows.
- [x] Existing `test-required-workflows-contract.sh` should pass because docs and checker remain synchronized by the shared workflow-name block.
- [x] No merge to `main` occurs without explicit user approval.

## Alternatives

- Leave cleanup workflows advisory only — rejected because the audit classifies semantic cleanup as enforced.
- Rely only on manual branch protection — rejected because the Engineering OS merge-readiness gate is the agent-side deterministic check.
- Add every workflow including post-merge validation — rejected for this change because post-merge validation is push-to-main/repair behavior, not a PR-head merge gate.

## Affected Surfaces

- `scripts/enforcement/check-merge-readiness.sh`
- `docs/operations/main-required-checks.md`
- `scripts/enforcement/tests/test-operational-readiness-gates.sh`

## Data/State Impact

No runtime data, secrets, schema, or user state changes.

## Integration Impact

GitHub Actions and branch-protection operator guidance are affected. No external API behavior changes.

## Validation Plan

- Static validation: confirm required workflow list includes the two cleanup policy workflows.
- Contract validation: `test-required-workflows-contract.sh` should keep docs and checker in sync.
- Negative validation: a workflow-runs payload missing the cleanup workflows should fail merge readiness.
- Self-review: confirm the change is minimal and does not make post-merge-only workflows required before merge.

## Open Questions

None.

## Progress Validation

- start: created before code/policy edits.
- mid: completed after updating the merge-readiness gate, operator docs, and operational-readiness fixture.
- pre-merge: self-review complete; PR will remain unmerged until live CI/review state is verified and the user explicitly approves merge.

## Verification Evidence

- `scripts/enforcement/check-merge-readiness.sh` now includes `semantic-cleanup-policy` and `import-cleanup-policy` in `REQUIRED_WORKFLOWS_DEFAULT`.
- `docs/operations/main-required-checks.md` mirrors the same required workflow list and branch-protection contexts.
- `scripts/enforcement/tests/test-operational-readiness-gates.sh` includes a positive all-green fixture and a negative `runs-missing-cleanup.json` fixture.
- Local sandbox reproduction of the merge-readiness logic passed the all-green case and failed the missing-cleanup case as expected.
