# Required cleanup workflows in merge readiness

| Field | Value |
|---|---|
| Task type | docs / governance / Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | governance, workflow, cleanup, CI, merge |
| Plan Scope | standard |
| Planning Mode | final-for-approval |
| Target paths | scripts/enforcement/check-merge-readiness.sh, docs/operations/main-required-checks.md, scripts/enforcement/tests/test-operational-readiness-gates.sh |
| Task-router evidence | core/task-router.md checked |
| Workflow evidence | core/workflow.md checked |
| Templates | Template Gap Waiver recorded below |
| Patterns | not required for targeted policy wiring |
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | check-merge-readiness, test-operational-readiness-gates, test-required-workflows-contract |

## Capability Evidence

- `routing.task-router-read` — core/task-router.md checked.
- `workflow.workflow-read` — core/workflow.md checked.
- `plan.route-plan-before-write` — plan exists before implementation edits.
- `source.github-repo-read` — GitHub connector used.
- `validation.policy-change-has-validator` — validator coverage selected.
- `validation.coderabbit-policy` — review policy selected.

## Goal

Prevent Engineering OS from reporting merge readiness when semantic cleanup CI workflows are absent or failing.

## Plan

1. Add `semantic-cleanup-policy` and `import-cleanup-policy` to `REQUIRED_WORKFLOWS_DEFAULT` in `scripts/enforcement/check-merge-readiness.sh`.
2. Update `docs/operations/main-required-checks.md` so the operator-facing branch-protection list and context mapping stay synchronized with the deterministic merge gate.
3. Update the operational readiness gate fixture so the positive case includes the cleanup workflows and the missing-workflow negative case proves they are now required.
4. Run/self-review the changed logic and verify no policy contradiction is introduced.

## DoD

- [ ] `check-merge-readiness.sh` requires both cleanup workflows by default.
- [ ] `main-required-checks.md` mirrors the same required workflow list and branch-protection contexts.
- [ ] `test-operational-readiness-gates.sh` positive fixture includes the cleanup workflows.
- [ ] Existing `test-required-workflows-contract.sh` should pass because docs and checker remain synchronized.
- [ ] No merge to `main` occurs without explicit user approval.

## Alternatives

- Leave cleanup workflows advisory only — rejected because the audit classifies semantic cleanup as enforced.
- Rely only on manual branch protection — rejected because the Engineering OS merge-readiness gate is the agent-side deterministic check.
- Add every workflow including post-merge validation — rejected because post-merge validation is push-to-main/repair behavior, not a PR-head merge gate.

## Affected Surfaces

- `scripts/enforcement/check-merge-readiness.sh`
- `docs/operations/main-required-checks.md`
- `scripts/enforcement/tests/test-operational-readiness-gates.sh`

## Data/State Impact

No runtime data, secrets, schema, or user state changes.

## Integration Impact

GitHub Actions and branch-protection operator guidance are affected. No external API behavior changes.

## Source of Truth Checks

| Source | Status | Decision |
|---|---|---|
| CLAUDE.md | checked | Entry point confirmed. |
| core/task-router.md | checked | Governance route selected. |
| core/workflow.md | checked | Workflow requirements confirmed. |
| core/git-policy.md | checked | Required checks confirmed. |
| docs/operations/operational-readiness-audit.md | checked | Cleanup enforcement claim identified. |
| scripts/enforcement/check-merge-readiness.sh | checked | Missing cleanup workflows identified. |

## Connector Evidence

- GitHub connector used for repository files and PR workflow evidence.

## Connector Usage Evidence

- source: GitHub connector on yotamfried-ux/Engineering-OS.
- action: fetched repo files and workflow results.
- result: found missing cleanup workflow requirements.
- decision: add cleanup workflows to the required set.
- target: scripts/enforcement/check-merge-readiness.sh, docs/operations/main-required-checks.md, scripts/enforcement/tests/test-operational-readiness-gates.sh.

## Documentation Asset Evidence

- internal: docs/operations/operational-readiness-audit.md, docs/operations/main-required-checks.md, core/git-policy.md, core/workflow.md, core/task-router.md.
- context7: not required because this is internal shell and Markdown governance.
- decision: internal docs define the policy behavior.

## Skill Evidence

- superpowers: used for plan and verification loop.

## Template Gap Waiver

- reason: targeted governance gate wiring; no scaffold template applies.
- scope: checker, docs, tests.
- risk: low because only existing pull_request workflows are selected.

## Claude Run Trace

- goal: align cleanup enforcement claims with deterministic merge readiness.
- hypothesis: missing cleanup workflow entries should fail merge readiness.
- steps: read sources, open plan, update merge readiness checker, and record mid-loop evidence.
- tools/connectors: GitHub connector.
- evidence: scripts/enforcement/check-merge-readiness.sh now includes semantic and import cleanup policies.
- result: checker update complete; docs and test fixture updates remain in this loop.

## Progress Lifecycle Evidence

- start: Route Plan committed before code/config/test edits for target paths.
- mid: merge readiness checker updated after work began and before docs/test fixture edits.
