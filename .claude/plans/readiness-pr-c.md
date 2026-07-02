# Readiness PR C — trace, simulation, test-contract, and plan-selection hardening

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task type | governance |
| Domain tags | readiness, enforcement |
| Task-router evidence | core/task-router.md checked; routed via routing_matrix section 7 |
| Workflow evidence | core/workflow.md checked; plan-file fallback carries the spec |
| Target paths | scripts/enforcement/enforce-run-trace.sh, scripts/enforcement/enforce-tests.sh, scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/lib/evidence.sh, scripts/enforcement/pre-tool-use-runtime-evidence.sh, scripts/enforcement/check-plan-scope.sh, scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/check-documentation-asset-evidence.sh, scripts/enforcement/simulation-coverage.tsv, scripts/enforcement/simulation-coverage.d, scripts/enforcement/coverage-required-gates.tsv, scripts/enforcement/tests, docs/operations/claude-run-trace.md, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, lessons-learned/bugs |
| Templates | not required |
| Patterns | not required |
| Skills | none |
| External systems/connectors | github |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, documentation-asset-policy, capability-evidence-policy, plan-policy, pr-policy, semantic-cleanup-policy, import-cleanup-policy |

## Scope

PR C closes four open gaps: deterministic run-trace scope with validated waiver bodies, an explicit non-waivable simulation token plus two real waiver fixtures, a CI hard-fail / local named-waiver contract for missing test tools, and shared target-aware active-plan selection across the three plan-consuming gates; plus the approved DoD quality schema and documentation-asset broad-claim rejection.

## Alternatives

- Document the tests-tool contract in core/quality-gates.md — rejected for this PR: MANIFEST md-sync would force a same-commit enforce-quality.sh change; the contract lives in the enforce-tests.sh header and the audit row instead.
- Fail stale plans outright when no plan matches a write target — rejected: no-match keeps today's newest-plan behavior so nothing new fails open or closed; only wrong-newest selection is corrected.
- Treat every waived simulation cell as replaceable — rejected: eight cells describe gates with deliberately no waiver path; they migrate to an explicit none-by-design token instead of pretending to be coverage debt.
- Require a verification verb in every DoD item — rejected as pretend-precision; the schema requires one concrete verification signal per DoD section and no placeholder items.

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read this session before writes.
- `workflow.workflow-read` — core/workflow.md read this session before writes.
- `plan.route-plan-before-write` — this plan is committed before the first code change of PR C.
- `source.github-repo-read` — GitHub MCP re-verified state after re-auth: PR #181 open draft at c54edcb, PR #180 identified as overlapping and closed as superseded per owner decision.
- `validation.policy-change-has-validator` — every gate change in this PR ships fixture tests in scripts/enforcement/tests.
- `validation.actions-checked` — CI results for the PR head SHA are verified before merge readiness.
- `validation.coderabbit-policy` — dedicated branch, draft PR based on the PR B branch, review evidence in the PR body, merge only on explicit approval.

## Connector Evidence

- github: read open PR state and closed the superseded PR via MCP (get_me, list_pull_requests, add_issue_comment, update_pull_request on PR #180); repository files inspected for gate logic and fixtures.

## Connector Selection Waiver

Notion is required for governance-class work by connector policy, but the Notion MCP connector is unavailable in this remote session environment; the approved fallback from core/workflow.md stage 1 applies — this plan file under .claude/plans/ carries the spec and progress validation.

## Connector Usage Evidence

- source: github repository yotamfried-ux/Engineering-OS — PR #181 (head c54edcb), PR #180 (readiness-pr-b2-connector-selection-v13), scripts/enforcement/enforce-run-trace.sh, scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/enforce-tests.sh.
- action: github MCP list_pull_requests surfaced the overlapping PR #180; after owner decision, add_issue_comment and update_pull_request closed PR #180 as superseded by PR #181.
- result: github state confirmed PR #181 open draft at c54edcb with base 721024f, PR #180 closed at github.com/yotamfried-ux/Engineering-OS/pull/180, and no other open PR overlaps the PR C scope.
- decision: github findings selected stacking PR C on the claude/engineering-os-readiness-pr-b branch from c54edcb and updated scripts/enforcement/enforce-run-trace.sh, scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/enforce-tests.sh, and scripts/enforcement/lib/evidence.sh in this branch.
- target: scripts/enforcement/enforce-run-trace.sh, scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/enforce-tests.sh, scripts/enforcement/lib/evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md

## Documentation Asset Evidence

- internal: docs/operations/claude-run-trace.md, scripts/enforcement/simulation-coverage.tsv, scripts/enforcement/coverage-required-gates.tsv, core/task-router.md, core/workflow.md, core/hooks-policy.md, scripts/enforcement/tests/test-run-trace.sh, scripts/enforcement/tests/test-tests.sh.
- context7: not required because this change edits internal Engineering OS governance enforcement (bash validators, TSV manifests, and operations docs) and does not implement or integrate any external library, framework, SDK, or API.
- decision: the existing run-trace doc headings fixed the trace-definition update shape, the simulation manifest schema fixed the none-by-design token design, and the existing test fixture layout fixed where each new negative case lands.

## Graphify Usage Evidence

- source: graphify query over graphify-out/graph.json for run-trace, plan-selection, and enforce-tests gate wiring.
- action: graphify query oriented the select_plan/newest_plan call sites and the enforce-tests warn_missing callers before edits.
- result: the graph showed plan selection duplicated across enforce-run-trace.sh, pre-tool-use-runtime-evidence.sh, and check-plan-scope.sh, confirming a shared lib/evidence.sh selector is the right consolidation point.
- decision: graph finding selected the shared eos_select_plan approach and scoped the write set to scripts/enforcement, its lib and tests, and docs/operations.
- target: scripts/enforcement, scripts/enforcement/lib, scripts/enforcement/tests, docs/operations, lessons-learned/bugs

## Template Gap Waiver

No project template applies: this is internal governance/enforcement maintenance inside Engineering OS itself; templates/ entries cover application project scaffolds and are out of scope for validator and manifest edits.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/enforce-run-trace.sh | checked |
| scripts/enforcement/enforce-tests.sh | checked |
| scripts/enforcement/check-simulation-coverage.sh | checked |
| scripts/enforcement/lib/evidence.sh | checked |
| scripts/enforcement/pre-tool-use-runtime-evidence.sh | checked |
| scripts/enforcement/check-plan-scope.sh | checked |
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/check-documentation-asset-evidence.sh | checked |
| scripts/enforcement/simulation-coverage.tsv | checked |
| scripts/enforcement/tests/test-run-trace.sh | checked |
| scripts/enforcement/tests/test-tests.sh | checked |
| docs/operations/claude-run-trace.md | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/hooks-policy.md | checked |

## Claude Run Trace

- goal: close the run-trace scope, simulation waiver, tests tool contract, and active-plan selection gaps with deterministic, fixture-tested gates.
- hypothesis: extending trace triggers, adding a none-by-design token, a CI hard-fail tool contract, and a shared target-aware plan selector strictly tighten enforcement without breaking existing fixtures.
- connectors: github MCP re-verified PR state after re-auth and closed superseded PR #180 per owner decision; notion_progress_validated: waived — Notion unavailable in this environment, plan-file fallback carries progress validation per the Connector Selection Waiver.
- steps: read gate sources; extend run-trace triggers and waiver-body validation; add none-by-design token and replace two waived cells with fixtures; implement the missing-tool contract; add eos_select_plan and wire three gates; add DoD schema and broad-claim rejection; flip gaps and audit rows.
- evidence: scripts/enforcement gate scripts, lib/evidence.sh, simulation manifests, fixture suites, docs/operations/claude-run-trace.md, known-gaps.tsv, and the audit change in this branch.
- rejected: quality-gates.md documentation coupling, universal DoD verb requirements, and failing no-match plan selection were rejected as over-coupled or false-block-prone; blaming the CI=true logic and the plan-selection change for the CI failure in run 28596073361 were both rejected during the repair loop after log extraction pointed at test-tests.sh fixture premises.
- result: four gaps close with deterministic checkers and fixtures; three gaps remain for PRs D and E.
- follow-up: PR D hardens PR-review schema and the merge-readiness artifact; PR E adds install downstream behavior tests.

## Lessons Reused

- lessons-learned/bugs/ci-environment-dependent-fixture-premise.md
  - Applied because: this PR's missing-tool fixtures are exactly the absence-dependent case the lesson covers; the runE_min sandbox implements its prevention.
  - Prevention: construct tool absence hermetically instead of assuming host inventory.

## Progress Lifecycle Evidence

- start: plan committed on claude/engineering-os-readiness-pr-c before any gate, manifest, doc, or test edits.
- mid: run-trace hardening landed in b472945, simulation token work in 5c2c746, tests-tool contract in 6b761e8, shared plan selection in ac615cd, DoD schema and broad-claim rejection in 0a87b8d, gap closures in 2d660e7; targeted suites re-ran green after each step.
- pre-merge: after the last code change the full enforcement suite ran green except the pre-existing test-plan-scope environment case that fails identically on pristine main in this container; readiness, known-gaps, simulation-coverage validators and the range-level evidence policies re-verified before push.
- pre-merge: after the CI repair commit de0e32c (hermetic missing-tool fixtures diagnosed from run 28596075449), test-tests.sh re-ran 16/16 in both env modes, the lesson was captured in lessons-learned/bugs/ci-environment-dependent-fixture-premise.md, and CI re-verification on the new head is the final gate.
- pre-merge: final range verification after the lesson commit 51efec7 re-ran the lifecycle, learning-reuse, and range evidence policies green before the repair push.

## DoD

- [x] Run-trace triggers cover patterns, templates, commands, evals, and >5-file ranges, with waiver bodies validated — verified by test-run-trace.sh fixtures.
- [x] Simulation manifest distinguishes none-by-design from waived, with the two replaceable cells covered by real fixtures — verified by test-simulation-coverage.sh and test-connector-evidence.sh.
- [x] Missing test tools hard-fail in CI and require a named local waiver — verified by test-tests.sh fixtures.
- [x] Target-aware plan selection runs in all three gates — verified by test-active-plan-selection.sh fixtures.
- [x] DoD schema and broad-claim rejection landed with negative fixtures in test-plan-quality.sh and test-documentation-asset-evidence.sh.
- [x] Four gaps flipped to closed with concrete artifacts; audit and ledger updated; check-readiness-audit.sh green.
- [x] Full local enforcement suite green except the disclosed pre-existing test-plan-scope environment case.
- [x] Draft PR opened with review evidence; merge deferred to explicit approval.

## Completed Work

- Branch claude/engineering-os-readiness-pr-c created from PR B head c54edcb; overlapping PR #180 closed as superseded per owner decision.

## Remaining Validation Outside This Plan

- PRs D and E cover PR-review quality schema, merge-readiness artifact, and install downstream behavior per the approved program.
