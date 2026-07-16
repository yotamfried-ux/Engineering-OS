# Remote workspace telemetry requires a durable handoff

## מה קרה

Two real Project 8 runs produced successful product pull requests and valid CI-generated Operational Work History, but the final artifact reported `telemetry_available=false` and `telemetry_events_count=0`. The second run had already passed the local session preflight, so local readiness created a false sense that the later CI artifact would contain the same events.

During repair, a second false-negative race was reproduced: a stale local sync could successfully bind a newer remote provisional bundle to the exact PR, then return before refreshing local `handoff-state.json`. GitHub held the correct exact bundle, but the next required local preflight still saw provisional or stale state.

A final review also found that PR CI history was filtered by PR number only after GitHub returned workflow runs. Because GitHub caps filtered workflow-run searches, pagination alone could omit early correction-loop runs in a busy repository.

## שורש הבעיה

Claude Code web recorded metadata-only events into a gitignored file inside its remote workspace. GitHub Actions generated Operational Work History from a separate clean checkout. No durable transport copied or correlated the local run into the CI workspace. The lifecycle webhook only closed the subscription; it did not carry the telemetry bundle.

The concurrency variant came from treating a newer remote bundle as a successful stale skip without returning its effective exact PR binding to the caller or persisting a matching local durable state.

A related false green existed in review readiness: the gate accepted a PR-body statement about thread resolution instead of checking live GitHub review-thread state. The CI-history variant came from relying on client-side PR filtering without a server-side time bound.

## השערות שנבדקו

- The hooks did not run — rejected for the second run because local preflight and session lifecycle behavior were present.
- Operational Work History discarded available telemetry — rejected because the collector accepts an explicit telemetry file and correctly reported unavailable when the clean checkout had none.
- The session-close webhook delivered telemetry — rejected because no exported bundle or non-zero event artifact existed after closure.
- The workspaces lacked a durable bridge — confirmed by comparing the remote local-only recorder path with the clean CI checkout and reproducing the boundary in a bare-Git simulation.
- A stale sync only affected remote event ordering — rejected after reproducing correct remote exact binding with stale local durable state.
- `gh api --paginate` guaranteed complete PR history — rejected because the upstream filtered search can be capped before client-side PR selection.

## ראיה

- Project 8 PR #6 artifact `operational-work-history-6-29245891365` retained 38 workflow runs and 15 historical failures while reporting zero session events.
- `scripts/monitoring/eos-telemetry-event.sh` writes to `.engineering-os/telemetry/events.jsonl` in the active workspace.
- The previous `.github/workflows/pr-policy.yml` never retrieved a bundle from another workspace.
- `scripts/enforcement/tests/test-remote-telemetry-handoff.sh` proves a session can persist a bundle to an isolated Git branch, a separate clean checkout can select it, stale provisional rebinding updates local exact state, and a conflicting PR rebind fails closed.
- `scripts/enforcement/tests/test-live-review-threads.sh` proves unresolved current and outdated threads are blocked from readiness.
- `scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh` requires trusted policy resolution and a server-side PR-created-at bound before local PR filtering.
- Live `pr-policy` run `29464405759` accepted the bounded query and generated OWH containing 737 PR-associated workflow runs before the live-thread gate blocked the outstanding thread.

## רמת ביטחון

High

## איך מזהים מוקדם

Treat these states as explicit failures before starting a real target task:

- local events exist but no durable handoff state exists;
- CI has no exact PR/head-matched telemetry bundle;
- the remote bundle is exact but local durable state is still provisional or bound elsewhere;
- the same run attempts to bind to a second PR;
- OWH reports zero events for a telemetry-required target;
- CI history retrieval has no server-side time/head bound before client-side filtering;
- review readiness claims resolved threads while GitHub still returns any unresolved thread.

## איך מונעים בעתיד

- Persist metadata-only telemetry outside the ephemeral Claude workspace during SessionStart and every terminal boundary.
- Require durable handoff state in the all-tools preflight.
- Match CI bundles by repository, PR number, source-branch hash, and exact head SHA.
- Treat exact PR binding as immutable for a run and return the effective remote binding from every sync path.
- Persist local durable state after every successful remote outcome, including stale-skip paths, without downgrading newer remote progress.
- Validate checksums and the metadata-only privacy contract before use.
- Feed only the exact selected bundle to Operational Work History and upload it for archive import.
- Bound workflow-run retrieval server-side from PR creation, then retain exact local PR-number filtering.
- Query live GitHub review threads and fail closed instead of trusting PR-body prose.

## טסט רגרסיה

- `scripts/enforcement/tests/test-remote-telemetry-handoff.sh`
- `scripts/enforcement/tests/test-live-review-threads.sh`
- `scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh`
- `scripts/enforcement/tests/test-install-policy-gate-coverage.sh`

## סטטוס הבשלה

Verified Lesson

## Prevented Future Issues: 0
