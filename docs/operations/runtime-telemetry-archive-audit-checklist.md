# Runtime Telemetry Archive Audit Checklist

Tracking plan: `docs/operations/runtime-telemetry-archive-plan.md`

Purpose: track execution of the runtime telemetry archive update. This checklist is not a readiness claim.

## Planning

- [x] Official documentation researched.
- [x] Central archive direction selected.
- [x] Archive folder layout defined.
- [x] Export bundle shape defined.
- [x] Import workflow defined.
- [x] Archive analysis workflow defined.
- [x] CI artifact workflow option defined.
- [x] Future Collector option documented.
- [x] Privacy model documented.
- [x] Full implementation plan created.

## Archive implementation

- [x] Add export command.
- [x] Add import command.
- [x] Add archive analyzer.
- [x] Add archive README.
- [x] Add tests for export.
- [x] Add tests for import.
- [x] Add tests for archive analysis.
- [x] Add duplicate-run handling.
- [x] Add archive index files.

## Remote workspace handoff implementation

- [x] Identify the clean-checkout boundary that caused local Claude events to disappear from OWH.
- [x] Add metadata-only persistence to an isolated Git branch.
- [x] Record and sync SessionStart, Stop, StopFailure, and SessionEnd sequentially.
- [x] Block required-mode tool use until the current run has durable handoff state.
- [x] Hash source branch metadata before remote persistence.
- [x] Reject raw/sensitive fields and checksum-invalid bundles.
- [x] Select bundles by repository, PR number, source-branch hash, and exact PR head SHA.
- [x] Feed the selected event file to Operational Work History.
- [x] Upload the matched bundle as a separate Actions artifact.
- [x] Add separate-workspace positive and stale/unrelated/tampered negative fixtures.
- [x] Query live GitHub review threads and block every unresolved thread.

These implementation items prove the transport and gates in fixtures. They do not prove that a new real Project 8 Claude session has produced, imported, and analyzed a non-empty bundle.

## Preliminary Project 8 evidence

- [x] Perform real Engineering OS target-project work with Operational Work History.
- [x] Inspect Project 8 PR #4 and PR #6 OWH artifacts and record their exact facts.
- [x] Confirm both completed runs lacked usable session telemetry in CI.
- [x] Record that OWH, webhook lifecycle closure, and Project 8 product outcomes do not substitute for session telemetry.
- [x] Merge the canonical installation/session/preflight fixes in Engineering OS PR #244.
- [x] Capture the durable-handoff root cause in `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md`.

## Project 8 telemetry evidence

- [ ] Merge the Engineering OS durable-handoff implementation.
- [ ] Install that exact Engineering OS version in Project 8.
- [ ] Merge the updated `pr-policy.yml` and telemetry runtime into `project-8/main` before the real workload.
- [ ] Enable required remote handoff in `.engineering-os/telemetry-policy.json`.
- [ ] Start a fresh Claude session after installation.
- [ ] Pass `require-telemetry-session.sh` with positive local events and positive remote handoff state.
- [ ] Run one bounded Project 8 task with the current telemetry baseline.
- [ ] Produce an exact PR/head-matched non-empty session telemetry artifact.
- [ ] Confirm Operational Work History reports non-zero telemetry events.
- [ ] Import the Project 8 telemetry artifact into the archive.
- [ ] Analyze the imported run.
- [ ] Write instrumented Project 8 findings.
- [ ] Identify missing telemetry coverage.
- [ ] Convert repeated missing coverage into follow-up work.

## Longitudinal learning

- [ ] Import at least one later target-project run.
- [ ] Compare Project 8 with the later run.
- [ ] Record recurring patterns.
- [ ] Decide whether the local archive is sufficient.
- [ ] Decide whether a later backend is needed.
- [ ] Update readiness only from real run evidence.

## Completion evidence

- [ ] Durable-handoff PR merged.
- [ ] Project 8 installation/configuration PR merged.
- [ ] Project 8 non-empty archive run imported.
- [ ] Instrumented Project 8 findings reviewed.
- [ ] At least one comparison run exists.
- [ ] Monitoring sufficiency decision is backed by real runs.
