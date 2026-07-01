# Route Plan - RTK install contract

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Target paths | scripts/enforcement/tests/test-clean-install-and-usage.sh |
| Templates | not required |
| Patterns | existing clean install contract fixture style |
| External systems/connectors | GitHub |
| Skills | none |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy, plan-policy, pr-policy |

## Capability Evidence

- routing.task-router-read
- workflow.workflow-read
- plan.route-plan-before-write
- source.github-repo-read
- validation.policy-change-has-validator
- validation.coderabbit-policy

## Connector Evidence

- GitHub: inspected PR #131, RTK checker, target-project installer, installed settings template, session setup, and the current clean-install fixture before implementation.

## Connector Usage Evidence

- source: GitHub files `scripts/enforcement/check-rtk-contract.sh`, `scripts/enforcement/tests/test-context-optimizer-contract.sh`, `scripts/enforcement/tests/test-clean-install-and-usage.sh`, `scripts/use-in-project.sh`, `.claude/settings.json`, and `scripts/session-setup.sh`.
- action: checked whether PR #131 contains safe, non-superseded RTK coverage to carry forward.
- result: PR #131 contains a contract bypass that should not be merged as-is, but it also highlights a safe missing assertion: clean install should prove target projects preserve RTK hook/session setup wiring.
- decision: implemented only the safe clean-install RTK wiring assertions.
- target: scripts/enforcement/tests/test-clean-install-and-usage.sh

## Documentation Asset Evidence

- internal: `scripts/enforcement/check-rtk-contract.sh`, `scripts/enforcement/tests/test-context-optimizer-contract.sh`, `scripts/enforcement/tests/test-clean-install-and-usage.sh`, `scripts/use-in-project.sh`, `.claude/settings.json`, and `scripts/session-setup.sh` were read.
- context7: not required because this is an internal test contract change.
- decision: strengthen install verification without changing RTK runtime behavior.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| core/workflow.md | checked |
| scripts/enforcement/check-rtk-contract.sh | checked |
| scripts/enforcement/tests/test-context-optimizer-contract.sh | checked |
| scripts/enforcement/tests/test-clean-install-and-usage.sh | checked |
| scripts/use-in-project.sh | checked |
| .claude/settings.json | checked |
| scripts/session-setup.sh | checked |

## Progress Lifecycle Evidence

- start: plan committed before modifying the clean install fixture.
- mid: clean-install fixture updated after implementation began to assert installed RTK hook and SessionStart wiring plus source setup commands.
- pre-merge: branch review completed after fixture update; clean branch carries forward safe RTK install verification only.

## Claude Run Trace

- goal: carry forward safe RTK install-contract coverage from old PR work.
- hypothesis: clean-install assertions for RTK hook and SessionStart wiring catch installer drift without adding an RTK bypass.
- connectors: GitHub used for source inspection and branch updates.
- steps: inspect PR #131 changes, compare with current main, read installer/settings/session setup, create this plan, update the clean-install fixture, review the clean branch diff, then open PR #173.
- evidence: implementation added assertions for `rtk hook claude`, `SessionStart`, `scripts/session-setup.sh`, `rtk init -g`, and `rtk --version`.
- rejected: carrying forward the bypass path is rejected because mandatory RTK should not gain a fail-open test contract.
- result: implementation complete and PR opened; CI validation pending.
- follow-up: merge only after green checks and review evidence.

## DoD

- [x] Route Plan committed before test changes.
- [x] Clean-install fixture asserts RTK hook command is present in installed target settings.
- [x] Clean-install fixture asserts SessionStart setup remains wired.
- [x] Clean-install fixture asserts source session setup still contains `rtk init -g` and `rtk --version`.
- [x] PR opened; CI remains the merge gate.
