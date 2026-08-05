# Route Plan — Reject non-regular hook wrappers instead of invoking them

## Route Plan

| Field | Decision |
|---|---|
| Task type | fail-closed hook wiring defect found in live review |
| Task class | `engineering_os_governance` |
| Domain tags | hook wiring, fail-closed enforcement, wrapper bootstrap, rendered settings |
| Plan Scope | focused |
| Planning Mode | implementation; tighten the existing bootstrap test rather than adding a new mechanism |
| Task-router evidence | `core/task-router.md` routes Engineering OS enforcement/hooks governance through `ops-readiness`. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, `core/hooks-policy.md`, `core/coderabbit-policy.md` require plan-first writes, focused PR, exact-head CI, review, explicit owner approval, expected-head merge, post-merge proof. |
| Target paths | `.claude/plans/reject-non-regular-hook-wrappers.md`; `.claude/settings.json`; `scripts/monitoring/patch-settings-telemetry.py`; `scripts/enforcement/patch-settings-runtime-evidence.sh`; `scripts/enforcement/tests/test-hook-home-resolution.sh`; `scripts/monitoring/telemetry_hook_match.py`; `lessons-learned/bugs/guard-precondition-weaker-than-the-operation.md` |
| Templates | waiver — focused change to two existing renderers and their regressions |
| Architecture guides | `core/hooks-policy.md`; `docs/operations/project8-telemetry-preflight.md` |
| Patterns | none — no new implementation pattern is introduced |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion` |
| Validation gates | hook home resolution; hard hook fail-closed; hook gate; hook boundary parity; user-level installer; full enforcement; PR policy; exact-head CI; review |
| Evidence to check | `[ -r <dir> ]` is true while `[ -f <dir> ]` is false; `bash <dir>` exits 126; 126 is non-blocking at PreToolUse |
| User decisions required | owner approval before merge; owner approved closing the remaining blockers end to end (2026-08-04) |

## Goal

PR #271 made an **unresolvable** Engineering OS home deny. Live review on the downstream
project-8 PR found that a **resolvable but malformed** one still fails open: the bootstrap
tests only whether the wrapper is readable, and a directory is readable.

Intended outcome: every rendered hook command refuses to run a wrapper that is not a regular
readable file, so the whole "wrapper unusable" class denies rather than only the
"wrapper absent" case.

## Scope

In scope: the wrapper existence test in both renderers, for both the hard and the soft form,
plus regressions that execute the malformed shapes.

Out of scope: the units themselves, the hook registry, `check-hard-hook-contract.py`
(its assertion is `"exit 2" in command`, which this change preserves), and any gap status
move.

## Claude Run Trace

- Live review on `yotamfried-ux/project-8#10` raised the non-regular wrapper case; two
  independent reviewers converged on the same defect class.
- The claim was measured before acting rather than accepted: `[ -r <dir> ]` is true,
  `[ -f <dir> ]` is false, and `bash <dir>` exits 126 with `Is a directory`.
- Per the Claude Code PreToolUse contract only exit 2 denies, so 126 is non-blocking — the
  same fail-open outcome PR #271 closed for exit 127, reached by a different route.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `scripts/monitoring/patch-settings-telemetry.py` | read | The hard bootstrap (`:123`) and the soft guard (`:129`) both test `[ -r "$WRAPPER" ]`. Readability alone does not imply the path can be executed as a script, so both admit a directory or other non-regular node. |
| `scripts/enforcement/patch-settings-runtime-evidence.sh` | read | Renders the same two shapes (`:22`, `:31`) for the runtime-evidence hooks, so fixing only the telemetry renderer would leave half the surface fail-open. |
| `scripts/enforcement/check-hard-hook-contract.py` | read | Asserts `"exit 2" in command` (`:191`) and the wrapper tokens (`:192-194`); it does not pin the exact test expression, so tightening the condition does not require a contract change. |
| `scripts/enforcement/tests/test-hook-boundary-parity.sh` | read | Contains the soft command text at `:309`, but re-read during implementation: that fixture *constructs* a deliberately soft-gated terminal boundary to check the contract rejects it, so it does not pin renderer output and needs no change. It does verify the checked-in `.claude/settings.json` against the canonical manifest (`:107`), which is the part this change has to keep consistent. |
| Measured directly | run | `[ -r <dir> ]` true, `[ -f <dir> ]` false, `bash <dir>` exit **126** with `Is a directory` — so the fail-open path is real and reproducible, not theoretical. |

## Design

Change the existence test from "readable" to "regular **and** readable" in both renderers and
both forms. `[ -f ]` follows symlinks and tests the target, so a symlink to a real script
still works while a symlink to a directory does not — which is the behaviour wanted here.

The hard form keeps its `exit 2`; the soft form keeps its warning and `exit 0`, because a soft
hook that started denying would change criticality, which the registry owns.

Rejected: mapping any nonzero wrapper-launch status to 2 in the command itself. It would also
swallow the wrapper's own deliberate statuses, so a real bug inside `hook-gate.sh` would be
reported as a denial rather than surfacing.

## Capability Evidence

- `routing.task-router-read` — routed as Engineering OS enforcement/hooks governance.
- `workflow.workflow-read` — plan-first write, then implementation, tests, CI, review, approval, merge, post-merge.
- `plan.route-plan-before-write` — this plan is committed before the first code change.
- `source.github-repo-read` — live `origin/main` at `4290481` re-read before any claim.
- `validation.policy-change-has-validator` — the new deny path gets an executing regression, not a static assertion.
- `validation.coderabbit-policy` — PR review required before merge.

## Skill Evidence

- `writing-plans` — scope, reuse decision, rejected alternative and non-goals recorded.
- `verification-before-completion` — implementation, focused tests, full suite, exact-head CI, review, approval, merge and post-merge remain separate assertions.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Re-read `origin/main` at `4290481` and both renderers before planning; the finding itself came from live review on `yotamfried-ux/project-8#10`. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS` `main` at `429048199345d5b4836c32626d0094116e5b4c25`, plus live review on `yotamfried-ux/project-8#10`.
- action: measured the reported shell behaviour directly before accepting the finding, then searched for every renderer that emits the same bootstrap shape rather than fixing only the file the review pointed at.
- result: measured against `origin/main` at `429048199345d5b4836c32626d0094116e5b4c25` — `[ -r <dir> ]` is true, `[ -f <dir> ]` is false, and `bash <dir>` exits 126. The readable-only test appears at `scripts/monitoring/patch-settings-telemetry.py:123` and `:129` and at `scripts/enforcement/patch-settings-runtime-evidence.sh:22` and `:31` — four places in two renderers, not the single site raised on `yotamfried-ux/project-8#10`.
- decision: changed all four sites rather than only the one review raised, added an executing regression for the malformed-wrapper case in both forms, and kept the checked-in `.claude/settings.json` hook set intact by normalising the two bootstrap expressions in place instead of regenerating it — regeneration was measured to add four hooks the file does not carry, so it was blocked and reverted.
- target: `scripts/monitoring/patch-settings-telemetry.py`; `scripts/enforcement/patch-settings-runtime-evidence.sh`; `scripts/enforcement/tests/test-hook-home-resolution.sh`.

## Documentation Asset Evidence

- internal: `core/hooks-policy.md`; `docs/operations/project8-telemetry-preflight.md`; `scripts/enforcement/lib/hook-gate.sh`.
- context7: no new external documentation asset was required, and the Context7 connector was not used. The governing external source is the Claude Code hooks reference at https://docs.claude.com/en/docs/claude-code/hooks — specifically its PreToolUse exit-code contract, where only exit 2 denies — and it is already cited in `docs/operations/project8-telemetry-preflight.md`. The behaviour this change turns on is a POSIX shell property (`test -r` versus `test -f`) measured directly in this repository rather than looked up.
- decision: reused the existing hooks policy and preflight runbook; this change enforces a contract already written there.

## Progress Lifecycle Evidence

- start: Route Plan committed before the first code change. Measured on `main` at `4290481`: `[ -r <dir> ]` true, `[ -f <dir> ]` false, `bash <dir>` exit 126; the readable-only test appears at `patch-settings-telemetry.py:123` and `:129` and at `patch-settings-runtime-evidence.sh:22` and `:31`.
- mid: updated after implementation with the before-and-after measurement this entry did not previously carry. The shipped change is `[ -r "$W" ]` → `[ -f "$W" ] && [ -r "$W" ]` at four sites — `scripts/monitoring/patch-settings-telemetry.py:123` and `:129`, `scripts/enforcement/patch-settings-runtime-evidence.sh:22` and `:31`. Before-and-after against one fixture, one environment: hard **126 → 2**, soft **126 → 0**. `scripts/enforcement/tests/test-hook-home-resolution.sh` went from 6 assertions to 8, and the full enforcement run went from 112 suites at the start of this work to 113 with 0 failures. Original mid note, kept because its measurements still hold: tightened both forms in both renderers and measured the result in the same environment against a wrapper path that is a readable directory. Pre-change: hard exits **126**, soft exits **126** because it also invokes bash. Post-change: hard exits **2** with `ERROR_FOR_AGENT`, soft exits **0** with `WARNING_FOR_AGENT` and never invokes the directory, so the soft form keeps its criticality instead of becoming a hard failure. The new regression asserts its own premise first — the fixture must satisfy `[ -r ]` and fail `[ -f ]` — so it cannot pass against a fixture that does not reproduce the reported shape. Two corrections to this plan, recorded rather than silently applied. First, the plan predicted `test-hook-boundary-parity.sh:309` would need updating in lockstep; measured, that fixture constructs a deliberately bad command to check the contract rejects it and does not pin renderer output, so it needed no change. Second, the plan did not anticipate that the repository's own checked-in `.claude/settings.json` carries the rendered form and would be reported as drift by the parity suite. Re-running `patch-settings-runtime-evidence.sh` to regenerate it added four hooks that the checked-in file does not carry, so that was reverted and the two bootstrap expressions were normalised in place instead: 28 commands rewritten, hook count unchanged at 38, diff exactly 28 insertions and 28 deletions.
- pre-merge: verified after the last code change. Full enforcement suite 113 suites, 0 failures; `shellcheck` clean on both changed shell files. `test-hook-home-resolution.sh` now carries 8 assertions, the two new ones executing the malformed-wrapper shape rather than inspecting rendered text, and both return 126 against the pre-change form, so neither is vacuous. The six focused suites — home resolution, hard-hook fail-closed, hook gate, boundary parity, user-level installer, install-policy-gate coverage — all pass. The boundary-parity suite initially failed because the repository's own checked-in settings still carried the old form; normalising the two bootstrap expressions in place rewrote 28 commands with the hook count unchanged at 38, and the suite passes. The failure class is recorded as a lesson with its regression named, since a guard whose precondition is weaker than the operation it protects is a class rather than a one-off.
- outstanding external gates: exact-head CI, live review reconciliation, explicit owner approval, expected-head protected merge, and post-merge validation. No gap status changes before all of those complete. The downstream project-8 PR stays open until this lands, because its own re-render depends on the corrected renderer.

## Definition of Done — Implementation

- [x] A rendered hard command whose wrapper path is a readable directory denies with exit 2 instead of exiting 126 — measured both before and after.
- [x] A rendered soft command in the same situation emits its warning and exits 0 rather than invoking bash, preserving its criticality — pre-change it exited 126.
- [x] Both renderers are fixed, not only the one review pointed at — `patch-settings-telemetry.py` and `patch-settings-runtime-evidence.sh`, hard and soft in each.
- [x] The regression executes the malformed shape rather than inspecting the rendered text, and is proven non-vacuous against the pre-change form — both new cases return 126 there, where they require 2 and 0.
- [x] The verification signal is the suite `scripts/enforcement/tests/test-hook-home-resolution.sh` (8 assertions), run together with the checker `scripts/enforcement/check-hard-hook-contract.py` through the `test-hook-boundary-parity.sh` gate and the full 113-suite enforcement CI job.

## Validation Plan

- Focused: `test-hook-home-resolution.sh`, `test-hard-hook-fail-closed.sh`, `test-hook-gate.sh`, `test-hook-boundary-parity.sh`, `test-user-level-telemetry-installer.sh`, `test-install-policy-gate-coverage.sh`.
- Full: the complete enforcement suite.
- External: exact-head CI, live review, owner approval, expected-head merge, post-merge validation.
