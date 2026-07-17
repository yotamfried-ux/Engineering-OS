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
| PR #244 / commit `c2572b03f296703d1ff6c84cfbf4e0796b62f588` | validated | introduced intentional all-tools fail-closed telemetry preflight |
| PR #245 / commit `7f0c2ccbb78e866186e4beb80c3018696f08d3b9` | validated | added durable handoff requirement and idempotent settings patcher without updating canonical settings |
| PR #80 / commit `b9ee21712d8fc2ea6217249fce42a56622aab750` | validated | introduced Stop-time runtime evidence with newest-plan-by-mtime fallback |
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

## Definition of Done Status

| Requirement | Status before PR |
|---|---|
| Plan committed before implementation changes | complete — plan commit `665234ffc44c68850fda1b1115944cc60904931d` precedes implementation |
| Fresh-session all-tool regression fixture | implemented in `test-fresh-session-hook-scoping.sh` |
| Stale-plan Stop scoping fixture | implemented in `test-stop-runtime-plan-scoping.sh` |
| Successful write records current plan | implemented and asserted in `test-runtime-evidence.sh` |
| Required telemetry remains fail-closed | implemented and covered by a negative fixture |
| Current-plan missing connector evidence remains blocking | implemented and covered by a negative fixture |
| Connector waiver and explicit active plan remain supported | implemented and covered by positive/negative fixtures |
| Write/Edit plan and Agent tasks.json gates remain intact | unchanged; existing enforcement suites remain the regression backstop |
| Focused and aggregate suites | pending GitHub Actions on the PR head |
| Automated review and live thread state | pending PR review |
| Merge | blocked pending exact-head green checks, resolved findings, and explicit owner approval |

## Connector Evidence

- GitHub: used to inspect canonical source, commit/PR history, branch state, Actions, and review threads.

## Connector Usage Evidence

- source: GitHub
- action: inspected `yotamfried-ux/Engineering-OS` main files, PR #80, PR #244, PR #245, their merge commits, and current enforcement tests
- result: implemented policy-aware telemetry preflight, current-session plan recording, Stop scoping, and three regression suites under `scripts/monitoring/`, `scripts/enforcement/`, and `scripts/enforcement/tests/`
- decision: kept all-tools telemetry coverage and fail-closed required mode, while removing unconditional local-only lockout and stale historical plan inference
- target: `scripts/monitoring/require-telemetry-session.sh`, `scripts/enforcement/pre-tool-use-runtime-evidence.sh`, `scripts/enforcement/check-runtime-evidence.sh`, `scripts/enforcement/tests/test-fresh-session-hook-scoping.sh`, `scripts/enforcement/tests/test-runtime-evidence.sh`, `scripts/enforcement/tests/test-stop-runtime-plan-scoping.sh`

## Capability Evidence

- `routing.task-router-read`: classified the change as Engineering OS governance.
- `workflow.workflow-read`: applied plan-first reproduce-fix-verify sequencing.
- `plan.route-plan-before-write`: commit `665234ffc44c68850fda1b1115944cc60904931d` created this plan before implementation.
- `source.github-repo-read`: inspected canonical GitHub source and the introducing PRs/commits.
- `validation.policy-change-has-validator`: added executable negative and positive regression cases.
- `validation.coderabbit-policy`: automated review and live thread state are mandatory before merge.
- `validation.actions-checked`: exact-head Actions evidence is mandatory before merge.

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

## Operational Work History Evidence

- automatic_sources: `.engineering-os/work-history/latest.json`
- selected_result_loop_contract: engineering-os-governance
- learning_loop_result: pending — regression fixtures plus final PR evidence will be the durable learning record

## Progress Lifecycle Evidence

- start: reproduced both contradictions from canonical source and identified the introducing PRs before implementation.
- mid: implemented mode-aware telemetry behavior, current-session plan recording, Stop scoping, connector waiver preservation, and focused regression fixtures.
- pre-merge: pending exact-head CI and review evidence; merge remains externally blocked.
