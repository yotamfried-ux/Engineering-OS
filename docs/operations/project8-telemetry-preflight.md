# Project 8 Telemetry Preflight

This preflight is mandatory before the next Project 8 experiment. It verifies both the exact Claude workspace and a durable metadata-only handoff that GitHub Actions can read from a separate clean checkout.

## Why this exists

The first Project 8 run did not install active Claude hooks. The next run recorded enough local lifecycle state to work, but its final Operational Work History still reported:

```text
telemetry_available: false
telemetry_events_count: 0
```

The second failure proved that local telemetry is not sufficient. Claude Code web runs in an ephemeral remote workspace, while GitHub Actions runs in an independent checkout. A successful experiment needs a durable bridge between them.

The corrected runtime now:

- creates or safely patches `.claude/settings.json`;
- records metadata-only session/tool events;
- pushes sanitized bundles to the isolated `engineering-os-telemetry` branch;
- blocks required-mode work until that push succeeds;
- lets `pr-policy` select only a bundle matching the exact repository, PR number, source-branch hash, and PR head SHA;
- uploads the matched bundle separately and feeds its events into Operational Work History.

## Safe installation sequence

The updated `pr-policy.yml` must already exist on the target repository default branch before remote sessions rely on automatic workflow dispatch. Use this order:

1. merge the Engineering OS telemetry-handoff update;
2. update the local Engineering OS reference;
3. run the installer in Project 8 and merge that installation/configuration PR;
4. confirm the updated `pr-policy.yml` is on `project-8/main`;
5. enable required handoff mode in Project 8;
6. close every existing Claude session;
7. open a fresh Claude Code session from the Project 8 repository root.

Do not combine steps 3–5 with the real experiment workload.

## Installation

From the Project 8 repository root, using the current Engineering OS reference:

```bash
ENGINEERING_OS_HOME=/absolute/path/to/Engineering-OS \
  bash /absolute/path/to/Engineering-OS/scripts/use-in-project.sh
```

Running `install-policy-gates.sh` directly is also supported. It creates missing settings, preserves custom hooks, installs the telemetry runtime, and creates a safe default policy with remote handoff disabled.

For the experiment-preparation PR, set `.engineering-os/telemetry-policy.json` to:

```json
{
  "schema_version": "eos.telemetry.policy.v1",
  "remote_handoff": {
    "mode": "required",
    "remote": "origin",
    "branch": "engineering-os-telemetry"
  }
}
```

Required mode is intentional: authentication or push failures must stop the experiment instead of producing another zero-event result.

## Fresh-session verification

After installation or policy changes, close the current Claude session and open a new one. Claude Code reloads `.claude/settings.json` and hook files live via a file watcher, so the hook wiring itself does not require a fresh session. What actually requires a fresh session is `SessionStart`-scoped state: the run id and the telemetry bundle are only created/opened once, by the `SessionStart` hook. A session that was already running before installation or a policy change never re-fires `SessionStart`, so it keeps its stale (or absent) run id and telemetry bundle regardless of live hook reload.

Before application work, run:

```bash
bash "$ENGINEERING_OS_HOME/scripts/monitoring/require-telemetry-session.sh"
```

Both lines must succeed:

```text
telemetry session ready: events=<positive integer>
telemetry remote handoff ready: events=<positive integer> boundary=<positive integer>
```

The command fails closed when:

- `.claude/settings.json` is missing;
- telemetry is disabled;
- `run_id` or `events.jsonl` is missing;
- the current run has no matching `session_start`;
- required recorder, boundary-sync, or preflight hooks are absent;
- no successful durable handoff state exists for the current run;
- the latest completed lifecycle boundary was not pushed;
- the configured telemetry branch does not match the handoff state.

Do not disable, bypass, or downgrade required mode to continue the experiment.

## Session and handoff boundaries

Every `SessionStart`:

1. archives the previous local run;
2. creates a new run id and fresh event file;
3. records `eos.session_start`;
4. exports a sanitized metadata-only bundle;
5. pushes it to `engineering-os-telemetry`;
6. records durable handoff state only after a successful push.

Every `Stop`, `StopFailure`, and `SessionEnd` records the boundary first and then refreshes the same remote bundle. This ordering prevents a final bundle from missing its own terminal event.

The telemetry branch is not a product branch and must never be merged into `main`.

## Pull request evidence

After a PR exists, a successful handoff automatically dispatches `pr-policy` for that PR. The workflow:

1. resolves the live PR head;
2. checks out the exact product SHA and the isolated telemetry branch separately;
3. rejects stale, unrelated, zero-event, checksum-invalid, or privacy-invalid bundles;
4. supplies the matched event file to Operational Work History;
5. uploads `session-telemetry-<pr>-<run>` as a separate 30-day artifact;
6. checks live GitHub review threads and blocks every unresolved thread.

The final PR run must show non-zero telemetry in both the session artifact and Operational Work History.

## Archive import

The Actions artifact is the durable handoff and transport evidence. After the run, import and analyze that exact artifact from the Engineering OS repository using the canonical telemetry archive tools. Do not use `--empty-run`.

The experiment is not complete until:

- the matched bundle has more than zero events;
- the bundle is imported into the Engineering OS archive;
- the analyzer completes;
- findings compare session telemetry, Operational Work History, and Project 8 product outcomes.

## Evidence layers

Keep these separate:

- **Session telemetry:** metadata-only hook/tool events from the exact Claude workspace, durably handed off and uploaded by CI.
- **Operational Work History:** PR, commit, review, current-check, and complete PR-scoped CI history.
- **Product outcome:** the actual Project 8 change and its tests/deployment evidence.

A green product PR, a lifecycle webhook, or Operational Work History without a non-empty matched session bundle is not a successful Engineering OS experiment.
