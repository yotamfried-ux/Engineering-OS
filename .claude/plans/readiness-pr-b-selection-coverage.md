# Readiness PR B1 - connector result identifiers

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task type | governance enforcement |
| Domain tags | governance, connectors, evidence |
| Task-router evidence | core/task-router.md checked |
| Workflow evidence | core/workflow.md checked; plan-file fallback used because Notion is unavailable |
| Target paths | scripts/enforcement/check-connector-evidence.sh, scripts/enforcement/tests/test-connector-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, scripts/enforcement/simulation-coverage.tsv |
| Templates | not required |
| Patterns | existing enforcement script and fixture-test pattern |
| Skills | none |
| External systems/connectors | github |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, documentation-asset-policy, capability-evidence-policy, plan-policy, pr-policy, semantic-cleanup-policy, import-cleanup-policy |

## Scope

Close the `connector-result-identifiers` gap only. Other PR B gaps remain open for later focused loops.

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: inspected repo policy files, current connector checker, connector tests, PR A result, and known gaps.

## Connector Selection Waiver

Notion is unavailable in this session; this route plan is the approved planning fallback.

## Connector Usage Evidence

- source: github files `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-connector-evidence.sh`, `scripts/enforcement/tests/test-connector-evidence.sh`, and PR #178 state.
- action: checked the registered connector result gap and current connector evidence checker behavior.
- result: `docs/operations/known-gaps.tsv` listed `connector-result-identifiers` as open, and `scripts/enforcement/check-connector-evidence.sh` allowed result lines without concrete identifiers.
- decision: added result identifier validation, path/PR positive fixtures, a vague-result negative fixture, audit updates, simulation coverage evidence, and known-gap closure artifacts.
- target: scripts/enforcement/check-connector-evidence.sh, scripts/enforcement/tests/test-connector-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, scripts/enforcement/simulation-coverage.tsv

## Documentation Asset Evidence

- internal: `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `core/capability-registry.yaml`, `core/task-router.md`, `scripts/enforcement/check-connector-evidence.sh`, and `scripts/enforcement/tests/test-connector-evidence.sh` were checked.
- context7: not required for internal Engineering OS enforcement.
- decision: use existing checker and fixture-test conventions.

## Graphify Usage Waiver

Graphify is not available in this ChatGPT connector runtime. Direct GitHub file inspection is the fallback for this narrow checker/test change.

## Template Gap Waiver

No project scaffold template applies to this internal governance change.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/hooks-policy.md | checked |
| core/capability-registry.yaml | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |
| scripts/enforcement/check-connector-evidence.sh | checked |
| scripts/enforcement/tests/test-connector-evidence.sh | checked |
| scripts/enforcement/simulation-coverage.tsv | checked |

## Progress Lifecycle Evidence

- start: plan committed before enforcement, test, audit, or known-gap edits.
- mid: connector result identifier checker and fixture updates were committed after implementation began.
- pre-merge: audit, simulation coverage, known-gap closure artifacts, and this plan were updated after the code/test changes.
- pre-merge: plan checklist and graphify fallback wording were repaired after initial CI feedback.

## Claude Run Trace

- goal: close `connector-result-identifiers`.
- hypothesis: requiring concrete identifiers in connector result lines blocks vague connector result claims while keeping deeper source-quality judgment in review.
- connectors: GitHub used for source inspection and file updates.
- steps: inspected sources, updated checker, added fixtures, updated coverage manifest, closed the known-gap row, updated the audit, opened PR, and repaired plan feedback.
- evidence: `test-connector-evidence.sh` includes `connector-result-without-identifier-fails` and `connector-result-pr-number-passes`; `check-connector-evidence.sh` validates result identifiers.
- result: connector result identifier enforcement is implemented.
- follow-up: run CI, address review, merge only after approval.

## DoD

- [x] Connector Usage Evidence result lines require a concrete identifier.
- [x] Vague result evidence has a negative fixture.
- [x] Path and PR-number result evidence have positive fixtures.
- [x] `simulation-coverage.tsv` records the coverage token.
- [x] `known-gaps.tsv` closes only `connector-result-identifiers` with concrete artifacts.
- [x] `operational-readiness-audit.md` reflects the new enforcement and remaining review judgment.
- [x] Required CI checks are the PR merge gate.
