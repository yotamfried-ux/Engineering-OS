# Readiness PR B2 - connector selection coverage

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task type | governance enforcement |
| Domain tags | governance, connectors, selection |
| Task-router evidence | core/task-router.md checked |
| Workflow evidence | core/workflow.md checked; plan-file fallback used because Notion is unavailable |
| Target paths | scripts/enforcement/check-required-connectors.sh, scripts/enforcement/tests/test-required-connectors-inventory.sh, scripts/enforcement/connector-selection-rules.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, scripts/enforcement/simulation-coverage.tsv |
| Templates | not required |
| Patterns | existing enforcement script and fixture-test pattern |
| Skills | none |
| External systems/connectors | github |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, documentation-asset-policy, capability-evidence-policy, plan-policy, pr-policy, semantic-cleanup-policy, import-cleanup-policy |

## Scope

Close `connector-selection-coverage` by moving connector trigger rules out of hard-coded checker prose into a TSV manifest tied to the connector inventory. Right-connector semantic judgment remains review-based by design.

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: inspected `external-systems/README.md`, `core/connector-policy.md`, `check-required-connectors.sh`, connector tests, `known-gaps.tsv`, and the readiness audit.

## Connector Selection Waiver

Notion is unavailable in this session; this route plan is the approved planning fallback.

## Connector Usage Evidence

- source: github files `external-systems/README.md`, `core/connector-policy.md`, `scripts/enforcement/check-required-connectors.sh`, `scripts/enforcement/tests/test-required-connectors-inventory.sh`, `scripts/enforcement/connector-selection-rules.tsv`, and `docs/operations/known-gaps.tsv`.
- action: checked connector inventory and hard-coded connector selection rules, then implemented manifest-backed selection coverage.
- result: `connector-selection-coverage` was open because selection rules were embedded in `check-required-connectors.sh`; `external-systems/README.md` lists MCP connectors that now require manifest coverage.
- decision: added `connector-selection-rules.tsv`, made the checker read it, added inventory coverage fixtures, updated simulation coverage, closed the known gap, and updated the readiness audit.
- target: scripts/enforcement/check-required-connectors.sh, scripts/enforcement/tests/test-required-connectors-inventory.sh, scripts/enforcement/connector-selection-rules.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, scripts/enforcement/simulation-coverage.tsv

## Documentation Asset Evidence

- internal: `external-systems/README.md`, `core/connector-policy.md`, `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-required-connectors.sh`, and connector-selection tests were checked.
- context7: not required for internal Engineering OS enforcement.
- decision: use the external-systems connector inventory and existing checker/test conventions.

## Graphify Usage Waiver

Graphify is not available in this ChatGPT connector runtime. Direct GitHub file inspection is the fallback for this narrow checker/test change.

## Template Gap Waiver

No project scaffold template applies to this internal governance change.

## Source of Truth Checks

| Source | Status |
|---|---|
| external-systems/README.md | checked |
| core/connector-policy.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |
| scripts/enforcement/check-required-connectors.sh | checked |
| scripts/enforcement/connector-selection-rules.tsv | checked |
| scripts/enforcement/tests/test-required-connectors-inventory.sh | checked |
| scripts/enforcement/simulation-coverage.tsv | checked |

## Progress Lifecycle Evidence

- start: plan committed before checker, test, manifest, audit, simulation, or known-gap edits.
- mid: connector selection manifest, checker manifest loading, and inventory fixtures were added after implementation began.
- pre-merge: simulation coverage, known-gap closure artifacts, readiness audit, and this plan were updated after the final checker/test changes.

## Claude Run Trace

- goal: close `connector-selection-coverage` with manifest-backed selection rules.
- hypothesis: a TSV manifest plus inventory coverage fixture can prevent new connectors from silently lacking selection treatment while preserving review-based judgment for exact connector fit.
- connectors: GitHub used for source inspection and branch/file changes.
- steps: inspected policy, inventory, gap, checker, and tests; created branch and plan; added manifest; changed checker to read it; added inventory positive/missing/invalid fixtures; updated coverage, gaps, audit, and plan.
- evidence: `test-required-connectors-inventory.sh` includes `inventory_manifest_coverage`, `inventory_missing_rule_fails`, and `inventory_invalid_status_fails`; `check-required-connectors.sh` reads `connector-selection-rules.tsv`.
- result: connector selection coverage is structurally closed.
- follow-up: open PR, validate CI, address review, merge only after approval.

## DoD

- [x] Connector selection rules live in a manifest file.
- [x] The checker reads the manifest instead of hard-coded trigger branches.
- [x] Inventory coverage test proves every MCP connector is ruled or optional-by-design.
- [x] Positive and negative connector-selection fixtures remain covered.
- [x] `known-gaps.tsv` closes `connector-selection-coverage` with concrete artifacts.
- [x] `operational-readiness-audit.md` reflects enforced structural coverage and review-based semantic judgment.
- [ ] Required CI checks are green before merge.
