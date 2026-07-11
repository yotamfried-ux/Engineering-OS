# Project 8 telemetry readiness fixes

Task type: Engineering OS telemetry installation and evidence hardening
Task class: engineering_os_governance
Domain tags: telemetry, installer, hooks, operational-work-history, ci, project-8
Plan Scope: focused
Planning Mode: staged
External systems/connectors: GitHub
Architecture guides: `docs/operations/runtime-telemetry-archive-plan.md`, `docs/operations/operational-work-history-rollout.md`, `core/debugging-policy.md`
Templates: existing enforcement-test shell fixture pattern
Patterns: reproduce-before-fix, fail-closed preflight, metadata-only telemetry
Skills: not required
Validation gates: enforcement-tests, plan-policy, pr-policy, connector-evidence-policy, capability-evidence-policy, workflow-evidence-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy
Target paths: `scripts/install-policy-gates.sh`, `scripts/monitoring/patch-settings-telemetry.py`, `scripts/monitoring/eos-telemetry-session-start.sh`, `scripts/monitoring/require-telemetry-session.sh`, `scripts/monitoring/enrich-work-history-ci-history.py`, `.github/workflows/pr-policy.yml`, `scripts/enforcement/policy-gate-dependencies.tsv`, telemetry/install regression tests, Project 8 preflight documentation

## Source of Truth Checks

| Source | Finding |
|---|---|
| `yotamfried-ux/project-8@main:.claude/settings.json` | missing (404) after the first experiment |
| `yotamfried-ux/project-8@main:scripts/monitoring/eos-telemetry-event.sh` | missing (404) after the first experiment |
| `scripts/install-policy-gates.sh` | copied CI gates and patched settings only when settings already existed; it did not create settings |
| `scripts/enforcement/patch-settings-runtime-evidence.sh` | added runtime evidence hooks but not telemetry hooks |
| `.claude/settings.json` | canonical telemetry hooks existed, proving the intended behavior was already designed |
| `scripts/monitoring/eos-telemetry-event.sh` | reused one persistent `run_id`, so separate sessions could be merged into one run |
| `.github/workflows/pr-policy.yml` | captured only a point-in-time check snapshot; earlier failed runs on the PR branch were lost from final friction evidence |
| Project 8 Operational Work History | `telemetry_available=false`, `telemetry_events_count=0` and final `ci_failure_count=0` despite real earlier failures |

## Root causes

1. Project 8 used the direct policy-gate installer. That path did not create `.claude/settings.json`, so Claude hooks never loaded.
2. The direct installer also did not guarantee telemetry hook patching for customized settings.
3. Session telemetry reused a persistent run id instead of rotating per Claude session.
4. There was no fail-closed preflight proving the current session had emitted a real `session_start` event before work began.
5. Operational Work History represented only the current check snapshot, not the earlier CI friction from the same PR branch.

## Implemented fixes

1. `install-policy-gates.sh` now creates canonical settings when absent, always applies telemetry hooks, preserves customized settings, and renders the concrete Engineering OS reference path.
2. `patch-settings-telemetry.py` adds telemetry hooks idempotently and adds a fail-closed preflight guard before Bash, Read/Glob, Write/Edit, and Agent tool work.
3. `require-telemetry-session.sh` requires settings, run id, non-empty events, and a matching current-run `session_start` event.
4. `eos-telemetry-session-start.sh` archives the prior local run, creates a fresh run id, resets current events, and records the new session start.
5. `pr-policy.yml` now collects branch-level pull-request workflow history in addition to the current check snapshot.
6. `enrich-work-history-ci-history.py` adds aggregate historical run/failure counts to Operational Work History and routes historical failures into friction signals without storing raw logs, URLs, or run ids.
7. `test-project8-telemetry-readiness.sh` covers direct installation, customized-settings preservation, idempotency, session preflight, run rotation, and historical CI friction.
8. `docs/operations/project8-telemetry-preflight.md` defines the mandatory fresh-session verification and export sequence for the next experiment.

## Definition of Done

- [x] Route Plan committed before implementation.
- [x] Direct policy-gate installation into an empty target creates `.claude/settings.json` with telemetry hooks.
- [x] Existing custom settings retain custom hooks and receive missing telemetry hooks idempotently.
- [x] A session-start event creates a fresh run id and rotates prior run files.
- [x] Preflight fails with no current session-start event and passes with a matching event.
- [x] Installed settings enforce the preflight before Bash/Read/Write/Agent work.
- [x] Operational Work History records branch-level historical CI failures separately from current check state.
- [x] Historical CI failures contribute to friction and learning-loop routing.
- [x] Executable regression coverage was added for install/runtime/history behavior.
- [ ] Full enforcement-tests and all policy gates pass on the final head.
- [ ] Valid automated review findings are resolved.

## Connector Usage Evidence

- source: GitHub
- action: inspected Project 8 `main`, Engineering OS installer/settings/telemetry/collector/workflow sources, and merged PR evidence; implemented the canonical corrections on branch `fix/project8-telemetry-readiness`
- result: concrete missing paths and fail-open installation behavior now have upstream scripts and regression coverage
- decision: fixed the canonical installer and telemetry lifecycle upstream rather than adding another Project 8-only workaround
- target: `scripts/install-policy-gates.sh`, telemetry hook/preflight scripts, `.github/workflows/pr-policy.yml`, and `scripts/enforcement/tests/test-project8-telemetry-readiness.sh`

## Capability Evidence

- `routing.task-router-read`: task classified as `engineering_os_governance`.
- `workflow.workflow-read`: plan-first staged correction loop selected.
- `source.github-repo-read`: Project 8 and Engineering OS current files were read before writes.
- `validation.policy-change-has-validator`: installer/hook/history changes have executable regression coverage.
- `validation.actions-checked`: final-head GitHub Actions status is required before merge readiness.

## Documentation Asset Evidence

- internal: `docs/operations/runtime-telemetry-archive-plan.md`, `docs/operations/runtime-telemetry-archive-audit-checklist.md`, `docs/operations/operational-work-history-rollout.md`, `docs/operations/project8-telemetry-preflight.md`
- decision: the existing architecture remains metadata-only local hook collection plus export/import; this task fixes the missing installation/session/history wiring rather than introducing a new backend.

## Claude Run Trace

1. Verified Project 8 had no installed Claude settings and therefore no active hook layer.
2. Traced direct installation behavior to `install-policy-gates.sh` and the settings patch boundary.
3. Committed this Route Plan before implementation.
4. Added an idempotent telemetry settings patcher and fail-closed session guard.
5. Added per-session run rotation and local history preservation.
6. Added branch-level CI-history aggregation for Operational Work History.
7. Added one end-to-end regression suite covering the exact Project 8 failure mode and the new behavior.
8. Added the run-day preflight document for the next experiment.

## Operational Work History Evidence

- automatic_sources: `.engineering-os/work-history/latest.json`
- learning_loop_result: none-with-reason — the root cause, correction, and permanent regression fixtures are contained in this PR; no separate lesson artifact is needed unless review or real-run validation reveals a broader recurring pattern.

## Progress Lifecycle Evidence

- start: verified Project 8 lacked `.claude/settings.json`, traced the zero-event result to the direct installer and patcher behavior, and documented the point-in-time CI-history limitation before implementation.
- mid: implemented settings creation/patching, session rotation, fail-closed preflight, historical CI aggregation, regression coverage, and Project 8 run-day documentation; final validation is now delegated to the real PR gates and automated review.
