# Remove fresh-session hook blocker regression

Task type: enforcement regression repair
Task class: engineering_os_governance
Domain tags: hooks, telemetry, runtime-evidence, connectors, regression, governance
Plan Scope: focused
Planning Mode: staged
Architecture guides: `core/hooks-policy.md`, `core/connector-policy.md`, `core/debugging-policy.md`
External systems/connectors: GitHub
Evidence to check: `main` hook wiring, telemetry guard history, active-plan selection history, regression fixtures, GitHub Actions, and PR review threads
User decisions required: explicit owner approval before merge; no change to the fail-closed policy for genuinely required enforcement gates

## Route Plan Evidence

| Field | Value |
|---|---|
| Task-router evidence | `core/task-router.md` classification: `engineering_os_governance` enforcement regression repair |
| Workflow evidence | plan-first reproduce-fix-verify lifecycle; preserve enforcement while correcting scope and failure mode |
| Templates | existing shell regression suites in `scripts/enforcement/tests/` |
| Patterns | fail-before/pass-after fixtures; active-plan evidence instead of newest-file inference |
| Skills | not required |
| Validation gates | enforcement-tests, telemetry-handoff-tests, plan-policy, pr-policy, connector-evidence-policy, capability-evidence-policy, workflow-evidence-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy |
| Target paths | `scripts/monitoring/require-telemetry-session.sh`, `scripts/enforcement/pre-tool-use-runtime-evidence.sh`, `scripts/enforcement/check-runtime-evidence.sh`, `scripts/enforcement/tests/` |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `.claude/settings.json` on `main` | read | all-tools telemetry guard is installed, but canonical Stop/StopFailure/SessionEnd hooks still use the local recorder rather than the durable boundary wrapper |
| `scripts/monitoring/require-telemetry-session.sh` | read | guard treated the missing durable-boundary registration as an unconditional exit-2 failure, so even disabled/local-only policy denied every tool |
| `https://github.com/yotamfried-ux/Engineering-OS/pull/244` | validated | commit `c2572b03f296703d1ff6c84cfbf4e0796b62f588` introduced intentional all-tools fail-closed telemetry preflight |
| `https://github.com/yotamfried-ux/Engineering-OS/pull/245` | validated | commit `7f0c2ccbb78e866186e4beb80c3018696f08d3b9` added durable handoff requirement and idempotent settings patcher without updating canonical settings |
| `https://github.com/yotamfried-ux/Engineering-OS/pull/80` | validated | commit `b9ee21712d8fc2ea6217249fce42a56622aab750` introduced Stop-time runtime evidence with newest-plan-by-mtime fallback |
| `scripts/enforcement/check-runtime-evidence.sh` | read | selected arbitrary newest historical plan when no current-task plan was supplied |
| `scripts/enforcement/lib/evidence.sh` | read | provides a per-session evidence ledger suitable for recording the plan actually selected by a successful write gate |

## Experiment

Executable fixtures cover both failures:

1. A fresh local-only telemetry session invokes the guard for Bash, Read, Glob, Grep, ToolSearch, AskUserQuestion, and an MCP GitHub tool; all must remain available after a valid SessionStart.
2. Required-handoff policy with legacy boundary wiring remains fail-closed.
3. A research-only fresh session with stale plans present must not inherit connector requirements from the newest historical plan.
4. A write session records the exact plan it selected, and Stop runtime evidence still blocks when that active plan genuinely lacks declared connector evidence.
5. Explicit active-plan selection and the documented connector waiver remain supported.

## Fix

- Make the telemetry guard policy-aware: local session integrity remains mandatory, but missing durable boundary runtime/wiring is warning-only for `disabled` and `best_effort`, and remains blocking for `required`.
- Preserve the intentional all-tools matcher so telemetry coverage is not silently reduced.
- Record the target-aware Route Plan selected by a successful Write/Edit runtime gate into the current session evidence ledger.
- Make Stop runtime evidence select only an explicit active plan, `.claude/plans/active.md`, or the plan actually selected during this session; remove arbitrary newest-file inference.
- Preserve connector evidence enforcement and documented connector waiver behavior whenever a current plan is present.

## Definition of Done

- [x] Route Plan commit `665234ffc44c68850fda1b1115944cc60904931d` precedes every implementation and test commit.
- [x] `test-fresh-session-hook-scoping.sh` covers every tool name reported in the fresh-session lockout.
- [x] A negative fixture proves `required` telemetry policy still blocks legacy durable-boundary wiring.
- [x] `test-runtime-evidence.sh` proves a successful Write gate records the exact current plan.
- [x] `test-stop-runtime-plan-scoping.sh` proves unrelated historical plans are ignored without session selection.
- [x] Stop-time tests prove missing connector evidence still blocks for the selected current plan.
- [x] Stop-time tests prove matching connector evidence and a documented connector waiver pass.
- [x] Existing Write/Edit Route Plan and Agent tasks.json gates remain unchanged and covered by the aggregate enforcement suite.
- [x] PR #246 runs all required GitHub Actions and records any correction loop on exact heads.
- [x] Merge remains disabled until exact-head checks, review threads, and explicit owner approval are all satisfied.

Exact-head green status and automated review remain external merge gates; they are not claimed by this implementation checkpoint.

## Connector Evidence

- GitHub: used to inspect canonical source, commit/PR history, branch state, Actions, and review threads.

## Connector Usage Evidence

- source: GitHub
- action: inspected `yotamfried-ux/Engineering-OS` main files, PR #80, PR #244, PR #245, their merge commits, current enforcement tests, and PR #246 workflow runs
- result: implemented policy-aware telemetry preflight, current-session plan recording, Stop scoping, three regression suites, and corrected the workflow-evidence plan format/source references on PR #246
- decision: kept all-tools telemetry coverage and fail-closed required mode, while removing unconditional local-only lockout and stale historical plan inference
- target: `scripts/monitoring/require-telemetry-session.sh`, `scripts/enforcement/pre-tool-use-runtime-evidence.sh`, `scripts/enforcement/check-runtime-evidence.sh`, `scripts/enforcement/tests/test-fresh-session-hook-scoping.sh`, `scripts/enforcement/tests/test-runtime-evidence.sh`, `scripts/enforcement/tests/test-stop-runtime-plan-scoping.sh`

## Capability Evidence

- `routing.task-router-read`: classified the change as Engineering OS governance.
- `workflow.workflow-read`: applied plan-first reproduce-fix-verify sequencing.
- `plan.route-plan-before-write`: commit `665234ffc44c68850fda1b1115944cc60904931d` created this plan before implementation.
- `source.github-repo-read`: inspected canonical GitHub source and the introducing PRs/commits.
- `validation.policy-change-has-validator`: added executable negative and positive regression cases.
- `validation.coderabbit-policy`: automated review and live thread state are mandatory before merge.
- `validation.actions-checked`: PR #246 workflows were inspected on implementation heads `40bef934317c3fe63885bfdba589d011be1ab3b9` and `2f515e22cd3735c2a046494695de960a25cf97fe`; exact final-head confirmation remains a merge gate.

## Documentation Asset Evidence

- internal: `core/hooks-policy.md`, `core/connector-policy.md`, `core/debugging-policy.md`, `.claude/settings.json`, telemetry patcher, and existing enforcement suites
- context7: not required; the defect is internal configuration/scoping drift, while PR #244 already validated official Claude hook exit semantics
- decision: restore mode-appropriate failure behavior and current-task scoping without changing the governing enforcement principles

## Claude Run Trace

1. Inspected `main` settings and confirmed the all-tools telemetry guard.
2. Proved the guard required a boundary marker absent from canonical settings.
3. Traced the all-tools fail-closed guard to PR #244 and the durable-handoff requirement to PR #245.
4. Traced newest-plan Stop enforcement to PR #80.
5. Created the Route Plan before implementation.
6. Made telemetry boundary readiness mode-aware while preserving current-session validation and required-mode blocking.
7. Recorded the plan selected by the successful write gate.
8. Replaced newest-plan Stop inference with explicit/current-session selection and added connector-waiver handling consistent with connector policy.
9. Added fresh-session, active-plan, stale-plan, required-mode, and waiver regression fixtures.
10. Opened PR #246; the first workflow-evidence run identified DoD/checkpoint formatting while the other completed policy workflows were green.
11. Replaced the DoD status table with concrete checked verification items and recorded an ordered pre-merge checkpoint after the final code/test commit.
12. Read the second workflow diagnostic artifact and replaced shorthand PR/commit source labels with concrete GitHub PR URLs.

## Operational Work History Evidence

- automatic_sources: `.engineering-os/work-history/latest.json`
- selected_result_loop_contract: engineering-os-governance
- learning_loop_result: none-with-reason — the introducing PR/commit trace, executable regression fixtures, and PR #246 correction history form the durable learning record

## Progress Lifecycle Evidence

- start: reproduced both contradictions from canonical source and identified PR #80, PR #244, and PR #245 before implementation.
- mid: implemented mode-aware telemetry behavior, current-session plan recording, Stop scoping, connector waiver preservation, and focused regression fixtures.
- pre-merge: reviewed the complete seven-file diff after the final code/test commit, opened PR #246, and corrected both workflow-evidence diagnostics from runs `29618267427` and `29618344383`.
