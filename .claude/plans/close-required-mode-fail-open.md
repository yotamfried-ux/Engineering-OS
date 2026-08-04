# Route Plan — Make required telemetry mode fail closed

## Route Plan

| Field | Decision |
|---|---|
| Task type | fail-closed hook wiring defect |
| Task class | `engineering_os_governance` |
| Domain tags | hook wiring, fail-closed enforcement, telemetry required mode, project surface |
| Plan Scope | focused |
| Planning Mode | implementation; reuse the existing renderer and hard gate rather than adding a new mechanism |
| Task-router evidence | `core/task-router.md` routes Engineering OS enforcement/hooks governance through `ops-readiness`. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, `core/hooks-policy.md`, `core/coderabbit-policy.md` require plan-first writes, focused PR, exact-head CI, review, explicit owner approval, expected-head merge, post-merge proof. |
| Target paths | `.claude/plans/close-required-mode-fail-open.md`; `scripts/install-policy-gates.sh`; `scripts/enforcement/check-hard-hook-contract.py`; `scripts/enforcement/tests/test-hook-home-resolution.sh` |
| Templates | waiver — focused change to an existing installer and an existing contract checker |
| Architecture guides | `core/hooks-policy.md`; `docs/operations/project8-telemetry-preflight.md` |
| Patterns | none — no new implementation pattern is introduced |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion` |
| Validation gates | hook gate; hard hook fail-closed; hook boundary parity; user-level installer; full enforcement; PR policy; exact-head CI; review |
| Evidence to check | a rendered gate-wrapped command with an unresolvable Engineering OS home exits 2; the bare form exits 127; `install-policy-gates.sh` substitution table omits `${ENGINEERING_OS_HOME:-$HOME/.engineering-os}` |
| User decisions required | owner approval before merge; owner approved fixing the blockers end to end (2026-08-04) |

## Goal

Make `remote_handoff.mode = "required"` actually fail closed when the Engineering OS runtime
cannot be resolved. Today a project-level settings file whose hook commands are not
gate-wrapped turns an unresolvable home into a **non-blocking** shell error, so a session
does all its work with no telemetry and reports success.

## Scope

In: the renderer's project-surface caller (`install-policy-gates.sh`), the deterministic
contract checker's ability to run against a project surface, and a regression that executes a
rendered command with an unresolvable home.

Out: `patch-settings-telemetry.py` (measured — it already renders the correct command),
project-8's own settings (separate PR, separate repository), the telemetry data model, and
any gap status change.

## Claude Run Trace

- **goal**: convert a silent fail-open into a deny, and make the fail-open shape impossible to
  reintroduce on a project surface.
- **hypothesis**: gate-wrapping with the *portable* root is sufficient, because the rendered
  hard command's `[ -r "$GATE" ] || exit 2` bootstrap fires before anything else when the home
  does not resolve.
- **connectors**: GitHub — re-read `origin/main` at `a1af899` before planning.
- **steps**: reproduced the defect in a real qualification session; measured the exit codes of
  both wirings against an unresolvable home; read the renderer, the hard gate, the contract
  checker and the project-surface installer; located the substitution table that misses
  project-8's form.
- **evidence**: gate-wrapped → `exit 2` with `ERROR_FOR_AGENT: Engineering OS hard-hook wrapper
  missing`; bare → `exit 127` with `No such file or directory`. Same input, same environment.
- **rejected attempts**: adding a portable-root option to `patch-settings-telemetry.py` —
  rejected after measuring that `--home` is already used verbatim (`:152`), so the portable form
  renders correctly with no code change. Baking an absolute path into the project surface —
  rejected because project-8's own contract forbids machine-specific paths.
- **result**: the renderer is reused unchanged; the fix is in the caller, the checker, and a
  regression that executes the rendered command.
- **follow-up**: project-8's settings are re-rendered in a separate PR in that repository.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `scripts/monitoring/patch-settings-telemetry.py` | read | `runtime_home = home or home_placeholder()` (`:152`) uses `--home` verbatim with no validation, so `--home '${ENGINEERING_OS_HOME:-$HOME/.engineering-os}'` already renders a gate-wrapped command carrying the `exit 2` bootstrap and no machine-specific path. No change needed here. |
| `scripts/enforcement/lib/hook-gate.sh` | read | Denies on a missing unit (`:39-40`) and converts any nonzero unit exit into a PreToolUse deny (`:250-261`), so gate-wrapping covers the whole failure class including the guard's own non-2 paths. Reused as-is. |
| `scripts/install-policy-gates.sh` | read | Calls the patcher with neither `--mode` nor `--home` (`:63-64`), then rewrites paths in a separate substitution pass (`:76-94`) whose table contains `$(pwd)`, `$PWD` and bare `${ENGINEERING_OS_HOME}` but **not** `${ENGINEERING_OS_HOME:-$HOME/.engineering-os}`. That omission is the root cause of the drift. |
| `scripts/enforcement/check-hard-hook-contract.py` | read | Already fails an ungated hard command (`:186`) and one lacking the `exit 2` bootstrap (`:191`), but is only ever run with `--surface source|installed`. It is never pointed at a project settings file, which is why the fail-open shape was never caught deterministically. |
| `scripts/enforcement/tests/test-hard-hook-fail-closed.sh` | read | Asserts the missing-**wrapper** bootstrap, but only against the `Bash`-matcher JSON-guard command, and never with an unresolvable home. No existing test executes a hook command whose Engineering OS home does not resolve. |

## Design

Reuse the renderer and the hard gate unchanged. Three changes:

1. `install-policy-gates.sh` passes the resolved home to the patcher explicitly instead of
   rendering with a placeholder and post-substituting a table that cannot cover every form.
2. `check-hard-hook-contract.py` gains the ability to validate an arbitrary project settings
   file, so the ungated shape is rejected by a gate rather than by review.
3. A regression executes both wirings with an unresolvable home and asserts `2` and `127`
   respectively, so the difference the fix protects is written down as an assertion rather than
   as prose.

## Capability Evidence

- `routing.task-router-read` — routed as Engineering OS enforcement/hooks governance.
- `workflow.workflow-read` — plan-first write, then implementation, tests, CI, review, approval, merge, post-merge.
- `plan.route-plan-before-write` — this plan is committed before the first code change.
- `source.github-repo-read` — live `origin/main` at `a1af899` re-read before any claim.
- `validation.policy-change-has-validator` — the new deny path has an executing regression, not a static assertion.
- `validation.coderabbit-policy` — PR review required before merge.

## Skill Evidence

- `writing-plans` — scope, reuse decision, rejected alternatives and non-goals recorded.
- `verification-before-completion` — implementation, focused tests, full suite, exact-head CI, review, approval, merge and post-merge remain separate assertions.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Re-read `origin/main` at `a1af899`, the renderer, the hard gate, the project-surface installer and the contract checker before planning. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS` `main`, plus a live qualification session on `yotamfried-ux/project-8`.
- action: ran a real session against an unresolved Engineering OS home, then measured both hook wirings directly rather than reasoning about the PreToolUse contract.
- result: the bare form exits 127 and does not block; the gate-wrapped form exits 2 and denies. The session that ran ungated produced 2 events, no `session_start`, no bundle, and reported success under `mode: required`.
- decision: fix the caller and the checker, reuse the renderer and gate unchanged, and assert the difference by executing both forms.
- target: `scripts/install-policy-gates.sh`; `scripts/enforcement/check-hard-hook-contract.py`; `scripts/enforcement/tests/test-hook-home-resolution.sh`.

## Documentation Asset Evidence

- internal: `core/hooks-policy.md`; `docs/operations/project8-telemetry-preflight.md`; `scripts/enforcement/lib/hook-gate.sh`; `scripts/monitoring/patch-settings-telemetry.py`.
- context7: the Claude Code hooks reference governs the exit-code contract (only exit 2 denies at PreToolUse); it is already cited in `docs/operations/project8-telemetry-preflight.md` and needs no new document.
- decision: reused the existing hooks policy and preflight runbook rather than adding a document; the contract this PR enforces is already written there.

## Progress Lifecycle Evidence

- start: Route Plan committed before the first code change. Measured on `main` at `a1af899`: a rendered gate-wrapped command with an unresolvable home exits 2, the bare form exits 127, and `install-policy-gates.sh`'s substitution table omits `${ENGINEERING_OS_HOME:-$HOME/.engineering-os}`.
- mid: rendered a settings file with the portable root and measured both wirings against an unresolvable home in one run, same input and same environment: gate-wrapped exits 2 with `ERROR_FOR_AGENT: Engineering OS hard-hook wrapper missing`, bare exits 127 with `No such file or directory`. Fixed the caller (`--mode direct --home` at render time) and closed the substitution-table omission behind it. Verified against a real `install-policy-gates.sh` run into a fresh git target: zero unresolved home forms remain and the guard is gate-wrapped with the exit-2 bootstrap. Dropped the planned `check-hard-hook-contract.py` project-surface extension after measuring that the registry expects Engineering OS's full enforcement set, so accepting a product repository's telemetry-only subset would have loosened the checker for every surface.
- pre-merge: full enforcement suite 113 suites, 0 failures — 112 previously plus this PR's new suite, which CI picks up automatically because `enforcement-tests.yml:104` globs `scripts/enforcement/tests/test-*.sh`. `test-hook-home-resolution.sh` carries 6 assertions and was proven non-vacuous rather than assumed to work: case 1's assertion was run against the bare form and returned 127 where it requires 2, so a regression to an ungated command fails it. That check matters here specifically — this PR's whole subject is a test-shaped blind spot, and a regression that cannot fail would have reproduced it. `shellcheck` reports no findings on both changed shell files; the one SC2016 it did raise was on the deliberate literal placeholder and is now suppressed with a stated reason rather than silently ignored. `check-workflow-evidence.sh`, `check-connector-evidence.sh`, `check-documentation-asset-evidence.sh` and `enforce-run-trace.sh` all pass. Recorded on the PR for this branch.
- outstanding external gates: exact-head CI, live review reconciliation, explicit owner approval, expected-head protected merge, and post-merge validation. No gap status changes before all of those complete.

## Definition of Done — Implementation

- [x] A rendered hard command with an unresolvable Engineering OS home denies rather than passing — measured: exit 2 with an `ERROR_FOR_AGENT` diagnostic, against 127 for the bare form.
- [x] The project-surface installer renders gate-wrapped commands without relying on a substitution table that cannot enumerate every home form — `install-policy-gates.sh` now passes `--mode direct --home`, and a real install leaves zero unresolved home forms.
- [x] The missing home form is added to the substitution table as defence in depth, so any other source of that form is normalised too.
- [x] A regression executes both wirings against an unresolvable home and asserts the exit codes, and is proven non-vacuous by checking that case 1's assertion fails on the bare form.

Scope correction made during implementation, recorded rather than silently applied: the plan
also proposed making `check-hard-hook-contract.py` validate a project surface. Measured while
implementing — the registry expects Engineering OS's full enforcement set (39 `both` rows,
9 `installed`), while a product repository carries only the telemetry subset and none of the
units on disk. Bending the checker to accept that would have loosened `validate_paths` and
`validate_hard_wiring` for every surface, weakening the guarantee this PR exists to
strengthen. Project-surface enforcement therefore moves to the repository that owns the
settings file, where its own CI already runs a validator.

## Validation Plan

- Focused: the new home-resolution regression, `test-hard-hook-fail-closed.sh`, `test-hook-gate.sh`, `test-hook-boundary-parity.sh`, `test-user-level-telemetry-installer.sh`, `test-install-policy-gate-coverage.sh`.
- Full: the complete enforcement suite.
- External: exact-head CI, live review, owner approval, expected-head merge, post-merge validation.
