# Project 8 telemetry readiness fixes

Task type: Engineering OS telemetry installation and evidence hardening
Task class: engineering_os_governance
Domain tags: telemetry, installer, hooks, operational-work-history, ci, project-8
Plan Scope: focused
Planning Mode: staged
External systems/connectors: GitHub
Architecture guides: `docs/operations/runtime-telemetry-archive-plan.md`, `docs/operations/operational-work-history-rollout.md`, `core/debugging-policy.md`, `https://code.claude.com/docs/en/hooks`
Evidence to check: Project 8 `main`, installed settings, session events/run id, export bundle, branch CI history, Operational Work History, named regression steps, reviews, and exact final-head checks
User decisions required: owner approval before merging PR #244; no provider or Project 8 application decision is needed here

## Route Plan Evidence

| Field | Value |
|---|---|
| Task-router evidence | `core/task-router.md` read; classified as `engineering_os_governance` before implementation |
| Workflow evidence | `core/workflow.md` and `core/debugging-policy.md` read; plan-first reproduce-fix-verify lifecycle used |
| Templates | existing enforcement shell-fixture pattern in `scripts/enforcement/tests/` |
| Patterns | reproduce-before-fix; fail-closed preflight; metadata-only telemetry |
| Skills | not required |
| Validation gates | enforcement-tests, plan-policy, pr-policy, connector-evidence-policy, capability-evidence-policy, workflow-evidence-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy |
| Target paths | `.claude/settings.json`; `.github/workflows/pr-policy.yml`; `.github/workflows/enforcement-tests.yml`; `scripts/install-policy-gates.sh`; `scripts/monitoring/`; `scripts/enforcement/tests/`; `docs/operations/project8-telemetry-preflight.md` |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `https://github.com/yotamfried-ux/project-8` | validated | Project 8 `main` lacked `.claude/settings.json` and the telemetry recorder after the first experiment |
| `scripts/install-policy-gates.sh` | read | direct installation created CI gates but did not create missing Claude settings |
| `.claude/settings.json` | read | canonical hooks existed but were not installed by the direct path |
| `scripts/monitoring/eos-telemetry-event.sh` | read | the original run-id behavior could merge separate sessions |
| `.github/workflows/pr-policy.yml` | read | the final check snapshot omitted earlier branch failures |
| `https://code.claude.com/docs/en/hooks` | validated | `PreToolUse` blocks only on exit 2 and the required lifecycle events are supported |

## Implemented fixes

1. Direct gate installation creates or safely patches Claude settings, validates referenced telemetry runtime files, preserves custom hooks, and renders the concrete Engineering OS path.
2. Telemetry settings guard all tools and record metadata-only Pre/Post/failure, prompt, instruction, permission, subagent, task, compaction, stop, and session lifecycle events.
3. Session start archives the prior run beside the configured event file and creates a fresh run id even under a stable environment seed.
4. The preflight requires settings, run id, events, and a matching session start; all denials return Claude's blocking exit code 2.
5. Recorder output contains hashes, categories, buckets, booleans, and safe tokens only; fixtures prove raw prompt, error, path, command, response, and secrets are not retained.
6. `pr-policy` collects branch PR-run history and enriches Operational Work History with aggregate historical failures, including `startup_failure`, without raw logs, URLs, ids, branches, or payloads.
7. Named installer and Project 8 telemetry steps were added to `enforcement-tests` while preserving the full existing `use-in-project` contract.
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
- [x] Three Codex findings and CodeRabbit's `startup_failure` finding were fixed with regression coverage and their implementation threads were resolved.

Final merge remains externally gated on all nine workflows passing on the final plan-only head, zero unresolved valid review threads, and explicit owner approval.

## Connector Evidence

- GitHub was used to inspect Project 8 `main`, Engineering OS sources, PR #244 check runs, job steps, and review threads. This evidence changed the installer, runtime, CI-history implementation, and regression structure.

## Connector Usage Evidence

- source: GitHub
- action: inspected Project 8 installation state, canonical installer/telemetry/workflow files, PR #244 CI jobs, and Codex/CodeRabbit threads
- result: implementation head `22af2809d5093d1da0164d4b4a95780f2b495d4f` contains corrections in `scripts/install-policy-gates.sh`, `scripts/monitoring/`, `.github/workflows/`, and the telemetry regression suites and passed the complete enforcement job
- decision: changed canonical upstream installation and telemetry behavior rather than adding a Project 8-only workaround; CI and review evidence changed code and tests
- target: `scripts/install-policy-gates.sh`, `scripts/monitoring/`, `.github/workflows/pr-policy.yml`, `.github/workflows/enforcement-tests.yml`, and `scripts/enforcement/tests/`

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
- decision: official documentation changed the implementation to exit 2, all-tools matching, and privacy-safe lifecycle coverage; no new backend was introduced

## Claude Run Trace

1. Verified the missing Project 8 settings/recorder and traced the zero-event run to direct installation.
2. Added settings patching, session isolation, blocking preflight, privacy-safe lifecycle events, and CI-history enrichment.
3. Updated installer contract simulations when real enforcement exposed incomplete fixtures.
4. Fixed three Codex runtime findings with regression coverage.
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
- pre-merge: after the last code/test change, implementation head `22af2809d5093d1da0164d4b4a95780f2b495d4f` passed all 26 enforcement steps and every non-lifecycle policy gate; all implementation findings were resolved. This plan-only update records the final checkpoint while merge remains conditional on a clean exact-head rerun and owner approval.
