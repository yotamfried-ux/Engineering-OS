# Route Plan — P1c: refresh managed settings in existing governed targets

## Route fields

| Field | Value |
|---|---|
| Task type | Engineering OS governance — target-propagation fix |
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read — classified engineering_os_governance (scripts/ change) |
| Workflow evidence | core/workflow.md + core/hooks-policy.md read; plan-before-code; tests-before-done |
| Target paths | scripts/use-in-project.sh, scripts/enforcement/tests/test-use-in-project-update.sh |
| Templates | Not applicable; internal propagation script |
| Patterns | Not applicable; bash installer logic, no reusable code pattern asset |
| Skills | none |
| External systems/connectors | none |
| Validation gates | enforcement suite, use-in-project contract, new update test, pre-commit gates |

## Goal / מטרה

Close P1 from the readiness experiment: `use-in-project.sh` skips settings for an existing
target (skip-if-exists), so template fixes (e.g. the hook-gate deny wiring) never reach a live
governed project. Add an opt-in refresh path.

## Plan / תכנון

1. Add `EOS_UPDATE_SETTINGS=1` branch to `use-in-project.sh` that backs up the existing target
   `.claude/settings.json` and refreshes it from the EOS template (then render + policy-gate install).
2. Add `test-use-in-project-update.sh` proving default preserves, update refreshes + backs up.
3. Verify gates; open PR; review; merge.

## Alternatives / חלופות

- Auto-overwrite existing settings unconditionally. Rejected: would clobber local customizations.
- Managed `<!-- BEGIN/END -->` block merge. Rejected as heavier than needed; a backed-up opt-in
  refresh is the minimal safe fix.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/use-in-project.sh (settings install skip-if-exists block, lines 244-255) | read |
| docs/research/readiness-experiment-2026-06.md (P1 target-propagation gap) | read |
| scripts/enforcement/tests/enforcement-tests contract pattern | validated |

## Capability Evidence

Required capabilities for task class `engineering_os_governance`:

- `routing.task-router-read` — routed and classified as engineering_os_governance.
- `workflow.workflow-read` — core/workflow.md + core/hooks-policy.md read; plan-before-code followed.
- `plan.route-plan-before-write` — this Route Plan is committed before the code commit (enforced by check-workflow-evidence.sh ordering).
- `source.github-repo-read` — read `use-in-project.sh`, the readiness report, and the enforcement-tests contract before changing.
- `validation.policy-change-has-validator` — added `test-use-in-project-update.sh` covering the new branch.
- `validation.coderabbit-policy` — PR opened ready-for-review for CodeRabbit; status checked before merge per core/coderabbit-policy.md.

## Claude Run Trace

- **Goal:** let EOS setting/gate fixes reach existing governed targets safely.
- **Hypothesis:** the skip-if-exists branch means stale fail-open target settings persist forever.
- **Connectors:** none integrated — local bash change. GitHub used only for delivery; `notion_progress_validated` is N/A (no Notion spec); Context7 not applicable.
- **Steps:** read the skip-if-exists block; add the `EOS_UPDATE_SETTINGS` refresh branch with a timestamped backup; add the update test; run it; run the enforcement suite.
- **Evidence:** `test-use-in-project-update.sh` passes 4/4; default run preserves settings, update run refreshes + creates `.bak`; `bash -n` clean.
- **Rejected:** unconditional overwrite (clobbers customizations); managed-block merge (heavier than needed).
- **Result:** opt-in refresh implemented; existing targets can now receive template fixes.
- **Follow-up:** apply it to Expiriens (Step 3) so the governed project is actually enforced.

## Progress Lifecycle Evidence

- **start:** readiness report P1 confirmed the skip-if-exists gap; before this change no path refreshes an existing target's managed settings.

## Definition of Done / תנאי סיום

- [x] `use-in-project.sh` refreshes existing target settings only under `EOS_UPDATE_SETTINGS=1`, with a backup.
- [x] Default run still preserves existing settings.
- [x] `test-use-in-project-update.sh` added and passing (4/4).
- [x] Enforcement suite + use-in-project contract green.
