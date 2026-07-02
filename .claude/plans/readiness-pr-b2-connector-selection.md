# Readiness PR B2 - connector selection coverage

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task type | governance enforcement |
| Domain tags | governance, connectors, selection |
| Task-router evidence | core/task-router.md checked |
| Workflow evidence | core/workflow.md checked; plan-file fallback used because Notion is unavailable |
| Target paths | scripts/enforcement/check-required-connectors.sh, scripts/enforcement/tests/test-required-connectors.sh, scripts/enforcement/connector-selection-rules.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, scripts/enforcement/simulation-coverage.tsv |
| Templates | not required |
| Patterns | existing enforcement script and fixture-test pattern |
| Skills | none |
| External systems/connectors | github |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, documentation-asset-policy, capability-evidence-policy, plan-policy, pr-policy, semantic-cleanup-policy, import-cleanup-policy |

## Scope

Close `connector-selection-coverage` by moving connector trigger rules out of hard-coded checker prose into a TSV manifest tied to the connector inventory. Keep right-connector semantic judgment review-based by design.

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: inspected `external-systems/README.md`, `core/connector-policy.md`, `check-required-connectors.sh`, `test-required-connectors.sh`, `known-gaps.tsv`, and the readiness audit.

## Connector Selection Waiver

Notion is unavailable in this session; this route plan is the approved planning fallback.

## Connector Usage Evidence

- source: github files `external-systems/README.md`, `core/connector-policy.md`, `scripts/enforcement/check-required-connectors.sh`, `scripts/enforcement/tests/test-required-connectors.sh`, and `docs/operations/known-gaps.tsv`.
- action: checked connector inventory and current hard-coded connector selection rules.
- result: `docs/operations/known-gaps.tsv` listed `connector-selection-coverage` as open, and current selection rules were embedded directly in `check-required-connectors.sh` instead of a manifest tied to inventory.
- decision: add `connector-selection-rules.tsv`, make the checker read it, add inventory coverage fixtures, and close the known gap only after tests and audit evidence are updated.
- target: scripts/enforcement/check-required-connectors.sh, scripts/enforcement/tests/test-required-connectors.sh, scripts/enforcement/connector-selection-rules.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, scripts/enforcement/simulation-coverage.tsv

## Documentation Asset Evidence

- internal: `external-systems/README.md`, `core/connector-policy.md`, `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-required-connectors.sh`, and `scripts/enforcement/tests/test-required-connectors.sh` were checked.
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
| scripts/enforcement/tests/test-required-connectors.sh | checked |
| scripts/enforcement/simulation-coverage.tsv | checked |

## Progress Lifecycle Evidence

- start: plan committed before checker, test, manifest, audit, simulation, or known-gap edits.

## Claude Run Trace

- goal: close `connector-selection-coverage` with manifest-backed selection rules.
- hypothesis: a TSV manifest plus inventory coverage fixture can prevent new connectors from silently lacking selection treatment while preserving review-based judgment for exact connector fit.
- connectors: GitHub used for source inspection and branch/file changes.
- steps: inspected current policy, inventory, gap, checker, and tests; created branch and plan.
- evidence: `external-systems/README.md` lists MCP connectors; `check-required-connectors.sh` currently hard-codes selection regexes.
- result: implementation pending.
- follow-up: update checker, tests, known gaps, audit, simulation coverage, open PR, validate CI, merge only after approval.

## DoD

- [ ] Connector selection rules live in a manifest file.
- [ ] The checker reads the manifest instead of hard-coded trigger branches.
- [ ] Inventory coverage test proves every MCP connector is ruled, optional-by-design, or intentionally fallback-only.
- [ ] Positive and negative connector-selection fixtures still pass.
- [ ] `known-gaps.tsv` closes `connector-selection-coverage` with concrete artifacts.
- [ ] `operational-readiness-audit.md` reflects the enforced structural coverage and review-based semantic judgment.
- [ ] Required CI checks are green before merge.
