# Fix semicolonless import cleanup enforcement

Task type: enforcement bug fix
Task class: engineering_os_governance
Domain tags: cleanup, javascript, typescript, ci, governance
Plan Scope: focused
Planning Mode: staged
Architecture guides: `core/debugging-policy.md`
External systems/connectors: GitHub
Evidence to check: canonical workflow, checker, regression suite, dependency manifest, and Project 8 PR #3
User decisions required: no new decision; the owner instructed execution through validated merge

## Route Plan Evidence

| Field | Value |
|---|---|
| Task-router evidence | `core/task-router.md` read; classified as `engineering_os_governance` before implementation |
| Workflow evidence | `core/workflow.md` and `core/debugging-policy.md` read; plan-first reproduce-fix-verify sequence applied |
| Templates | existing enforcement test structure in `scripts/enforcement/tests/test-import-cleanup-policy.sh` |
| Patterns | fail-before/pass-after regression fixture design |
| Skills | not required |
| Validation gates | enforcement-tests, workflow-evidence-policy, pr-policy, import-cleanup-policy, capability-evidence-policy, connector-evidence-policy, documentation-asset-policy, plan-policy |
| Target paths | `.github/workflows/import-cleanup-policy.yml`, `scripts/enforcement/check-import-cleanup.py`, `scripts/enforcement/tests/test-import-cleanup-policy.sh`, `scripts/enforcement/policy-gate-dependencies.tsv` |

## Source of Truth Checks

| Source | Status |
|---|---|
| `.github/workflows/import-cleanup-policy.yml` | read |
| `scripts/enforcement/policy-gate-dependencies.tsv` | checked |
| `core/capability-registry.yaml` | read |
| `yotamfried-ux/project-8` PR #3 review thread `PRRT_kwDOQk64s86P5GRR` | validated |

The previous workflow parser required a trailing semicolon. Project 8 uses semicolonless JS/JSX imports, so the installed gate could silently skip real imports. The capability registry confirms this canonical enforcement change belongs to `engineering_os_governance`.

## Experiment

A dedicated executable suite covers semicolonless unused and used bindings, semicolon-terminated behavior, multiline named imports, namespace imports, side-effect imports, concrete waivers, and both modern `with {}` and legacy `assert {}` import attributes.

## Fix

The inline workflow parser was replaced by a focused standalone checker. Static imports are considered complete when their module specifier and optional import-attribute block close, with or without a trailing semicolon. The gate remains fail-closed and preserves the existing waiver behavior.

## Definition of Done

- [x] Plan committed before code/config/test changes.
- [x] Semicolonless unused default import is covered by a failing fixture.
- [x] Semicolonless unused named imports are covered by a failing fixture.
- [x] Used semicolonless import is covered by a passing fixture.
- [x] Existing semicolon-terminated behavior remains enforced by a fixture.
- [x] Multiline, namespace, side-effect, and waiver cases are covered.
- [x] Modern `with {}` and legacy `assert {}` import attributes are covered.
- [x] Installer dependency manifest includes the checker.
- [x] Workflow invokes the standalone checker rather than duplicated inline logic.

Final-head CI, automated review, and thread resolution remain mandatory external merge gates and are verified directly on GitHub before merge.

## Connector Evidence

- GitHub: used as the source of truth for the canonical workflow, current `main`, Project 8 PR #3, the review findings, branch commits, and CI results.

## Connector Usage Evidence

- source: GitHub
- action: inspected `yotamfried-ux/Engineering-OS/.github/workflows/import-cleanup-policy.yml`, Project 8 PR #3, and PR #242 review findings
- result: added and hardened `scripts/enforcement/check-import-cleanup.py` plus `scripts/enforcement/tests/test-import-cleanup-policy.sh` on PR #242
- decision: implemented and review-hardened the fix upstream so installed target projects receive one canonical tested policy rather than a Project 8-only workaround
- target: `.github/workflows/import-cleanup-policy.yml`, `scripts/enforcement/check-import-cleanup.py`, `scripts/enforcement/tests/test-import-cleanup-policy.sh`, `scripts/enforcement/policy-gate-dependencies.tsv`

## Capability Evidence

- `routing.task-router-read`: used the canonical Route Plan contract before implementation.
- `workflow.workflow-read`: followed plan-first and lifecycle checkpoint ordering.
- `plan.route-plan-before-write`: commit `f690871` created this plan before enforcement code/config/test commits.
- `source.github-repo-read`: inspected canonical `main` and Project 8 PR #3 before changing code.
- `validation.policy-change-has-validator`: added the dedicated executable regression suite `test-import-cleanup-policy.sh`.
- `validation.coderabbit-policy`: automated review status and findings are mandatory before merge.
- `validation.actions-checked`: final-head GitHub Actions checks are mandatory before merge.

## Documentation Asset Evidence

- internal: `.github/workflows/import-cleanup-policy.yml`, `core/debugging-policy.md`, `core/capability-registry.yaml`, and `scripts/enforcement/policy-gate-dependencies.tsv`
- context7: not required because this change is entirely internal enforcement logic and does not implement or integrate an external library, framework, SDK, API, or service
- decision: the existing workflow and debugging policy confirmed that the correct solution is a reproduce-before-fix regression suite plus one installable checker, not a target-project workaround

## Claude Run Trace

1. Read the canonical import-cleanup workflow and confirmed its regex required `;`.
2. Verified the real semicolonless style and open review finding on Project 8 PR #3.
3. Committed this Route Plan before implementation.
4. Added a standalone checker, then recorded the mid checkpoint.
5. Added pass/fail fixtures, rewired the workflow, and registered the install dependency.
6. Recorded a pre-merge checkpoint after the initial final code/config/test change.
7. Corrected Route Plan evidence formatting after the real policy gates identified missing table-based fields.
8. Codex identified import-attribute syntax as a real regression risk; extended the checker and added fail/pass fixtures for `with {}` and `assert {}`.
9. Updated this pre-merge checkpoint after the final review-driven code/test changes.

## Operational Work History Evidence

- automatic_sources: .engineering-os/work-history/latest.json
- learning_loop_result: none-with-reason — the regression suite, including the review-driven import-attribute fixtures, is the permanent learning artifact for this enforcement defect.

## Progress Lifecycle Evidence

- start: verified the existing regex only matches static imports ending in semicolons and committed this plan before implementation.
- mid: added a standalone parser that recognizes complete semicolonless and semicolon-terminated static imports while preserving the existing waiver and metadata-only failure output.
- pre-merge: completed import-attribute hardening, workflow wiring, installer dependency registration, regression fixtures, and full Route Plan evidence after the final code/test change.
