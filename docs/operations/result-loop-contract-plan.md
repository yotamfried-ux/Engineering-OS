# Result Loop Contract Plan

Purpose: make long AI development sessions result-driven instead of instruction-driven. A project task is not controllable until the selected project type has a contract that tells the AI how to run, observe, test, measure, monitor, export telemetry, and repair the work.

This document is a plan, not a readiness claim. Full readiness requires deterministic enforcement for every applicable template/project type.

## Result Loop Contract fields

Every project type contract must define these fields:

1. `setup_command` — how to prepare the local environment.
2. `run_command` — how to run the project locally.
3. `visible_result` — how to view the actual result.
4. `required_tests` — tests/lint/typecheck/e2e commands that must run.
5. `feedback_surfaces` — visual, operational, logical, console, network, and log feedback.
6. `performance_monitoring` — metrics and monitoring tools used to measure performance.
7. `acceptance_metrics` — measurable pass/fail criteria for the requested outcome.
8. `telemetry_export` — how to export metadata-only telemetry to the archive.
9. `failure_repair_loop` — what the AI must do when tests, views, metrics, or monitoring fail.
10. `evidence_artifacts` — exact files, URLs, or artifacts to preserve for review.

## Official documentation references

| Need | Official source | Contract use |
|---|---|---|
| Browser execution and visual/debug feedback | Playwright Trace Viewer: https://playwright.dev/docs/trace-viewer | Store trace.zip/html report on failure; require screenshots, DOM snapshots, console, network, and action-log review for UI work. |
| Visual regression | Playwright visual comparisons: https://playwright.dev/docs/test-snapshots | Require screenshot baselines or explicit waiver for UI/visual changes. |
| Video artifacts | Playwright videos: https://playwright.dev/docs/videos | Preserve videos when e2e or visual flows fail. |
| Observability model | OpenTelemetry observability primer: https://opentelemetry.io/docs/concepts/observability-primer/ | Treat logs, metrics, and traces as first-class feedback surfaces. |
| Telemetry signals | OpenTelemetry signals: https://opentelemetry.io/docs/concepts/signals/ | Require the contract to specify which logs, metrics, traces, and profiles apply. |
| Instrumentation model | OpenTelemetry instrumentation: https://opentelemetry.io/docs/concepts/instrumentation/ | Require code or zero-code instrumentation choice per project type. |
| Metrics and alerting | Prometheus overview: https://prometheus.io/docs/introduction/overview/ | Use pull-style metrics/exporters when a service exposes runtime performance data. |
| Dashboards | Grafana dashboards: https://grafana.com/docs/grafana/latest/visualizations/dashboards/ | Require dashboard or dashboard-like report for service/runtime metrics when applicable. |
| Performance assertions | Lighthouse CI configuration: https://github.com/GoogleChrome/lighthouse-ci/blob/main/docs/configuration.md | Require performance budgets/assertions for web apps. |
| Load thresholds | k6 thresholds: https://grafana.com/docs/k6/latest/using-k6/thresholds/ | Require threshold-based pass/fail criteria for load/performance-sensitive APIs and services. |
| CI evidence transport | GitHub Actions artifacts: https://docs.github.com/en/actions/tutorials/store-and-share-data | Upload traces, screenshots, reports, logs, telemetry bundles, and performance reports as artifacts. |
| Mobile runtime feedback | Expo development builds: https://docs.expo.dev/develop/development-builds/introduction/ | Require device/emulator/development-build path for mobile apps. |
| ML evaluation | MLflow model evaluation: https://mlflow.org/docs/latest/ml/evaluation/ | Require dataset/metric evaluation for ML tasks. |
| Agent/model evaluation | OpenAI Evals: https://platform.openai.com/docs/guides/evals | Require eval sets/graders for AI-agent behavior changes when applicable. |

## Project type matrix

| Project type | Required result-loop feedback |
|---|---|
| web-application | local run command, browser URL, Playwright e2e, visual comparison or waiver, Lighthouse CI, telemetry export, artifact upload. |
| mobile-application | install/run command, emulator/device/development build, screenshot/video evidence, crash/log capture, performance metrics, telemetry export. |
| api-service / microservice | local service command, health endpoint, contract tests, integration tests, k6 or equivalent thresholds when performance-sensitive, OTel/Prometheus metrics, telemetry export. |
| cli-tool | install command, golden output tests, error-path tests, shell logs, telemetry export. |
| data-pipeline / ETL | fixture dataset, dry run, output validation, data quality checks, runtime metrics, telemetry export. |
| machine-learning | dataset fixture, training/inference command, MLflow or equivalent evaluation, metric thresholds, artifact capture, telemetry export. |
| ai-agent / RAG | eval set, trace/eval artifacts, retrieval quality checks, latency/cost/error metrics, failure repair loop, telemetry export. |
| computer-vision / video | fixture media, output artifact, visual review evidence, quality metrics, performance metrics, telemetry export. |
| browser-extension | local extension run/load path, Playwright/browser automation where applicable, screenshots/videos, console/network feedback, telemetry export. |
| desktop-application | local run command, screenshot/video or UI automation evidence, logs/crash capture, performance metrics, telemetry export. |

## Enforcement design

Add a deterministic gate: `scripts/enforcement/check-result-loop-contract.py`.

The gate must:

- Load a manifest such as `scripts/enforcement/result-loop-requirements.tsv` or per-template `result-loop.yaml` files.
- Fail if any template/project type lacks a contract or explicit exemption.
- Fail if a Route Plan targets code/config/test changes without naming the selected result-loop contract.
- Fail if the selected contract omits any required field.
- Fail if UI/web/mobile contracts lack visual feedback or an explicit waiver.
- Fail if service/API/ML/AI contracts lack performance monitoring or metric thresholds where applicable.
- Fail if telemetry export is missing or not linked to `scripts/monitoring/export-telemetry-run.sh` / archive import flow.
- Require positive and negative fixtures in `scripts/enforcement/tests/test-result-loop-contract.sh`.

## Repair loop required behavior

When a feedback surface fails, the AI must:

1. Stop claiming completion.
2. Record the failing signal and artifact path.
3. Identify the likely root cause from tests/logs/traces/metrics, not from guesswork.
4. Apply the smallest targeted fix.
5. Re-run the exact failing check plus the broader required gate set.
6. Export or update telemetry evidence.
7. Update the plan/checklist and only then request review/merge.

## Implementation phases

- [ ] Phase 1: document contract, references, and audit gap.
- [ ] Phase 2: add result-loop contract schema and example file.
- [ ] Phase 3: map every template/project type to a contract or explicit exemption.
- [ ] Phase 4: implement `check-result-loop-contract.py` and required fixtures.
- [ ] Phase 5: wire the check into enforcement-tests and the relevant write gate.
- [ ] Phase 6: update `CLAUDE.md` / `core/workflow.md` so long tasks must select and use a result-loop contract.
- [ ] Phase 7: run Project 8 through the contract and import telemetry evidence.
- [ ] Phase 8: close the gap only after CI enforcement and real target-project evidence exist.

## Non-goals for this planning PR

- Do not claim every project type is already result-loop ready.
- Do not claim monitoring sufficiency before real Project 8 and at least one future comparison run exist.
- Do not store raw user/model text, shell commands, credentials, connector payloads, or private transcript data in telemetry artifacts.
