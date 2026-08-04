# Route Plan — Allow plan approval before telemetry readiness

## Route Plan

| Field | Decision |
|---|---|
| Task type | telemetry hook regression repair |
| Task class | `engineering_os_governance` |
| Domain tags | telemetry, hooks, plan mode, fail-closed enforcement, UX |
| Plan Scope | focused |
| Planning Mode | implementation; preserve fail-closed execution while excluding a non-executing control-plane action |
| Task-router evidence | `core/task-router.md` routes hook and telemetry enforcement changes through Engineering OS governance. |
| Workflow evidence | `core/workflow.md` and `core/hooks-policy.md` require reproduce, isolate, plan before write, minimal fix, focused tests, exact-head CI, review, explicit owner approval, expected-head merge, and post-merge proof. |
| Target paths | `.claude/plans/allow-plan-approval-before-telemetry.md`; `scripts/monitoring/require-telemetry-session.sh`; `scripts/enforcement/tests/test-fresh-session-hook-scoping.sh` |
| Templates | waiver — focused repair to existing hook and existing regression suite |
| Architecture guides | `core/hooks-policy.md`; `docs/operations/remote-multirepo-telemetry-hooks.md`; official Claude Code hooks reference |
| Patterns | fail-before/pass-after fixture; control-plane action exemption inside the existing guard |
| External systems/connectors | GitHub; official Claude Code documentation |
| Skills | `writing-plans`; `verification-before-completion` |
| Validation gates | focused fresh-session hook suite; shell syntax; full enforcement; exact-head PR workflows; review reconciliation |
| Evidence to check | `PreToolUse` matcher is `.*`; `ExitPlanMode` is a documented PreToolUse tool; `require-telemetry-session.sh` exits 2 before plan approval when SessionStart or handoff state is absent; execution tools must remain blocked in the same state |
| User decisions required | explicit owner approval before merge; no gap closure and no behavioral experiment start in this PR |

## Goal

Permit the user to approve a generated plan even when the current Claude session does not yet satisfy the telemetry preflight, while preserving fail-closed denial for every tool that can read, write, execute, delegate, or access an external system.

## Reproduction

The checked-in and installed hook surfaces apply `scripts/monitoring/require-telemetry-session.sh` under catch-all `PreToolUse` matching. Claude Code documents `ExitPlanMode` as a PreToolUse tool. When the current session lacks a valid SessionStart or required handoff state, the guard exits 2, so Claude can render a plan but the UI reports `Failed to approve plan` when the owner approves it.

This is a scope defect, not evidence that plan generation failed. Approval is a human control-plane transition; it does not execute the plan or mutate the repository. The first operational tool after approval must still be denied until telemetry is ready.

## Scope

In scope:

- detect the exact `ExitPlanMode` PreToolUse payload in the existing telemetry guard;
- allow only that control-plane action to pass before telemetry readiness;
- add a negative fixture proving Bash remains blocked under the same missing-session condition;
- add a positive fixture proving ExitPlanMode is not blocked;
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
| `.claude/settings.json` | read | catch-all PreToolUse invokes the hard telemetry guard for every tool. |
| `scripts/enforcement/hook-criticality.tsv` | read | `require-telemetry-session.sh` is canonically hard/fail-closed under matcher `.*`; keep this ownership and classification. |
| `scripts/monitoring/require-telemetry-session.sh` | read | the script validates telemetry before considering tool semantics and therefore blocks ExitPlanMode. |
| `scripts/enforcement/tests/test-fresh-session-hook-scoping.sh` | read | covers ordinary tool names and valid fresh sessions but has no ExitPlanMode or missing-session control-plane fixture. |
| Claude Code hooks reference | validated | `ExitPlanMode` is a PreToolUse tool that presents the plan for owner approval; exit 2 blocks the tool call. |
| screenshot from the live qualification attempt | observed | plan text rendered successfully, then owner approval returned `Failed to approve plan`. |

## Design

1. Read the hook payload once at the start of `require-telemetry-session.sh` without making valid direct/manual invocations dependent on stdin.
2. If and only if parsed `tool_name` is exactly `ExitPlanMode`, exit 0 before telemetry readiness checks.
3. Treat malformed JSON, missing tool names, and every other tool exactly as today; no permissive fallback.
4. Keep the catch-all hard hook in `hook-criticality.tsv` and every rendered settings surface. The exception belongs in the canonical unit because all surfaces must share the same semantics.
5. Extend `test-fresh-session-hook-scoping.sh` with a missing-session fixture: ExitPlanMode passes, Bash exits 2.

## Validation

Focused:

- `bash -n scripts/monitoring/require-telemetry-session.sh`
- `bash scripts/enforcement/tests/test-fresh-session-hook-scoping.sh`

Broader:

- full enforcement suite;
- exact-head GitHub Actions on the PR;
- review reconciliation with zero unresolved actionable threads.

## Definition of Done

- [ ] Route Plan committed before code or test changes.
- [ ] Live failure is represented by a deterministic missing-session fixture.
- [ ] ExitPlanMode passes without a telemetry run.
- [ ] Bash remains fail-closed without a telemetry run.
- [ ] Valid fresh-session behavior remains green.
- [ ] Required-mode durable handoff failure remains blocked.
- [ ] Focused and full suites pass.
- [ ] Exact-head CI is terminal and green.
- [ ] Review findings are reconciled.
- [ ] Owner approval is requested before merge.

## Connector Evidence

- GitHub: read current `main`, PR #266 history, canonical settings, guard, registry, and tests.
- Official Claude Code documentation: confirmed PreToolUse semantics and `ExitPlanMode` input/deny behavior.

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS` at `a1af89941b085230b389cbc1c60984df1df8ae69`, plus the official Claude Code hooks reference.
- action: traced the catch-all matcher to `require-telemetry-session.sh`, compared its exit-2 behavior with the documented `ExitPlanMode` PreToolUse lifecycle, and checked the existing fresh-session fixtures.
- result: the hard hook correctly blocks operational tools but also blocks the owner-only plan approval transition; no existing fixture distinguishes those two classes.
- decision: keep fail-closed catch-all wiring and add one exact control-plane exemption inside the canonical guard, with a paired fixture proving Bash remains denied.
- target: `scripts/monitoring/require-telemetry-session.sh`; `scripts/enforcement/tests/test-fresh-session-hook-scoping.sh`.

## Documentation Asset Evidence

- internal: `core/hooks-policy.md`; `docs/operations/remote-multirepo-telemetry-hooks.md`; `.claude/settings.json`; `scripts/enforcement/hook-criticality.tsv`.
- context7: official vendor documentation was accessed directly instead; it establishes that `ExitPlanMode` is a PreToolUse user-approval tool.
- decision: no new runbook is needed for a narrow regression repair; executable behavior and its fixture are the durable source.

## Capability Evidence

- `routing.task-router-read` — classified as Engineering OS hook governance.
- `workflow.workflow-read` — used reproduce/isolate/plan/change/rerun sequencing.
- `plan.route-plan-before-write` — this file precedes implementation.
- `source.github-repo-read` — current main and introducing PR history were verified.
- `validation.policy-change-has-validator` — paired positive and negative fixtures are required.
- `validation.coderabbit-policy` — review reconciliation remains required.
- `validation.actions-checked` — exact-head workflows will be inspected before merge.

## Skill Evidence

- `writing-plans` — narrow scope and invariant are recorded before the fix.
- `verification-before-completion` — local, CI, review, approval, merge, and post-merge claims remain separate.

## Claude Run Trace

- goal: unblock owner plan approval without allowing uninstrumented execution.
- hypothesis: catch-all telemetry enforcement treats `ExitPlanMode` as execution even though it is a user control-plane transition.
- evidence: live UI failure; canonical matcher `.*`; guard exit 2; official tool lifecycle; missing regression coverage.
- minimal change: exact `ExitPlanMode` exemption in the existing guard plus paired fixture.
- rejected alternatives: weakening the matcher, making the guard soft, disabling telemetry, or changing Project 8.
- next decision: merge only after exact-head CI, review, and explicit owner approval.

## Operational Work History Evidence

- automatic_sources: `.engineering-os/work-history/latest.json`
- selected_result_loop_contract: engineering-os-governance
- learning_loop_result: a live qualification failure is converted into a narrow regression rather than bypassing the telemetry gate.

## Progress Lifecycle Evidence

- start: reproduced the semantic conflict from current main and official hook semantics before any code/test write.
- mid: pending implementation and focused test result.
- pre-merge: pending final exact-head verification and review reconciliation.
