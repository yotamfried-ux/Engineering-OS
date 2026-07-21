# Project 8 Telemetry Preflight

This preflight is mandatory before the next Project 8 experiment. It verifies both the exact Claude workspace and a durable metadata-only handoff that GitHub Actions can read from a separate clean checkout.

## Why this exists

The first Project 8 run did not install active Claude hooks. A later run produced valid Operational Work History but still reported:

```text
telemetry_available: false
telemetry_events_count: 0
```

Local telemetry alone is not sufficient. Claude Code Remote runs in an ephemeral workspace, while GitHub Actions runs in an independent checkout. A successful experiment needs a durable bridge between them.

The corrected runtime now:

- creates or safely patches Claude settings;
- records metadata-only session/tool events;
- pushes sanitized bundles to the isolated `engineering-os-telemetry` branch;
- blocks required-mode work until current-session initialization and durable handoff are ready;
- lets `pr-policy` select only a bundle matching the exact repository, PR number, source-branch hash, and PR head SHA;
- copies only the validated bundle allowlist;
- uploads the matched bundle separately and feeds its events into Operational Work History.

## Official lifecycle constraints

The design follows the official Claude Code hooks reference:

- `SessionStart` is the per-session initialization boundary used to create a fresh run id.
- `Stop` may participate in completion control.
- `StopFailure` ignores hook output and exit status.
- `SessionEnd` cannot block termination and has a short default timeout.

Source: `https://code.claude.com/docs/en/hooks`.

Therefore a terminal hook invocation is not, by itself, proof of durable delivery. The experiment is successful only when the remote branch, exact PR/head selection, CI artifact, archive import, and analysis all confirm the same non-empty bundle.

The Git remote parser follows the official Git URL forms, including scheme URLs and `[user@]host:path` scp-style syntax. Source: `https://git-scm.com/docs/git-clone.html#_git_urls`.

## Current prerequisite state

Already merged in Project 8:

- tracked telemetry policy with `remote_handoff.mode=required`;
- full Claude hook configuration;
- hardened trusted-policy loading;
- regular-file and metadata-only bundle validation;
- exact PR/head selector and Operational Work History integration;
- experiment repository preflight.

Still required before opening the experiment session:

1. merge the Engineering OS canonical Git-remote parsing and trust-boundary hardening PR chain;
2. update the actual `ENGINEERING_OS_HOME` checkout to that merged head;
3. install and exactly verify the user-level dispatcher from that checkout;
4. open a genuinely fresh Claude session.

Do not run another blind full `use-in-project.sh` sync into Project 8 before the canonical hardening is merged. A previous attempted full sync was rejected because it would have replaced stricter Project 8 controls with weaker canonical copies. After the canonical repair is merged and validated, normal installer convergence can resume in a separate preparation PR if needed.

## Safe preparation sequence

The updated `pr-policy.yml` and required telemetry policy already exist on `project-8/main`. Use this order:

1. merge the Engineering OS experiment-readiness PR chain;
2. update the canonical Engineering OS checkout used by Claude;
3. install the user-level dispatcher:

   ```bash
   ENGINEERING_OS_HOME=/absolute/path/to/Engineering-OS \
     bash /absolute/path/to/Engineering-OS/scripts/monitoring/install-user-level-telemetry-hooks.sh
   ```

4. verify the installed hook set exactly:

   ```bash
   ENGINEERING_OS_HOME=/absolute/path/to/Engineering-OS \
     bash /absolute/path/to/Engineering-OS/scripts/monitoring/install-user-level-telemetry-hooks.sh --verify
   ```

5. confirm Project 8 still contains its tracked required policy and hardened repository preflight;
6. close every existing Claude session that may carry stale SessionStart state;
7. open a fresh Claude Code session from the Project 8 repository root, or a parent-started Remote session covered by the verified dispatcher;
8. run the readiness command before product work.

Do not combine installation/configuration changes with the bounded product task used for the experiment.

## Required policy

Project 8 must retain:

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

Required mode is intentional: authentication, identity, selection, or push failures must stop the controlled experiment instead of permitting another zero-event result.

## Fresh-session verification

Claude Code can reload settings and hook files while a session is open, but that does not recreate SessionStart-scoped state. The run id, initial event, repository cache, and first durable bundle must belong to the actual experiment session from its start.

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

- Claude settings are missing or incomplete;
- telemetry is disabled;
- the run id or events file is missing;
- the current run has no matching `session_start`;
- required recorder, boundary-sync, or guard hooks are absent;
- no successful durable handoff state exists for the current run;
- the latest completed lifecycle boundary was not pushed;
- repository, branch, head, PR, policy, or remote-branch identity does not match.

Do not disable, bypass, or downgrade required mode to continue the experiment.

## Controlled smoke task

Before the main Project 8 migration task, use one bounded governance-only or evidence-only change to prove the complete transport loop. The currently open Project 8 preparation PR may serve as the smoke target only if its head is unchanged and the session bundle can match that exact head.

The smoke pass must prove:

1. managed Project 8 initializes at SessionStart;
2. unrelated or unmanaged activity is neither attributed nor blocked;
3. tool events are written under the Project 8 run id;
4. a lifecycle boundary refreshes the remote bundle;
5. the telemetry branch contains a non-empty bundle for the exact repository, branch, and head;
6. `pr-policy` selects that bundle for the exact PR;
7. the uploaded session artifact and Operational Work History both show a positive event count;
8. no raw prompt, response, command, path, connector payload, environment value, or secret appears.

A failed smoke run is evidence for debugging, not authorization to proceed with the main experiment.

## Session and handoff boundaries

Every `SessionStart`:

1. archives the previous local run;
2. creates a new run id and fresh event file;
3. records `eos.session_start`;
4. exports a sanitized metadata-only bundle;
5. pushes it to `engineering-os-telemetry`;
6. records durable handoff state only after a successful push.

`Stop`, `StopFailure`, and `SessionEnd` record the boundary first and then attempt to refresh the same remote bundle. Because the official runtime does not allow every terminal event to block, the remote bundle and downstream evidence must be checked explicitly before the workspace is discarded.

The telemetry branch is transport state, not a product branch, and must never be merged into `main`.

## Pull request evidence

After a PR exists, a successful handoff dispatches or enables `pr-policy` to:

1. resolve the live PR head;
2. check out the exact product SHA and isolated telemetry branch separately;
3. reject stale, unrelated, zero-event, checksum-invalid, privacy-invalid, symlinked, or identity-mismatched bundles;
4. copy only `manifest.json`, `events.jsonl`, and `latest-summary.md` into the selected artifact;
5. supply the matched event file to Operational Work History;
6. upload `session-telemetry-<pr>-<run>` as a separate workflow artifact;
7. check live GitHub review threads and block every unresolved thread.

GitHub documents workflow artifacts as persisted run outputs that can be shared between jobs or retained after a run. They are the transport/evidence layer here, not the final longitudinal archive. Source: `https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts`.

The final PR run must show non-zero telemetry in both the session artifact and Operational Work History.

## Archive import and analysis

After the smoke or experiment task:

1. obtain the exact matched artifact or export bundle from the workspace;
2. import it into the Engineering OS archive using the canonical importer;
3. run the archive analyzer for `project-8`;
4. write or update the run's `findings.md`;
5. compare session telemetry, Operational Work History, and Project 8 product outcomes without conflating them.

Do not use `--empty-run`.

The first-run evidence decision is complete only when:

- the matched bundle has more than zero events;
- repository, branch, head, PR, and run identities match;
- the bundle is imported into the Engineering OS archive;
- the analyzer completes;
- findings record missing coverage, friction, false positives, decision quality, and product outcome.

A later second valid run is required for longitudinal comparison, but it does not block the first controlled Project 8 experiment.

## Evidence layers

Keep these separate:

- **Session telemetry:** metadata-only hook/tool events from the exact Claude workspace, durably handed off and uploaded by CI.
- **Operational Work History:** PR, commit, review, current-check, and complete PR-scoped CI history.
- **Product outcome:** the actual Project 8 change and its tests/deployment evidence.

A green product PR, lifecycle webhook, or Operational Work History without a non-empty matched session bundle is not a successful Engineering OS experiment.
