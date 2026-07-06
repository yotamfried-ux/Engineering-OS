# Runtime Telemetry Archive Implementation Plan

| Field | Value |
|---|---|
| Task type | infra / observability / Engineering OS governance |
| Task class | engineering_os_governance |
| Domain tags | observability, testing, governance, workflow |
| Plan Scope | standard |
| Planning Mode | approved |
| Target paths | scripts/monitoring/export-telemetry-run.sh, scripts/monitoring/import-telemetry-run.py, scripts/monitoring/analyze-telemetry-archive.py, scripts/enforcement/tests/test-telemetry-archive.sh, telemetry-archive/README.md, telemetry-archive/indexes/*, docs/operations/runtime-telemetry-archive-audit-checklist.md |
| Patterns | patterns/observability/README.md, patterns/testing/README.md |
| Connector | GitHub |
| Validation gates | bash -n, python3 -m py_compile, test-telemetry-archive.sh, GitHub Actions, CodeRabbit review |

## Scope

Implement the local export/import/analyze archive layer described in `docs/operations/runtime-telemetry-archive-plan.md` without claiming monitoring readiness. This creates a durable metadata-only archive so Project 8 and later target-project runs can be imported and compared after real telemetry exists.

## Source-of-truth checks

- `CLAUDE.md`, `core/task-router.md`, `core/workflow.md`, and `core/coderabbit-policy.md` were checked before implementation.
- `docs/operations/runtime-telemetry-archive-plan.md` and `docs/operations/runtime-telemetry-archive-audit-checklist.md` define the implementation scope.
- `scripts/monitoring/eos-telemetry-event.sh` and `scripts/monitoring/eos-telemetry-summary.py` define the current local telemetry baseline.
- Official docs checked: Claude Code hooks, OpenTelemetry Collector components, and GitHub Actions artifacts.

## Capability Evidence

- `routing.task-router-read` — task routed as infra/observability plus Engineering OS governance.
- `workflow.workflow-read` — `.claude/plans/` fallback used because Notion is unavailable here.
- `plan.route-plan-before-write` — this plan records target paths and validation gates before implementation writes.
- `source.github-repo-read` — GitHub connector read current main files before branching.
- `validation.policy-change-has-validator` — new archive behavior ships with `scripts/enforcement/tests/test-telemetry-archive.sh`.
- `validation.coderabbit-policy` — dedicated branch and PR; merge requires Actions, review, and explicit user approval.

## Connector Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS`.
- action: read current main source files and telemetry docs before implementation.
- result: confirmed PR #205 provides local metadata telemetry and PR #206 defines archive/export/import/analyze as the next step.
- decision: implement local file-bundle archive first; do not build Collector/backend yet.
- target: monitoring scripts, archive README/indexes, archive test suite, and runtime telemetry archive checklist.

## DoD evidence

- Export command emits `manifest.json`, `events.jsonl`, and `latest-summary.md` only.
- Import command validates manifest, JSONL, required event fields, privacy contract, and duplicate imports.
- Analyzer produces markdown comparing counts, coverage, and command categories.
- Archive README documents layout, privacy, retention, artifacts, and future Collector deferral.
- Fixture suite covers positive export/import/analyze plus negative validation cases.
- Project 8 evidence, future-run comparison, and monitoring sufficiency remain unchecked until real data exists.
