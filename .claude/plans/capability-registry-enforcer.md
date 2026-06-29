# Capability Registry Enforcer

## Goal

Close the operational-readiness gap where `core/capability-registry.yaml` is declared runtime-enabled but still appears as non-runtime / unenforced in governance wiring.

## Requirements

- Keep `CLAUDE.md` as the thin entrypoint.
- Make capability-registry enforcement explicit in the manifest and pre-commit path.
- Add deterministic validation for staged changes to `core/capability-registry.yaml`.
- Add tests/loggable simulations proving pass/fail behavior.
- Do not merge to `main` without explicit user approval.

## Route Plan

Task type: Engineering OS governance / enforcement
Task class: engineering_os_governance
Domain tags: governance, workflow, testing, hooks
Templates: existing enforcement test pattern
Architecture guides: none applicable
Patterns: scripts/enforcement/tests shell-test pattern
External systems / connectors: GitHub connector used to read/write repo state
Skills: manual self-review; PR review required before merge per policy
Validation gates: shell syntax, registry validator, pre-commit wiring simulation, manifest consistency

## Capability Evidence

- `routing.task-router-read` — `core/task-router.md` read before writing.
- `workflow.workflow-read` — `core/workflow.md` read before writing.
- `plan.route-plan-before-write` — this plan created before code changes.
- `source.github-repo-read` — repo metadata and relevant files read through GitHub connector.
- `validation.policy-change-has-validator` — add/update enforcer test coverage for registry changes.
- `validation.coderabbit-policy` — branch created; merge requires PR/review/user approval.

## Alternatives

1. Leave `capability-registry.yaml` as `NONE` in the manifest. Rejected: contradicts runtime-enabled registry and weakens readiness.
2. Reuse only the existing CI test. Rejected: CI validation alone does not bind staged registry changes to pre-commit governance.
3. Add a dedicated enforcer script with tests and wire it into pre-commit. Selected: smallest deterministic enforcement improvement.

## Definition of Done

- [ ] Manifest maps `core/capability-registry.yaml` to a deterministic enforcer instead of `NONE`.
- [ ] CLAUDE navigation reflects active registry enforcement.
- [ ] Pre-commit runs the registry enforcer in the Engineering OS repo.
- [ ] Registry enforcer validates schema/anchors and staged-diff regressions.
- [ ] Test suite proves clean registry passes and unsafe staged changes fail.
- [ ] Self-review confirms no merge to `main` and no enforcement escape hatch introduced.
