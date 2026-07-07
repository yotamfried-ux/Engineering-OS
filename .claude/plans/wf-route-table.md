# Workflow Routing Route Plan

Plan Scope: standard

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | workflow, governance, routing |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Templates | governance-maintenance waiver |
| Architecture guides | governance-maintenance waiver |
| Patterns | core/task-router.md routing pattern |
| External systems/connectors | GitHub |
| Skills | not required |
| Validation gates | scripts/enforcement/tests/test-required-gates-map.sh |
| Evidence to check | core/task-router.md; core/workflow.md; scripts/enforcement/check-route-plan-contract.sh |
| User decisions required | none |
| selected_project_type | engineering_os_governance |
| selected_template | governance-maintenance waiver |
| selected_roadmap | docs/operations/project-type-roadmaps.md |
| selected_result_loop_contract | scripts/enforcement/result-loop-requirements.tsv |
| required_user_simulation | fixture test coverage |
| local_creator_review_path | local CLI tests |
| telemetry_export_path | scripts/monitoring/export-telemetry-run.sh |
| evidence_policy_rule | metadata-only evidence export |
| Target paths | scripts/enforcement/check-route-plan-contract.sh, scripts/enforcement/tests/test-required-gates-map.sh, docs/operations/workflow-result-loop-integration-audit.md, scripts/enforcement/tests/test-telemetry-archive.sh |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| core/task-router.md | checked | Routing source. |
| core/workflow.md | checked | Workflow source. |
| scripts/enforcement/check-route-plan-contract.sh | checked | Validator target. |
| scripts/enforcement/tests/test-required-gates-map.sh | checked | Fixture target. |
| scripts/enforcement/tests/test-telemetry-archive.sh | checked | Pre-existing hardcoded-date bug found while closing out enforcement-tests failures; fixed to derive the expected archive date from the bundle's own manifest instead of a literal 2026-07-06. |

## Documentation Asset Evidence

- internal: core/task-router.md; core/workflow.md; docs/operations/result-loop-contract-plan.md.
- context7: not required because this is internal governance enforcement.
- decision: docs confirmed checker scope.

## Connector Evidence

- GitHub: used for repository reads and writes.

## Connector Usage Evidence

- source: GitHub repository yotamfried-ux/Engineering-OS.
- action: GitHub inspected main policy files.
- result: GitHub checked scripts/enforcement/check-route-plan-contract.sh and core/workflow.md.
- decision: GitHub selected clean branch and checker target.
- target: scripts/enforcement/check-route-plan-contract.sh; scripts/enforcement/tests/test-required-gates-map.sh; docs/operations/workflow-result-loop-integration-audit.md

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — plan before edits.
- `source.github-repo-read` — repository files read.
- `validation.policy-change-has-validator` — validator in scope.
- `validation.coderabbit-policy` — manual review fallback.

## Claude Run Trace

- read routing and workflow sources.
- added route-plan checker.
- moved route-plan fixture coverage into an existing enforcement test suite.
- added workflow integration audit note.
- added route loop fields used by checker.
- switched route checker to shell implementation.
- fixed route field matching with fixed-string checks.
- removed temporary workflow diagnostics before final validation.
- goal: get PR #223 (route checker) to a clean, all-green merge without claiming full operational readiness.
- hypothesis: the enforcement-tests failure was state leakage between test suites (per prior debugging notes); tested by running the suspected suite standalone.
- rejected: the state-leakage hypothesis, after reproducing the same failure with `bash scripts/enforcement/tests/test-telemetry-archive.sh` run in isolation — confirming instead a hardcoded-date bug in that fixture.
- connectors: GitHub (job logs, PR body, check runs) was the only connector used to diagnose the three failing checks.
- steps: read job logs for enforcement-tests/workflow-evidence-policy/pr-policy; reproduced the telemetry-archive failure locally; patched the fixture to derive its expected date from the export bundle's manifest; refreshed Route Plan scope and evidence.
- evidence: job log output showing `imported telemetry run: 2026-07-07/...` versus the hardcoded `2026-07-06` assertion; local rerun of the full `test-*.sh` suite passing after the fix.
- result: `bash scripts/enforcement/tests/test-telemetry-archive.sh` and the full enforcement-tests suite loop pass locally after the fix.
- follow-up: refresh the pre-merge checkpoint in a final commit after this code change, then update the PR body's Merge Readiness `ci:`/`expected-head-sha:` fields with the final head SHA.

## Graphify Usage Evidence

- source: graphify explain query against graphify-out/graph.json.
- action: ran `graphify explain "test-telemetry-archive.sh"` to check the graph for callers/dependents of this fixture before editing it.
- result: no graph node/edges exist for this fixture script — it is an isolated enforcement test file with no tracked callers or dependents in the graph.
- decision: since the graph shows no dependents for this file, the hardcoded-date fix is safely isolated to scripts/enforcement/tests/test-telemetry-archive.sh with no cross-module impact.
- target: scripts/enforcement/tests/test-telemetry-archive.sh

## Alternatives

- Considered deferring the enforcement-tests hardcoded-date bug (test-telemetry-archive.sh) to a separate PR since it's unrelated to the route checker feature; rejected because CI requires enforcement-tests to be green to merge #223 regardless, the fix is small and isolated to one test file, and it also blocks main/other PRs today.

## Affected Surfaces

- scripts/enforcement/tests/test-telemetry-archive.sh (test fixture only). No product/runtime code paths are touched.

## Data/State Impact

- None: this PR only edits governance scripts, tests, and docs/plan files. No application data or persisted state is affected.

## Integration Impact

- None: no connector, API, or service integration behavior changes. GitHub is used only for PR read/write operations already covered under Connector Evidence.

## Validation Plan

- Run `bash scripts/enforcement/tests/test-telemetry-archive.sh` locally to confirm the date fix passes before pushing.
- Confirm all required GitHub Actions checks (enforcement-tests, workflow-evidence-policy, pr-policy, plan-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy) are green and 0 review threads are open before merge.

## Open Questions

- None outstanding. CodeRabbit is currently rate-limited (confirmed via its own PR comment); the Review Fallback Evidence section documents the accepted self-review path per connector-policy fallback.

## Progress Lifecycle Evidence

- start: core/task-router.md and core/workflow.md were checked before the first code/config/test change.
- mid: route-plan checker was added after the route plan established scope.
- pre-merge: final readiness evidence refreshed after the debug workflow removal and the test-telemetry-archive.sh hardcoded-date fix — this is the last plan update after all code/config/test changes on this branch.

## DoD

- Add route-plan checker.
- Add fixture tests.
- Add audit note.