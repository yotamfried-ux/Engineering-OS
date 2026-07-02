# Readiness PR B — Selection coverage hardening

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task type | governance |
| Domain tags | readiness, enforcement |
| Task-router evidence | core/task-router.md checked; routed via routing_matrix section 7 |
| Workflow evidence | core/workflow.md checked; plan-file fallback carries the spec |
| Target paths | scripts/enforcement/check-required-connectors.sh, scripts/enforcement/connector-requirements.tsv, scripts/enforcement/check-required-templates.py, scripts/enforcement/template-requirements.tsv, scripts/enforcement/check-required-patterns.sh, scripts/enforcement/check-required-skills.sh, scripts/enforcement/check-capability-staged-changes.sh, scripts/enforcement/capability-staged-map.tsv, scripts/enforcement/check-learning-reuse.sh, scripts/enforcement/pre-tool-use-runtime-evidence.sh, scripts/enforcement/coverage-required-gates.tsv, scripts/enforcement/simulation-coverage.d, scripts/enforcement/tests, .github/workflows/capability-evidence-policy.yml, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | not required |
| Skills | none |
| External systems/connectors | github |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, documentation-asset-policy, capability-evidence-policy, plan-policy, pr-policy, semantic-cleanup-policy, import-cleanup-policy |

## Scope

PR B closes the five open selection-coverage gaps: manifest-driven connector selection tied to the external-systems inventory, manifest-driven template selection covering every templates/ directory, a registry-driven required-pattern gate, expanded skill selection rules with inventory coverage, a staged-change capability guard, plus an irrelevant-lesson-citation rule for learning reuse.

## Alternatives

- Keep hardcoded keyword rules and only append new ones — rejected: coverage against the inventory cannot be tested without a manifest, so silent drift returns as connectors are added.
- Force patterns from path heuristics instead of patterns/registry.yaml domains — rejected: registry domains are the canonical pattern vocabulary; heuristics would duplicate ownership.
- Fail stale declared capabilities in the staged guard — rejected: high false-block risk; only missing implied capabilities fail, and this is documented in the checker.
- Skip the learning-reuse citation-direction rule — rejected: relevance-washing (citing an unrelated lesson) would stay invisible; the new rule is deterministic on Applies To Paths / Domain Tags.

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read this session before writes.
- `workflow.workflow-read` — core/workflow.md read this session before writes.
- `plan.route-plan-before-write` — this plan is committed before the first code change of PR B.
- `source.github-repo-read` — GitHub MCP read merged main state: commit 721024f, merge 0960973, docs/operations/known-gaps.tsv (12 open gaps).
- `validation.policy-change-has-validator` — every selection policy change in this PR ships its own checker plus fixture tests.
- `validation.actions-checked` — capability-evidence-policy.yml changes and CI results for the head SHA are verified before merge readiness.
- `validation.coderabbit-policy` — dedicated branch, draft PR, review evidence in PR body, merge only on explicit approval.

## Connector Evidence

- github: read merged main via MCP (list_commits, get_file_contents) and repository files for inventories, checkers, and fixtures.

## Connector Selection Waiver

Notion is required for governance-class work by connector policy, but the Notion MCP connector is unavailable in this remote session environment; the approved fallback from core/workflow.md stage 1 applies — this plan file under .claude/plans/ carries the spec and progress validation.

## Connector Usage Evidence

- source: github repository yotamfried-ux/Engineering-OS — external-systems/README.md, patterns/registry.yaml, scripts/enforcement/check-required-connectors.sh, scripts/enforcement/check-required-skills.sh, scripts/enforcement/check-required-templates.py, docs/operations/known-gaps.tsv.
- action: github MCP list_commits and get_file_contents confirmed merged PR A state and B1 closure before branching from origin/main.
- result: github inspection of commit 721024f and merge 0960973 confirmed connector-result-identifiers is closed in docs/operations/known-gaps.tsv while 12 gaps remain open, and PR #178 review fixes landed in scripts/enforcement/check-readiness-audit.sh.
- decision: github findings selected the PR B scope — manifest extraction for scripts/enforcement/check-required-connectors.sh and scripts/enforcement/check-required-templates.py, new scripts/enforcement/check-required-patterns.sh and scripts/enforcement/check-capability-staged-changes.sh, and closure bookkeeping in docs/operations/known-gaps.tsv.
- target: scripts/enforcement/check-required-connectors.sh, scripts/enforcement/check-required-templates.py, scripts/enforcement/check-required-patterns.sh, scripts/enforcement/check-capability-staged-changes.sh, scripts/enforcement/check-required-skills.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md

## Documentation Asset Evidence

- internal: external-systems/README.md, external-skills/README.md, patterns/registry.yaml, core/task-router.md, core/workflow.md, core/capability-registry.yaml, scripts/enforcement/simulation-coverage.tsv, scripts/enforcement/coverage-required-gates.tsv.
- context7: not required because this change edits internal Engineering OS governance enforcement (bash/python validators and TSV manifests) and does not implement or integrate any external library, framework, SDK, or API.
- decision: the inventories fixed the manifest contents (connector and template rows mirror external-systems/README.md and templates/), and patterns/registry.yaml domains fixed the required-pattern vocabulary, following the existing checker-plus-fixture convention.

## Graphify Usage Evidence

- source: graphify query over graphify-out/graph.json for the selection gate wiring (required-connectors, required-skills, capability, and test communities).
- action: graphify query oriented the checker/test dependency map before file reads for PR B.
- result: the graph showed test-required-connectors.sh and test-capability-registry.sh as the fixture owners for the selection gates, confirming each checker pairs with a sibling test file under scripts/enforcement/tests.
- decision: graph finding selected checker-plus-manifest-plus-sibling-test structure for all five gaps and informed wiring the pattern gate into pre-tool-use-runtime-evidence.sh after the skills gate.
- target: scripts/enforcement, scripts/enforcement/tests, .github/workflows, docs/operations

## Template Gap Waiver

No project template applies: this is internal governance/enforcement maintenance inside Engineering OS itself; templates/ entries cover application project scaffolds and are out of scope for validator and manifest edits.

## Source of Truth Checks

| Source | Status |
|---|---|
| external-systems/README.md | checked |
| external-skills/README.md | checked |
| patterns/registry.yaml | checked |
| scripts/enforcement/check-required-connectors.sh | checked |
| scripts/enforcement/check-required-skills.sh | checked |
| scripts/enforcement/check-required-templates.py | checked |
| scripts/enforcement/check-learning-reuse.sh | checked |
| scripts/enforcement/validate-capability-evidence.sh | checked |
| scripts/enforcement/pre-tool-use-runtime-evidence.sh | checked |
| scripts/enforcement/check-connector-evidence.sh | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/hooks-policy.md | checked |

## Claude Run Trace

- goal: close the five selection-coverage gaps with manifest-driven, inventory-tied, fixture-tested selection gates.
- hypothesis: moving keyword rules into TSV manifests preserves behavior for existing rules while making inventory coverage itself testable.
- connectors: github MCP confirmed merged main state (721024f) and open gap set before branching; notion_progress_validated: waived — Notion unavailable in this environment, plan-file fallback carries progress validation per the Connector Selection Waiver.
- steps: read inventories and checkers; extract connector and template manifests; add pattern and staged-capability checkers; extend skill rules; add irrelevant-lesson rule; flip gaps and audit rows; add fixtures for every rule.
- evidence: scripts/enforcement checkers, manifests, tests, simulation-coverage.d rows, capability-evidence-policy.yml, docs/operations/known-gaps.tsv, and the audit change in this branch.
- rejected: path-heuristic pattern detection, stale-capability failures, and unmanifested keyword appends were rejected as untestable or false-block-prone.
- result: five selection gaps close with deterministic checkers and fixtures; residual selection judgment stays review-based by design.
- follow-up: PR C hardens run-trace scope, simulation waiver fixtures, tests tool contract, and active-plan selection.

## Progress Lifecycle Evidence

- start: plan committed on claude/engineering-os-readiness-pr-b before any checker, manifest, workflow, gaps, or test edits.
- mid: connector/template manifests landed in b2f3166, pattern and skill gates in 22e6c50, staged capability guard in c947eca, learning-reuse citation rule and gap closures in 7567cd6; targeted suites re-ran green after each step.
- pre-merge: after the last code change the full enforcement suite ran green except the pre-existing test-plan-scope environment case that fails identically on pristine main in this container; readiness, known-gaps, simulation-coverage, and range-level evidence policies re-verified.

## DoD

- [x] Connector selection is manifest-driven with inventory coverage and fixtures.
- [x] Template selection is manifest-driven with per-directory coverage and fixtures.
- [x] Required-pattern gate runs in the write gate with fixtures and a registry-presence guard.
- [x] Skill selection rules extended with inventory coverage and fixtures.
- [x] Staged-change capability guard runs in capability-evidence-policy CI with fixtures.
- [x] Irrelevant lesson citation fails with a fixture.
- [x] Five gaps flipped to closed with concrete artifacts; audit rows and ledger updated; readiness validator green.
- [x] Full local suite green except the known pre-existing test-plan-scope environment case.
- [x] Draft PR opened with review evidence; merge deferred to explicit approval.

## Completed Work

- Branch claude/engineering-os-readiness-pr-b created from origin/main at 721024f after GitHub MCP state verification.

## Remaining Validation Outside This Plan

- PRs C, D, and E cover trace/simulation/test contracts, governance evidence, and install-depth per the approved program.
