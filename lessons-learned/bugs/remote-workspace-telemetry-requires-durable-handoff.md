# Remote workspace telemetry requires a durable handoff

## מה קרה

Two real Project 8 runs produced successful product pull requests and valid CI-generated Operational Work History, but the final artifact reported `telemetry_available=false` and `telemetry_events_count=0`. The second run had already passed the local session preflight, so local readiness created a false sense that the later CI artifact would contain the same events.

## שורש הבעיה

Claude Code web recorded metadata-only events into a gitignored file inside its remote workspace. GitHub Actions generated Operational Work History from a separate clean checkout. No durable transport copied or correlated the local run into the CI workspace. The lifecycle webhook only closed the subscription; it did not carry the telemetry bundle.

A related false green existed in review readiness: the gate accepted a PR-body statement about thread resolution instead of checking live GitHub review-thread state.

## השערות שנבדקו

- The hooks did not run — rejected for the second run because local preflight and session lifecycle behavior were present.
- Operational Work History discarded available telemetry — rejected because the collector accepts an explicit telemetry file and correctly reported unavailable when the clean checkout had none.
- The session-close webhook delivered telemetry — rejected because no exported bundle or non-zero event artifact existed after closure.
- The workspaces lacked a durable bridge — confirmed by comparing the remote local-only recorder path with the clean CI checkout and reproducing the boundary in a bare-Git simulation.

## ראיה

- Project 8 PR #6 artifact `operational-work-history-6-29245891365` retained 38 workflow runs and 15 historical failures while reporting zero session events.
- `scripts/monitoring/eos-telemetry-event.sh` writes to `.engineering-os/telemetry/events.jsonl` in the active workspace.
- The previous `.github/workflows/pr-policy.yml` never retrieved a bundle from another workspace.
- `scripts/enforcement/tests/test-remote-telemetry-handoff.sh` now proves a session can persist a bundle to an isolated Git branch and that a separate clean checkout can select it and produce non-zero OWH telemetry.
- `scripts/enforcement/tests/test-live-review-threads.sh` proves unresolved current and outdated threads are blocked from readiness.

## רמת ביטחון

High

## איך מזהים מוקדם

Treat these states as explicit failures before starting a real target task:

- local events exist but no durable handoff state exists;
- CI has no exact PR/head-matched telemetry bundle;
- OWH reports zero events for a telemetry-required target;
- review readiness claims resolved threads while GitHub still returns any unresolved thread.

## איך מונעים בעתיד

- Persist metadata-only telemetry outside the ephemeral Claude workspace during SessionStart and every terminal boundary.
- Require durable handoff state in the all-tools preflight.
- Match CI bundles by repository, PR number, source-branch hash, and exact head SHA.
- Validate checksums and the metadata-only privacy contract before use.
- Feed only the exact selected bundle to Operational Work History and upload it for archive import.
- Query live GitHub review threads and fail closed instead of trusting PR-body prose.

## טסט רגרסיה

- `scripts/enforcement/tests/test-remote-telemetry-handoff.sh`
- `scripts/enforcement/tests/test-live-review-threads.sh`
- `scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh`
- `scripts/enforcement/tests/test-install-policy-gate-coverage.sh`

## סטטוס הבשלה

Verified Lesson

## Prevented Future Issues: 0
