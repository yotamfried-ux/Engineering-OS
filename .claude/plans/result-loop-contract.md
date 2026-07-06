# Result Loop Contract Plan

| Field | Value |
|---|---|
| Task type | governance / validation / observability |
| Task class | engineering_os_governance |
| Domain tags | result-loop, testing, observability, monitoring, feedback, templates |
| Plan Scope | standard |
| Planning Mode | approved |
| Target paths | docs/operations/result-loop-contract-plan.md, docs/operations/result-loop-contract-audit-checklist.md, docs/operations/operational-readiness-audit.md, docs/operations/known-gaps.tsv, scripts/enforcement/tests/test-result-loop-contract.sh |
| Task-router evidence | core/task-router.md checked; this is Engineering OS governance and validation infrastructure. |
| Workflow evidence | core/workflow.md checked; plan-file workflow is required before writes. |
| Templates | not applying an app template because this changes Engineering OS policy. |
| Architecture guides | docs/operations/operational-readiness-audit.md, docs/operations/runtime-telemetry-archive-plan.md, patterns/testing/README.md, patterns/observability/README.md |
| Patterns | testing, observability, UI feedback, monitoring, telemetry archive |
| External systems/connectors | GitHub connector; official documentation from Playwright, OpenTelemetry, Prometheus, Grafana, GitHub Actions, Lighthouse CI, k6, Expo, MLflow, OpenAI Evals |
| Skills | not required |
| Validation gates | enforcement-tests, check-readiness-audit.sh, check-known-gaps.sh, test-result-loop-contract.sh |
| Evidence to check | PR diff, enforcement-tests, audit row, known-gap row, official-doc reference list |
| User decisions required | explicit user approval before merge |

## Scope

Create the documented plan and audit tracking for a mandatory Result Loop Contract per project type. The contract must eventually require every selected project template to define how an AI agent runs the project, observes the result, runs tests, collects visual/operational/logical feedback, measures performance, exports telemetry, and repairs failures.

This PR does not claim that every project type is already covered. It records the gap honestly and defines the enforcement path.

## Source of Truth Checks

| Source | Status |
|---|---|
| CLAUDE.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| docs/operations/operational-readiness-audit.md | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/runtime-telemetry-archive-plan.md | checked |
| patterns/testing/README.md | checked |
| patterns/observability/README.md | checked |

## Documentation Asset Evidence

- Playwright trace viewer, visual comparisons, and videos were checked for visual feedback, trace, screenshot, DOM snapshot, console, and network evidence.
- OpenTelemetry concepts, signals, and instrumentation docs were checked for logs, metrics, traces, and instrumentation model.
- Prometheus overview was checked for pull-based metrics and alerting model.
- Grafana dashboards docs were checked for monitoring dashboards.
- Lighthouse CI configuration docs were checked for performance collection and assertions.
- k6 thresholds docs were checked for performance pass/fail thresholds.
- GitHub Actions artifact docs were checked for sharing result-loop evidence from CI.
- Expo development build docs were checked for mobile project runtime feedback.
- MLflow model evaluation docs and OpenAI Evals docs were checked for AI/ML/agent evaluation loops.

## Capability Evidence

- `routing.task-router-read` — task routed as Engineering OS governance.
- `workflow.workflow-read` — workflow source checked before writing.
- `plan.route-plan-before-write` — this plan records target paths and gates before doc/test writes.
- `source.github-repo-read` — GitHub connector read current main audit and gap sources.
- `validation.policy-gap-tracked` — open readiness gap will be linked in known-gaps and audit matrix.
- `validation.result-loop-contract` — new test file will verify plan/checklist/reference presence.

## Connector Evidence

- source: GitHub connector for repository yotamfried-ux/Engineering-OS.
- action: GitHub connector fetch_file and search were used before write decisions.
- result: GitHub connector confirmed that Engineering OS has templates, tests, telemetry archive, and operational-readiness audit, but no explicit Result Loop Contract gate.
- decision: create a plan and audit gap before claiming enforcement; the later implementation must add a deterministic required contract gate.
- target: docs/operations/result-loop-contract-plan.md, docs/operations/result-loop-contract-audit-checklist.md, docs/operations/operational-readiness-audit.md, docs/operations/known-gaps.tsv, scripts/enforcement/tests/test-result-loop-contract.sh.

## Connector Usage Evidence

- source: GitHub connector for yotamfried-ux/Engineering-OS.
- action: GitHub connector fetched docs/operations/operational-readiness-audit.md at sha 78cf82b8ae0d649ffcf1590de42c12500aa2fa3e and docs/operations/known-gaps.tsv at sha aca44cb62600c9d109412252d0cb47bdb700fb2e.
- result: operational-readiness audit already requires non-closed gaps to be linked from matrix rows and known-gaps.tsv already enforces path-backed test/evidence fields.
- decision: add a non-closed gap and a dedicated audit row instead of pretending result-loop enforcement already exists.
- target: docs/operations/operational-readiness-audit.md and docs/operations/known-gaps.tsv.

## Progress Lifecycle Evidence

- start: route plan created before audit, gap, checklist, or test writes.

## DoD

- [ ] Official documentation references are recorded for run, visual feedback, tests, monitoring, performance metrics, telemetry export, and AI/ML evaluation.
- [ ] Operational readiness audit records that Result Loop Contract enforcement is currently missing.
- [ ] Known gap tracks the missing enforcement and points to the plan and test artifact.
- [ ] A dedicated audit checklist records implementation tasks without claiming readiness.
- [ ] A regression test verifies the plan/checklist/reference contract is present.
- [ ] Future implementation path requires a deterministic gate before the gap can close.
