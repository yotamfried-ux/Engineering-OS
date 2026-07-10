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
- `scripts/enforcement/policy-gate-dependencies.tsv`: must register any new standalone checker installed with the workflow.

## Experiment

Create a minimal fixture containing `import Unused from './dep'` without a semicolon. Confirm the current scanner misses it. Add control fixtures for used imports, semicolon-terminated imports, multiline named imports, side-effect imports, and explicit cleanup waivers.

## Fix

Move the inline parser into a small standalone checker and make static-import termination accept either a semicolon or the end of a complete import declaration. Keep the gate fail-closed and preserve existing waiver behavior.

## Definition of Done

- [x] Plan committed before code/config/test changes.
- [ ] Semicolonless unused default import fails.
- [ ] Semicolonless unused named import fails.
- [ ] Used semicolonless import passes.
- [ ] Existing semicolon-terminated behavior remains enforced.
- [ ] Multiline and side-effect imports are handled correctly.
- [ ] Installer dependency manifest includes the checker.
- [ ] Full enforcement tests and PR policy gates pass.
- [ ] Review findings are resolved.

## Connector Usage Evidence

- source: GitHub
- action: inspected canonical workflow and Project 8 review finding
- result: reproduced design-level cause before implementation
- decision: fix upstream, then sync Project 8 from the canonical source
- target: `.github/workflows/import-cleanup-policy.yml`

## Capability Evidence

- `validation.policy-change-has-validator`: this policy change will include a dedicated executable regression suite.
- `validation.actions-checked`: GitHub Actions results will be verified on the final head before merge.

## Documentation Asset Evidence

- internal: `.github/workflows/import-cleanup-policy.yml`, `scripts/enforcement/policy-gate-dependencies.tsv`
- decision: no external API documentation is required for this local static-analysis bug.

## Operational Work History Evidence

- automatic_sources: .engineering-os/work-history/latest.json
- learning_loop_result: none-with-reason — the regression test and focused checker are the durable learning artifact for this parser defect.

## Progress Lifecycle Evidence

- start: verified the existing regex only matches static imports ending in semicolons and committed this plan before implementation.
- mid: added a standalone parser that recognizes complete semicolonless and semicolon-terminated static imports while preserving the existing waiver and metadata-only failure output.
