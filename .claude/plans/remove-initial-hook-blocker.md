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
| Target paths | `scripts/monitoring/require-telemetry-session.sh`, `scripts/enforcement/lib/evidence.sh`, `scripts/enforcement/pre-tool-use-runtime-evidence.sh`, `scripts/enforcement/check-runtime-evidence.sh`, `scripts/enforcement/tests/` |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `.claude/settings.json` on `main` | read | all-tools telemetry guard is installed, but canonical Stop/StopFailure/SessionEnd hooks still use the local recorder rather than the durable boundary wrapper |
| `scripts/monitoring/require-telemetry-session.sh` | read | guard treated the missing durable-boundary registration as an unconditional exit-2 failure, so even disabled/local-only policy denied every tool |
| `https://github.com/yotamfried-ux/Engineering-OS/pull/244` | validated | commit `c2572b03f296703d1ff6c84cfbf4e0796b62f588` introduced intentional all-tools fail-closed telemetry preflight |
| `https://github.com/yotamfried-ux/Engineering-OS/pull/245` | validated | commit `7f0c2ccbb78e866186e4beb80c3018696f08d3b9` added durable handoff requirement and idempotent settings patcher without updating canonical settings |
| `https://github.com/yotamfried-ux/Engineering-OS/pull/80` | validated | commit `b9ee21712d8fc2ea6217249fce42a56622aab750` introduced Stop-time runtime evidence with newest-plan-by-mtime fallback |
| `scripts/enforcement/check-runtime-evidence.sh` | read | selected arbitrary newest historical plan when no current-task plan was supplied |
| `scripts/enforcement/lib/evidence.sh` | read | provides a per-session evidence ledger and now owns shared connector-waiver parsing for both Write/Edit and Stop gates |

## Experiment

Executable fixtures cover both failures and the review correction:

1. A fresh local-only telemetry session invokes the guard for Bash, Read, Glob, Grep, ToolSearch, AskUserQuestion, and an MCP GitHub tool; all must remain available after a valid SessionStart.
2. Required-handoff policy with legacy boundary wiring remains fail-closed.
3. A research-only fresh session with stale plans present must not inherit connector requirements from the newest historical plan.
4. A write session records the exact plan it selected, and Stop runtime evidence still blocks when that active plan genuinely lacks declared connector evidence.
5. Explicit active-plan selection and the documented connector waiver remain supported.
6. A connector waiver must have identical semantics at Write/Edit and Stop: without evidence or waiver the write blocks; with a connector-specific documented waiver the write passes and records the active plan.

## Fix

- Make the telemetry guard policy-aware: local session integrity remains mandatory, but missing durable boundary runtime/wiring is warning-only for `disabled` and `best_effort`, and remains blocking for `required`.
- Preserve the intentional all-tools matcher so telemetry coverage is not silently reduced.
- Record the target-aware Route Plan selected by a successful Write/Edit runtime gate into the current session evidence ledger.
- Make Stop runtime evidence select only an explicit active plan, `.claude/plans/active.md`, or the plan actually selected during this session; remove arbitrary newest-file inference.
- Centralize connector-waiver parsing in `lib/evidence.sh` and use the same helper at Write/Edit and Stop so documented waivers cannot be accepted at only one lifecycle stage.
- Preserve connector evidence enforcement whenever neither matching evidence nor a connector-specific documented waiver exists.

## Definition of Done

- [x] Route Plan commit `665234ffc44c68850fda1b1115944cc60904931d` precedes every implementation and test commit.
- [x] `test-fresh-session-hook-scoping.sh` covers every tool name reported in the fresh-session lockout.
- [x] A negative fixture proves `required` telemetry policy still blocks legacy durable-boundary wiring.
- [x] `test-runtime-evidence.sh` proves a successful Write gate records the exact current plan.
- [x] `test-stop-runtime-plan-scoping.sh` proves unrelated historical plans are ignored without session selection.
- [x] Stop-time tests prove missing connector evidence still blocks for the selected current plan.
- [x] Stop-time tests prove matching connector evidence and a documented connector waiver pass.
- [x] Write-time tests prove a declared connector without evidence or waiver blocks, while a connector-specific documented waiver passes.
- [x] Write/Edit and Stop consume the same shared connector-waiver parser.
- [x] Existing Write/Edit Route Plan and Agent tasks.json gates remain unchanged and covered by the aggregate enforcement suite.
- [x] PR #246 runs all required GitHub Actions and records every correction loop on exact heads.
- [x] Merge remains disabled until exact-head checks, review threads, and explicit owner approval are all satisfied.

Exact-head green status remains an external merge gate and will be re-established after this review-finding correction.

## Connector Evidence

- GitHub: used to inspect canonical source, commit/PR history, branch state, Actions, comments, and review threads.

## Connector Usage Evidence

- source: GitHub
- action: inspected `yotamfried-ux/Engineering-OS` main files, PR #80, PR #244, PR #245, PR #246 Actions, CodeRabbit quota notice, and the live P2 review thread on `check-runtime-evidence.sh`
- result: implemented policy-aware telemetry preflight, current-session plan recording, Stop scoping, shared waiver semantics, and focused regression suites; accepted and corrected the valid review finding that waivers were previously Stop-only
- decision: kept all-tools telemetry coverage and fail-closed required mode, removed unconditional local-only lockout and stale historical plan inference, and made waiver enforcement consistent without broadening waiver scope
- target: `scripts/monitoring/require-telemetry-session.sh`, `scripts/enforcement/lib/evidence.sh`, `scripts/enforcement/pre-tool-use-runtime-evidence.sh`, `scripts/enforcement/check-runtime-evidence.sh`, `scripts/enforcement/tests/test-fresh-session-hook-scoping.sh`, `scripts/enforcement/tests/test-runtime-evidence.sh`, `scripts/enforcement/tests/test-stop-runtime-plan-scoping.sh`

## Capability Evidence

- `routing.task-router-read`: classified the change as Engineering OS governance.
- `workflow.workflow-read`: applied plan-first reproduce-fix-verify sequencing.
- `plan.route-plan-before-write`: commit `665234ffc44c68850fda1b1115944cc60904931d` created this plan before implementation.
- `source.github-repo-read`: inspected canonical GitHub source and the introducing PRs/commits.
- `validation.policy-change-has-validator`: added executable negative and positive regression cases, including write-time waiver coverage.
- `validation.coderabbit-policy`: CodeRabbit was quota-limited; a structured fallback review was documented, and a separate live P2 review finding was accepted and fixed.
- `validation.actions-checked`: exact-head Actions were green at `6eaae8bcfc6a92414e6d1eca191277bff216cf99` before the review correction; all required workflows must rerun on the new final head.

## Documentation Asset Evidence

- internal: `core/hooks-policy.md`, `core/connector-policy.md`, `core/debugging-policy.md`, `.claude/settings.json`, telemetry patcher, shared evidence library, and existing enforcement suites
- context7: not required; the defect is internal configuration/scoping drift, while PR #244 already validated official Claude hook exit semantics
- decision: restore mode-appropriate failure behavior, current-task scoping, and lifecycle-consistent waiver handling without changing the governing enforcement principles

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
10. Opened PR #246 and corrected two workflow-evidence diagnostics without changing implementation behavior.
11. Confirmed all exact-head code, telemetry, and policy workflows green at `6eaae8bcfc6a92414e6d1eca191277bff216cf99`; corrected PR review metadata separately.
12. Verified CodeRabbit did not run because of quota, documented the fallback review honestly, and inspected live review threads directly.
13. Accepted P2 thread `PRRT_kwDOS6Ejks6R6hn1`: Stop accepted a connector waiver that Write/Edit could not use.
14. Moved waiver parsing into `lib/evidence.sh`, wired both runtime gates to it, and added write-time negative/positive waiver fixtures through code head `7844d7d9e8063f5bba008fd7a0e11e73e0f9eab3`.
15. Recorded this new pre-merge checkpoint after the review-finding implementation and before the final exact-head CI rerun.

## Operational Work History Evidence

- automatic_sources: `.engineering-os/work-history/latest.json`
- selected_result_loop_contract: engineering-os-governance
- learning_loop_result: the live P2 review finding became a shared helper plus a permanent write-time regression fixture, preventing lifecycle divergence from recurring

## Progress Lifecycle Evidence

- start: reproduced both contradictions from canonical source and identified PR #80, PR #244, and PR #245 before implementation.
- mid: implemented mode-aware telemetry behavior, current-session plan recording, Stop scoping, connector waiver preservation, and focused regression fixtures.
- pre-merge: after the initial exact-head green run, inspected the live P2 thread, corrected waiver consistency in commits `5bca65754d297b34cca4e189eaafa105f4d9cdd1` through `7844d7d9e8063f5bba008fd7a0e11e73e0f9eab3`, and queued a complete exact-head validation loop before resolution or merge.
