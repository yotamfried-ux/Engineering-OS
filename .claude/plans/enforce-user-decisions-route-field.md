# Route Plan - user decisions route field

| Field | Decision |
|---|---|
| Task type | governance maintenance |
| Task class | engineering_os_governance |
| Domain tags | governance, enforcement, testing |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md checked |
| Workflow evidence | core/workflow.md checked |
| Target paths | scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh; .claude/plans/enforce-user-decisions-route-field.md |
| Templates | existing governance validator maintenance |
| Architecture guides | docs/operations/merge-readiness-checklist.md |
| Patterns | existing enforcement test fixture style |
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | enforcement-tests, pr-policy, connector-evidence-policy, workflow-evidence-policy, capability-evidence-policy, plan-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy |
| Evidence to check | PR #196 diff, workflow runs, head SHA |
| User decisions required | none |

## Definition of Done

- [x] Route Plan contract includes User decisions required.
- [x] Validator enforces the field.
- [x] Regression test proves a missing field fails.

## Source of Truth Checks

| Source | Status | Result |
|---|---|---|
| core/task-router.md | checked | route plan contract requires user decision handling |
| scripts/enforcement/validate-capability-evidence.sh | checked | field list needs the missing contract field |
| scripts/enforcement/tests/test-capability-evidence.sh | checked | regression fixture covers the missing field |

## Documentation Asset Evidence

- internal: core/task-router.md; scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh.
- context7: not required because this is an internal shell and Python validator fixture change with no external library or API integration.
- decision: update the existing validator and its existing test only.

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- GitHub used for repository files, branch state, PR #196, and workflow checks.

## Connector Usage Evidence

- source: GitHub connector.
- action: GitHub connector checked PR #196 and repository files.
- result: PR #196 branch enforce-user-decisions-route-field updated scripts/enforcement/validate-capability-evidence.sh and scripts/enforcement/tests/test-capability-evidence.sh after base 353b2de0b4f3dd1e27a1f5174b5fb8890877c6cf.
- target: scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh.
- decision: updated a minimal validator and fixture change.

## Skill Evidence

- superpowers used for planning and validation discipline.

## Template/Pattern Rating Waiver

No concrete templates/ or patterns/ asset is selected; this is an internal validator and fixture update.

## Claude Run Trace

- goal: enforce User decisions required in the Route Plan validator.
- hypothesis: adding the field to ROUTE_FIELDS plus a missing-field fixture closes the real gap.
- connectors: GitHub.
- steps: create plan first, update validator, update test, record lifecycle checkpoints, run CI.
- evidence: exact-head workflow results before merge.
- result: validator and regression fixture updated.

## Progress Lifecycle Evidence

- start: Route Plan created before code or test changes.
- mid: validator and regression test updated after the start checkpoint.
