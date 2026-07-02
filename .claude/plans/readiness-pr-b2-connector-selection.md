# Readiness PR B2 connector selection coverage

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task type | governance enforcement |
| Domain tags | governance, connectors, selection |
| Task-router evidence | core/task-router.md checked |
| Workflow evidence | core/workflow.md checked |
| Target paths | scripts/enforcement/check-required-connectors.sh, scripts/enforcement/tests/test-required-connectors-inventory.sh, scripts/enforcement/connector-selection-rules.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, scripts/enforcement/simulation-coverage.tsv |
| Templates | not required |
| Patterns | existing checker and fixture-test pattern |
| Skills | none |
| External systems/connectors | github |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, documentation-asset-policy, capability-evidence-policy, plan-policy, pr-policy, semantic-cleanup-policy, import-cleanup-policy |

## Scope

Close `connector-selection-coverage` with a manifest-backed connector rule inventory and fixture tests.

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: inspected the connector inventory, connector policy, connector checker, tests, known gaps, and readiness audit.

## Connector Selection Waiver

Notion was unavailable in this session, so this plan file is the planning record.

## Connector Usage Evidence

- source: github files `external-systems/README.md`, `core/connector-policy.md`, `scripts/enforcement/check-required-connectors.sh`, `scripts/enforcement/tests/test-required-connectors-inventory.sh`, `scripts/enforcement/connector-selection-rules.tsv`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.
- action: checked connector inventory and the existing connector selection checker, then implemented manifest-backed coverage.
- result: `docs/operations/known-gaps.tsv` showed `connector-selection-coverage` open; `scripts/enforcement/connector-selection-rules.tsv` now records inventory-backed connector selection coverage.
- decision: added the manifest, updated the checker, added inventory fixtures, updated coverage records, closed the known gap, and restored detailed audit wording.
- target: scripts/enforcement/check-required-connectors.sh, scripts/enforcement/tests/test-required-connectors-inventory.sh, scripts/enforcement/connector-selection-rules.tsv, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, scripts/enforcement/simulation-coverage.tsv

## Documentation Asset Evidence

- internal: `external-systems/README.md`, `core/connector-policy.md`, `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-required-connectors.sh`, and connector-selection tests were checked.
- context7: not required for internal Engineering OS enforcement.
- decision: use the connector inventory and checker/test conventions.

## Template Gap Waiver

No project template applies to this internal governance change.

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
- mid: manifest loading and inventory fixtures were added after implementation began.
- pre-merge: coverage records, known gap closure, audit, and plan were updated after implementation.
- pre-merge: manifest comment parsing and audit detail were repaired after validation feedback.
- pre-merge: Connector Usage Evidence result was updated with concrete file paths after connector-evidence feedback.

## Claude Run Trace

- goal: close connector selection coverage.
- hypothesis: a connector rules manifest plus inventory fixtures prevents connector inventory drift.
- connectors: GitHub was used for source inspection and file updates.
- steps: inspected sources, added manifest, updated checker, added fixtures, updated coverage records, closed the gap, and updated the audit.
- evidence: `test-required-connectors-inventory.sh` covers `inventory_manifest_coverage`, `inventory_missing_rule_fails`, and `inventory_invalid_status_fails`.
- result: connector selection coverage is structurally closed.
- follow-up: merge after required validation and owner approval.

## DoD

- [x] Connector selection rules live in a manifest file.
- [x] The checker reads the manifest.
- [x] Inventory coverage test proves every MCP connector is ruled or optional-by-design.
- [x] Existing connector-selection fixtures remain covered.
- [x] `known-gaps.tsv` closes `connector-selection-coverage` with concrete artifacts.
- [x] `operational-readiness-audit.md` reflects the enforcement.
- [x] Required checks are green before merge.
