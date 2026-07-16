# Project 8 First Real-Run Findings

Date: 2026-07-12
Engineering OS baseline after the run: `c2572b03f296703d1ff6c84cfbf4e0796b62f588`
Project 8 merged change: PR #4, merge commit `2d26b3cde2c68ff260c9f91a87700a953c6e29c8`
Operational Work History artifact: `operational-work-history-4-29178357323`

## Classification

This was a real Engineering OS run against a real target project. It produced valid Operational Work History and real Project 8 improvements. It was not a valid session-telemetry archive run.

Keep the evidence layers separate:

- Operational Work History: available and valid.
- Claude session telemetry: unavailable; zero events.
- Project 8 product outcome: real baseline repairs merged.

## Operational Work History evidence

The final artifact records:

- PR head: `e391f4ddf88c3fa9fe29b08b05c36bcebf6eda86`.
- Base: `52f3648562af7afba54e20adf0108800b42c62e6`.
- 33 changed files.
- 49 commits.
- 14 current checks observed.
- zero current failing checks.
- one review observed.
- valid `booking-system` result-loop contract.
- 25 repeated-cycle commits.
- `telemetry_available: false`.
- `telemetry_events_count: 0`.

The artifact is metadata-only. It contains no raw prompts, responses, file contents, commands, paths, connector payloads, environment values, or secrets.

## Engineering OS behavior findings

### Positive influence

Engineering OS materially changed the run:

1. A Route Plan was committed before implementation.
2. MongoDB/provider drift was rejected and the approved Supabase/Postgres plus Vercel direction was preserved for later phases.
3. The run used repeated experiment/fix/CI loops instead of declaring success after compilation.
4. Review findings caused real corrections to source-text coverage, ephemeral database provisioning, and cross-timezone day keys.
5. Merge was blocked until the exact final head passed baseline, policy, deployment, review-thread, and Operational Work History checks.

### Friction and blind spots

1. The run required 49 commits and the artifact classified 25 as repeated-cycle commits.
2. The final point-in-time CI snapshot showed zero failures even though the correction loop contained many failed runs. Engineering OS PR #244 now adds paginated historical CI aggregation so later OWH artifacts retain that friction.
3. Several policy failures were evidence-format corrections rather than application defects. They were useful for enforcing the contract, but their frequency is an efficiency signal that should be compared with later runs.
4. The target had CI policy gates but no `.claude/settings.json`, so the session produced no telemetry. A green PR did not prove monitoring coverage.

## Project 8 secondary outcome

The experiment also improved Project 8 according to the approved requirements:

- repaired a server parser failure;
- restored corrupted Hebrew customer/operator text;
- corrected booking day and time handling in the business timezone;
- repaired runtime import and logger-context defects exposed by deeper testing;
- added source-text integrity checks;
- added full client tests/build;
- added full server tests against an ephemeral SQL Server plus health/readiness smoke checks;
- preserved Azure rollback and did not import MongoDB changes.

These outcomes validate Project 8 as a useful real target for Engineering OS, but they do not close telemetry or migration work.

## Why telemetry evidence is invalid

Project 8 `main` still lacked `.claude/settings.json` after the run. Claude Code hooks are loaded at session startup, so the completed session cannot be retroactively instrumented. Operational Work History cannot substitute for hook/session telemetry.

Engineering OS PR #244 fixes the canonical installer, current-session preflight, session isolation, metadata-only lifecycle coverage, and historical CI aggregation. It removes the installation blocker for the next run; it does not create evidence for the completed run.

## Status decision

- `project-8-real-run-evidence`: move from `blocked` to `open`.
- `monitoring-metrics-sufficiency`: remain `open`.
- No telemetry checklist completion item is satisfied yet.

The gap is open because a fresh valid run is now executable, not because the closure bar was met.

## Next valid experiment

The next Project 8 task must start only after all of the following:

1. Install current Engineering OS in the exact Project 8 workspace that will run Claude.
2. Close the current Claude session and open a new session in that workspace.
3. Run `require-telemetry-session.sh` and receive `telemetry session ready` with a positive event count.
4. Perform a meaningful Project 8 task. The next approved product direction remains Supabase/Postgres and Vercel; the run should use a bounded migration-foundation task rather than unrelated feature work.
5. Export a non-empty metadata-only telemetry bundle.
6. Import it into the Engineering OS archive.
7. Analyze the run together with its Operational Work History.
8. Record missing coverage, friction, false positives, decision quality, and Project 8 outcomes.

Do not use `--empty-run`, bypass the preflight, or mark either readiness gap closed from OWH alone.
