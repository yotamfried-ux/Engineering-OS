# Remote workspace telemetry requires a durable handoff

## מה קרה

Two real Project 8 runs produced successful product pull requests and valid CI-generated Operational Work History, but the final artifact reported `telemetry_available=false` and `telemetry_events_count=0`. The second run had already passed the local session preflight, so local readiness created a false sense that the later CI artifact would contain the same events.

During repair, several related false-green and false-negative paths were reproduced:

- a stale local sync could bind a newer remote provisional bundle to the exact PR but leave local `handoff-state.json` provisional;
- CI could trust a PR-controlled telemetry policy instead of the exact base policy;
- scalar secrets nested inside JSON arrays bypassed the metadata-only scan;
- noncanonical repository identity, custom telemetry source paths, and `best_effort` policy behavior could diverge between recording, export, sync, and preflight;
- strict exact-head validation rejected a valid remote bundle after the product branch advanced to a descendant commit;
- a stale workspace could otherwise overwrite telemetry already associated with a newer descendant product head;
- PR CI history was filtered locally after an upstream capped query;
- merge readiness trusted PR-body prose rather than live review-thread state.

## שורש הבעיה

Claude Code web recorded metadata-only events into a gitignored file inside its remote workspace. GitHub Actions generated Operational Work History from a separate clean checkout. No durable transport copied or correlated the local run into the CI workspace. The lifecycle webhook only closed the subscription; it did not carry the telemetry bundle.

The follow-on defects came from treating delivery as a single local-state check instead of an end-to-end contract. Policy, repository identity, telemetry source paths, remote bundle integrity, product-head ancestry, PR binding, remote progress, local durable state, CI selection, and live review state were validated in different places with inconsistent assumptions.

The product-head variant was especially subtle: exact-head selection is correct in CI, but sync must first validate an existing remote bundle independently of the current head, then allow replacement only when its head is the same commit or an ancestor of the current product head. A descendant or unrelated remote head must fail closed to prevent stale downgrade.

## השערות שנבדקו

- The hooks did not run — rejected for the second run because local preflight and session lifecycle behavior were present.
- Operational Work History discarded available telemetry — rejected because the collector accepts an explicit telemetry file and correctly reported unavailable when the clean checkout had none.
- The session-close webhook delivered telemetry — rejected because no exported bundle or non-zero event artifact existed after closure.
- The workspaces lacked a durable bridge — confirmed by comparing the remote local-only recorder path with the clean CI checkout and reproducing the boundary in a bare-Git simulation.
- A stale sync only affected remote event ordering — rejected after reproducing correct remote exact binding with stale local durable state.
- Exact current-head validation was required for every sync read — rejected because it blocked a normal descendant commit before the existing bundle could be safely replaced.
- `gh api --paginate` guaranteed complete PR history — rejected because the upstream filtered search can be capped before client-side PR selection.
- A configured `best_effort` mode could reuse the required preflight unchanged — rejected because missing durable state then blocked the next tool call.
- The exporter automatically followed the same custom source paths as the recorder — rejected until `EOS_TELEMETRY_FILE` and `EOS_TELEMETRY_RUN_ID_FILE` were propagated consistently.

## ראיה

- Project 8 PR #6 artifact `operational-work-history-6-29245891365` retained 38 workflow runs and 15 historical failures while reporting zero session events.
- `scripts/enforcement/tests/test-remote-telemetry-handoff.sh` proves separate-workspace persistence, exact clean-checkout selection, trusted-policy enforcement, privacy and checksum rejection, canonical identity, monotonic remote progress, local exact-state convergence, and conflicting-PR rejection.
- `scripts/enforcement/tests/test-telemetry-policy-and-path-overrides.sh` proves `best_effort` remains nonblocking, `required` remains fail-closed, and custom event/run-id paths are exported without silently reading default files.
- `scripts/enforcement/tests/test-telemetry-head-advancement.sh` proves stale local state is rejected after a commit, a validated ancestor-head bundle can advance to the current descendant head, and a stale product head cannot downgrade a newer remote bundle.
- `scripts/enforcement/tests/test-live-review-threads.sh` proves unresolved current and outdated threads are blocked from readiness.
- `scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh` requires trusted exact-base policy resolution and a server-side PR-created-at bound before local PR filtering.
- `telemetry-handoff-tests` run `29498660824` passed the named remote handoff, policy/path override, product-head advancement, and live-thread stages on application head `8bc8682aa5719dcba8e4cd89df881fecc7b24aab`.
- `enforcement-tests` run `29498660859` passed all 26 stages, including the aggregate all-suites pass, on the same application head.
- Live `pr-policy` run `29464405759` accepted the bounded query and generated OWH containing 737 PR-associated workflow runs before the live-thread gate blocked the outstanding thread.

## רמת ביטחון

High

## איך מזהים מוקדם

Treat these states as explicit failures before starting a real target task:

- local events exist but no durable handoff state exists in `required` mode;
- `best_effort` unexpectedly blocks tool execution after a transport failure;
- recording validates one telemetry path while export reads another;
- repository identity is not canonical `owner/repo`;
- a fetched remote bundle has not passed schema, checksum, JSONL, privacy, run, repository, branch, and PR-binding validation;
- the remote product head is a descendant of or unrelated to the local product head;
- the current product head advanced but local telemetry progress is behind the validated ancestor-head remote bundle;
- CI has no exact PR/head-matched telemetry bundle;
- the remote bundle is exact but local durable state is still provisional or bound elsewhere;
- the same run attempts to bind to a second PR;
- OWH reports zero events for a telemetry-required target;
- CI history retrieval has no server-side time/head bound before client-side filtering;
- review readiness claims resolved threads while GitHub still returns any unresolved thread.

## איך מונעים בעתיד

- Persist metadata-only telemetry outside the ephemeral Claude workspace during SessionStart and every terminal boundary.
- Resolve repository identity canonically and fail closed when `owner/repo` cannot be established.
- Read handoff policy from the exact trusted base SHA in CI, never from the PR-controlled checkout.
- Use the same explicit event and run-id source paths for validation, export, sync, and readiness.
- Keep `best_effort` nonblocking and `required` fail-closed through both sync and preflight.
- Validate every fetched bundle completely before trusting progress or PR binding.
- Match CI bundles by repository, PR number, source-branch hash, and exact head SHA.
- During sync, distinguish same, ancestor, descendant, and unrelated product heads: permit safe ancestor advancement, reject stale descendant downgrade, and fail closed on unrelated history.
- Preserve the greater validated remote event/boundary progress and never overwrite it with stale local data.
- Treat exact PR binding as immutable for a run and return the effective remote binding from every sync path.
- Persist local durable state after every successful remote outcome without claiming a head or progress state that the remote bundle does not contain.
- Scan scalar values inside arrays as well as dictionaries for sensitive patterns.
- Feed only the exact selected bundle to Operational Work History and upload it for archive import.
- Bound workflow-run retrieval server-side from PR creation, then retain exact local PR-number filtering.
- Query live GitHub review threads and fail closed instead of trusting PR-body prose.
- Keep high-risk regressions as named CI stages with explicit job timeouts so failures are isolated before broad reruns.

## טסט רגרסיה

- `scripts/enforcement/tests/test-remote-telemetry-handoff.sh`
- `scripts/enforcement/tests/test-telemetry-policy-and-path-overrides.sh`
- `scripts/enforcement/tests/test-telemetry-head-advancement.sh`
- `scripts/enforcement/tests/test-live-review-threads.sh`
- `scripts/enforcement/tests/test-pr-policy-workflow-wiring.sh`
- `scripts/enforcement/tests/test-install-policy-gate-coverage.sh`

## סטטוס הבשלה

Verified Lesson

## Prevented Future Issues: 0
