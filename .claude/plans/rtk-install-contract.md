# Route Plan - RTK install contract evidence

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

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- GitHub: inspected PR #131, RTK checker, target project installer, installed settings template, session setup, and current clean install fixture before implementation.

## Connector Usage Evidence

- source: GitHub files `scripts/enforcement/check-rtk-contract.sh`, `scripts/enforcement/tests/test-context-optimizer-contract.sh`, `scripts/enforcement/tests/test-clean-install-and-usage.sh`, `scripts/use-in-project.sh`, `.claude/settings.json`, and `scripts/session-setup.sh`.
- action: checked whether the remaining RTK branch contains safe, non-superseded coverage that should be carried forward.
- result: PR #131 adds an unsafe environment bypass that conflicts with mandatory RTK intent, but it also exposes a useful missing clean-install assertion: target projects should preserve RTK hook/session setup wiring.
- decision: do not merge PR #131 as-is; implement only the safe target-project install contract assertion in the clean-install fixture.
- target: scripts/enforcement/tests/test-clean-install-and-usage.sh

## Documentation Asset Evidence

- internal: `scripts/enforcement/check-rtk-contract.sh`, `scripts/enforcement/tests/test-context-optimizer-contract.sh`, `scripts/enforcement/tests/test-clean-install-and-usage.sh`, `scripts/use-in-project.sh`, `.claude/settings.json`, and `scripts/session-setup.sh` were read.
- context7: not required because this is an internal installer/test contract change and does not change external RTK API behavior.
- decision: strengthen install verification while rejecting the unsafe bypass path.

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

## Claude Run Trace

- goal: salvage safe RTK install-contract coverage without weakening mandatory RTK enforcement.
- hypothesis: adding explicit clean-install assertions for RTK hook/session setup evidence catches target-project installer drift without introducing a bypass.
- connectors: GitHub used for source inspection, open PR inspection, and branch updates.
- steps: inspect PR #131 changes, compare with current main, read installer/settings/session setup, then create this plan before implementation.
- evidence: implementation pending.
- rejected: carrying forward `EOS_BYPASS_RTK=1` is rejected because it creates a fail-open contract bypass for mandatory RTK.
- result: pending implementation.
- follow-up: run CI and merge only after green checks and review evidence.

## DoD

- [x] Route Plan committed before test changes.
- [ ] Clean-install fixture asserts RTK hook command is present in installed target settings.
- [ ] Clean-install fixture asserts SessionStart setup remains wired.
- [ ] Clean-install fixture asserts source session setup still contains `rtk init -g` and `rtk --version`.
- [ ] PR opened and CI green before merge.
