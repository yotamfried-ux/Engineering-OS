# Remote multi-repository telemetry hooks

This runbook covers Claude Code Remote sessions that start above one or more repositories. The design and evidence history are in `.claude/plans/remote-multirepo-telemetry-hooks.md` and PR #250.

## Scope

The user-level `$HOME/.claude/settings.json` contains a dispatcher because project-local settings are not active when a session starts from a parent directory. The dispatcher is not general machine monitoring: only Git roots with a currently valid `.engineering-os/telemetry-policy.json` marker participate.

## Installation lifecycle

Use `scripts/monitoring/install-user-level-telemetry-hooks.sh` with the canonical `ENGINEERING_OS_HOME`. The installer needs no sudo, preserves unrelated settings, backs up valid JSON, writes atomically, refuses malformed JSON, supports dry-run and exact verification, and removes only Engineering-OS-owned entries during uninstall.

A newly created settings file is mode `0600`; an existing file retains its current mode during atomic replacement. Ownership requires an Engineering OS runtime command plus the expected action, so an unrelated user hook such as `post_tool_use-notify.sh` is preserved.

When converting from direct mode to dispatcher mode, the patcher removes all old Engineering OS hooks first, including the direct SessionStart entry. Install and verify before opening the validation session; mid-session installation cannot recreate the missing initial SessionStart evidence.

## Discovery

1. Check whether event cwd is inside a managed Git repository.
2. Otherwise inspect immediate child directories only.
3. Require each candidate to be its own Git root with a valid, regular, non-escaping policy marker.
4. Resolve, deduplicate, and sort real paths.
5. Never recursively scan the home directory.

A direct project installation is suppressed only for the native repository of an actual in-repository SessionStart **and only when the complete direct hook set is present under the expected events**: SessionStart, catch-all PreToolUse guard and recorder, and Stop/StopFailure/SessionEnd boundaries. Partial or stale project settings remain dispatchable so missing enforcement is supplied by the user-level bootstrap. Settings that merely exist in a parent-session sibling do not prove those hooks are active.

Cached repository paths are revalidated before every later event and lifecycle fan-out. Removing, corrupting, or escaping the policy marker ends attribution and enforcement immediately and rewrites the cache without that repository.

## Attribution

All explicit targets are authoritative and must agree:

1. Actual path fields such as `file_path` and `path`, after realpath resolution. Search expressions such as `Grep.pattern` are not paths.
2. Explicit GitHub or MCP repository identity matched to a discovered repository's `origin` slug.
3. Payload cwd only when no explicit target exists.
4. Sole-repository fallback only when no routing signal exists.

Repository identities must resolve to an exact two-component `owner/repo` shape, whether supplied directly or as a supported Git URL. Extra components are rejected rather than truncated. If multiple identity forms are present—such as `repository_full_name`, `owner` + `repo`, and `repository`—all must normalize to the same slug. Any malformed, incomplete, unmanaged, or conflicting identity remains unattributed.

Multiple filesystem paths must resolve to the same managed repository. Filesystem and repository targets must also agree. Cwd cannot override explicit negative evidence.

Unattributed events never enter repository bundles. Their diagnostic contains only event type, host correlation ID, and timestamp.

## Repository-scoped guard

User-level PreToolUse enforcement runs through `eos-telemetry-dispatch.sh guard`. The dispatcher proves the repository before invoking `require-telemetry-session.sh`.

For an attributed managed repository, the guard receives dispatcher mode and the active user settings path. It validates SessionStart under `hooks.SessionStart`, the guard and recorder inside a catch-all PreToolUse block (`matcher` absent or `.*`), and boundary commands under Stop, StopFailure, and SessionEnd. A narrow matcher such as `Read` cannot satisfy required fail-closed coverage. Marker-only managed repositories therefore do not require project-local settings.

Unmanaged or unattributed activity does not inherit another repository's guard.

## Isolation and lifecycle boundaries

Every managed repository keeps separate run ID, events, policy, branch/head, handoff state, bundle, and PR matching. Host correlation is additive only.

Required, best-effort, and disabled policies remain repository-local. Stop, StopFailure, and SessionEnd visit every currently valid managed repository, then return failure if any required durable handoff failed. A failure is not hidden and does not prevent sibling boundary recording.

## Privacy and retention

The dispatcher retains the metadata-only contract: no conversation text, file contents, complete commands, complete tool inputs, environment dumps, or credentials are stored. Paths and markers are resolved before boundary checks. Resolver failures use separate hashed diagnostics. Session caches are pruned during SessionStart after a bounded retention period and revalidated before every use.

## Validation status

Automated tests cover installation and mode migration, settings permissions and unrelated-hook preservation, managed-only discovery, complete versus partial direct-hook coexistence, cached-marker revocation, path and repository attribution, exact and conflicting identity forms, Grep path handling, marker-only guard behavior, hook-event and matcher placement, policy and boundary isolation, failure handling, downstream handoff, product-head advancement, and cross-repository PR matching.

A real Remote attempt proved installation, verification, dynamic loading, and two failure paths. It was not a successful closure run because installation occurred after the session began and a restart was required.

The open `multirepo-remote-telemetry-validation` gap requires a fresh post-install session to prove:

1. managed repositories initialize at SessionStart;
2. managed activity records under the correct repository;
3. outside activity is neither blocked nor attributed, including with a managed cwd;
4. marker-only guard validation succeeds after SessionStart under catch-all PreToolUse coverage;
5. run IDs remain separate and host correlation is shared;
6. unmanaged siblings receive no telemetry state;
7. marker removal during a session ends further attribution and fan-out;
8. session completion creates the correct non-empty bundle and surfaces required handoff failures;
9. repository, branch, head, and PR matching cannot cross repository boundaries;
10. diagnostics satisfy the metadata-only contract.

The next experiment must start in a new Claude Code Remote session created after the merged code and user-level installation are present.
