# Remote/multi-repo telemetry hooks — Route Plan

Branch: `claude/project-8-telemetry-preflight-5hllaw` (this session's designated
Engineering-OS branch; shared name with the project-8 branch in the sibling repo —
not a conflict, separate git remotes).

## Route Plan (`core/task-router.md` contract)

Task type: infra / developer-tooling (Claude Code hook + settings runtime)
Task class: `security_sensitive_change` (`core/capability-registry.yaml` — closest
match: "infrastructure, deployment, production-bound code"; no exact "hook runtime"
class exists, recorded explicitly rather than guessed)
Domain tags: governance, observability, privacy, cross-repository
Plan Scope: **project** (new architecture surface: user-level hook bootstrap +
multi-repository discovery/attribution runtime; not a bugfix to existing code)
Planning Mode: **final-for-approval** — full plan below; requires explicit "מאושר"
from the user (quoted, dated) before any code is written, per
`core/workflow.md` › `<evidence_backed_planning>` › User Approval for `project` scope.
Templates: none found for this class of task (Claude Code hook runtimes are not a
templated domain in `templates/`) — Template Gap Waiver, same pattern as
`postgres-migration-foundation.md` in project-8.
Architecture guides: none found under `docs/architecture-guides/` specific to
multi-repo Claude Code session telemetry — gap noted, not blocking.
Patterns: none in `patterns/` cover this — not re-consulted (no populated guidance).
External systems/connectors: GitHub (this repo itself), Claude Code (settings/hooks
runtime — verified against official docs via `claude-code-guide` subagent, see
Evidence Checked).
Skills: security-review (required before merge — this changes a privacy-sensitive
data-collection surface); superpowers:verification-before-completion (used through
the test matrix below).
Validation gates: existing `.github/workflows/telemetry-handoff-tests.yml` plus all
`scripts/enforcement/tests/test-*telemetry*.sh` (must stay green, unmodified scope);
new tests added under the same directory for this feature (see Test Plan).
Evidence to check: `scripts/monitoring/*.py`/`*.sh` (read in full this session),
`scripts/install-policy-gates.sh`, `scripts/monitoring/patch-settings-telemetry.py`,
official Claude Code settings/hooks docs (via subagent, see below),
`docs/operations/project8-telemetry-preflight.md`,
`docs/operations/managed-settings-deployment-proof.md`,
`architecture-decisions/ADR-2026-002-managed-settings-rollout.md`.
User decisions required: none outstanding — the user supplied the full approved
direction verbatim across three messages this session (scope narrowing to "rules
apply to project-8, the repo we're working on", then the complete architecture +
test matrix + documentation + PR + merge-gate spec). This plan operationalizes that
spec against the actual current codebase; it does not introduce new design choices
the user hasn't already made. Remaining open items are listed under **Open
Questions** below, each traceable to a real gap found during investigation, not a
re-litigation of an already-answered question.

### Capability Evidence

- `routing.task-router-read`: `core/task-router.md` read before this plan.
- `workflow.workflow-read`: `core/workflow.md` `<workflow>` and
  `<evidence_backed_planning>` read; this plan follows the `project`-scope Minimum
  Planning Contract.
- `source.docs-read`: official Claude Code settings/hooks behavior verified via two
  `claude-code-guide` subagent calls against current docs (not memory) — see
  Evidence Checked.
- `source.repo-read`: every script this plan proposes to touch or wrap was read in
  full this session before this plan was written (`eos-telemetry-session-start.sh`,
  `eos-telemetry-event.sh`, `record-and-sync-telemetry.sh`, `sync-telemetry-run.py`,
  `select-pr-telemetry.py`, `telemetry_handoff.py`, `require-telemetry-session.sh`,
  `patch-settings-telemetry.py`, `install-policy-gates.sh`).

## Minimum Planning Contract (Plan Scope: project)

**Project Type:** Internal developer-tooling extension to Engineering OS's existing
telemetry runtime — not a new product/service.

**User Goal:** Engineering OS's governance rules (in particular: telemetry
collection) must actually apply to projects it governs (starting with project-8),
even when the Claude Code Remote session that does the work does not start inside
that project's own directory. Today they silently don't, with no error surfaced
until a preflight check is run manually.

**Target Users/Surfaces:** Any Claude Code Remote (or local CLI) session working on
a repository that has opted into Engineering OS telemetry via
`.engineering-os/telemetry-policy.json`, when that session's working directory is
not the repository root itself (e.g. a parent directory containing multiple repo
sources, as in this session: `/home/user` containing both `Engineering-OS` and
`project-8`).

**Known Requirements:** See the exhaustive test-scenario list (A–I) under Test Plan
below — these were dictated in full by the user and are treated as the acceptance
criteria for this feature, not a suggestion.

**MVP Features:**
1. A `$HOME/.claude/settings.json` (user-level) bootstrap installer, idempotent,
   update-safe, uninstallable, that never touches non-Engineering-OS settings.
2. A repository-discovery routine (cwd-first, then immediate-subdirectory scan,
   marker = valid `.engineering-os/telemetry-policy.json`, no recursive `$HOME`
   scan, symlink-safe).
3. A per-event repository-attribution routine (explicit file path → explicit tool
   cwd → single unambiguous discovered repo → unattributed, in that order; never
   guesses).
4. Per-repository isolated telemetry state (own run_id, own events file, own
   policy, own push/handoff) — reusing the **existing, unmodified** per-repo
   scripts by invoking them with the correct working directory / env-var overrides,
   not rewriting their internals.
5. Full test coverage per the Test Plan below, including a real Claude Code Remote
   experiment (not just simulation) as a closure condition.

**Non-goals (explicit, per the user's own constraints):**
- Not a general-purpose "monitor everything on this machine" system — only
  directories with a valid Engineering-OS marker are ever touched.
- Not a rewrite of the existing push/handoff/PR-matching pipeline
  (`sync-telemetry-run.py`, `select-pr-telemetry.py`, `telemetry_handoff.py`,
  `pr-policy.yml`) — that stays as-is; this plan only changes *how many times* and
  *with what working directory* the existing per-repo entry points get invoked.
- Not `managed settings` / `/etc/claude-code` (ADR-2026-002's mechanism) — that
  requires sudo/system paths and applies to literally every session on the machine
  regardless of project; the user explicitly narrowed scope away from that to
  user-level (`$HOME/.claude/settings.json`), which needs no elevated privileges
  and still only *activates* for Engineering-OS-marked repositories.

**Architecture:**

Root cause (verified by reading the actual scripts and by an authoritative
doc-check subagent, not assumed):
- `.claude/settings.json` (where hooks live) loads **only from the session's actual
  starting directory** — it is not inherited from parent directories the way
  `CLAUDE.md` is. A session starting at `/home/user` (a plain directory, not a git
  repo, containing `Engineering-OS/` and `project-8/` as siblings) loads **neither**
  repo's `.claude/settings.json` — so none of their hooks ever fire. This is why
  `require-telemetry-session.sh` failed with "SessionStart hook did not initialize
  this session" earlier in this session (empirically reproduced, not theoretical).
- Independently, even where hooks do fire, `scripts/monitoring/eos-telemetry-event.sh`
  computes its repo root as `git rev-parse --show-toplevel 2>/dev/null || pwd` —
  the **ambient OS-level cwd of the hook subprocess**, evaluated *before* the
  script even parses the JSON payload from stdin. It never reads the payload's own
  `cwd` (or `tool_input.file_path`) field for this purpose today. Confirmed present
  in `eos-telemetry-session-start.sh`, `eos-telemetry-event.sh`, and
  `telemetry_handoff.py`'s `repo_root()` helper.

Fix, in two independent layers:

**Layer 1 — where hooks are registered.** Add a new installer,
`scripts/monitoring/install-user-level-telemetry-hooks.sh` (name chosen to mirror
`install-policy-gates.sh`'s naming; final name may change during implementation if
a clearer one emerges — not a design decision, just naming), that patches
`$HOME/.claude/settings.json` (not a project's `.claude/settings.json`) with **one**
hook per lifecycle event, each pointing at a new **dispatcher** script (Layer 2)
instead of directly at the existing per-repo scripts. Reuses
`patch-settings-telemetry.py`'s existing idempotent merge primitives
(`ensure_hook`, `find_block`, marker-based dedup) — extended to accept a target
settings path and a different command set (dispatcher, not direct scripts), not
reimplemented from scratch.

**Layer 2 — what the hooks actually do.** A new dispatcher,
`scripts/monitoring/eos-telemetry-dispatch.sh`, becomes the thing `$HOME/.claude/settings.json`
actually invokes for SessionStart/PreToolUse/PostToolUse/PostToolUseFailure/
PermissionDenied/Stop/StopFailure/SessionEnd. It does exactly one job per event:
resolve **which single repository root** (if any) this specific event belongs to,
then `cd` into that root and exec the **existing, byte-for-byte-unmodified**
per-event script (`eos-telemetry-session-start.sh`, `eos-telemetry-event.sh`, or
`record-and-sync-telemetry.sh`) exactly as `patch-settings-telemetry.py` already
wires it today for a project-local install. Because those scripts already compute
their root from `git rev-parse --show-toplevel || pwd`, cd-ing into the right
directory before calling them requires **zero changes to their internals** — this
is the minimal-surface design principle from `core/core_principles`
("בנה את הפתרון המינימלי").

Repository-discovery algorithm (used by the dispatcher on SessionStart, and as a
fallback source for attribution):
1. Is the event's own `cwd` (from the JSON payload) itself inside a git repo with a
   valid `.engineering-os/telemetry-policy.json` at its root? If yes, that's the
   repo — done, no scan needed.
2. Otherwise, list the **immediate child directories only** of that `cwd` (one
   level — never recursive, never walks into `$HOME` broadly). For each child that
   is itself a git repository root (`.git` present) **and** has a
   `.engineering-os/telemetry-policy.json` that is a regular file (not a symlink
   escaping the child's own tree — resolved via `realpath` and a prefix check
   against the child's own resolved root) and parses as valid JSON matching the
   `eos.telemetry.policy.v1` schema already enforced by `telemetry_handoff.py`'s
   `load_policy` — that child is a **managed repository**.
3. Sort discovered repos deterministically (lexicographic by resolved absolute
   path) before initializing state for each, so discovery order never depends on
   filesystem iteration order.
4. A repo discovered via step 1 and also present among step 2's siblings (e.g. cwd
   itself is a sibling from an earlier resolution) is only ever initialized once —
   dedup by resolved real path, not by name.
5. `unrelated-repo` (a git repo without the marker) and `random-folder` (not a git
   repo at all) are never touched, never listed, never opened beyond the single
   `stat`/existence check needed to rule them out.

Per-event attribution algorithm (used by the dispatcher for PreToolUse/PostToolUse/
PostToolUseFailure/PermissionDenied — the events that carry a specific tool call):
1. **Explicit file path from tool input** (`tool_input.file_path` / `.path` /
   `.pattern` for Read/Edit/Write/Glob/Grep) — normalize (resolve `.`/`..`, strip
   trailing slash) and `realpath` it (resolving symlinks); the owning repo is the
   nearest ancestor directory that is a discovered managed repo's root. A symlink
   whose real target falls outside every discovered managed repo's tree is treated
   as unmanaged, not attributed.
2. **Explicit tool/command working directory** — for Bash, the payload's top-level
   `cwd` field (this is the *tool call's* cwd per the official hooks docs, "the
   working directory when the event fired" — verified via subagent, see Evidence
   Checked; the dispatcher must use this field, not its own ambient process cwd,
   since the two are not documented as guaranteed-equal). No shell/command-text
   parsing is ever attempted to infer a `cd` inside the command string — explicitly
   forbidden by the user's spec, and correctly so: parsing shell semantics
   speculatively is unreliable and risks misattribution.
3. **Single unambiguous discovered repo** — only when exactly one managed repo was
   discovered in this session/event and neither (1) nor (2) yielded a path/cwd
   inside *any* discovered repo (e.g. a tool with no path-like input at all) does
   the dispatcher fall back to "the one repo in play." If two or more repos are
   discovered and neither (1) nor (2) disambiguates, this tier does not apply.
4. **MCP/GitHub tool with an explicit repo identifier in its arguments** (e.g.
   `owner`/`repo` params on `mcp__github__*` calls) — use that identifier directly,
   but only record local telemetry for it if it also resolves to a discovered
   managed repo; otherwise treat as unattributed (never invent a repo that wasn't
   discovered).
5. If none of the above yields a single, provable repository: the event is
   **unattributed**. It is not silently dropped — the dispatcher writes one
   minimal `unattributed_event` diagnostic record (event name, hook type, a
   truncated/hashed reason code, timestamp — no raw command, no raw path, no
   prompt) to a host-session-scoped diagnostic log
   (`$HOME/.engineering-os/telemetry/unattributed.jsonl`, new, separate from any
   per-repo `events.jsonl`), and does **not** call into any repo's recorder. This
   satisfies "no PR bundle ever receives a mis-attributed event" without silently
   losing the fact that *something* happened.
6. An action that provably touches multiple repos (rare — e.g. a single Bash
   command with two path arguments in two different discovered repos, if that ever
   becomes detectable) gets one dispatcher-assigned correlation id shared across
   per-repo records, but each repo's own recorder call is separate and only
   receives that repo's own portion — never a shared/merged event row.

**Stack:** Bash (dispatcher, installers — matches all existing telemetry runtime),
Python 3 (JSON/settings manipulation — matches `patch-settings-telemetry.py` and
`telemetry_handoff.py`'s existing style; reuse their libraries where the logic
already exists instead of re-deriving it in a second language).

**Data Model / State (per repository, unchanged from today, just multiplied):**
`repository identity` (owner/repo slug, from `git remote get-url origin` at that
repo's own root — identical to `sync-telemetry-run.py`'s existing
`detect_repo_slug`), `repository root` (absolute path), `telemetry policy` (that
repo's own `.engineering-os/telemetry-policy.json`), `run_id` / `events.jsonl`
(under that repo's own `.engineering-os/telemetry/`, exactly as today — no schema
change), `branch` / `head_sha` (computed at that repo's root), `handoff state`
(that repo's own push-state file). A **host-session correlation id** (new,
generated once per Claude Code session by the dispatcher on first invocation,
stored at `$HOME/.engineering-os/telemetry/session_correlation_id` scoped to the
*user-level* runtime, never inside any repo) is attached as an *additional*
attribute on every record the dispatcher forwards, without replacing or aliasing
any repo's own `run_id`. No shared/global run_id is ever used as a repo's `run_id`.

**Auth/Roles:** N/A — local file-system/hook runtime, no new auth surface. GitHub
push/PR-matching auth is unchanged (still whatever `sync-telemetry-run.py` uses
today).

**Integrations/Connectors:** GitHub (unchanged downstream — this repo's own PR
pipeline). Claude Code hooks/settings (the actual integration surface being
extended) — verified against official docs this session (see Evidence Checked),
not assumed.

**Environment/Deployment:** `$HOME/.claude/settings.json` is written on the
machine/environment this Engineering OS installer is run on — for this session's
Claude Code Remote environment, `$HOME=/root`. This plan does not attempt to make
the deployment persist automatically across future fresh environments/containers
(that would require environment-level provisioning outside this repo's control,
e.g. a setup script the environment owner configures) — it only fixes the
mechanism itself and documents, in Troubleshooting, that a fresh container needs
the installer re-run once (same as `install-policy-gates.sh` needs re-running per
project today).

**Evidence Checked (project-scope requirement):**
- `claude-code-guide` subagent, call 1: confirmed `.claude/settings.json` loads
  only from the session's starting directory (not inherited like `CLAUDE.md`), and
  that `$HOME/.claude/settings.json` (user-level) "applies as a baseline to all
  repos" without requiring managed/sudo deployment.
- `claude-code-guide` subagent, call 2: confirmed the hook JSON payload schema
  includes a top-level `cwd` field on every event ("the working directory when the
  event fired"), `tool_input.file_path` is absolute for Edit/Write, Bash has no
  separate cwd field beyond the top-level one, SessionStart's payload does not
  enumerate attached repository sources, and — flagged explicitly as a genuine doc
  gap, not filled with a guess — the docs do not explicitly guarantee the hook
  subprocess's own OS-level cwd equals that JSON `cwd` field. This gap is exactly
  why Test Plan section H/I and the real Remote experiment (not just unit tests)
  are required before this feature can be called proven, not just implemented.
- Direct reads of every script this plan proposes to wrap or extend (listed under
  Evidence to check above) — confirmed their exact current behavior, including the
  `EOS_TELEMETRY_FILE`/`EOS_TELEMETRY_RUN_ID_FILE`/`EOS_TELEMETRY_DIR`/
  `EOS_TELEMETRY_POLICY_FILE` env-var override points that make Layer 2's
  "cd + exec existing script unmodified" approach viable without touching them.
- `ADR-2026-002-managed-settings-rollout.md` and
  `docs/operations/managed-settings-deployment-proof.md` — confirmed a *different*,
  heavier mechanism (managed settings, `/etc/claude-code/...`, sudo-gated) already
  exists and was deliberately not chosen as the default; this plan's user-level
  approach is the intentionally narrower alternative, matching the user's explicit
  scope decision this session.

**Open Questions (real gaps, not re-litigated decisions):**
1. Exact final filenames for the two new scripts (dispatcher, user-level
   installer) — naming only, does not block implementation, will follow existing
   `eos-telemetry-*` / `install-*-hooks.sh` conventions.
2. Whether the dispatcher should be one script with an event-name argument (mirrors
   `eos-telemetry-event.sh`'s own `"${1:-unknown}"` pattern) or multiple thin
   per-event wrappers — implementation detail, default to one script + argument,
   consistent with the existing recorder's own shape, revisit only if it proves
   awkward during implementation.
3. Whether a real Claude Code Remote experiment (Test Plan section H/I closure) is
   executable *within this same session* (this session's own `$HOME` is `/root`,
   writable, so installing here and opening a **new** session afterward, as this
   session already had to do once for the project-8 preflight, is plausible) —
   or whether it requires the user to do it from their own client after merge.
   Both paths are documented in the Test Plan; whichever is actually reachable
   will be attempted, and the gap left honestly open if neither is reachable
   within this engagement, per the user's own explicit instruction not to claim
   an unproven Remote experiment as done.

**Validation Plan:** See Test Plan (scenarios A–I) below — this is the full
validation plan for `project` scope, not a separate abbreviated one.

## User Approval

**Status: pending.** Per `core/workflow.md` › `<evidence_backed_planning>`, no code
is written until the user replies with explicit approval (e.g. "מאושר") to this
plan, quoted/dated in this thread. The architecture above is the user's own
verbatim specification (three messages this session), cross-checked against the
actual codebase and official docs by this session — this plan does not introduce
new design choices beyond what the user already decided; approval here confirms
"yes, proceed to implementation of exactly this," not a fresh design review.

---

## Failure modes (design-time enumeration, informs Test Plan section I)

| Failure | Handling |
|---|---|
| `$HOME/.claude/settings.json` missing | Installer creates it with valid minimal JSON — no sudo. |
| Existing user settings present | Preserved verbatim except the Engineering-OS-owned hook entries (marker-based, reusing `patch-settings-telemetry.py`'s existing dedup marker convention). |
| Malformed existing JSON | Installer refuses to silently overwrite; prints a clear error, writes a timestamped backup before any repair attempt, never leaves a partial file (atomic temp-file + validate + rename, matching the pattern already used by `sync-telemetry-run.py`'s `atomic_write_json`). |
| Re-running installer | Idempotent — no duplicate hook entries, no duplicate commands (reuses existing marker-based `find_block`/`ensure_hook`). |
| Version update of the dispatcher command | Existing Engineering-OS-owned entry is replaced in place, old and new never coexist. |
| Uninstall | Removes only Engineering-OS-owned marker entries; if nothing Engineering-OS-owned remains, the file itself is left alone (never deletes a user-created file). |
| Marker (`telemetry-policy.json`) is a symlink escaping its repo | Not treated as a valid marker — discovery skips it. |
| Marker present but not inside an actual git repo root | Not treated as managed — discovery requires both. |
| Nested repos / git worktrees / submodules | Out of scope for auto-discovery beyond the documented one-level sibling scan; a nested/worktree repo one level down with a valid marker is discovered like any other sibling; deeper nesting is not scanned (matches "no recursive scan" requirement) — documented explicitly, not silently unhandled. |
| Detached HEAD / no remote / multiple remotes | `branch`/`head_sha`/`repo slug` resolution reuses existing `sync-telemetry-run.py` logic unchanged — whatever it already does for these cases today is inherited, not redesigned here. |
| Event arrives before SessionStart discovery completes | Dispatcher runs discovery synchronously and cheaply (one `ls` per candidate) on first invocation of *any* event type within a session if no discovery-result cache exists yet for this session's correlation id — not solely gated on SessionStart having literally fired first. |
| SessionStart fires twice | Discovery/initialization is idempotent per repo (same guard the existing `eos-telemetry-session-start.sh` already has via its run-history archiving). |
| Stop/SessionEnd with no prior state | No-ops per repo with no state, exactly as today's scripts already do when their files are absent. |
| Repo becomes inaccessible mid-session | That repo's events stop being recordable (attribution tier 1–3 simply won't resolve to it); no crash, no effect on other repos' state. |
| No permission to read policy / write telemetry state | Fails soft for that one repo (matches existing recorder's fail-soft philosophy for PostToolUse recorders per `hooks-policy.md`'s hard/advisory/recorder/lifecycle classification) — never blocks an unrelated research tool call. |
| Concurrent events for two repos | Each dispatcher invocation is a fresh short-lived process writing only to its resolved repo's own files — no shared mutable state between them beyond the append-only per-repo `events.jsonl`, which already handles concurrent appends today. |
| Path traversal / symlink traversal in tool input | Always `realpath`-resolved and prefix-checked against discovered repo roots before attribution — never attributed on the raw string. |
| Malformed hook payload | Dispatcher fails closed for hard-classified hooks (matches `pre-tool-use-json-guard.sh` philosophy already documented in `hooks-policy.md`), fails soft (no false evidence) for recorder-classified ones — do not invent new fail-open behavior. |

## Test Plan (scenarios A–I, as specified)

New tests live under `scripts/enforcement/tests/`, matching the existing
`test-*telemetry*.sh` naming and harness. Each scenario below is a pass/fail
contract, not prose to summarize away:

- **A. In-repo session (regression baseline):** existing single-repo behavior is
  provably unchanged — all existing `test-*telemetry*.sh` continue passing.
- **B. Discovery from a parent directory:** fixture tree
  (`Engineering-OS/`, `project-8/`, `unrelated-repo/`, `random-folder/`) proves:
  only marker-valid repos are discovered; unrelated/random are never touched;
  scan is one level, not recursive; no double-registration; symlink escapes are
  rejected; discovery order is deterministic.
- **C. User-level settings lifecycle:** no-file / existing-user-settings /
  re-run / version-update / uninstall / malformed-JSON / atomicity / dry-run /
  verify / path-safety — each as its own test, per the exact criteria the user
  specified (no sudo, no data loss, no duplicates, clear errors, backups, atomic
  writes, absolute paths, safe handling of spaces/special chars).
- **D. Per-repository event attribution:** Read/Edit/Write/Glob/Grep path
  resolution, Bash cwd-based attribution, unattributed-by-default for ambiguous
  Bash, absolute paths outside any managed repo never attributed to a nearby one,
  relative-path resolution against the correct tool cwd (never "last seen repo"),
  path normalization/`..`/trailing-slash/spaces, symlink realpath resolution,
  MCP/GitHub explicit-repo-argument handling, multi-repo-touching actions never
  collapsed into one repo, unattributed events excluded from every repo's bundle
  and containing no raw sensitive content.
- **E. Multi-repository session isolation:** separate full state per repo (identity,
  root, policy, branch, head SHA, run ID, event file, bundle, handoff state); shared
  host correlation id present but never substituted for a repo's own run ID;
  cross-repo event leakage in either direction is a hard failure; one repo's
  stop/failure never deletes another's state; disabled-policy repo gets no bundle
  even when a sibling repo is `required`; no single shared state file gets
  overwritten across repos; concurrent/out-of-order hook firing never mixes events.
- **F. Policy isolation:** `required`/`best_effort`/`disabled`/unmanaged all behave
  per-repo exactly as today's single-repo policy semantics already define, with no
  policy leaking into a "global default" for sibling repos in the same session.
- **G. Downstream compatibility:** manifest format, remote handoff, branch/head-SHA
  matching, PR-number matching, `select-pr-telemetry.py` bundle selection, and every
  existing `test-*telemetry*.sh` / `pr-policy`-adjacent test continue passing
  unmodified in scope; a project-8 bundle can never satisfy an Engineering-OS PR
  match or vice versa; repo identity is checked before any push/selection.
- **H. Remote-like smoke test (simulation, explicitly labeled as such — not proof
  of a real Remote host):** the exact fixture the user specified (`$HOME/.claude/settings.json`
  with the bootstrap, session cwd `/home/user`, `project-8` with a valid marker,
  `unrelated-repo` without one) proves SessionStart discovers only `project-8`, an
  in-repo tool event lands in `project-8`'s state only, the unrelated repo collects
  nothing, and the resulting bundle is structurally acceptable to the existing
  PR-matching mechanism. Documented explicitly in the test's own output/comments as
  a simulation, not a live-host proof.
- **I. Regression/failure tests:** the full negative list the user specified (missing
  settings, corrupt JSON, missing runtime path, corrupt/misplaced marker, duplicate
  discovery, nested repos/worktrees/submodules, detached HEAD, remote-less/multi-remote
  repos, branch/head-SHA changing mid-session, out-of-order events, double
  SessionStart, Stop/SessionEnd with no state, repo disappearing mid-session,
  permission failures on read/write, concurrent multi-repo events, path/symlink
  traversal, malformed payloads, and confirming no raw sensitive content ever
  appears in any diagnostic).

**Real Claude Code Remote experiment (closure condition, not optional):** after the
simulation suite is green, install the user-level bootstrap in an actual Claude Code
Remote environment, open a genuinely fresh session starting outside any repo, and
observe: SessionStart fires, `project-8` is discovered, an unmanaged sibling is not,
a real tool event in `project-8` lands in its bundle, branch/head SHA are correct,
and PR-matching selects the right PR. If this cannot be executed within this
engagement, the gap is left explicitly open/blocked in the PR and in
`docs/operations/known-gaps.tsv` — never marked closed on simulation alone. A short
runbook for the user to run this experiment themselves is provided either way.

## Documentation updates required

- New `docs/operations/` runbook (installation, discovery scope, attribution rules,
  multi-repo session model, privacy statement, troubleshooting table) — mirrors the
  structure already used by `docs/operations/project8-telemetry-preflight.md` and
  `docs/operations/managed-settings-deployment-proof.md`.
- `docs/operations/known-gaps.tsv` and `docs/operations/operational-readiness-audit.md`
  updated to reflect this feature's real status (including the Remote-experiment gap
  if it remains open).
- This plan file itself stays as the Route Plan / Claude Run Trace record until merge.

## Definition of Done

- [ ] User Approval recorded above (blocks all items below).
- [ ] Dispatcher + user-level installer implemented, existing per-repo scripts
      byte-for-byte unmodified.
- [ ] Test scenarios A–I all green.
- [ ] Existing telemetry/handoff/PR-matching tests remain green, unmodified scope.
- [ ] `security-review` skill run against the full diff (privacy-sensitive surface).
- [ ] Documentation + `known-gaps.tsv` + `operational-readiness-audit.md` updated.
- [ ] PR opened ready-for-review (not draft) with full evidence sections per the
      user's spec (root cause, doc references, discovery/attribution/state models,
      privacy impact, install/update/uninstall behavior, migration, tests run,
      simulation result, real-Remote-experiment result or explicit gap, known
      limitations, Merge Readiness with exact head SHA).
- [ ] All CI green on the exact same head SHA; CodeRabbit review addressed (or
      documented structured fallback if unavailable); no unresolved review threads.
- [ ] Real Claude Code Remote experiment executed and evidence recorded, OR gap
      explicitly left open/blocked with a runbook for the user to run it.
- [ ] Explicit user approval to merge (separate from the User Approval above — this
      is the merge-time approval per `core/git-policy.md`).
