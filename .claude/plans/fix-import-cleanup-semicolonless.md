# Fix semicolonless import cleanup enforcement

Task type: enforcement bug fix
Task class: engineering_os_governance
Domain tags: cleanup, javascript, typescript, ci, governance
Plan Scope: focused
Planning Mode: staged
Templates: existing enforcement-test pattern under `scripts/enforcement/tests/`
Architecture guides: `core/debugging-policy.md` reproduce-before-fix loop
Patterns: fail-before/pass-after regression fixture
External systems/connectors: GitHub
Skills: not required because this is a focused internal static-analysis correction with executable regression coverage
Validation gates: enforcement-tests, workflow-evidence-policy, pr-policy, import-cleanup-policy, capability-evidence-policy, connector-evidence-policy, documentation-asset-policy, plan-policy
Evidence to check: `.github/workflows/import-cleanup-policy.yml`, `scripts/enforcement/check-import-cleanup.py`, `scripts/enforcement/tests/test-import-cleanup-policy.sh`, `scripts/enforcement/policy-gate-dependencies.tsv`, and Project 8 PR #3
User decisions required: no new decision; the owner already instructed execution through validated merge
Target paths: `.github/workflows/import-cleanup-policy.yml`, `scripts/enforcement/check-import-cleanup.py`, `scripts/enforcement/tests/test-import-cleanup-policy.sh`, `scripts/enforcement/policy-gate-dependencies.tsv`

## Source of Truth Checks

- `.github/workflows/import-cleanup-policy.yml`: verified the previous parser required a trailing semicolon.
- `yotamfried-ux/project-8` PR #3: verified real repository style contains semicolonless JS/JSX imports and review thread `PRRT_kwDOQk64s86P5GRR` reported the blind spot.
- `scripts/enforcement/policy-gate-dependencies.tsv`: registered the standalone checker for target-repository installation.
- `core/capability-registry.yaml`: selected `engineering_os_governance` because this changes canonical enforcement scripts and workflows.

## Experiment

A dedicated executable suite covers a semicolonless unused default import, semicolonless unused named imports, a used semicolonless import, semicolon-terminated behavior, multiline named imports, namespace imports, side-effect imports, and a concrete waiver.

## Fix

The inline workflow parser was replaced by a focused standalone checker. Static imports are considered complete when their module specifier closes, with or without a trailing semicolon. The gate remains fail-closed and preserves the existing waiver behavior.

## Definition of Done

- [x] Plan committed before code/config/test changes.
- [x] Semicolonless unused default import is covered by a failing fixture.
- [x] Semicolonless unused named imports are covered by a failing fixture.
- [x] Used semicolonless import is covered by a passing fixture.
- [x] Existing semicolon-terminated behavior remains enforced by a fixture.
- [x] Multiline, namespace, side-effect, and waiver cases are covered.
- [x] Installer dependency manifest includes the checker.
- [x] Workflow invokes the standalone checker rather than duplicated inline logic.

Final-head CI, automated review, and thread resolution remain mandatory merge gates and will be verified directly on GitHub before merge.

## Connector Evidence

- GitHub: used as the source of truth for the canonical workflow, current `main`, Project 8 PR #3, the unresolved review finding, branch commits, and CI results.

## Connector Usage Evidence

- source: GitHub
- action: inspected `yotamfried-ux/Engineering-OS/.github/workflows/import-cleanup-policy.yml` and `yotamfried-ux/project-8` PR #3 review thread, then created upstream PR #242
- result: added `scripts/enforcement/check-import-cleanup.py` and `scripts/enforcement/tests/test-import-cleanup-policy.sh` on PR #242
- decision: implemented the fix upstream so installed target projects receive one canonical tested policy rather than a Project 8-only workaround
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

## Operational Work History Evidence

- automatic_sources: .engineering-os/work-history/latest.json
- learning_loop_result: none-with-reason — the new regression suite is the permanent learning artifact for this enforcement defect.

## Progress Lifecycle Evidence

- start: verified the existing regex only matches static imports ending in semicolons and committed this plan before implementation.
- mid: added a standalone parser that recognizes complete semicolonless and semicolon-terminated static imports while preserving the existing waiver and metadata-only failure output.
- pre-merge: completed workflow wiring, installer dependency registration, regression fixtures, and full Route Plan evidence; the branch is ready for final-head CI and review validation.
