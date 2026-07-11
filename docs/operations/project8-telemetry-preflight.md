# Project 8 Telemetry Preflight

This preflight is mandatory before the next Project 8 experiment. It verifies the exact target workspace that will run Claude, not a separate CI checkout.

## Why this exists

The first Project 8 run installed CI policy gates but did not create `.claude/settings.json`. As a result, no Claude hook events were recorded and the final Operational Work History correctly reported:

```text
telemetry_available: false
telemetry_events_count: 0
```

The corrected installer now creates or safely patches settings, installs the telemetry hooks, and adds a fail-closed guard.

## Installation

From the Project 8 repository root, using the current Engineering OS reference:

```bash
ENGINEERING_OS_HOME=/absolute/path/to/Engineering-OS \
  bash /absolute/path/to/Engineering-OS/scripts/use-in-project.sh
```

Running `install-policy-gates.sh` directly is also supported. It now creates missing settings and patches existing custom settings without removing custom hooks.

After installation or settings changes, **close the current Claude session and open a new session in the Project 8 repository**. Claude Code loads hooks at session startup; installing settings midway through a session cannot retroactively create a `session_start` event.

## Required verification

In the new session, before application work:

```bash
bash "$ENGINEERING_OS_HOME/scripts/monitoring/require-telemetry-session.sh"
```

Expected result:

```text
telemetry session ready: events=<positive integer>
```

The command fails closed when:

- `.claude/settings.json` is missing;
- telemetry was disabled;
- `run_id` is missing;
- `events.jsonl` is empty;
- required hook commands are absent from settings;
- the current run id has no matching `session_start` event, which normally means settings were installed after the session began.

Do not continue the experiment by disabling or bypassing this check.

## Session boundaries

Every `SessionStart` now:

1. archives the previous session under `.engineering-os/telemetry/history/`;
2. creates a new run id;
3. starts a fresh `events.jsonl`;
4. records a matching `eos.session_start` event.

This prevents multiple Claude sessions from being combined into one telemetry run.

## End-of-run export

After the work session and before discarding its workspace:

```bash
bash "$ENGINEERING_OS_HOME/scripts/monitoring/export-telemetry-run.sh" \
  --out /absolute/path/telemetry-export/project-8 \
  --project project-8 \
  --engineering-os-head-sha "$(git -C "$ENGINEERING_OS_HOME" rev-parse HEAD)"
```

The export must contain more than zero events. Do not use `--empty-run` for the experiment.

Import and analyze from the Engineering OS repository as documented in `docs/operations/runtime-telemetry-archive-plan.md`.

## Evidence layers

Keep these separate:

- **Session telemetry:** hook/tool events written in the exact Claude workspace.
- **Operational Work History:** CI-generated PR, commit, review, current-check, and historical-CI aggregate metadata.

A successful experiment requires both layers. A green PR with no session telemetry is not sufficient evidence.
