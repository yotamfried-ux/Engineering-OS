# Remote multi-repository telemetry hooks

This runbook covers Claude Code Remote sessions that start above one or more repositories. The design and evidence history are in `.claude/plans/remote-multirepo-telemetry-hooks.md` and PR #250.

## Scope

The user-level `$HOME/.claude/settings.json` contains a dispatcher because project-local settings are not active when a session starts from a parent directory. The dispatcher is not general machine monitoring: only Git roots with a valid `.engineering-os/telemetry-policy.json` marker participate.

## Installation lifecycle

Use `scripts/monitoring/install-user-level-telemetry-hooks.sh` with the canonical `ENGINEERING_OS_HOME`. The installer needs no sudo, preserves unrelated settings, backs up valid JSON, writes atomically, refuses malformed JSON, supports dry-run and verification, and removes only Engineering-OS-owned entries during uninstall.

When converting from direct mode to dispatcher mode, the patcher removes all old Engineering OS hooks first, including the direct SessionStart entry. Install and verify before opening the validation session; mid-session installation cannot recreate the missing initial SessionStart evidence.

## Discovery

1. Check whether event cwd is inside a managed Git repository.
2. Otherwise inspect immediate child directories only.
3. Require each candidate to be its own Git root with a valid, regular, non-escaping policy marker.
4. Resolve, deduplicate, and sort real paths.
5. Never recursively scan the home directory.

A direct project hook is suppressed only for the native repository of an actual in-repository SessionStart. Settings that merely exist in a parent-session sibling do not prove those hooks are active.

## Attribution

All explicit targets are authoritative and must agree:

1. Actual path fields such as `file_path` and `path`, after realpath resolution. Search expressions such as `Grep.pattern` are not paths.
2. Explicit GitHub or MCP repository identity matched to a discovered repository's `origin` slug.
3. Payload cwd only when no explicit target exists.
4. Sole-repository fallback only when no routing signal exists.

Multiple paths must resolve to the same managed repository. Filesystem and repository targets must also agree. Invalid, malformed, unmanaged, or conflicting explicit targets remain unattributed; cwd cannot override them.

Unattributed events never enter repository bundles. Their diagnostic contains only event type, host correlation ID, and timestamp.

## Repository-scoped guard

User-level PreToolUse enforcement runs through `eos-telemetry-dispatch.sh guard`. The dispatcher proves the repository before invoking `require-telemetry-session.sh`.

For an attributed managed repository, the guard receives dispatcher mode and the active user settings path. It validates SessionStart under `hooks.SessionStart`, guard and recorder under `hooks.PreToolUse`, and boundary commands under Stop, StopFailure, and SessionEnd. Marker-only managed repositories therefore do not require project-local settings.

Unmanaged or unattributed activity does not inherit another repository's guard.

## Isolation and lifecycle boundaries

Every managed repository keeps separate run ID, events, policy, branch/head, handoff state, bundle, and PR matching. Host correlation is additive only.

Required, best-effort, and disabled policies remain repository-local. Stop, StopFailure, and SessionEnd visit every discovered repository, then return failure if any required durable handoff failed. A failure is not hidden and does not prevent sibling boundary recording.

## Privacy and retention

The dispatcher retains the metadata-only contract: no conversation text, file contents, complete commands, complete tool inputs, environment dumps, or credentials are stored. Paths and markers are resolved before boundary checks. Resolver failures use separate hashed diagnostics. Session caches are pruned during SessionStart after a bounded retention period.

## Validation status

Automated tests cover installation and mode migration, managed-only discovery, direct-hook coexistence, path and repository attribution, Grep path handling, malformed/conflicting targets, marker-only guard behavior, hook-event placement, policy and boundary isolation, failure handling, downstream handoff, and cross-repository PR matching.

A real Remote attempt proved installation, verification, dynamic loading, and two failure paths. It was not a successful closure run because installation occurred after the session began and a restart was required.

The open `multirepo-remote-telemetry-validation` gap requires a fresh post-install session to prove:

1. managed repositories initialize at SessionStart;
2. managed activity records under the correct repository;
3. outside activity is neither blocked nor attributed, including with a managed cwd;
4. marker-only guard validation succeeds after SessionStart;
5. run IDs remain separate and host correlation is shared;
6. unmanaged siblings receive no telemetry state;
7. session completion creates the correct non-empty bundle and surfaces required handoff failures;
8. repository, branch, head, and PR matching cannot cross repository boundaries;
9. diagnostics satisfy the metadata-only contract.

The next experiment must start in a new Claude Code Remote session created after the merged code and user-level installation are present.
