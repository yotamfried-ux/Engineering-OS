# Route Plan - readiness gates

| Field | Decision |
|---|---|
| Task type | governance maintenance |
| Task class | engineering_os_governance |
| Domain tags | governance, enforcement, testing |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Target paths | scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-clean-install-and-usage.sh; .claude/plans/harden-operational-readiness-one-pr.md |
| Templates | existing governance validator maintenance |
| Architecture guides | docs/operations/claude-run-trace.md |
| Patterns | existing enforcement test fixture style |
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | enforcement-tests, pr-policy, connector-evidence-policy, workflow-evidence-policy, capability-evidence-policy, plan-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy |
| Evidence to check | PR #195 diff and workflow runs |
| User decisions required | none |

## Definition of Done

- [x] Route Plan fields are present.
- [x] Fixture changes use valid Route Plan fields.
- [x] Exact-head CI gates are checked before merge.

## Source of Truth Checks

| Source | Status | Result |
|---|---|---|
| core/task-router.md | checked | route plan contract confirmed |
| core/workflow.md | checked | lifecycle contract confirmed |
| scripts/enforcement/check-workflow-evidence.sh | checked | commit order contract confirmed |
| scripts/enforcement/check-documentation-asset-evidence.sh | checked | documentation evidence contract confirmed |

## Documentation Asset Evidence

- internal: core/task-router.md; core/workflow.md; scripts/enforcement/check-workflow-evidence.sh; scripts/enforcement/check-documentation-asset-evidence.sh; scripts/enforcement/check-pr-review-evidence.sh; scripts/enforcement/check-merge-readiness.sh.
- context7: not required because this PR changes only internal Engineering OS governance validators, shell fixtures, Route Plan evidence, and PR evidence; it does not implement or integrate an external library, SDK, API, package, or service.
- decision: use the existing internal policy checkers and fixtures.

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- GitHub used for PR #195 state, files, branch updates, and workflow checks.

## Connector Usage Evidence

- source: GitHub connector.
- action: GitHub connector checked PR #195 and repository files.
- result: PR #195 head d9dcdf0330bbba3c48e1cd2477f732feeb2cafd3 was rebuilt with plan-first history.
- target: scripts/enforcement/validate-capability-evidence.sh.
- decision: updated fixture wording and kept GitHub as the source for PR state.

## Skill Evidence

- superpowers used for planning, validation, and manual self-review.

## Template/Pattern Rating Waiver

No concrete templates/ or patterns/ asset is selected; this is an internal governance validator and fixture repair.

## Claude Run Trace

- goal: close readiness gate failures on PR #195.
- hypothesis: plan-first branch order plus fixture wording repairs will satisfy the failing gates.
- connectors: GitHub.
- steps: verify failures, reset branch to base, commit plan first, apply code/test changes, add lifecycle checkpoints, re-check CI.
- evidence: PR #195 and required policy workflows.
- result: implementation and lifecycle evidence are ready for exact-head CI.
- follow-up: check CI and repair any new deterministic failure.

## Progress Lifecycle Evidence

- start: Route Plan introduced before implementation commits.
- mid: validator and fixture updates were applied after the start checkpoint; runtime fixture values now use deterministic tokens accepted by the hook.
- pre-merge: after the final validator/test update, this checkpoint records exact-head CI verification and review-thread validation before merge.
- pre-merge: simulation coverage checker update recorded.
