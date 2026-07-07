# Clean Workflow Integration Route Plan

Plan Scope: standard
Planning Mode: approved

## Progress Lifecycle Evidence

- start: PR #216 and current main were inspected before writing.
- mid: clean branch created from current main; checker, fixtures, audit addendum, and targeted router update added.
- pre-merge: PR #221 opened; pending PR body update, current-head CI, and review-thread validation.

## Connector Usage Evidence

- source: GitHub connector repository yotamfried-ux/Engineering-OS.
- action: inspected PR #216, created clean branch, and opened PR #221.
- result: PR #221 contains the clean workflow integration artifacts.
- decision: proceed with PR #221 instead of merging PR #216 directly.
- target: core/task-router.md; scripts/enforcement/check-route-plan-contract.py; scripts/enforcement/tests/test-route-plan-contract.sh; docs/operations/workflow-result-loop-integration-audit.md; .claude/plans/wf-clean.md

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read before writing.
- `workflow.workflow-read` — core/workflow.md read before writing.
- `plan.route-plan-before-write` — plan created before clean-branch edits.
- `source.github-repo-read` — PR #216 and current main files inspected through GitHub.
- `validation.policy-change-has-validator` — checker and fixtures were added.
- `validation.coderabbit-policy` — PR body will record review fallback.

## DoD

- [x] Add route-plan contract checker.
- [x] Add positive and negative fixtures.
- [x] Update routing contract without rewriting core workflow.
- [x] Add workflow integration audit note.
- [x] Open clean PR.
- [ ] Validate current-head CI and review threads.