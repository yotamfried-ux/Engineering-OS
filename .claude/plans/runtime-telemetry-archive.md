# Runtime Telemetry Archive Implementation Plan

| Field | Value |
|---|---|
| Task type | infra / observability / Engineering OS governance |
| Task class | engineering_os_governance |
| Domain tags | observability, testing, governance, workflow |
| Plan Scope | standard |
| Planning Mode | approved |
| Target paths | scripts/monitoring/export-telemetry-run.sh, scripts/monitoring/export-telemetry-run.py, scripts/monitoring/import-telemetry-run.py, scripts/monitoring/analyze-telemetry-archive.py, scripts/enforcement/tests/test-telemetry-archive.sh, telemetry-archive/README.md, telemetry-archive/indexes/runs.jsonl, telemetry-archive/indexes/projects.json, telemetry-archive/indexes/gaps.jsonl, docs/operations/runtime-telemetry-archive-audit-checklist.md |
| Task-router evidence | core/task-router.md checked; routed as infra/observability plus Engineering OS governance. |
| Workflow evidence | core/workflow.md checked; plan-file fallback used because Notion is unavailable here. |
| Templates | not required because this is internal Engineering OS monitoring/governance maintenance. |
| Architecture guides | docs/operations/runtime-telemetry-archive-plan.md, scripts/monitoring/eos-telemetry-event.sh, scripts/monitoring/eos-telemetry-summary.py |
| Patterns | patterns/observability/README.md, patterns/testing/README.md |
| External systems/connectors | GitHub connector |
| Skills | not required |
| Validation gates | enforcement-tests, scripts/enforcement/tests/test-telemetry-archive.sh, python3 -m py_compile, bash -n |
| Evidence to check | scripts/enforcement/tests/test-telemetry-archive.sh and GitHub Actions results for PR head |
| User decisions required | explicit user approval before merge |

## Scope

Implement the local export/import/analyze archive layer described in docs/operations/runtime-telemetry-archive-plan.md without claiming monitoring readiness.

## Source of Truth Checks

| Source | Status |
|---|---|
| CLAUDE.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/coderabbit-policy.md | checked |
| docs/operations/runtime-telemetry-archive-plan.md | checked |
| docs/operations/runtime-telemetry-archive-audit-checklist.md | checked |
| scripts/monitoring/eos-telemetry-event.sh | checked |
| scripts/monitoring/eos-telemetry-summary.py | checked |

## Capability Evidence

- `routing.task-router-read` — task routed as infra/observability plus Engineering OS governance.
- `workflow.workflow-read` — workflow source checked before writing.
- `plan.route-plan-before-write` — this plan records target paths and validation gates before implementation writes.
- `source.github-repo-read` — GitHub connector read current main files before branching.
- `validation.policy-change-has-validator` — new archive behavior ships with test-telemetry-archive.sh.
- `validation.coderabbit-policy` — dedicated branch and PR; merge requires Actions, review, and explicit user approval.

## Connector Evidence

- source: GitHub repository yotamfried-ux/Engineering-OS.
- action: read current main source files and telemetry docs before implementation.
- result: confirmed PR 205 provides local metadata telemetry and PR 206 defines archive/export/import/analyze as the next step.
- decision: implement local file-bundle archive first; do not build a later backend yet.
- target: scripts/monitoring, telemetry-archive, scripts/enforcement/tests, docs/operations/runtime-telemetry-archive-audit-checklist.md.

## Documentation Asset Evidence

- internal: docs/operations/runtime-telemetry-archive-plan.md, docs/operations/runtime-telemetry-archive-audit-checklist.md, patterns/observability/README.md, patterns/testing/README.md.
- context7: external docs were checked through the web because this environment does not expose Context7; sources included Claude Code hooks, OpenTelemetry Collector component docs, and GitHub Actions artifact docs.
- decision: the docs confirmed the local export/import archive should be implemented before a later backend, and that CI artifacts should remain transport rather than durable archive storage.

## Template/Pattern Rating Waiver

This PR reads observability and testing patterns for design guidance but does not adopt a reusable implementation asset from patterns/ or templates/. Rating lifecycle feedback is not applicable to a new internal archive script set.

## Claude Run Trace

- goal: add Runtime Telemetry Archive export/import/analyze layer.
- hypothesis: a simple metadata-only bundle and strict importer validation gives enough evidence to compare Project 8 with future runs before deciding whether a backend is needed.
- connectors: GitHub connector read repo files and PR state.
- steps: read source files and docs; create exporter; create importer; create analyzer; add archive docs/indexes; add regression tests; update checklist.
- evidence: scripts/enforcement/tests/test-telemetry-archive.sh and PR Actions.
- rejected: claiming readiness before real Project 8 and later comparison data exists.

## Progress Lifecycle Evidence

- start: plan committed before the first code/config/test change; target paths and validation gates were recorded before implementation.

## DoD

- [ ] Export command emits manifest.json, events.jsonl, and latest-summary.md only.
- [ ] Import command validates manifest, JSONL, required event fields, metadata-only contract, and duplicate imports.
- [ ] Analyzer produces markdown comparing counts, coverage, and command categories.
- [ ] Archive README documents layout, privacy, retention, artifacts, and future backend deferral.
- [ ] Regression suite covers positive export/import/analyze plus negative validation cases.
- [ ] Project 8 evidence, future-run comparison, and monitoring sufficiency remain unchecked until real data exists.
