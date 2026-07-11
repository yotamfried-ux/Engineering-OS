# Project 8 telemetry readiness fixes

Task type: Engineering OS telemetry installation and evidence hardening
Task class: engineering_os_governance
Domain tags: telemetry, installer, hooks, operational-work-history, ci, project-8
Plan Scope: focused
Planning Mode: staged
External systems/connectors: GitHub
Architecture guides: `docs/operations/runtime-telemetry-archive-plan.md`, `docs/operations/operational-work-history-rollout.md`, `core/debugging-policy.md`, `https://code.claude.com/docs/en/hooks`
Templates: existing enforcement shell-fixture pattern
Patterns: reproduce-before-fix, fail-closed preflight, metadata-only telemetry
Skills: not required; this is a focused internal enforcement correction with executable regression coverage
Validation gates: enforcement-tests, plan-policy, pr-policy, connector-evidence-policy, capability-evidence-policy, workflow-evidence-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy
Evidence to check: Project 8 `main`, installed settings, session events/run id, export bundle, branch CI history, Operational Work History, named regression steps, reviews, and exact final-head checks
User decisions required: owner approval before merging PR #244; no provider or Project 8 application decision is needed here
Target paths: `.claude/settings.json`, `.github/workflows/{pr-policy,enforcement-tests}.yml`, `scripts/install-policy-gates.sh`, `scripts/monitoring/{patch-settings-telemetry.py,eos-telemetry-session-start.sh,eos-telemetry-event.sh,require-telemetry-session.sh,enrich-work-history-ci-history.py}`, `scripts/enforcement/policy-gate-dependencies.tsv`, `scripts/enforcement/tests/{test-install-policy-gate-coverage.sh,test-project8-telemetry-readiness.sh}`, `docs/operations/project8-telemetry-preflight.md`

## Source of Truth Checks

| Source | Finding |
|---|---|
| Project 8 `main` | `.claude/settings.json` and the telemetry recorder were absent after the first experiment |
| `install-policy-gates.sh` | installed CI gates but did not create missing Claude settings |
| telemetry recorder/session code | reused a persistent run id and initially resolved runtime files from the wrong root |
| `pr-policy.yml` | captured a final check snapshot but lost earlier branch failures |
| first Project 8 artifact | `telemetry_available=false`, `telemetry_events_count=0`, final `ci_failure_count=0` despite earlier failures |
| official Claude hooks reference | project settings are shareable; hook JSON arrives on stdin; lifecycle hooks are supported; `PreToolUse` blocks only with exit code 2 |

## Implemented fixes

1. Direct gate installation now creates or safely patches Claude settings, validates all referenced telemetry runtime files, preserves custom hooks, and renders the concrete Engineering OS path.
2. Telemetry settings now guard all tools and record metadata-only Pre/Post/failure, prompt, instruction, permission, subagent, task, compaction, stop, and session lifecycle events.
3. Session start archives the prior run beside the configured event file and always creates a fresh run id, including under a stable environment seed.
4. The preflight requires settings, run id, events, and a matching current-session start event; all denials return Claude's blocking exit code 2.
5. Recorder output contains hashes, categories, buckets, booleans, and safe tokens only; fixtures prove raw prompt, error, path, command, response, and secrets are not retained.
6. `pr-policy` collects branch pull-request run history and enriches Operational Work History with aggregate historical failures, including `startup_failure`, without raw logs, URLs, run ids, branches, or payloads.
7. Named installer and Project 8 telemetry steps were added to `enforcement-tests`; the existing complete `use-in-project` contract was preserved.
8. `docs/operations/project8-telemetry-preflight.md` defines fresh-session verification and non-empty export/import preparation.

## Definition of Done

- [x] Plan committed before implementation.
- [x] Empty-target direct installation creates usable telemetry settings.
- [x] Custom settings retain custom hooks and receive idempotent telemetry hooks.
- [x] Sessions rotate run ids and archive prior events/summary correctly.
- [x] Runtime scripts resolve without `ENGINEERING_OS_HOME` in the target process.
- [x] Preflight blocks with exit code 2 when telemetry is missing/disabled and passes for a matching current session.
- [x] Tool and lifecycle metadata coverage is installed for the next experiment.
- [x] Privacy fixture proves raw sensitive content is not stored.
- [x] Historical CI failures and `startup_failure` feed friction evidence.
- [x] Installer/runtime/privacy/history changes have executable regression tests and named CI steps.
- [x] Implementation head `22af2809d5093d1da0164d4b4a95780f2b495d4f` passed all 26 enforcement steps and every non-lifecycle policy gate.
- [x] Three Codex findings and CodeRabbit's `startup_failure` finding were fixed with regression coverage; their implementation threads were resolved.

Final merge remains externally gated on all nine workflows passing on the final plan-only head, zero unresolved valid review threads, and explicit owner approval.

## Connector Evidence

- GitHub inspection of Project 8 `main`, Engineering OS sources, PR #244 check runs, job steps, and review threads directly changed the implementation: it proved the installation gap, isolated CI failures, and surfaced valid review findings.

## Connector Usage Evidence

- source: GitHub
- action: inspected Project 8 installation state, canonical installer/telemetry/workflow sources, PR #244 CI jobs, and Codex/CodeRabbit threads
- result: concrete corrections exist in the installer, session/preflight/recorder/history scripts, named CI steps, and regression suites; implementation head `22af2809d5093d1da0164d4b4a95780f2b495d4f` passed the complete enforcement job
- decision: fixed canonical upstream behavior rather than adding another Project 8-only workaround; CI and review evidence materially changed code and tests
- target: the target paths declared above

## Capability Evidence

- `routing.task-router-read`: classified as `engineering_os_governance`.
- `workflow.workflow-read`: used plan-first staged correction.
- `plan.route-plan-before-write`: plan commit preceded implementation.
- `source.github-repo-read`: Project 8 and Engineering OS sources, CI, and reviews were inspected before corrections.
- `validation.policy-change-has-validator`: every behavior change has executable regression coverage.
- `validation.coderabbit-policy`: valid Codex/CodeRabbit findings were fixed and resolved before this checkpoint.
- `validation.actions-checked`: implementation-head Actions were checked; final plan-only head must pass again.

## Documentation Asset Evidence

- internal: `docs/operations/runtime-telemetry-archive-plan.md`, `docs/operations/runtime-telemetry-archive-audit-checklist.md`, `docs/operations/operational-work-history-rollout.md`, `docs/operations/project8-telemetry-preflight.md`
- context7: `https://code.claude.com/docs/en/hooks` was checked directly for hook events, stdin payloads, cadence, matcher behavior, parallel handlers, and blocking exit semantics
- decision: official documentation changed the implementation to exit 2, all-tools matching, and privacy-safe prompt/failure/instruction/session lifecycle coverage; no new backend was introduced

## Claude Run Trace

1. Verified the missing Project 8 settings/recorder and traced the zero-event run to direct installation.
2. Added settings patching, session isolation, blocking preflight, privacy-safe lifecycle events, and CI-history enrichment.
3. Updated installer contract simulations when real enforcement exposed incomplete fixtures.
4. Fixed three Codex session-runtime findings with regression coverage.
5. Applied official hook semantics, including exit code 2 and supported lifecycle events.
6. Restored the full `use-in-project` contract after simulation coverage detected removed assertions.
7. Added `startup_failure` after CodeRabbit review.
8. Implementation head `22af2809d5093d1da0164d4b4a95780f2b495d4f` passed all 26 enforcement steps; implementation review threads were resolved.

## Operational Work History Evidence

- automatic_sources: `.engineering-os/work-history/latest.json`
- learning_loop_result: none-with-reason — CI failures and review findings were fixed inline with permanent regression coverage, so this PR and plan are the durable record.

## Progress Lifecycle Evidence

- start: verified the missing settings/recorder, zero-event result, persistent run id, and point-in-time CI limitation before implementation.
- mid: corrected installation, lifecycle coverage, session isolation, blocking semantics, privacy, historical CI aggregation, named CI visibility, and review findings.
- pre-merge: after the last code/test change, implementation head `22af2809d5093d1da0164d4b4a95780f2b495d4f` passed all 26 enforcement steps and every non-lifecycle policy gate; all implementation findings were resolved. This plan-only commit records the final checkpoint, while merge remains conditional on a clean final-head rerun and owner approval.
