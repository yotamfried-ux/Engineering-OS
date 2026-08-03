# Route Plan — Close eos-repo-boundary-sync-drift

## Route Plan

| Field | Decision |
|---|---|
| Task type | hook wiring parity implementation |
| Task class | `engineering_os_governance` |
| Domain tags | hook governance, installer parity, telemetry wiring, settings surfaces |
| Plan Scope | focused |
| Planning Mode | implementation; single canonical required-hook manifest |
| Task-router evidence | `core/task-router.md` routes Engineering OS hook/installer governance through `install-governance` and `hooks-governance`. |
| Workflow evidence | `core/workflow.md`, `core/hooks-policy.md`, `core/git-policy.md`, `core/quality-gates.md`, `core/coderabbit-policy.md` require plan-first writes, deterministic enforcement, focused PR, exact-head CI, review, explicit owner approval, expected-head merge, post-merge proof. |
| Target paths | `.claude/plans/close-eos-repo-boundary-sync-drift.md`; `scripts/enforcement/hook-criticality.tsv`; `scripts/enforcement/check-hard-hook-contract.py`; `scripts/monitoring/patch-settings-telemetry.py`; `scripts/monitoring/require-telemetry-session.sh`; `scripts/monitoring/install-user-level-telemetry-hooks.sh`; `scripts/install-policy-gates.sh`; `.claude/settings.json`; `scripts/enforcement/tests/` |
| Templates | waiver — focused change to existing registry, validator, and patcher schemas |
| Architecture guides | `core/hooks-policy.md`; `docs/operations/operational-readiness-audit.md`; `docs/operations/remote-multirepo-telemetry-hooks.md` |
| Patterns | none — no new implementation pattern is introduced |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion` |
| Validation gates | hook classification; hard-hook contract; clean install and usage; user-level installer; install policy gate coverage; full enforcement; PR policy; exact-head CI; review |
| Evidence to check | `.claude/settings.json` contains zero `record-and-sync-telemetry.sh` references; `patch-settings-telemetry.py:desired_hooks()` is a second manifest; `check-hard-hook-contract.py:validate_soft_rows` skips absent rows |
| User decisions required | owner approval before merge; owner selected `hook-criticality.tsv` as single canonical owner (2026-08-03) |

## Goal

Give the required hook set exactly one canonical owner so that every place Engineering OS
can run wires the same collection mechanisms. Today an event recorded through one install
path is dropped by another, which during the experiment would read as "the model did not do
X" when the truth is "the system did not record X".

## Scope

Wiring parity only. Failure behaviour *inside* an already-wired hard hook belongs to
`hard-hook-fail-closed` and is not reopened. No telemetry runtime semantics, no exporter,
no importer, no Project 8 changes, no bypass work.

## Claude Run Trace

- **goal**: Make every place Engineering OS can run wire the same required hook set, so a
  missing event during the experiment cannot be misread as model behaviour.
- **hypothesis**: The four surfaces had already drifted, and the drift was invisible
  because two manifests existed and the contract checker only enforced hard units.
- **connectors/tools**: GitHub connector for `origin/main` at `bd07042`; local execution of
  `patch-settings-telemetry.py --verify`, `check-hard-hook-contract.py`, `hook-gate.sh`,
  and the focused enforcement suites. The Notion connector is not authorized in this
  session, so no `notion_progress_validated` evidence is produced here; per
  `core/connector-policy.md` fallback, the GitHub-backed record for this change — PR head
  SHA, required workflow conclusions, and review threads — is the progress evidence
  instead. No Notion state is claimed or inferred.
- **steps**: Read all four surfaces; diffed them against `hook-criticality.tsv`; pointed the
  terminal rows at `record-and-sync-telemetry.sh`; made the contract fail on absent
  recorder/lifecycle rows; derived the patcher from the registry; re-rendered checked-in
  settings; declared the registry a required install dependency; re-ran the suites.
- **evidence**: `grep -c record-and-sync-telemetry.sh .claude/settings.json` → `0` before
  the change. `--verify` reported 40+ mismatches before, `verified` after.
  `check-hard-hook-contract.py --surface source` failed with
  `registered lifecycle unit is not wired` before the settings fix and passed after
  (`direct=13 nested=1`). `hook-gate.sh` invoked directly on the dispatcher unit exited 0.
  Semantic settings diff: 3 hooks changed, 35 unchanged.
- **rejected attempts**: (1) Adding registry columns — rejected because two independent
  10-column parsers exist and one, `lib/hook-gate.sh`, is a hard fail-closed path.
  (2) Modelling the dispatcher as ordinary registry rows — rejected because one unit
  serves both guard and recorder roles on `PreToolUse` and collides on the registry key;
  it is rendered instead, with a single `dispatcher`-surface row so `hook-gate.sh` accepts
  it. (3) Prepending the telemetry guard — rejected because it would run before the
  PreToolUse JSON guard and break the hard-hook contract; registry order plus append is
  correct.
- **result**: One canonical owner; identical criticality across surfaces; the terminal
  boundary is wired on every surface, so an Engineering OS session now completes a run.
  A follow-on defect surfaced from the full suite: `require-telemetry-session.sh` held a
  third and fourth copy of the expected command shape, both testing only for a bare
  trailing argument. Once hooks are gate-wrapped the guard reported them missing, and in
  the boundary case under a `required` policy that verdict blocks rather than warns —
  which would have blocked Project 8 instead of producing a bundle. Both checks now match
  a unit whether it is invoked bare or through a gate. Measured `BOUNDARY_READY=1` on the
  direct, dispatcher, and checked-in surfaces.
- **follow-up enforcement**: Per-mismatch-class regressions (missing, mismatched,
  duplicate, legacy, wrong criticality, missing terminal boundary), then exact-head CI,
  review, owner approval, expected-head merge, post-merge validation, and gap closure.
- **trace_boundary**: no independent Claude Code session trace is claimed; recorded command
  output and the semantic settings diff are the auditable surrogate.
  `exact_token_usage_available: no`.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `scripts/enforcement/hook-criticality.tsv` | read | Already carries event, matcher, unit, class, failure semantics, wiring, parent, surface, requires, deny mode. Reused as the canonical owner; not replaced. |
| `scripts/monitoring/patch-settings-telemetry.py` | read | `desired_hooks()` / `command_set()` are a second, conflicting manifest. Removed in favour of registry-derived rendering. |
| `.claude/settings.json` | read | `grep -c record-and-sync-telemetry.sh` → `0`. `Stop`/`StopFailure`/`SessionEnd` map to the plain recorder, so an Engineering OS session never completes a terminal boundary. |
| `scripts/enforcement/check-hard-hook-contract.py` | read | `validate_soft_rows` returns early when a registered recorder/lifecycle row is absent from settings. This is the hole that let the terminal-boundary drift survive. |
| `scripts/enforcement/lib/hook-gate.sh` | read | Second independent 10-column parser of the registry, on a hard fail-closed path. Therefore no new columns are introduced. |
| `scripts/monitoring/sync-telemetry-run.py` | read | `sync()` returns 0 immediately when policy mode is `disabled`. Engineering OS has no `.engineering-os/telemetry-policy.json`, so adding the terminal-boundary hook to source settings records the event and no-ops the sync. |
| `scripts/monitoring/install-user-level-telemetry-hooks.sh` | read | Delegates entirely to the patcher with `--mode dispatcher`; inherits the canonical set automatically. |

## Design

`hook-criticality.tsv` stays the single source of truth and gains no new columns.

1. The three terminal rows (`Stop`, `StopFailure`, `SessionEnd`) change unit from
   `scripts/monitoring/eos-telemetry-event.sh` to
   `scripts/monitoring/record-and-sync-telemetry.sh`, classified `lifecycle` /
   `soft_setup`. `record-and-sync-telemetry.sh` invokes the recorder itself, so this
   removes a duplicate rather than adding one.
2. `patch-settings-telemetry.py` derives its required set from the registry rows whose unit
   lives under `scripts/monitoring/`, and renders per mode: `direct` emits the gate-wrapped
   unit command, `dispatcher` emits `eos-telemetry-dispatch.sh <subcommand>`. The dispatcher
   is a renderer, not extra rows — one unit serves two roles on `PreToolUse`, which the
   registry key `(event, matcher, unit, wiring, surface)` cannot express.
3. Rendering uses the same gates as the source surface: `lib/hook-gate.sh` for `hard`,
   `lib/soft-hook-gate.sh` for `recorder`/`lifecycle`. This closes the second half of the
   drift, where `require-telemetry-session.sh` is declared `hard`/`fail_closed` but was
   installed into targets raw and therefore fail-open.
4. `check-hard-hook-contract.py:validate_soft_rows` fails when a registered
   recorder/lifecycle row is absent from the settings surface it applies to.
5. `.claude/settings.json` gains the terminal-boundary hooks.

## Capability Evidence

- `routing.task-router-read` — routed as Engineering OS install/hook governance.
- `workflow.workflow-read` — plan-first writes, then implementation, tests, CI, review, approval, merge, post-merge.
- `plan.route-plan-before-write` — this plan is committed before any registry, validator, patcher, or settings write.
- `source.github-repo-read` — live `origin/main` state re-read before any claim.
- `validation.policy-change-has-validator` — every change is covered by an existing or new enforcement test.
- `validation.coderabbit-policy` — PR review required before merge.

## Skill Evidence

- `writing-plans` — scope, canonical owner decision, and non-goals recorded before writes.
- `verification-before-completion` — implementation, focused tests, full suite, exact-head CI, review, approval, merge, and post-merge remain separate assertions.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Re-read `origin/main` at `bd07042`, the known-gaps registry, the readiness audit checklist, and the four settings surfaces before planning. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS` `main`, plus the working tree for the four settings surfaces.
- action: compared checked-in settings, the direct-mode patcher, the user-level dispatcher installer, and generated target settings against `hook-criticality.tsv`.
- result: against `main` at `bd07042cffd2cc12447318379e08620d1034cf14`, `.claude/settings.json` held zero references to `scripts/monitoring/record-and-sync-telemetry.sh`, so no Engineering OS session completed a terminal boundary; `scripts/monitoring/patch-settings-telemetry.py` carried a second manifest in `desired_hooks()`; the installed surface wired `scripts/monitoring/require-telemetry-session.sh` un-gated despite `scripts/enforcement/hook-criticality.tsv` declaring it hard/fail_closed; and `scripts/enforcement/check-hard-hook-contract.py:validate_soft_rows` skipped absent rows. Recorded on PR #266.
- decision: selected `scripts/enforcement/hook-criticality.tsv` as the single canonical owner and changed `scripts/monitoring/patch-settings-telemetry.py` to derive from it, deleting the duplicate manifest; kept the ten-column schema because `scripts/enforcement/lib/hook-gate.sh` parses it on a hard fail-closed path; added one `dispatcher`-surface row so the scope resolver is accepted as canonical; updated `.claude/settings.json` with the terminal boundary; and blocked partial installs by adding the registry to both installer preflights.
- target: `scripts/enforcement/hook-criticality.tsv`; `scripts/monitoring/patch-settings-telemetry.py`; `scripts/enforcement/check-hard-hook-contract.py`; `scripts/monitoring/require-telemetry-session.sh`; `.claude/settings.json`.

## Documentation Asset Evidence

- internal: `core/hooks-policy.md`; `docs/operations/operational-readiness-audit.md`; `docs/operations/known-gaps.tsv`; `docs/operations/remote-multirepo-telemetry-hooks.md`; `scripts/enforcement/hook-criticality.tsv`; `scripts/enforcement/lib/hook-gate.sh`; `scripts/enforcement/lib/soft-hook-gate.sh`.
- context7: the official vendor source <https://code.claude.com/docs/en/hooks> remains the basis for hook event names, matcher semantics, and deny behaviour. This change alters wiring parity only and does not reinterpret those semantics.
- decision: reused the existing criticality registry, both gate wrappers, and the existing `--verify` reporting rather than introducing a new manifest format, a new validator, or new documentation surface. No new doc asset is required because `core/hooks-policy.md` already owns hook structure and now matches the implementation.

## Progress Lifecycle Evidence

- start: Route Plan committed before any change to `scripts/enforcement/hook-criticality.tsv`, `scripts/monitoring/patch-settings-telemetry.py`, `scripts/enforcement/check-hard-hook-contract.py`, `scripts/monitoring/require-telemetry-session.sh`, or `.claude/settings.json`. Measured drift on `main` at `bd07042cffd2cc12447318379e08620d1034cf14`: `grep -c record-and-sync-telemetry.sh .claude/settings.json` returned `0`, and `patch-settings-telemetry.py --mode direct --verify` reported more than forty mismatches.
- mid: made `scripts/enforcement/hook-criticality.tsv` the single owner, derived `scripts/monitoring/patch-settings-telemetry.py` from it, closed the `validate_soft_rows` hole, re-rendered `.claude/settings.json`, declared the registry an install dependency, and added `scripts/enforcement/tests/test-hook-boundary-parity.sh`. The full suite then surfaced a defect this plan had not anticipated: `scripts/monitoring/require-telemetry-session.sh` held a third and fourth copy of the expected command shape, each matching only a bare trailing argument, so gate-wrapped hooks read as missing. Under a `required` telemetry policy the boundary copy blocks rather than warns, which would have blocked Project 8 instead of producing a bundle. Both checks are now gate-aware, with a regression that reuses the guard's own boundary block.
- outstanding external gates: exact-head CI on PR #266, live review reconciliation, explicit owner approval, expected-head protected merge, and post-merge validation. No gap status changes before all of those complete.

## Definition of Done — Implementation

- [x] One canonical manifest owns event, matcher, command identity, criticality, failure mode, and terminal-boundary behaviour: `scripts/enforcement/hook-criticality.tsv`, with `patch-settings-telemetry.py` deriving its required set from it and the duplicate `desired_hooks()` manifest deleted.
- [x] All four surfaces are checked against it: checked-in settings and generated target settings through `check-hard-hook-contract.py`, direct-mode and user-level dispatcher installs through `patch-settings-telemetry.py --verify`.
- [x] `--verify` fails on missing, mismatched, duplicate, legacy/unregistered, and wrong-criticality required hooks: `test-hook-boundary-parity.sh` covers one case each, 12/12 passing.
- [x] Parity proven in checked-in Engineering OS and in a clean installed target: `test-clean-install-and-usage.sh` and `test-install-policy-gate-coverage.sh` pass; the parity test asserts source and generated surfaces agree on unit, argument, and criticality.
- [x] The registry is a declared install dependency, so a missing registry refuses the install instead of wiring a partial hook set.
- [x] Focused suites pass: hook classification, hook gate, hard-hook fail-closed, hard-hook symlinks, boundary parity, user-level installer, fresh-session scoping, clean install, install policy-gate coverage, target install smoke, and the three dispatch suites.

External gates remaining before closure:

- full enforcement suite and exact-head CI on the final PR head, latest attempt only;
- live review reconciled to zero unresolved threads;
- explicit owner approval for the final exact head;
- expected-head protected merge and post-merge validation;
- only then: `known-gaps.tsv` row and the audit checklist move to closed.

## Validation Plan

1. `test-hook-classification.sh`, `test-hard-hook-fail-closed.sh`, `test-hard-hook-symlinks.sh`, `test-hook-gate.sh`.
2. `test-clean-install-and-usage.sh`, `test-install-policy-gate-coverage.sh`, `test-user-level-telemetry-installer.sh`, `test-fresh-session-hook-scoping.sh`.
3. Full enforcement suite.
4. Exact-head CI on the PR head; latest attempt only.
5. Reconcile every live review thread; do not weaken a gate to pass CI.
6. No merge without a new explicit owner approval for the final exact head.
