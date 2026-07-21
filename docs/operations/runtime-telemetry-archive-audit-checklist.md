# Runtime Telemetry Archive Audit Checklist

Tracking plan: `docs/operations/runtime-telemetry-archive-plan.md`

Purpose: track implementation, first-run evidence, and later longitudinal learning as three separate layers. This checklist is not itself a readiness claim.

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
- [x] Add a user-level dispatcher for parent-started multi-repository Remote sessions.
- [x] Add managed-only discovery, strict attribution, per-repository isolation, and scoped guard fixtures.
- [ ] Merge the current canonical URL parsing and trust-boundary hardening PR chain.

The checked implementation items prove code paths and negative cases. They do not prove that a fresh real Remote session has produced and durably handed off a non-empty bundle.

## Preliminary Project 8 evidence

- [x] Perform real Engineering OS target-project work with Operational Work History.
- [x] Inspect Project 8 PR #4 and PR #6 OWH artifacts and record their exact facts.
- [x] Confirm both completed runs lacked usable session telemetry in CI.
- [x] Record that OWH, webhook lifecycle closure, and Project 8 product outcomes do not substitute for session telemetry.
- [x] Merge the canonical installation/session/preflight fixes in Engineering OS PR #244.
- [x] Merge durable remote-handoff infrastructure in Engineering OS.
- [x] Merge the required telemetry policy into `project-8/main`.
- [x] Merge the hardened telemetry runtime, exact selector, and preflight into `project-8/main`.
- [x] Capture the durable-handoff root cause in `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md`.
- [x] Detect that Project 8 contains stricter trust-boundary controls than the canonical installer.
- [ ] Merge those reviewed Project 8 controls back into the canonical Engineering OS source.

Do not run a blind full installer sync into Project 8 while the final canonical hardening item is unchecked. The existing Project 8 runtime must not be replaced with a weaker copy.

## First Project 8 telemetry run — blocks experiment readiness closure

- [ ] Update the actual `ENGINEERING_OS_HOME` checkout to the merged experiment-ready head.
- [ ] Verify the user-level telemetry installer against that exact checkout.
- [ ] Start a genuinely fresh Claude session after installation.
- [ ] Pass `require-telemetry-session.sh` with positive local events and positive remote handoff state.
- [ ] Confirm unmanaged or unattributed work is not recorded or blocked.
- [ ] Run one bounded Project 8 task with the current telemetry baseline.
- [ ] Produce an exact repository/branch/head/PR-matched non-empty session telemetry artifact.
- [ ] Confirm Operational Work History reports non-zero telemetry events.
- [ ] Import the Project 8 telemetry artifact into the Engineering OS archive.
- [ ] Analyze the imported run.
- [ ] Write instrumented Project 8 findings.
- [ ] Identify missing telemetry coverage, false positives, friction, and decision-quality signals.
- [ ] Convert concrete unresolved coverage into implementation work or registered gaps.

Completion of this section closes the first-run evidence decision. It does not claim longitudinal maturity from one run.

## Longitudinal learning — does not block the first Project 8 experiment

- [ ] Import at least one later valid target-project run.
- [ ] Compare Project 8 with the later run.
- [ ] Record recurring coverage, failure, friction, and decision-quality patterns.
- [ ] Decide whether the local archive is sufficient.
- [ ] Decide whether a later OpenTelemetry Collector or external backend is needed.
- [ ] Update longitudinal readiness only from the multi-run evidence.

## Completion evidence

### Implementation readiness

- [x] Archive commands and deterministic tests exist.
- [x] Durable-handoff infrastructure is merged.
- [x] Project 8 installation and required policy are merged.
- [ ] Canonical URL parsing and trust-boundary hardening are merged.

### First-run readiness

- [ ] Project 8 non-empty archive run is imported.
- [ ] Instrumented Project 8 findings are reviewed.
- [ ] `project-8-real-run-evidence` is closed from the actual run.
- [ ] `monitoring-metrics-sufficiency` is closed from the imported and analyzed first run.

### Longitudinal readiness

- [ ] At least one comparison run exists.
- [ ] `monitoring-longitudinal-sufficiency` is backed by reviewed multi-run evidence.
