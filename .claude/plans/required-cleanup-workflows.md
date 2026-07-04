# Required cleanup workflows in merge readiness

| Field | Value |
|---|---|
| Task type | docs / governance |
| Task class | engineering_os_governance |
| Target paths | scripts/enforcement/check-merge-readiness.sh, docs/operations/main-required-checks.md, scripts/enforcement/tests/test-operational-readiness-gates.sh, scripts/enforcement/tests/test-ops-branch-protection.sh, scripts/install-policy-gates.sh, scripts/enforcement/tests/test-clean-install-and-usage.sh |
| Task-router evidence | core/task-router.md checked |
| Workflow evidence | core/workflow.md checked |
| Templates | Template Gap Waiver recorded below |
| Patterns | not required |
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | check-merge-readiness, test-operational-readiness-gates, test-required-workflows-contract, test-ops-branch-protection, test-clean-install-and-usage |

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
- [x] branch protection context test updated.
- [x] downstream installer copies cleanup workflows.
- [x] clean install simulation includes cleanup workflows.

## Source of Truth Checks

| Source | Status | Decision |
|---|---|---|
| core/task-router.md | checked | route selected |
| core/workflow.md | checked | lifecycle selected |
| scripts/enforcement/check-merge-readiness.sh | checked | target updated |
| scripts/enforcement/tests/test-ops-branch-protection.sh | checked | context test updated |
| scripts/install-policy-gates.sh | checked | downstream installer updated |
| scripts/enforcement/tests/test-clean-install-and-usage.sh | checked | clean install test updated |

## Connector Evidence

- GitHub connector used for repository files and workflow evidence.

## Connector Usage Evidence

- source: GitHub connector on yotamfried-ux/Engineering-OS.
- action: GitHub fetched files and workflow results.
- result: GitHub found scripts/install-policy-gates.sh and scripts/enforcement/tests/test-clean-install-and-usage.sh on PR #193 head ebdc12d3bf07a5e4ca07003a699898642b1f10e1.
- decision: added cleanup workflow installation and clean-install coverage.
- target: scripts/enforcement/check-merge-readiness.sh, docs/operations/main-required-checks.md, scripts/enforcement/tests/test-operational-readiness-gates.sh, scripts/enforcement/tests/test-ops-branch-protection.sh, scripts/install-policy-gates.sh, scripts/enforcement/tests/test-clean-install-and-usage.sh.

## Documentation Asset Evidence

- internal: docs/operations/main-required-checks.md, core/workflow.md, core/task-router.md.
- context7: not required for internal shell and Markdown governance.
- decision: internal docs selected.

## Skill Evidence

- superpowers: used.

## Template Gap Waiver

- reason: internal gate wiring.
- scope: checker, docs, tests, installer.
- risk: low.

## Claude Run Trace

- goal: align checks.
- hypothesis: missing cleanup checks fail readiness.
- steps: plan, checker, docs, tests, context test repair, downstream install repair.
- tools/connectors: GitHub connector.
- evidence: changed target files.
- result: ordered lifecycle recorded.

## Progress Lifecycle Evidence

- start: Route Plan committed before code/config/test edits for target paths.
- mid: merge readiness checker updated after work began and before docs/test fixture edits.
- pre-merge: self-review complete after downstream clean-install workflow repair and installer alignment.
