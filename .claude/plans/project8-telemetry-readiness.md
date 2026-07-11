# Project 8 telemetry readiness fixes

Task type: Engineering OS telemetry installation and evidence hardening
Task class: engineering_os_governance
Domain tags: telemetry, installer, hooks, operational-work-history, ci, project-8
Plan Scope: focused
Planning Mode: staged
External systems/connectors: GitHub
Architecture guides: `docs/operations/runtime-telemetry-archive-plan.md`, `docs/operations/operational-work-history-rollout.md`, `core/debugging-policy.md`, official Claude Code hooks reference
Templates: existing enforcement-test shell fixture pattern
Patterns: reproduce-before-fix, fail-closed preflight, metadata-only telemetry
Skills: not required because this is a focused internal hook/installer correction with executable regression coverage
Validation gates: enforcement-tests, plan-policy, pr-policy, connector-evidence-policy, capability-evidence-policy, workflow-evidence-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy
Evidence to check: Project 8 `main`, `.claude/settings.json`, installer output, current-session `events.jsonl`, run-id rotation, exported telemetry bundle, branch-level GitHub Actions history, Operational Work History artifact, named telemetry regression steps, and final-head PR reviews/checks
User decisions required: explicit owner approval is required before merging PR #244; no provider-side or Project 8 application decision is required in this upstream task
Target paths: `.claude/settings.json`, `scripts/install-policy-gates.sh`, `scripts/monitoring/patch-settings-telemetry.py`, `scripts/monitoring/eos-telemetry-session-start.sh`, `scripts/monitoring/eos-telemetry-event.sh`, `scripts/monitoring/require-telemetry-session.sh`, `scripts/monitoring/enrich-work-history-ci-history.py`, `.github/workflows/pr-policy.yml`, `.github/workflows/enforcement-tests.yml`, `scripts/enforcement/policy-gate-dependencies.tsv`, `scripts/enforcement/tests/test-install-policy-gate-coverage.sh`, `scripts/enforcement/tests/test-project8-telemetry-readiness.sh`, `docs/operations/project8-telemetry-preflight.md`

## Source of Truth Checks

| Source | Finding |
|---|---|
| `yotamfried-ux/project-8@main:.claude/settings.json` | missing (404) after the first experiment |
| `yotamfried-ux/project-8@main:scripts/monitoring/eos-telemetry-event.sh` | missing (404) after the first experiment |
| `scripts/install-policy-gates.sh` | copied CI gates and patched settings only when settings already existed; it did not create settings |
| `scripts/enforcement/patch-settings-runtime-evidence.sh` | added runtime evidence hooks but not telemetry hooks |
| `.claude/settings.json` | canonical telemetry hooks existed, proving the intended behavior was designed but not installed by the direct path |
| `scripts/monitoring/eos-telemetry-event.sh` | reused one persistent `run_id`, so separate sessions could be merged into one run |
| `.github/workflows/pr-policy.yml` | captured only a point-in-time check snapshot; earlier failed runs on the PR branch were lost from final friction evidence |
| Project 8 Operational Work History | `telemetry_available=false`, `telemetry_events_count=0` and final `ci_failure_count=0` despite real earlier failures |
| `https://code.claude.com/docs/en/hooks` | confirms project settings are shareable, command hooks receive JSON on stdin, SessionStart/SessionEnd are per-session, UserPromptSubmit is per-turn, PostToolUseFailure fires after tool failure, InstructionsLoaded is intended for observability, all matching handlers can run in parallel, and PreToolUse blocks only on exit code 2 |

## Root causes

1. Project 8 used the direct policy-gate installer. That path did not create `.claude/settings.json`, so Claude hooks never loaded.
2. The direct installer did not guarantee telemetry hook patching for customized settings.
3. The SessionStart wrapper originally resolved the recorder from the target repo rather than from the installed absolute wrapper path.
4. Session telemetry reused a persistent run id, including when a stable process-level seed was present.
5. The first preflight implementation exited with code 1, which Claude Code treats as a non-blocking hook error rather than a PreToolUse denial.
6. Telemetry covered only a subset of successful tools and omitted prompt, instruction-loading, failure, permission, subagent, task, compaction, and session-end lifecycle events.
7. Operational Work History represented only the current check snapshot, not earlier CI friction from the same PR branch.
8. The aggregate `enforcement-tests` shard made telemetry regressions visible only as a broad G–L failure instead of a named contract result.

## Implemented fixes

1. `install-policy-gates.sh` creates canonical settings when absent, always applies telemetry hooks, preserves customized settings, and renders the concrete Engineering OS reference path.
2. `patch-settings-telemetry.py` normalizes legacy recorder hooks into all-tools Pre/Post coverage, adds prompt/failure/instruction/subagent/task/session lifecycle hooks, preserves unrelated custom/enforcement hooks, and remains idempotent.
3. Canonical `.claude/settings.json` now contains the same fail-closed and lifecycle coverage installed downstream.
4. `require-telemetry-session.sh` requires settings, run id, non-empty events, and a matching current-run `session_start`; every failure exits with Claude Code's blocking code 2.
5. `eos-telemetry-session-start.sh` resolves its recorder beside the wrapper, derives history beside an overridden event path, archives the prior run, and creates a fresh id even when `EOS_TELEMETRY_RUN_ID` is a stable seed.
6. `eos-telemetry-event.sh` prefers the per-session run-id file, resolves its summary analyzer beside itself, captures prompt/instruction/effort/agent/task/error metadata, and stores only hashes, buckets, categories, booleans, and safe tokens.
7. `pr-policy.yml` collects branch-level pull-request workflow history in addition to the current check snapshot.
8. `enrich-work-history-ci-history.py` adds aggregate historical run/failure counts to Operational Work History and routes historical failures into friction signals without storing raw logs, URLs, run ids, branches, or payloads.
9. Installer and telemetry regression suites cover direct installation, customized-settings preservation, idempotency, exact exit code 2, self-contained wrapper/summary resolution, stable-seed session rotation, privacy-safe prompt/failure/instruction events, and historical CI friction.
10. `enforcement-tests.yml` exposes installer telemetry coverage and Project 8 telemetry readiness as named CI steps before the alphabetical aggregate shards.
11. `docs/operations/project8-telemetry-preflight.md` defines the mandatory fresh-session verification and export sequence for the next experiment.

## Definition of Done

- [x] Route Plan committed before implementation.
- [x] Direct policy-gate installation into an empty target creates `.claude/settings.json` with telemetry hooks.
- [x] Existing custom settings retain custom hooks and receive missing telemetry hooks idempotently.
- [x] A session-start event creates a fresh run id and rotates prior run files, including under a stable process-level seed.
- [x] The session wrapper and stop summary resolve their sibling telemetry scripts without `ENGINEERING_OS_HOME` in the target process.
- [x] Preflight blocks with exit code 2 when current-session telemetry is absent or disabled and passes with a matching event.
- [x] All tool types are guarded; prompt, instruction, tool-failure, permission, subagent, task, compaction, stop-failure, and session-end metadata are configured.
- [x] Prompt, error, instruction path, commands, responses, and sensitive values are not stored raw in the regression fixture.
- [x] Operational Work History records branch-level historical CI failures separately from current check state.
- [x] Historical CI failures contribute to friction and learning-loop routing.
- [x] Executable regression coverage was added for install/runtime/privacy/history behavior.
- [x] Critical installer and Project 8 telemetry suites have named CI steps.
- [ ] Full enforcement-tests and all policy gates pass on the final head.
- [ ] Valid automated review findings are resolved.

## Connector Evidence

- GitHub was used to inspect the exact Project 8 `main` installation state, Engineering OS canonical sources, PR #244 check runs, job steps, review threads, and changed files. The connector changed the implementation by proving the installed settings and recorder paths were missing, exposing the broad G–L failure location, and surfacing three valid Codex findings that required wrapper and run-id corrections.

## Connector Usage Evidence

- source: GitHub
- action: inspected Project 8 `main`, Engineering OS installer/settings/telemetry/collector/workflow sources, PR #244 CI jobs, and its Codex review threads
- result: `scripts/install-policy-gates.sh`, `scripts/monitoring/eos-telemetry-session-start.sh`, `scripts/monitoring/require-telemetry-session.sh`, `scripts/enforcement/tests/test-project8-telemetry-readiness.sh`, and `.github/workflows/enforcement-tests.yml` now contain concrete upstream corrections and named regression coverage
- decision: implemented the canonical installer and telemetry lifecycle fixes upstream; Codex P1/P2 findings, official hook exit semantics, and the broad G–L CI failure changed the code and validation structure before merge readiness
- target: `.claude/settings.json`, installer, telemetry recorder/session/preflight scripts, `.github/workflows/pr-policy.yml`, `.github/workflows/enforcement-tests.yml`, and both install/telemetry regression suites

## Capability Evidence

- `routing.task-router-read`: task classified as `engineering_os_governance`.
- `workflow.workflow-read`: plan-first staged correction loop selected.
- `plan.route-plan-before-write`: this plan was committed before implementation files.
- `source.github-repo-read`: Project 8 and Engineering OS current files, PR CI, and review threads were read before corrective writes.
- `validation.policy-change-has-validator`: installer/hook/privacy/history changes have executable regression coverage and named CI steps.
- `validation.coderabbit-policy`: Codex findings are treated as external review; CodeRabbit status/fallback and all valid findings must be recorded before merge.
- `validation.actions-checked`: final-head GitHub Actions status is required before merge readiness.

## Documentation Asset Evidence

- internal: `docs/operations/runtime-telemetry-archive-plan.md`, `docs/operations/runtime-telemetry-archive-audit-checklist.md`, `docs/operations/operational-work-history-rollout.md`, `docs/operations/project8-telemetry-preflight.md`
- context7: `https://code.claude.com/docs/en/hooks` was checked directly because this task changes Claude Code hook event names, matcher behavior, command stdin, lifecycle cadence, parallel handler behavior, and blocking exit-code semantics.
- decision: the official hook reference changed the implementation: the preflight now exits 2 instead of 1, telemetry uses an all-tools matcher, and supported UserPromptSubmit/PostToolUseFailure/InstructionsLoaded/SessionEnd lifecycle events are collected metadata-only; the existing archive architecture remains local export/import rather than adding a backend.

## Claude Run Trace

1. Verified Project 8 had no installed Claude settings and therefore no active hook layer.
2. Traced direct installation behavior to `install-policy-gates.sh` and the settings patch boundary.
3. Committed this Route Plan before implementation.
4. Added an idempotent telemetry settings patcher, session wrapper, fail-closed preflight, CI-history enricher, and initial fixtures.
5. Updated an existing installer contract test after G–L enforcement tests exposed its incomplete fake Engineering OS home.
6. Codex found three real session-wrapper gaps: wrong recorder root, wrong history root under overridden paths, and stable seed reuse. All three were fixed with regression coverage.
7. Official Claude Code hook documentation revealed that PreToolUse exit 1 is non-blocking and that relevant prompt/failure/instruction/session lifecycle events are supported. The implementation and fixtures were expanded accordingly.
8. Canonical settings and the downstream patcher were aligned to one all-tools, privacy-safe lifecycle contract.
9. Branch-level CI-history aggregation and Project 8 run-day documentation remain part of the same focused readiness fix.
10. Added named installer and telemetry readiness CI steps so future failures identify the exact contract rather than only an alphabetical shard.

## Operational Work History Evidence

- automatic_sources: `.engineering-os/work-history/latest.json`
- learning_loop_result: none-with-reason — early CI failures and three real Codex findings were fixed inline with permanent regression coverage; they are recorded in this plan and PR evidence rather than duplicated in a separate lesson artifact.

## Progress Lifecycle Evidence

- start: verified Project 8 lacked `.claude/settings.json`, traced the zero-event result to the direct installer and patcher behavior, and documented the point-in-time CI-history limitation before implementation.
- mid: corrected direct/custom installation, all-tools lifecycle coverage, session isolation, blocking exit semantics, privacy-safe event metadata, historical CI aggregation, named CI visibility, the preflight procedure, and the real Codex findings; final-head validation and final review resolution remain outstanding external gates.
