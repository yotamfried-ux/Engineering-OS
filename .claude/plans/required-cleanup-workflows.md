# Required cleanup workflows in merge readiness

| Field | Value |
|---|---|
| Task type | docs / governance |
| Task class | engineering_os_governance |
| Target paths | scripts/enforcement/check-merge-readiness.sh, docs/operations/main-required-checks.md, scripts/enforcement/tests/test-operational-readiness-gates.sh |
| Task-router evidence | core/task-router.md checked |
| Workflow evidence | core/workflow.md checked |
| Templates | Template Gap Waiver recorded below |
| Patterns | not required |
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | check-merge-readiness, test-operational-readiness-gates, test-required-workflows-contract |

## Capability Evidence

- `routing.task-router-read` — checked.
- `workflow.workflow-read` — checked.
- `plan.route-plan-before-write` — checked.
- `source.github-repo-read` — checked.
- `validation.policy-change-has-validator` — checked.
- `validation.coderabbit-policy` — checked.

## DoD

- [x] checker test fixture updated.
- [x] docs list updated.

## Source of Truth Checks

| Source | Status | Decision |
|---|---|---|
| core/task-router.md | checked | route |
| core/workflow.md | checked | workflow |
| scripts/enforcement/check-merge-readiness.sh | checked | target |

## Connector Evidence

- GitHub connector used.

## Connector Usage Evidence

- source: GitHub connector.
- action: fetched files.
- result: missing cleanup checks found.
- decision: add cleanup checks.
- target: scripts/enforcement/check-merge-readiness.sh, docs/operations/main-required-checks.md, scripts/enforcement/tests/test-operational-readiness-gates.sh.

## Documentation Asset Evidence

- internal: docs/operations/main-required-checks.md, core/workflow.md, core/task-router.md.
- context7: not required for internal shell and Markdown governance.
- decision: internal docs selected.

## Skill Evidence

- superpowers: used.

## Template Gap Waiver

- reason: internal gate wiring.
- scope: checker, docs, tests.
- risk: low.

## Claude Run Trace

- goal: align checks.
- hypothesis: missing cleanup checks fail readiness.
- steps: plan, checker, docs, tests.
- tools/connectors: GitHub connector.
- evidence: changed target files.
- result: ordered lifecycle recorded.

## Progress Lifecycle Evidence

- start: Route Plan committed before code/config/test edits for target paths.
- mid: merge readiness checker updated after work began and before docs/test fixture edits.
- pre-merge: self-review complete after docs/test fixture edits and checker alignment.
