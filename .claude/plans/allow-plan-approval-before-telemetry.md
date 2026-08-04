# Route Plan — Allow plan approval before telemetry readiness

## Route Plan

| Field | Decision |
|---|---|
| Task type | telemetry hook regression repair |
| Task class | `engineering_os_governance` |
| Domain tags | telemetry, hooks, plan mode, fail-closed enforcement, UX |
| Plan Scope | focused |
| Planning Mode | implementation; preserve fail-closed execution while excluding a non-executing control-plane action and preserving manual preflight behavior |
| Task-router evidence | `core/task-router.md` routes hook and telemetry enforcement changes through Engineering OS governance. |
| Workflow evidence | `core/workflow.md` and `core/hooks-policy.md` require reproduce, isolate, plan before write, minimal fix, focused tests, exact-head CI, review, explicit owner approval, expected-head merge, and post-merge proof. |
| Target paths | `.claude/plans/allow-plan-approval-before-telemetry.md`; `scripts/monitoring/require-telemetry-session.sh`; `scripts/enforcement/tests/test-fresh-session-hook-scoping.sh` |
| Templates | waiver — focused repair to existing hook and existing regression suite |
| Architecture guides | `core/hooks-policy.md`; `docs/operations/remote-multirepo-telemetry-hooks.md`; `https://code.claude.com/docs/en/hooks` |
| Patterns | fail-before/pass-after fixture; exact control-plane exemption; canonical hard-wrapper assertion; PTY timeout regression for the direct CLI path |
| External systems/connectors | GitHub; Claude Code documentation |
| Skills | `writing-plans`; `verification-before-completion` |
| Validation gates | focused fresh-session hook suite; shell syntax; full enforcement; exact-head PR workflows; review reconciliation |
| Evidence to check | `PreToolUse` matcher is `.*`; `ExitPlanMode` is a documented PreToolUse tool; `hook-gate.sh` forwards input and preserves allow/deny semantics; direct interactive preflight does not wait for terminal EOF |
| User decisions required | explicit owner approval before merge; no gap closure and no behavioral experiment start in this PR |

## Goal

Permit the user to approve a generated plan even when the current Claude session does not yet satisfy the telemetry preflight, while preserving fail-closed denial for every tool that can read, write, execute, delegate, or access an external system. Preserve the documented direct/manual telemetry preflight path without making it wait for stdin EOF, and prove behavior through the same hard wrapper rendered by settings.

## Reproduction

The checked-in and installed hook surfaces apply `scripts/monitoring/require-telemetry-session.sh` under catch-all `PreToolUse` matching. Claude Code documents `ExitPlanMode` as a PreToolUse tool. When the current session lacks a valid SessionStart or required handoff state, the guard exits 2, so Claude can render a plan but the UI reports `Failed to approve plan` when the owner approves it.

The first implementation read stdin unconditionally to classify the tool. Codex review comment `3715220343` and CodeRabbit review comment `3715233434` independently identified that an interactive direct invocation has a TTY stdin and therefore waits for EOF before running any readiness checks. CodeRabbit comment `3715233431` also identified that direct unit tests alone do not prove the production path because `.claude/settings.json` invokes the unit through `scripts/enforcement/lib/hook-gate.sh`, which validates and forwards stdin and converts exit 2 into structured deny JSON.

These are scope defects, not evidence that plan generation or fail-closed telemetry enforcement should be removed. Approval is a human control-plane transition; direct preflight has no hook payload; the first operational tool after approval must still be denied until telemetry is ready.

## Scope

In scope:

- detect the exact `ExitPlanMode` PreToolUse payload in the existing telemetry guard;
- allow only that control-plane action to pass before telemetry readiness;
- read a hook payload only when stdin is not a TTY;
- prove direct interactive preflight exits through existing fail-closed logic without waiting for EOF;
- prove direct and wrapped Bash behavior remains denied under the same missing-session condition;
- prove the canonical hard wrapper forwards `ExitPlanMode` and emits structured deny JSON for Bash;
- preserve all existing fresh-session and required-handoff behavior.

Out of scope:

- weakening the catch-all matcher;
- exempting Bash, file, Agent, MCP, Web, or repository tools;
- changing telemetry schemas, attribution, bundle validation, archive import, or Project 8;
- closing any canonical gap;
- starting the behavioral experiment.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `.claude/settings.json` | read | catch-all PreToolUse invokes the hard telemetry guard through `scripts/enforcement/lib/hook-gate.sh`. |
| `scripts/enforcement/hook-criticality.tsv` | read | `require-telemetry-session.sh` is canonically hard/fail-closed under matcher `.*`; keep this ownership and classification. |
| `scripts/enforcement/lib/hook-gate.sh` | read | validates PreToolUse JSON, forwards the saved input file to the unit, returns empty success for allow, and converts unit exit 2 into structured `permissionDecision: deny`. |
| `scripts/monitoring/require-telemetry-session.sh` | read | the original guard validated telemetry before tool classification; the first fix then read stdin unconditionally and regressed the manual path. |
| `scripts/enforcement/tests/test-fresh-session-hook-scoping.sh` | read | previous coverage did not distinguish direct, hard-wrapper, and PTY invocation surfaces. |
| `https://code.claude.com/docs/en/hooks` | validated | `ExitPlanMode` is listed as a PreToolUse tool and deny output blocks the tool call before execution. |
| PR #270 review comment `3715220343` | accepted | direct interactive invocation can hang because unconditional `cat` waits for TTY EOF. |
| PR #270 review comment `3715233431` | accepted | the regression must be exercised through the canonical hard wrapper, not only the unit. |
| PR #270 review comment `3715233434` | accepted | payload input must be read only when stdin is not a TTY. |
| screenshot from the live qualification attempt | observed | plan text rendered successfully, then owner approval returned `Failed to approve plan`. |

## Design

1. Initialize an empty hook payload and read stdin only when `test -t 0` reports that stdin is not a terminal.
2. Parse `tool_name` only from that bounded non-TTY payload; malformed JSON and absent payload produce no exemption.
3. If and only if parsed `tool_name` is exactly `ExitPlanMode`, exit 0 before telemetry readiness checks.
4. Treat missing tool names and every other tool exactly as today; no permissive fallback.
5. Keep the catch-all hard hook in `hook-criticality.tsv` and every rendered settings surface. The exception belongs in the canonical unit because all surfaces must share the same semantics.
6. Extend `test-fresh-session-hook-scoping.sh` with paired direct unready-session fixtures and a PTY child whose master remains open: direct preflight must exit 2 within three seconds rather than wait for EOF.
7. Exercise `hook-gate.sh --event PreToolUse --matcher '.*' --unit require-telemetry-session.sh` with real hook JSON: `ExitPlanMode` must produce empty allow output, while Bash must produce valid structured deny JSON containing the telemetry diagnostic.

## Validation

Focused:

- `bash -n scripts/monitoring/require-telemetry-session.sh`
- `bash -n scripts/enforcement/tests/test-fresh-session-hook-scoping.sh`
- `bash scripts/enforcement/tests/test-fresh-session-hook-scoping.sh`

Broader:

- full enforcement suite;
- exact-head GitHub Actions on the PR;
- review reconciliation with zero unresolved actionable threads.

## Definition of Done

- [x] Route Plan commit `1b1f85c019822fc1023bef7241e39af4acdc16cb` precedes the original code and test changes.
- [x] The deterministic missing-session fixture represents the live plan-approval failure.
- [x] Exact `ExitPlanMode` input returns success before telemetry readiness checks.
- [x] Direct `Bash` remains fail-closed with exit 2 under the identical unready-session fixture.
- [x] The canonical hard wrapper produces no deny output for `ExitPlanMode` and structured deny JSON for Bash.
- [x] Malformed JSON and missing tool names remain on the existing fail-closed path.
- [x] Direct TTY input is not consumed, preserving manual preflight behavior.
- [x] A PTY timeout fixture fails the old unconditional-read behavior and requires exit 2 from existing fail-closed logic.
- [x] Catch-all matcher, hook criticality, dispatcher wiring, telemetry schemas, and Project 8 remain unchanged.
- [x] Every observed CI and review failure was inspected by concrete run, job, or review-comment identifier before correction.

Merge readiness remains a separate live-state decision in PR #270; this implementation checklist does not claim owner approval, final exact-head CI, qualification closure, or merge.

## Connector Evidence

- GitHub: read `yotamfried-ux/Engineering-OS` main `a1af89941b085230b389cbc1c60984df1df8ae69`, PR #266 history, PR #270, canonical settings, wrapper, guard, registry, tests, exact-head workflow runs, jobs, logs, and review threads.
- Claude Code documentation: read `https://code.claude.com/docs/en/hooks` to confirm the provider-defined PreToolUse lifecycle, exact `ExitPlanMode` tool name, and deny semantics.

## Connector Usage Evidence

- source: GitHub supplied `yotamfried-ux/Engineering-OS` main `a1af89941b085230b389cbc1c60984df1df8ae69`, PR #266, PR #270, exact-head workflow run `30939157373`, Codex review comment `3715220343`, and CodeRabbit review comments `3715233431` and `3715233434`; Claude Code documentation supplied `https://code.claude.com/docs/en/hooks`.
- action: GitHub was used to trace `.claude/settings.json`, `scripts/enforcement/hook-criticality.tsv`, `scripts/enforcement/lib/hook-gate.sh`, `scripts/monitoring/require-telemetry-session.sh`, `scripts/enforcement/tests/test-fresh-session-hook-scoping.sh`, and the independent review findings; Claude Code documentation was used to verify that `ExitPlanMode` is a PreToolUse owner-approval tool whose call can be blocked before execution.
- result: GitHub identified the catch-all `.*` false positive, the unconditional-stdin regression, and the missing wrapper-level proof; Claude Code documentation established the exact provider-controlled transition. Together they require non-TTY payload parsing, an exact `ExitPlanMode` exemption, direct PTY coverage, and canonical wrapper assertions in PR #270.
- decision: kept the GitHub-verified catch-all matcher, wrapper, and hard criticality unchanged; accepted all three review findings; and added evidence at the unit, wrapper, and interactive boundaries instead of weakening telemetry enforcement.
- target: `scripts/monitoring/require-telemetry-session.sh`; `scripts/enforcement/tests/test-fresh-session-hook-scoping.sh`.

## Documentation Asset Evidence

- internal: `core/hooks-policy.md`; `docs/operations/remote-multirepo-telemetry-hooks.md`; `.claude/settings.json`; `scripts/enforcement/lib/hook-gate.sh`; `scripts/enforcement/hook-criticality.tsv`.
- context7: official vendor documentation at `https://code.claude.com/docs/en/hooks` was selected directly because this task depends on Claude Code provider hook semantics rather than a third-party library API.
- decision: internal hook policy preserves fail-closed coverage, the vendor lifecycle permits the exact approval transition, and the production wrapper requires explicit wrapper-level regression evidence; no parallel runbook or hook owner is introduced.

## Capability Evidence

- `routing.task-router-read` — classified as Engineering OS hook governance.
- `workflow.workflow-read` — used reproduce/isolate/plan/change/rerun sequencing.
- `plan.route-plan-before-write` — this file preceded the original implementation and records the post-review correction after the final code/test write.
- `source.github-repo-read` — current main, introducing PR history, CI, and review threads were verified.
- `validation.policy-change-has-validator` — paired direct, wrapper, malformed-input, and PTY fixtures are required.
- `validation.coderabbit-policy` — review reconciliation remains required.
- `validation.actions-checked` — exact-head workflows are inspected before merge.

## Skill Evidence

- `writing-plans` — narrow scope and invariant were recorded before implementation, then updated from real review evidence.
- `verification-before-completion` — focused, CI, review, approval, merge, and post-merge claims remain separate.

## Claude Run Trace

- goal: unblock owner plan approval without allowing uninstrumented execution, breaking direct preflight, or bypassing the production hard wrapper.
- hypothesis: catch-all telemetry enforcement treats `ExitPlanMode` as execution; the first classification fix assumes every invocation carries hook JSON on stdin; direct-only tests do not prove wrapper semantics.
- evidence: live UI failure; canonical matcher `.*`; guard exit 2; official tool lifecycle; Codex comment `3715220343`; CodeRabbit comments `3715233431` and `3715233434`; missing PTY and wrapper coverage.
- minimal change: exact `ExitPlanMode` exemption, non-TTY-only payload read, paired direct execution denial, hard-wrapper structured-output assertions, and PTY timeout regression in the existing owner and suite.
- rejected alternatives: weakening the matcher, making the guard soft, disabling telemetry, exempting manual calls from readiness, bypassing `hook-gate.sh`, or changing Project 8.
- result: original commits `d0d72e845fcd21c8295e5a3f95d5d60db4b79116` and `2f323acc1d97fc952ed2a714c64053dcf121ff5c` established the exact exemption; review-driven commits `b029224fa9cd6dd1e5e4c753604c10e93b668b68` and `fdb4547eece26ab217a49f1633173049eefa775d` preserve manual TTY behavior and add PTY coverage; commit `2ada5948cdbc24cc015b1146723a022a2240e222` adds canonical wrapper allow/deny assertions without changing wrapper code.
- next decision: the protected merge remains disallowed until the new exact head has terminal CI, all actionable review threads are reconciled, and the owner explicitly approves that exact head.

## Operational Work History Evidence

- automatic_sources: `.engineering-os/work-history/latest.json`
- selected_result_loop_contract: engineering-os-governance
- learning_loop_result: a live qualification false positive became a paired regression, and independent review converted interactive-path and wrapper-path blind spots into deterministic fixtures before merge.

## Progress Lifecycle Evidence

- start: reproduced the semantic conflict from current main and official hook semantics before any code/test write.
- mid: after plan commit `1b1f85c019822fc1023bef7241e39af4acdc16cb`, implemented the exact parsed `ExitPlanMode` exemption in `d0d72e845fcd21c8295e5a3f95d5d60db4b79116` and the paired unready-session fixture in `2f323acc1d97fc952ed2a714c64053dcf121ff5c`; an isolated guard smoke measured ExitPlanMode=0, Bash=2, and malformed payload=2.
- pre-merge: PR #270 review comments `3715220343`, `3715233431`, and `3715233434` found interactive-EOF and wrapper-coverage blind spots after the original implementation. Commit `b029224fa9cd6dd1e5e4c753604c10e93b668b68` reads only non-TTY hook input; `fdb4547eece26ab217a49f1633173049eefa775d` adds the PTY timeout; `2ada5948cdbc24cc015b1146723a022a2240e222` exercises the production `hook-gate.sh` path and validates empty allow output for ExitPlanMode plus structured telemetry denial for Bash. This post-test checkpoint precedes a fresh exact-head CI attempt; older successful runs remain historical evidence only.
