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

## Implementation

- [x] Add export command.
- [x] Add import command.
- [x] Add archive analyzer.
- [x] Add archive README.
- [x] Add tests for export.
- [x] Add tests for import.
- [x] Add tests for archive analysis.
- [x] Add duplicate-run handling.
- [x] Add archive index files.

## Preliminary Project 8 evidence

- [x] Perform a real Engineering OS target-project run with Operational Work History.
- [x] Inspect the Project 8 PR #4 OWH artifact and record its exact facts.
- [x] Confirm the completed run had `telemetry_available: false` and zero events.
- [x] Record that OWH and Project 8 product outcomes do not substitute for session telemetry.
- [x] Merge the canonical installation/session/preflight fixes in Engineering OS PR #244.
- [x] Write `docs/operations/project8-first-real-run-findings.md`.

These items establish a real OWH-only run and remove the technical installation blocker. They do not satisfy the telemetry evidence section below.

## Project 8 telemetry evidence

- [ ] Install current Engineering OS in the exact Project 8 Claude workspace.
- [ ] Start a fresh Claude session after installation.
- [ ] Pass `require-telemetry-session.sh` with a positive event count before application work.
- [ ] Run Project 8 with the current Engineering OS telemetry baseline.
- [ ] Export a non-empty Project 8 telemetry bundle.
- [ ] Import Project 8 telemetry into the archive.
- [ ] Write instrumented Project 8 findings.
- [ ] Identify missing telemetry coverage.
- [ ] Convert repeated missing coverage into follow-up work.

## Longitudinal learning

- [ ] Import at least one future target-project run.
- [ ] Compare Project 8 with a later run.
- [ ] Record recurring patterns.
- [ ] Decide whether the local archive is sufficient.
- [ ] Decide whether a later backend is needed.
- [ ] Update readiness only from real run evidence.

## Completion evidence

- [ ] Export/import/analyzer PR merged.
- [ ] Project 8 archive run imported.
- [ ] Instrumented Project 8 findings reviewed.
- [ ] At least one comparison run exists.
- [ ] Monitoring sufficiency decision is backed by real runs.
