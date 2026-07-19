# Remote / multi-repo telemetry hooks

This runbook documents the user-level telemetry bootstrap and multi-repository
dispatch mechanism added to fix a real, reproduced failure: a Claude Code
Remote session whose working directory is not inside any single managed
repository never loads that repository's own `.claude/settings.json` — so its
hooks (including the mandatory telemetry SessionStart hook) never fire at all.
Full design rationale, root cause, and the test matrix live in
`.claude/plans/remote-multirepo-telemetry-hooks.md` (local, not committed —
see that repo's own `.claude/plans/` convention); this file is the durable,
committed operational record.

## Why this exists

Confirmed this session, empirically and against official Claude Code docs
(not assumed):

- `.claude/settings.json` (where hooks live) loads only from the session's
  actual starting directory — unlike `CLAUDE.md`, it is not inherited from
  parent directories.
- A session starting at a directory that merely *contains* managed
  repositories as siblings (e.g. `/home/user/Engineering-OS`,
  `/home/user/project-8`) loads neither repository's project-local settings,
  so neither repository's hooks — telemetry or otherwise — ever fire.
- User-level settings (`$HOME/.claude/settings.json`) apply as a baseline to
  every session for that user, regardless of the session's starting
  directory. This is the mechanism this feature uses.

## Installation

Project-local settings (`install-policy-gates.sh`, unchanged) remain the
right choice whenever a session reliably starts inside the target repository
— nothing about this feature changes that path.

The user-level bootstrap is a separate, additive install for when it doesn't:

```bash
export ENGINEERING_OS_HOME=/absolute/path/to/Engineering-OS
bash "$ENGINEERING_OS_HOME/scripts/monitoring/install-user-level-telemetry-hooks.sh"
```

This writes (or safely merges into) `$HOME/.claude/settings.json`, pointing
Engineering-OS-owned hook entries at `scripts/monitoring/eos-telemetry-dispatch.sh`
instead of directly at the per-repo scripts. No `sudo` is required — this is
a plain user-owned file, not the OS-level "managed settings" mechanism
(`ADR-2026-002-managed-settings-rollout.md` covers that separate, heavier,
sudo-gated path; it was deliberately not used here).

**This does not turn on machine-wide monitoring.** The dispatcher only ever
touches a directory that is itself a git repository with a valid
`.engineering-os/telemetry-policy.json` at its root — see Discovery scope
below. A session working only in repositories without that marker collects
nothing, no matter how many directories it touches.

Lifecycle commands:

```bash
# Preview changes without writing anything:
bash "$ENGINEERING_OS_HOME/scripts/monitoring/install-user-level-telemetry-hooks.sh" --dry-run

# Confirm the currently-installed hooks are complete and non-duplicated:
bash "$ENGINEERING_OS_HOME/scripts/monitoring/install-user-level-telemetry-hooks.sh" --verify

# Remove only the Engineering-OS-owned entries, leaving any other user hooks
# and settings untouched, and never deleting the file itself:
bash "$ENGINEERING_OS_HOME/scripts/monitoring/install-user-level-telemetry-hooks.sh" --uninstall
```

Re-running the plain install command is always safe: it is idempotent (no
duplicate hooks, no-op when already current) and writes a
`$HOME/.claude/settings.json.backup.<timestamp>` before any in-place change to
an existing file. Writes are atomic (temp file, JSON-validated, then renamed
over the original) — an interrupted run never leaves a corrupted settings
file.

**A repo that already has its own working project-local hooks does not need,
and must not receive, the user-level dispatcher's help for that repo.**
Claude Code merges hooks across scopes rather than overriding — see
Multi-repo sessions below for why this matters and how it's handled.

## Discovery scope

On `SessionStart` (and re-checked, from cache, on every other dispatched
event), the dispatcher decides which repositories are "managed" for this
session:

1. If the event's own working directory is itself inside a git repository
   with a valid marker, that is the only managed repository — no further scan.
2. Otherwise, list the **immediate child directories only** of that working
   directory (never a recursive walk of `$HOME`) and keep the ones that are
   themselves git repository roots with a valid marker.

A repository is "managed" only if `.engineering-os/telemetry-policy.json`:

- is a **regular file**, not a symlink whose real target escapes the
  repository's own resolved directory tree;
- parses as valid JSON matching the existing `eos.telemetry.policy.v1` schema
  (the same validation `telemetry_handoff.load_policy` already enforces for
  single-repo installs — not a new, separate schema).

Discovery results are deduplicated by resolved real path and sorted
deterministically, so re-scanning never depends on filesystem iteration
order. A repository without the marker (or with a malformed one) is invisible
to this mechanism — never scanned deeper, never touched.

## Attribution

For an individual tool-call event (`PreToolUse`, `PostToolUse`,
`PostToolUseFailure`, `PermissionDenied`), the dispatcher decides which single
managed repository, if any, that specific event belongs to, in this order:

1. An explicit file path in the tool's own input (`file_path`/`path`/`pattern`
   for Read/Edit/Write/Glob/Grep), normalized and resolved to its real path
   (symlinks included) before matching against a discovered repository's root.
2. The event's own working-directory field (used for Bash, which has no
   separate path field of its own) — never inferred by parsing the shell
   command text.
3. The single managed repository discovered this session, but only when
   neither (1) nor (2) yielded any in-repo signal at all (e.g. a tool with no
   path-like input).

If none of these resolves to exactly one repository, the event is
**unattributed** — never guessed, never assigned to "the last repo seen."  An
unattributed event is recorded only as a minimal diagnostic line (event name,
host correlation id, timestamp — no raw command, no raw path, no prompt) at
`$HOME/.engineering-os/telemetry/unattributed.jsonl`, and is never written
into any repository's own `events.jsonl`, so it can never end up in a PR's
telemetry bundle.

## Multi-repo sessions

Each discovered managed repository gets its own fully independent state —
its own `run_id`, `events.jsonl`, telemetry policy, branch/head tracking, and
remote handoff/push — by the dispatcher simply `cd`-ing into that
repository's root and invoking the existing, unmodified per-repo scripts
(`eos-telemetry-session-start.sh`, `eos-telemetry-event.sh`,
`record-and-sync-telemetry.sh`). None of that existing pipeline was changed;
the dispatcher only decides *where* to point it.

All repositories touched in one session share a single **host session
correlation id** (`eos.session.host_correlation_id` on every recorded event),
generated once and cached for that session — this lets analysis join events
across repositories that were worked on together, without ever replacing or
aliasing any repository's own independent `run_id`.

**A repository that already has its own working project-local
`.claude/settings.json` (Engineering-OS-owned hooks installed the "direct"
way) is deliberately excluded from dispatcher-side recording.** Claude Code
merges hooks across settings scopes rather than overriding one with the
other (confirmed against official docs) — a session starting inside such a
repository would fire that repository's own hooks directly *and* the
dispatcher would also resolve to the same repository, double-recording every
event. `telemetry_repo_discovery.has_conflicting_project_local_hooks()`
detects this and skips the repository entirely from the dispatcher's side.
This is a deliberate, conservative trade-off: a repository with its own
project-local install but a session that did *not* actually start inside it
gets zero dispatcher-side telemetry too, rather than risk a double count.
Tracked as `dispatch-scope-double-record` in `known-gaps.tsv`.

## Privacy

The dispatcher and its discovery/attribution logic collect no more than the
existing single-repo recorder already did — this feature does not introduce
a new privacy surface, it only decides which repository's copy of the
*existing* recorder to invoke:

- No raw prompts, conversation content, tool payloads, file contents,
  commands, or environment values are ever written to any telemetry file —
  same metadata-only contract `eos-telemetry-event.sh` already enforced.
- No repository without a valid `.engineering-os/telemetry-policy.json`
  marker is ever recorded, scanned recursively, or otherwise observed beyond
  the one-level existence/marker check needed to exclude it.
- `$HOME` itself is never recursively scanned — only immediate children of
  the session's own working directory.
- Symlinks that would escape a repository's own resolved boundary (for a
  marker file or for tool-input path attribution) are never followed for
  attribution or discovery purposes.
- Each repository's own `.engineering-os/telemetry-policy.json` — including
  `disabled` mode — is respected independently; one repository's policy
  never becomes an implicit default for a sibling repository in the same
  session.

## Troubleshooting

| Symptom | Likely cause | Action |
|---|---|---|
| No telemetry from any repo in a Remote session | User-level hooks not installed on this machine/environment | Run the installer; `--verify` to confirm. |
| One managed repo gets no dispatcher telemetry despite being touched | It already has its own project-local hooks installed | Expected — see Multi-repo sessions above; that repo's own project-local install is the source of truth for it. |
| A repo with a valid marker is never discovered | Session's working directory isn't the repo itself and isn't its immediate parent | Discovery is one level only by design; a session two or more directories away from the repo won't find it. |
| Events showing up in `unattributed.jsonl` | A tool call had no resolvable path/cwd signal and more than one repo was in play | Expected for genuinely ambiguous events (e.g. a bare `ls` from a multi-repo parent directory) — not a bug. |
| `--verify` reports missing/duplicate owned hooks | Settings file edited by hand, or partially migrated from an older patcher version | Re-run the plain install command; it repairs in place. |
| Installer refuses with a JSON error | `$HOME/.claude/settings.json` is malformed | Fix or restore it manually first — the installer never overwrites malformed JSON silently, by design. |
| Two repos appear to double-record the same event | The double-recording guard (`has_conflicting_project_local_hooks`) somehow didn't trigger | This would be a real regression — see `test-dispatch-project-local-coexistence.sh`; report it, do not work around it locally. |

## What is not yet proven

Everything above is verified against simulated fixtures in
`scripts/enforcement/tests/test-multirepo-dispatch.sh`,
`test-dispatch-project-local-coexistence.sh`,
`test-dispatch-policy-isolation.sh`,
`test-dispatch-downstream-pr-matching.sh`, and
`test-dispatch-failure-modes.sh` — all green, no regression to the 12
pre-existing telemetry tests. **A real Claude Code Remote session has not yet
exercised this mechanism.** The official hooks documentation does not
explicitly guarantee that a hook subprocess's own OS-level working directory
equals the JSON payload's `cwd` field, which the dispatcher's attribution
depends on — this is a real, flagged doc gap, not an assumption presented as
fact. Tracked as `multirepo-remote-telemetry-validation` in
`known-gaps.tsv`, open until a real session run confirms: SessionStart fires
from the user-level install, only genuinely managed sibling repositories are
discovered, an unmanaged sibling collects nothing, a real tool event in a
managed repository lands in that repository's own bundle, and PR-matching
selects the correct PR from a non-empty bundle.

### Runbook for the real-Remote-experiment closure

1. Install the user-level bootstrap in the target Claude Code Remote
   environment (see Installation above).
2. Open a fresh session whose working directory is a parent of at least one
   managed repository and one unmanaged one.
3. Perform a safe `Read` inside the managed repository, and a safe `Read`
   inside the unmanaged one.
4. End the session normally.
5. Verify: the managed repository's `.engineering-os/telemetry/events.jsonl`
   contains the `Read` event; the unmanaged repository has no
   `.engineering-os/telemetry/` directory at all; the exported/pushed bundle
   matches the expected repository, branch, and head SHA; PR-matching (if a
   PR exists) selects that exact bundle.
6. Record the evidence (event types, repository identity, run ids,
   timestamps, branch/head SHA, bundle manifest, matching result — never raw
   file contents or prompts) in the PR, and update
   `multirepo-remote-telemetry-validation`'s status in `known-gaps.tsv`
   accordingly.
