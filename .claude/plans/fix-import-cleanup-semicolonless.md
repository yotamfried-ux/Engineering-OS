# Fix semicolonless import cleanup enforcement

Task type: enforcement bug fix
Task class: bug_fix
Domain tags: cleanup, javascript, typescript, ci, governance
Plan Scope: focused
Planning Mode: staged
Templates: existing enforcement-test pattern
Patterns: fail-before/pass-after regression fixture
Skills: not required
External systems/connectors: GitHub
Validation gates: enforcement-tests, workflow-evidence-policy, pr-policy, import-cleanup-policy
Target paths: .github/workflows/import-cleanup-policy.yml, scripts/enforcement/check-import-cleanup.py, scripts/enforcement/tests/test-import-cleanup-policy.sh, scripts/enforcement/policy-gate-dependencies.tsv

## Source of Truth Checks

- `.github/workflows/import-cleanup-policy.yml`: verified current parser requires a trailing semicolon.
- `yotamfried-ux/project-8` PR #3: verified real repository style contains semicolonless JS/JSX imports and Codex reported the blind spot.
- `scripts/enforcement/policy-gate-dependencies.tsv`: registered the standalone checker for target-repository installation.

## Experiment

A dedicated executable suite now covers a semicolonless unused default import, semicolonless unused named imports, a used semicolonless import, semicolon-terminated behavior, multiline named imports, namespace imports, side-effect imports, and a concrete waiver.

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
- [ ] Full enforcement tests and PR policy gates pass on the final head.
- [ ] Review findings are resolved.

## Connector Usage Evidence

- source: GitHub
- action: inspected canonical workflow and Project 8 review finding, then implemented the upstream checker and regression suite
- result: semicolonless imports are now part of the enforceable policy contract
- decision: fix upstream, then sync Project 8 from the canonical source
- target: `.github/workflows/import-cleanup-policy.yml`, `scripts/enforcement/check-import-cleanup.py`

## Capability Evidence

- `validation.policy-change-has-validator`: this policy change includes `scripts/enforcement/tests/test-import-cleanup-policy.sh` with pass/fail fixtures.
- `validation.actions-checked`: GitHub Actions results will be verified on the final head before merge.

## Documentation Asset Evidence

- internal: `.github/workflows/import-cleanup-policy.yml`, `scripts/enforcement/check-import-cleanup.py`, `scripts/enforcement/tests/test-import-cleanup-policy.sh`, `scripts/enforcement/policy-gate-dependencies.tsv`
- decision: no external API documentation is required for this local static-analysis bug.

## Operational Work History Evidence

- automatic_sources: .engineering-os/work-history/latest.json
- learning_loop_result: none-with-reason — the regression test and focused checker are the durable learning artifact for this parser defect.

## Progress Lifecycle Evidence

- start: verified the existing regex only matches static imports ending in semicolons and committed this plan before implementation.
- mid: added a standalone parser that recognizes complete semicolonless and semicolon-terminated static imports while preserving the existing waiver and metadata-only failure output.
- pre-merge: completed workflow wiring, installer dependency registration, and regression fixtures; the branch is ready for CI and review validation.
