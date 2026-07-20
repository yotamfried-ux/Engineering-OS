# Remote / multi-repository telemetry hooks

This runbook documents the user-level Claude Code hook bootstrap added for
sessions that begin outside a single managed repository, such as a Remote
session rooted at `/home/user` with `project-8/` and `Engineering-OS/` as
siblings.

The design and evidence history live in
`.claude/plans/remote-multirepo-telemetry-hooks.md` and PR #250.

## Why this exists

Project-local `.claude/settings.json` hooks are not sufficient when the session
starts from a parent directory. User-level settings at
`$HOME/.claude/settings.json` are therefore used as a bootstrap that is available
to the session regardless of which managed child repository is touched.

This is **not general machine monitoring**. The bootstrap activates repository
telemetry only for Git repositories with a valid
`.engineering-os/telemetry-policy.json` marker.

## Installation

Set the canonical Engineering OS checkout, then install:

```bash
export ENGINEERING_OS_HOME=/absolute/path/to/Engineering-OS
bash "$ENGINEERING_OS_HOME/scripts/monitoring/install-user-level-telemetry-hooks.sh"
```

Lifecycle commands:

```bash
# Show the proposed change without writing.
bash "$ENGINEERING_OS_HOME/scripts/monitoring/install-user-level-telemetry-hooks.sh" --dry-run

# Verify the exact installed commands, mode, and runtime path.
bash "$ENGINEERING_OS_HOME/scripts/monitoring/install-user-level-telemetry-hooks.sh" --verify

# Remove only Engineering-OS-owned entries.
bash "$ENGINEERING_OS_HOME/scripts/monitoring/install-user-level-telemetry-hooks.sh" --uninstall
```

The installer:

- requires no sudo;
- preserves unrelated user settings and hooks;
- uses absolute runtime paths;
- replaces stale owned commands instead of duplicating them;
- writes a timestamped backup before changing an existing valid file;
- validates JSON and replaces the file atomically;
- refuses to overwrite malformed JSON silently;
- leaves the settings file in place during uninstall.

Install the bootstrap **before opening the validation session**. Installing it
mid-session can make hooks load, but cannot retroactively create the real
SessionStart evidence required by the managed repository guard.

## Discovery scope

For each session/event, the dispatcher uses this bounded discovery contract:

1. When the event cwd is inside a managed Git repository, that repository is a
   candidate.
2. Otherwise, only immediate child directories of the event cwd are inspected.
3. A child is managed only when it is its own Git root and contains a valid,
   regular, non-escaping `.engineering-os/telemetry-policy.json` file.
4. Results are resolved, deduplicated, sorted, and cached per Claude session.
5. There is no recursive home-directory scan.

Repositories without the marker, malformed markers, non-Git folders, and
symlink escapes are outside the telemetry scope.

## Project-local and user-level hook coexistence

Claude Code can merge hooks from multiple settings scopes. Running both a direct
project-local telemetry hook and the user-level dispatcher for the same native
repository would double-count events.

The dispatcher therefore suppresses a direct project-local installation only
when all of the following are true:

- the current event is the actual `SessionStart`;
- the SessionStart cwd is inside that repository;
- the repository's project settings contain Engineering-OS direct hooks.

This distinction is important:

- **Session starts inside the repo:** direct project hooks are active, so the
  dispatcher skips that native repo.
- **Session starts from the parent:** sibling project settings may exist on disk
  but are not active for that session, so the dispatcher must still initialize
  those managed siblings.
- **User-level hooks appear after SessionStart:** a later event cache miss must
  not treat on-disk project settings as proof that direct hooks were active.

This behavior is regression-tested by
`test-dispatch-project-local-coexistence.sh`.

## Event attribution

A tool event is attributed using evidence, in this order:

1. Explicit path-like tool input such as `file_path`, `path`, or `pattern`, after
   normalization and realpath resolution.
2. The hook payload's cwd.
3. An explicit GitHub/MCP repository identifier such as
   `repository_full_name` or `owner` + `repo`, matched to the real `origin` slug
   of a discovered managed repository.
4. The sole discovered repository only when the payload contains **no routing
   signal at all**.

An explicit path, cwd, or repository identifier outside the managed set is
negative evidence. It does not fall through to the sole managed repository.
This prevents an unrelated operation from inheriting `project-8` merely because
`project-8` is the only managed sibling.

When attribution is not safe, the event is `unattributed`. The host diagnostic
contains only event type, host correlation id, and timestamp. It contains no raw
command, raw path, prompt, response, file content, or full tool payload, and it
never enters a repository telemetry bundle.

## Repository-scoped PreToolUse guard

Dispatcher-mode settings route the hard guard through:

```text
eos-telemetry-dispatch.sh guard
```

The dispatcher resolves the current event first:

- attributed managed repository → run the existing
  `require-telemetry-session.sh` from that repository root and preserve its
  fail-closed exit status;
- unmanaged or unattributed event → do not run another repository's guard and do
  not block the operation.

This preserves the safety requirement inside managed work without turning a
user-level hook into a global session blocker.

## Multi-repository state

Each managed repository receives its own existing telemetry runtime:

- `run_id`;
- `events.jsonl`;
- telemetry policy;
- branch and head SHA;
- handoff/push state;
- bundle and PR matching.

The dispatcher changes into the resolved root and delegates to the existing
SessionStart, event, guard, or boundary script. It does not merge repository
state or redesign the downstream pipeline.

A host-session correlation id is shared across repositories as an additive
attribute. It never replaces a repository run id.

## Policy isolation

Each repository's policy is evaluated independently:

- `required` keeps its existing fail-closed semantics after attribution;
- `best_effort` records warnings without becoming another repository's policy;
- `disabled` produces no required handoff;
- an unmanaged repository is outside scope rather than treated as a policy mode.

## Privacy and security

The dispatcher retains the existing metadata-only contract:

- no raw prompts, responses, file contents, commands, tool payloads, environment
  values, or secrets are stored;
- no unmanaged repository gets a telemetry directory from discovery;
- no recursive filesystem observer is introduced;
- paths and marker files are resolved before repository-boundary checks;
- explicit outside-repository evidence cannot be overwritten by a default;
- resolver failures are recorded as a diagnostic type, exit status, timestamp,
  and hash of the diagnostic rather than raw payload or stderr.

Dispatch-session cache files are pruned on SessionStart after a bounded retention
period. The default is 30 days and can be adjusted with
`EOS_DISPATCH_CACHE_MAX_AGE_SECONDS`.

## Troubleshooting

| Symptom | Meaning | Action |
|---|---|---|
| Installer cannot find Engineering OS | `ENGINEERING_OS_HOME` is missing or stale | Point it at the canonical checkout and rerun. |
| `--verify` reports a stale owned hook | The checkout moved or settings contain an old command | Run the normal installer, then verify again. |
| Managed-repo guard says no matching SessionStart | Hooks were installed after the current session started, or SessionStart failed | Open a genuinely fresh session after installation. Do not bypass the guard. |
| An unrelated event is blocked by a managed repository | Repository-scoped guard attribution regressed | Stop and report the payload category and diagnostic metadata; do not continue the experiment. |
| Managed sibling with project settings gets no parent-session telemetry | It may have been wrongly treated as an active native direct install | Run the coexistence test and inspect SessionStart discovery. |
| Event appears in `unattributed.jsonl` | No single repository could be proven | Expected for genuine ambiguity or explicit outside-repository activity. |
| Event for a GitHub tool is unattributed | Repository identifier or origin slug did not match a discovered managed repo | Verify `repository_full_name`/`owner`+`repo` and the repository origin. |
| Resolver failure appears in `dispatch-errors.jsonl` | Discovery/attribution runtime failed, distinct from ordinary ambiguity | Inspect the hashed failure context and rerun the focused dispatcher tests. |
| Settings JSON is malformed | Installer correctly refused destructive repair | Restore or repair the JSON manually, then rerun. |

## Validation status

Automated fixtures cover installer lifecycle, managed-only discovery,
project-local coexistence, explicit path/cwd/GitHub attribution, outside-path
rejection, repository-scoped guard behavior, policy isolation, per-repository
state isolation, failure handling, downstream handoff, and cross-repository PR
matching.

A real Claude Code Remote attempt also proved that:

- the installer can patch the real user settings;
- `--verify` can validate that installation;
- hooks can become visible dynamically in an existing Remote session;
- an on-disk project-settings assumption caused a real zero-event failure;
- installing after SessionStart correctly triggers the existing restart guard;
- the old sole-repository fallback could incorrectly extend that guard to an
  unrelated operation and deadlock the session.

Those defects are fixed and covered by regression tests. The attempt was real,
but it was **not** a successful end-to-end closure run because it necessarily
ended with a required restart.

`multirepo-remote-telemetry-validation` therefore remains open until a fresh
post-install session proves all of the following:

1. SessionStart initializes the intended managed repositories.
2. A safe managed-repository Read is recorded under the correct repository.
3. A safe unmanaged/outside Read is neither blocked nor attributed.
4. Repository run ids remain separate and host correlation is shared.
5. An unmanaged sibling receives no telemetry directory.
6. Session completion produces a non-empty bundle for the correct repository.
7. Branch/head/repository identity match the intended PR and cannot satisfy a PR
   in another repository.
8. Diagnostics contain no prohibited raw data.

The next experiment must begin in a **new Claude Code Remote session created
after the merged code and user-level installation are present**.
