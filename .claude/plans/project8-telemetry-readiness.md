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
Target paths: `scripts/install-policy-gates.sh`, `scripts/enforcement/patch-settings-runtime-evidence.sh`, `.claude/settings.json`, `scripts/monitoring/eos-telemetry-event.sh`, `scripts/monitoring/require-telemetry-session.sh`, `scripts/monitoring/collect-pr-work-history.py`, `.github/workflows/pr-policy.yml`, telemetry/install regression tests

## Source of Truth Checks

| Source | Finding |
|---|---|
| `yotamfried-ux/project-8@main:.claude/settings.json` | missing (404) after the first experiment |
| `yotamfried-ux/project-8@main:scripts/monitoring/eos-telemetry-event.sh` | missing (404) after the first experiment |
| `scripts/install-policy-gates.sh` | copies CI gates and patches settings only when settings already exists; it does not create settings |
| `scripts/enforcement/patch-settings-runtime-evidence.sh` | adds runtime evidence hooks but not telemetry hooks |
| `.claude/settings.json` | canonical telemetry hooks exist, proving the intended behavior is already designed |
| `scripts/monitoring/eos-telemetry-event.sh` | reuses one persistent `run_id`, so separate sessions can be merged into one run |
| `.github/workflows/pr-policy.yml` | captures only a point-in-time check snapshot; earlier failed runs on the PR branch are lost from final friction evidence |
| Project 8 Operational Work History | `telemetry_available=false`, `telemetry_events_count=0` and final `ci_failure_count=0` despite real earlier failures |

## Root causes

1. Project 8 used the direct policy-gate installer. That path did not create `.claude/settings.json`, so Claude hooks never loaded.
2. The direct installer also did not guarantee telemetry hook patching for customized settings.
3. Session telemetry reused a persistent run id instead of rotating per Claude session.
4. There was no fail-closed preflight proving the current session had emitted a real `session_start` event before work began.
5. Operational Work History represented only the current check snapshot, not the earlier CI friction from the same PR branch.

## Planned fixes

1. Make `install-policy-gates.sh` create canonical settings when absent and patch existing settings without overwriting custom hooks.
2. Extend the settings patcher to install telemetry hooks plus a fail-closed session preflight guard.
3. Add `require-telemetry-session.sh`, which requires the current run id and a matching `session_start` event before tool work proceeds.
4. Rotate telemetry at every `session_start`, archive the previous run locally, and generate a new run id.
5. Extend PR metadata collection with branch-level CI history and include historical failures in Operational Work History friction signals.
6. Add regression fixtures for direct installation, customized-settings patching, session rotation/preflight, and historical CI friction.
7. Update run-day documentation so the next Project 8 run starts in a fresh Claude session after installation and fails closed if telemetry is not active.

## Definition of Done

- [x] Route Plan committed before implementation.
- [ ] Direct policy-gate installation into an empty target creates `.claude/settings.json` with telemetry hooks.
- [ ] Existing custom settings retain custom hooks and receive missing telemetry hooks idempotently.
- [ ] A session-start event creates a fresh run id and rotates prior run files.
- [ ] Preflight fails with no current session-start event and passes with a matching event.
- [ ] Canonical settings enforce the preflight before Bash/Read/Write/Agent work.
- [ ] Operational Work History records branch-level historical CI failures separately from current check state.
- [ ] Historical CI failures contribute to friction and learning-loop routing.
- [ ] Install/runtime/collector regression suites pass.
- [ ] Full enforcement-tests and all policy gates pass on the final head.
- [ ] Valid automated review findings are resolved.

## Connector Usage Evidence

- source: GitHub
- action: inspected Project 8 `main`, Engineering OS installer/settings/telemetry/collector/workflow sources, and merged PR evidence
- result: concrete missing paths and fail-open installation behavior were identified before implementation
- decision: fix the canonical installer and telemetry lifecycle upstream rather than adding another Project 8-only workaround
- target: the installer, telemetry hook layer, and Operational Work History collector paths listed above

## Capability Evidence

- `routing.task-router-read`: task classified as `engineering_os_governance`.
- `workflow.workflow-read`: plan-first staged correction loop selected.
- `source.github-repo-read`: Project 8 and Engineering OS current files were read before writes.
- `validation.policy-change-has-validator`: every installer/hook/collector change will have executable regression coverage.
- `validation.actions-checked`: final-head GitHub Actions status is required before merge readiness.

## Documentation Asset Evidence

- internal: `docs/operations/runtime-telemetry-archive-plan.md`, `docs/operations/runtime-telemetry-archive-audit-checklist.md`, `docs/operations/operational-work-history-rollout.md`
- decision: the existing architecture remains metadata-only local hook collection plus export/import; this task fixes the missing installation/session/history wiring rather than introducing a new backend.

## Operational Work History Evidence

- automatic_sources: `.engineering-os/work-history/latest.json`
- learning_loop_result: none-with-reason — this PR itself will contain the root-cause evidence and permanent regression fixtures for the discovered installation and session-lifecycle defects.

## Progress Lifecycle Evidence

- start: verified Project 8 lacks both `.claude/settings.json` and the local telemetry recorder, traced that to the direct installer and patcher behavior, and documented the point-in-time CI-history limitation before implementation.
