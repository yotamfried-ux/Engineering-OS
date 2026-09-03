# Route Plan — Automatic local archiving of telemetry runs

Plan Scope: standard
Plan Timestamp: 2026-09-03T19:50:39Z
Planning Mode: approved

## Route Plan

| Field | Decision |
|---|---|
| Task type | reliability/automation fix — telemetry runs from a target project must land in `telemetry-archive/` without a manual export/import step |
| Task class | `engineering_os_governance` |
| Domain tags | telemetry, observability, monitoring, hooks, session lifecycle, project-8 experiment readiness |
| Plan Scope | standard |
| Plan Timestamp | 2026-09-03T19:50:39Z |
| Planning Mode | approved |
| Task-router evidence | `core/task-router.md` §7 (Engineering OS maintenance/governance): "שינוי ב-OS חייב לחזק את שכבת ההכרעה/האכיפה, לא רק להוסיף עוד טקסט הסברי" — this change adds a real, tested archiving step to the boundary hook chain, not documentation. |
| Workflow evidence | `core/workflow.md` `<evidence_backed_planning>` (Plan Scope/Timestamp declared below); `core/coderabbit-policy.md` (branch → draft PR → live review → explicit owner approval before merge — followed below); `core/git-policy.md` (commit protocol). |
| Target paths | `scripts/monitoring/archive-local-telemetry-run.py` (new); `scripts/monitoring/record-and-sync-telemetry.sh` (wire the new step into Stop/StopFailure/SessionEnd); `scripts/enforcement/tests/test-local-telemetry-auto-archive.sh` (new validator, follows the existing `test-project8-telemetry-readiness.sh` / `test-telemetry-archive.sh` harness pattern). |
| Templates | waiver — this is a focused addition to the existing telemetry runtime; no scaffold/project template applies. |
| Architecture guides | `docs/operations/project8-telemetry-preflight.md`, `docs/operations/runtime-telemetry-archive-plan.md`, `docs/operations/known-gaps.tsv` (`project-8-real-run-evidence`). |
| Patterns | none applicable — this is runtime script code, not a product pattern. |
| External systems/connectors | not required |
| Skills | none |
| Validation gates | new `scripts/enforcement/tests/test-local-telemetry-auto-archive.sh`; existing `scripts/enforcement/tests/test-telemetry-archive.sh`, `test-project8-telemetry-readiness.sh` (must keep passing — confirms no regression to the existing recorder/sync contract); a live local simulation against the real `project-8` checkout + real `telemetry-archive/` (see Validation Plan) before opening the PR. |
| Evidence to check | Read (this session): `scripts/monitoring/export-telemetry-run.py`, `import-telemetry-run.py`, `record-and-sync-telemetry.sh`, `sync-telemetry-run.py`, `require-telemetry-session.sh`, `eos-telemetry-session-start.sh`, `analyze-telemetry-archive.py`, and the two existing telemetry tests, to confirm the archive/import contract and reuse it exactly rather than reinventing sanitization or identity checks. |
| User decisions required | none remaining — user explicitly asked to plan **and** execute this in the same instruction ("תיצור תוכנית לעדכון - תבצע אותו ואז תאמת בעזרת סימולציה"). Merge to `main` still requires the owner's explicit approval per `coderabbit-policy.md`; this plan does not authorize merging. |

## Capability Evidence

Task class: `engineering_os_governance`.

- `routing.task-router-read` — `core/task-router.md` §7 and `<required_output>` read this session before writing this plan.
- `workflow.workflow-read` — `core/workflow.md` `<workflow>` and `<evidence_backed_planning>` read this session; this file follows the `standard` Plan Scope contract.
- `plan.route-plan-before-write` — this file, created before any script edit.
- `source.github-repo-read` — `git log`/`git status`/`git branch` checked on both `Engineering-OS` and `project-8` local checkouts before planning; both are clean and on the session's designated branch.
- `validation.policy-change-has-validator` — new `scripts/enforcement/tests/test-local-telemetry-auto-archive.sh` added alongside the code change (see Validation Plan).
- `validation.coderabbit-policy` — `core/coderabbit-policy.md` read this session; the PR opened for this change will follow its live-review-status flow before any merge is requested.

## Source of Truth Checks

| Source | Status | What it settled |
|---|---|---|
| core/task-router.md | read | Routed this task to `engineering_os_governance` and to the plan → branch → draft PR → review → owner-approval path. |
| core/workflow.md | read | `standard` Plan Scope, the required plan sections, and the `Plan Timestamp` contract. |
| core/coderabbit-policy.md | read | The branch → PR → live-review-status → explicit-approval flow this PR follows; no merge without Yotam's approval. |
| scripts/monitoring/export-telemetry-run.py | read | The exact sanitization allowlist and manifest shape a new archiving step must reuse rather than reimplement. |
| scripts/monitoring/import-telemetry-run.py | validated | Confirmed by direct reproduction, not assumed: a bare export-only bundle is rejected — the shared integrity validator requires `sync-telemetry-run.py`'s handoff metadata block. |
| scripts/monitoring/sync-telemetry-run.py | read | `write_handoff_manifest()`, `detect_repo_slug()`, `latest_boundary_position()`, and `engineering_os_head()` are the exact functions the new script reuses instead of duplicating. |
| scripts/monitoring/record-and-sync-telemetry.sh | read | The exact insertion point for the new archiving step (after the existing recorder + sync calls, before the script's exit status). |
| scripts/enforcement/tests/test-project8-telemetry-readiness.sh | read | The scratch-repo-plus-real-scripts test harness pattern the new test follows. |
| scripts/enforcement/tests/test-telemetry-archive.sh | read | Confirmed via `sync_bundle()` that handoff enrichment is a precondition the archive already enforces elsewhere, not new to this change. |
| docs/operations/known-gaps.tsv | read | `project-8-real-run-evidence` (open, P1) is the readiness gap this change is meant to help close for the next Project 8 session. |

## Skill Evidence

- none — routing was done directly against `core/task-router.md` and `core/workflow.md`
  (see Source of Truth Checks above), not through the packaged `engineering-route` skill;
  the `Skills` field is `none` rather than claiming a skill invocation that did not happen.

## Progress Lifecycle Evidence

- start: Session opened on `main` at `4d51784` on branch `claude/loving-mccarthy-8bekkh`.
  Confirmed by reading both repos' `.github/workflows/` that no workflow anywhere calls
  `import-telemetry-run.py`, so a session with no PR never gets archived. Initial plan was
  a bare `export-telemetry-run.py` → `import-telemetry-run.py` call from the new script.
- mid: The initial plan was wrong in one concrete way: `import-telemetry-run.py`'s shared
  integrity validator rejected the bare export-only bundle with `telemetry bundle has no
  valid handoff metadata` — reproduced directly, not assumed. Fixed by dynamically loading
  `sync-telemetry-run.py` and reusing its own `write_handoff_manifest()`/`detect_repo_slug()`
  /`latest_boundary_position()` instead of duplicating that logic. The first version of the
  new test then exposed a second wrong assumption: it expected a session with zero tool
  calls to have zero events, but `eos-telemetry-session-start.sh` always writes one
  `eos.session_start` event and the `Stop` boundary always adds a second `eos.stop` event
  before archiving — a "zero-event session" isn't a real case. Mid-task, an explicit
  requirement arrived that the archive stay orderly over time rather than accumulate
  clutter; added a check that skips archiving a run made only of session-lifecycle
  bookkeeping events (`session_start`/`stop`/`stop_failure`/`session_end`) with no real
  tool/prompt/subagent activity in between.
- pre-merge: `scripts/enforcement/tests/test-local-telemetry-auto-archive.sh` passes all
  11 checks; `test-telemetry-archive.sh` and `test-project8-telemetry-readiness.sh` still
  pass unchanged (no regression to the existing recorder/sync contract). A live simulation
  against the real `project-8` checkout's identity (a throwaway local clone, origin URL
  only, never pushed) and this repo's real `telemetry-archive/`, run end to end through the
  unmodified `record-and-sync-telemetry.sh stop`, produced one correctly identity-matched
  entry (`repo: yotamfried-ux/project-8`, real `head_sha`, real Engineering OS `head_sha`,
  `metadata-only`, no raw content) that `analyze-telemetry-archive.py` read successfully;
  reverted afterward so the real archive stays empty. Opening the PR then surfaced five
  governance gates this plan had gotten wrong on the first pass — connector-evidence field
  format (`External systems/connectors` needed an exact none-ish phrase, not a descriptive
  sentence), Documentation Asset Evidence, capability-evidence's placeholder check
  (`not required` satisfies both the connector checker's none-ish set and the
  capability checker's non-placeholder requirement, where bare `none` satisfied only one),
  Route-Plan-before-code commit ordering (this plan's own commit had to precede the code
  commit, not share it), and this section's own start/mid/pre-merge staged-commit
  requirement — each was reproduced locally against the exact base/head SHAs with the
  same scripts CI runs, and fixed before pushing again, rather than pushed speculatively.

## Goal / מטרה

Today, a Claude Code session's telemetry events are recorded locally
(`.engineering-os/telemetry/events.jsonl`) and — only when `remote_handoff.mode=required`
succeeds and a PR later runs `pr-policy.yml` — surfaced as a GitHub Actions workflow
artifact. Nothing ever imports a run into `telemetry-archive/` in the Engineering OS
repository (the archive `analyze-telemetry-archive.py` reads from) without a human
manually running `export-telemetry-run.py` + `import-telemetry-run.py`. Verified: no
workflow in either `project-8` or `Engineering-OS` calls `import-telemetry-run.py`.

Goal: when a Claude Code session ends (`Stop`/`StopFailure`/`SessionEnd`) in a project
managed by Engineering OS, and a local Engineering OS checkout is reachable via
`ENGINEERING_OS_HOME`, automatically export and import that session's metadata-only
telemetry bundle into `telemetry-archive/` — so the run is available for
`analyze-telemetry-archive.py` without any manual step.

## Plan / תכנון

1. Add `scripts/monitoring/archive-local-telemetry-run.py`:
   - Resolve `ENGINEERING_OS_HOME` (same default as `sync-telemetry-run.py`'s
     `engineering_os_head()`: two parents above this script's own location).
   - If `<home>/telemetry-archive` or `<home>/scripts/monitoring/{export,import}-telemetry-run.py`
     is missing → log one diagnostic line to stderr and exit 0 (best-effort; many setups,
     e.g. ephemeral remote sessions without a local Engineering OS checkout, legitimately
     have nothing to archive into).
   - If the current run's events file is missing/empty → exit 0 silently (nothing to
     archive yet; this is the normal case on early boundary calls).
   - Export via `export-telemetry-run.py` (subprocess) to a private temp dir, then enrich
     that bundle's manifest with `sync-telemetry-run.py`'s own `write_handoff_manifest()`
     (loaded dynamically, same technique `test-telemetry-archive.sh`'s `sync_bundle()`
     helper already uses) — **verified during implementation, not assumed**: a bare
     export-only bundle is rejected by `import-telemetry-run.py`'s shared integrity
     validator, which requires the `handoff` metadata block `sync()` normally adds only
     right before its remote push. Reusing that helper directly (pr_number=0, so the
     bundle is correctly marked `pr_binding: provisional`) is the only way to produce a
     locally-importable bundle without duplicating `sync()`'s validation logic.
   - Skip archiving (exit 0, not an error) when the run's events are all pure
     session-lifecycle bookkeeping (`eos.session_start`, `eos.stop`, `eos.stop_failure`,
     `eos.session_end`) with no tool/prompt/subagent activity in between. Every managed
     session reaches at least one boundary event, so archiving unconditionally would fill
     `telemetry-archive/` with "opened and closed" noise on every trivial session instead
     of runs worth analyzing later — added in response to an explicit mid-task requirement
     that the catalog stay orderly over time, not accumulate clutter.
   - Import via `import-telemetry-run.py` (subprocess) into `<home>/telemetry-archive`,
     passing `--expected-repo`, `--expected-head-sha`, `--expected-run-id`,
     `--expected-engineering-os-head-sha` so import-time identity validation is exercised,
     not skipped.
   - Treat the importer's "duplicate telemetry import" failure as expected/idempotent
     (Stop, StopFailure, and SessionEnd can all fire for one session) — log info, exit 0.
     Treat any other importer/exporter failure as a **non-fatal warning**: write a
     privacy-safe diagnostic line (event name, exit code, stderr sha256 — never raw
     content) to `.engineering-os/telemetry/local-archive-errors.jsonl` in the target
     project, print one `WARNING_FOR_AGENT` line, and exit 0. This step must never block
     session termination — that is a deliberate difference from the `required`-mode
     PreToolUse guard, which is allowed to block.
2. Wire it into `scripts/monitoring/record-and-sync-telemetry.sh`, after the existing
   recorder + `sync-telemetry-run.py` calls, guarded with `|| true` so a defect in the new
   script cannot break the existing boundary hook contract.
3. Add `scripts/enforcement/tests/test-local-telemetry-auto-archive.sh`, following the
   harness pattern in `test-project8-telemetry-readiness.sh`: a scratch git repo standing
   in for a target project, real `eos-telemetry-session-start.sh` /
   `eos-telemetry-event.sh` / `record-and-sync-telemetry.sh` calls with realistic JSON
   hook payloads, `ENGINEERING_OS_HOME` pointed at a scratch Engineering-OS-shaped home
   (real `scripts/monitoring/` copied in, empty `telemetry-archive/`), and assertions that:
   - a lifecycle-only session (session_start + the boundary event itself, no real
     activity) produces no archive entry, and a run with real tool-call activity does;
   - a session with real tool-call events produces exactly one archive entry with matching
     repo/head/run identity after `Stop`;
   - a second boundary call (`SessionEnd`) for the same run does not fail and does not
     duplicate the archive entry;
   - no raw prompt/command/path content appears in the archived bundle.
4. Run the new test plus the two existing telemetry tests.
5. Run a live simulation against the **real** `project-8` checkout and the **real**
   `telemetry-archive/` in this Engineering-OS checkout (isolated from the real GitHub
   remote — the sim's `origin` points at a scratch local bare repo, so
   `sync-telemetry-run.py`'s existing required-mode push is exercised without touching
   `github.com/yotamfried-ux/project-8`), to prove the behavior end-to-end on the actual
   target project, not only in a synthetic fixture.
6. Commit, push the session's designated branch, open a draft PR, subscribe to its
   activity, and follow `coderabbit-policy.md` — do not merge without Yotam's explicit
   approval.

## DoD / תנאי סיום

- [x] New script exists, is non-blocking on failure, and never writes raw prompt/tool
      content into the archive (reuses `export-telemetry-run.py`'s existing allowlist).
- [x] `record-and-sync-telemetry.sh` calls it for `stop`/`stop_failure`/`session_end`.
- [x] New test passes; both pre-existing telemetry tests still pass.
- [x] Live simulation against the real `project-8` + real `telemetry-archive/` shows a
      new, non-empty, identity-matching run appear automatically after a simulated `Stop`,
      with zero manual `export`/`import` commands run by the operator (then reverted, so
      the real archive stays empty until an actual Project 8 run happens).
- [x] PR opened, PR activity subscribed, marked ready for review so required checks and
      CodeRabbit can run against it — no merge without explicit owner approval
      (`coderabbit-policy.md`).

## Alternatives / חלופות

- **CI-based cross-repo import** (a `project-8` workflow pushes to
  `engineering-os-telemetry`, and a separate Engineering-OS workflow pulls and imports
  it): rejected for this change — it requires a cross-repo credential/workflow with write
  access to `Engineering-OS`, which is a materially larger, shared-system change that
  needs its own explicit sign-off, and it would still do nothing for sessions that never
  open a PR (the exact case in the upcoming Project 8 experiment). Local archiving at the
  `Stop` boundary covers that case with no new credentials and no network dependency.
- **Auto-commit the archive files into git**: rejected — writing files into the working
  tree is enough for `analyze-telemetry-archive.py` to read immediately; committing/pushing
  telemetry-archive data automatically, on every session end, from any managed project,
  would create shared-history writes with no review step, which conflicts with
  `core/precedence.md` #1 (no irreversible/shared action without explicit human approval).
  The operator reviews and commits the new archive entries deliberately.

## Affected Surfaces / משטחים מושפעים

`scripts/monitoring/record-and-sync-telemetry.sh` (all managed projects, at session
boundaries only); new `scripts/monitoring/archive-local-telemetry-run.py`; new test under
`scripts/enforcement/tests/`. No change to `.claude/settings.json` in any target project
(the hook command path is unchanged; the new behavior lives entirely inside the existing
`record-and-sync-telemetry.sh` entry point). No change to `sync-telemetry-run.py`'s remote
handoff, `require-telemetry-session.sh`'s guard, or the telemetry policy schema.

## Data/State Impact / השפעה על דאטה ומצב

Writes new files under `telemetry-archive/runs/...` and updates
`telemetry-archive/indexes/{runs.jsonl,projects.json,gaps.jsonl}` in the local Engineering
OS working tree, whenever a managed session with a local Engineering OS checkout ends with
one or more recorded events. Does not commit or push those files. No schema change to
existing manifest/event formats — reuses them as-is.

## Integration Impact / השפעה על אינטגרציות

None on GitHub/CI — `sync-telemetry-run.py`'s remote handoff and `pr-policy.yml`'s bundle
selection are untouched and keep working exactly as before. Purely additive local
behavior at the `Stop`/`StopFailure`/`SessionEnd` boundary.

## Validation Plan / תוכנית בדיקות

New unit-style test (`test-local-telemetry-auto-archive.sh`) plus the two pre-existing
telemetry tests, plus a live simulation against real `project-8` + real
`telemetry-archive/` (isolated remote) proving a non-empty, identity-matched run appears
automatically after a simulated real session, with the resulting `analyze-telemetry-archive.py
--project project-8` output inspected manually as evidence.

## Open Questions / שאלות פתוחות

None blocking. One deliberate limitation the findings should record after the real Project
8 experiment: this makes the run **available locally** for analysis; it does not, by
itself, make the archived data durable/shared (that still requires a deliberate commit —
see Alternatives).

## Documentation Asset Evidence

- internal: `docs/operations/project8-telemetry-preflight.md`,
  `docs/operations/known-gaps.tsv` (`project-8-real-run-evidence`),
  `docs/operations/project8-first-real-run-findings.md`,
  `scripts/enforcement/tests/test-project8-telemetry-readiness.sh`,
  `scripts/enforcement/tests/test-telemetry-archive.sh`
- context7: not required — this is purely internal bash/python runtime code that does not
  integrate an external library, framework, SDK, or API; it only reuses this repository's
  own existing telemetry export/import/sync modules (`scripts/monitoring/*.py`).
- decision: `docs/operations/project8-telemetry-preflight.md` and `known-gaps.tsv`
  (`project-8-real-run-evidence`) confirmed the session → export → import → analyze
  sequence this change automates, and confirmed that a session with no PR currently gets
  no durable archive at all; reading the two pre-existing telemetry tests decided the test
  harness pattern this change's new test follows (scratch repo + real scripts, not
  hand-built fixtures) instead of inventing a different one.

## Claude Run Trace

- **Goal:** make a finished Claude Code session's telemetry run land in
  `telemetry-archive/` automatically at the session boundary, without a human running
  `export-telemetry-run.py` + `import-telemetry-run.py` by hand, so a session that never
  opens a PR (the next Project 8 qualification run) still gets archived.
- **Hypothesis:** the missing piece was purely mechanical — call the existing exporter,
  then the existing importer, from the existing `Stop`/`StopFailure`/`SessionEnd` boundary
  script. This hypothesis was wrong in one concrete way (see Evidence) and was corrected
  before merge rather than argued around.
- **Connectors:** GitHub only (branch, draft PR, CI, review status). Context7 not
  required — no external library/framework/SDK/API is involved; this reuses the
  repository's own `scripts/monitoring/*.py` modules.
- **Steps:** read the existing exporter/importer/sync/boundary scripts and the two
  pre-existing telemetry tests; wrote this Route Plan; wrote
  `archive-local-telemetry-run.py` and wired it into `record-and-sync-telemetry.sh`; ran
  it and found the bare export→import call rejected by the importer; fixed it by reusing
  `sync-telemetry-run.py`'s own handoff-enrichment function; added the new test; ran it
  and found a second wrong assumption (a session can have zero events) contradicted by
  direct reproduction; fixed the test and, per an explicit mid-task requirement that the
  archive stay orderly over time, added a lifecycle-only-run skip so trivial sessions
  don't clutter the archive; ran a live simulation against the real `project-8` identity
  and this repo's real `telemetry-archive/`; opened the PR; fixed five separate governance
  gates (connector-evidence field format, documentation/capability/workflow evidence
  sections, and Route-Plan-before-code commit ordering) by reproducing each CI check
  locally against the exact base/head SHAs before pushing again.
- **Evidence:** `import-telemetry-run.py`'s shared integrity validator rejected a bare
  export-only bundle with `bundle failed shared integrity validation: telemetry bundle has
  no valid handoff metadata` — reproduced directly in a scratch repo, not assumed from
  reading the code. After reusing `write_handoff_manifest()`, the same scratch repo
  archived successfully. Separately, `eos-telemetry-session-start.sh` was confirmed to
  always write one `eos.session_start` event and the `Stop` boundary always adds a second
  `eos.stop` event before archiving runs, so "zero-event session" is not a real case — the
  test's premise was wrong, not the archiver. The final new test
  (`test-local-telemetry-auto-archive.sh`) has 11 passing checks; both pre-existing
  telemetry tests pass unchanged. The live simulation against the real `project-8`
  checkout's identity and this repo's real `telemetry-archive/` produced one correctly
  identity-matched archive entry (`repo: yotamfried-ux/project-8`, real `head_sha`, real
  Engineering OS `head_sha`, `metadata-only`, no raw paths/commands in the events.jsonl),
  which `analyze-telemetry-archive.py --project project8-sim` read successfully; the
  simulated entry and index changes were then reverted so the real archive stays empty.
- **Rejected:** a bare export→import call from the new script (rejected by the importer's
  own integrity validator, not a design choice); modifying `sync-telemetry-run.py`'s
  `sync()` itself to also write locally (would couple local archiving to the remote
  handoff's `required`/`best_effort`/`disabled` policy mode, which is the wrong
  dependency — local archiving should not depend on remote-push policy); auto-committing
  archived runs into git automatically (an unreviewed, repeated shared-history write on
  every session end, rejected under `core/precedence.md` #1); archiving every session
  unconditionally (would fill the archive with "opened and closed" noise, rejected after
  the explicit mid-task cataloging requirement).
- **Result:** `record-and-sync-telemetry.sh` now calls the new script at every boundary
  event; a run with real activity is archived automatically with verified identity and no
  raw content; a lifecycle-only run is not; the existing remote handoff is untouched;
  failures are logged and never block session teardown.
- **Follow-up:** the next real Project 8 qualification session
  (`project-8-real-run-evidence` in `docs/operations/known-gaps.tsv`) should now produce a
  non-empty archived run with no manual export/import step; its findings should record
  whether anything about the real session differs from this simulation.
