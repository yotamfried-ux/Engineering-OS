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
| Architecture guides | `core/hooks-policy.md`; `docs/operations/remote-multirepo-telemetry-hooks.md`; `https://code.claude.com/docs/en/hooks` |
| Patterns | fail-before/pass-after fixture; control-plane action exemption inside the existing guard |
| External systems/connectors | GitHub; Claude Code documentation |
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
| `scripts/enforcement/tests/test-fresh-session-hook-scoping.sh` | read | covers ordinary tool names and valid fresh sessions but had no ExitPlanMode or missing-session control-plane fixture. |
| `https://code.claude.com/docs/en/hooks` | validated | `ExitPlanMode` is listed as a PreToolUse tool and exit 2 blocks the tool call before execution. |
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

- [x] Route Plan commit `1b1f85c019822fc1023bef7241e39af4acdc16cb` precedes both code and test changes.
- [x] The deterministic missing-session fixture represents the live plan-approval failure.
- [x] Exact `ExitPlanMode` input returns success before telemetry readiness checks.
- [x] `Bash` remains fail-closed with exit 2 under the identical unready-session fixture.
- [x] Malformed JSON and missing tool names remain on the existing fail-closed path.
- [x] Catch-all matcher, hook criticality, dispatcher wiring, telemetry schemas, and Project 8 remain unchanged.
- [x] First exact-head CI attempt was inspected by workflow name, run ID, job, and failure log rather than treated as a generic red status.

Merge readiness remains a separate live-state decision in PR #270; this implementation checklist does not claim owner approval, final exact-head CI, or merge.

## Connector Evidence

- GitHub: read `yotamfried-ux/Engineering-OS` main `a1af89941b085230b389cbc1c60984df1df8ae69`, PR #266 history, PR #270, canonical settings, guard, registry, tests, exact-head workflow runs, jobs, and logs.
- Claude Code documentation: read `https://code.claude.com/docs/en/hooks` to confirm the provider-defined PreToolUse lifecycle, exact `ExitPlanMode` tool name, and exit-2 deny semantics.

## Connector Usage Evidence

- source: GitHub supplied `yotamfried-ux/Engineering-OS` main `a1af89941b085230b389cbc1c60984df1df8ae69`, PR #266, PR #270, and exact-head run `30939157373`; Claude Code documentation supplied `https://code.claude.com/docs/en/hooks`.
- action: GitHub was used to trace `.claude/settings.json`, `scripts/enforcement/hook-criticality.tsv`, `scripts/monitoring/require-telemetry-session.sh`, and `scripts/enforcement/tests/test-fresh-session-hook-scoping.sh`; Claude Code documentation was used to verify that `ExitPlanMode` is a PreToolUse owner-approval tool whose call is blocked by exit 2.
- result: GitHub identified the catch-all `.*` hard guard and the missing regression at `scripts/enforcement/tests/test-fresh-session-hook-scoping.sh`, while Claude Code documentation identified `ExitPlanMode` as the blocked transition; together they locate the false positive in `scripts/monitoring/require-telemetry-session.sh` and PR #270.
- decision: kept the GitHub-verified catch-all matcher and hard criticality unchanged, then implemented the Claude Code documentation-derived exact `ExitPlanMode` exemption with a paired `Bash` denial fixture instead of weakening telemetry enforcement.
- target: `scripts/monitoring/require-telemetry-session.sh`; `scripts/enforcement/tests/test-fresh-session-hook-scoping.sh`.

## Documentation Asset Evidence

- internal: `core/hooks-policy.md`; `docs/operations/remote-multirepo-telemetry-hooks.md`; `.claude/settings.json`; `scripts/enforcement/hook-criticality.tsv`.
- context7: not required — the official vendor source `https://code.claude.com/docs/en/hooks` directly defines the relevant hook input and blocking behavior.
- decision: no new runbook is needed for a narrow regression repair; executable behavior and its fixture are the durable source.

## Capability Evidence

- `routing.task-router-read` — classified as Engineering OS hook governance.
- `workflow.workflow-read` — used reproduce/isolate/plan/change/rerun sequencing.
- `plan.route-plan-before-write` — this file precedes implementation.
- `source.github-repo-read` — current main and introducing PR history were verified.
- `validation.policy-change-has-validator` — paired positive and negative fixtures are required.
- `validation.coderabbit-policy` — review reconciliation remains required.
- `validation.actions-checked` — exact-head workflows are inspected before merge.

## Skill Evidence

- `writing-plans` — narrow scope and invariant are recorded before the fix.
- `verification-before-completion` — local, CI, review, approval, merge, and post-merge claims remain separate.

## Claude Run Trace

- goal: unblock owner plan approval without allowing uninstrumented execution.
- hypothesis: catch-all telemetry enforcement treats `ExitPlanMode` as execution even though it is a user control-plane transition.
- evidence: live UI failure; canonical matcher `.*`; guard exit 2; official tool lifecycle; missing regression coverage.
- minimal change: exact `ExitPlanMode` exemption in the existing guard plus paired fixture.
- rejected alternatives: weakening the matcher, making the guard soft, disabling telemetry, or changing Project 8.
- result: commits `d0d72e845fcd21c8295e5a3f95d5d60db4b79116` and `2f323acc1d97fc952ed2a714c64053dcf121ff5c` implement the exact exemption and paired fixture; isolated shell proof returned ExitPlanMode=0, Bash=2, malformed payload=2.
- next decision: the protected merge decision remains conditioned on terminal exact-head CI, review reconciliation, and explicit owner approval.

## Operational Work History Evidence

- automatic_sources: `.engineering-os/work-history/latest.json`
- selected_result_loop_contract: engineering-os-governance
- learning_loop_result: a live qualification failure is converted into a narrow regression rather than bypassing the telemetry gate.

## Progress Lifecycle Evidence

- start: reproduced the semantic conflict from current main and official hook semantics before any code/test write.
- mid: after plan commit `1b1f85c019822fc1023bef7241e39af4acdc16cb`, implemented the exact parsed `ExitPlanMode` exemption in `d0d72e845fcd21c8295e5a3f95d5d60db4b79116` and the paired unready-session fixture in `2f323acc1d97fc952ed2a714c64053dcf121ff5c`; `bash -n` passed for both scripts and an isolated guard smoke measured ExitPlanMode=0, Bash=2, malformed payload=2.
- pre-merge: PR #270 exact head `4a9b152766a57bf74ba8d0d73bb826ca9197dfca` produced successful semantic-cleanup-policy run `30939157045`, import-cleanup-policy run `30939157144`, capability-evidence-policy run `30939158082`, and telemetry-handoff-tests run `30939157637`; the same attempt exposed evidence corrections through workflow-evidence-policy `30939157373`, documentation-asset-policy `30939157227`, connector-evidence-policy `30939157380`, and plan-policy `30939157201`. Their job logs were read and this post-code checkpoint records the concrete corrections without changing runtime code or any gap status.
