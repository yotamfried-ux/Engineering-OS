# Result Loop Contract Plan

Purpose: make long AI development sessions result-driven instead of instruction-driven. A project task is not controllable until the selected project type has a contract that tells the AI how to run, observe, test, measure, monitor, export telemetry, and repair the work.

This document is a plan, not a readiness claim. Full readiness requires deterministic enforcement for every applicable template/project type.

**Per-PR declaration decision:** the per-PR "does this PR declare its result-loop contract" dimension of `gap:result-loop-contract-enforcement` is satisfied by the CI-generated Operational Work History artifact and gate (`docs/operations/operational-work-history.md`, `gap:operational-work-history-foundation`), not by wiring `check-route-plan-contract.sh`'s 8-field Route Plan requirement into CI. That checker stays unwired by explicit design.

A real `chatgpt-codex-connector` review on PR #237 found that the artifact/gate did not, at that point, actually implement this dimension — it only covered `automatic_sources:` and learning-loop routing. `docs/operations/operational-work-history.md`'s "Result-loop contract selection" section now implements it: the collector deterministically derives `selected_result_loop_contract` from changed paths (`templates/<project_type_id>/...` maps to that project type; every other changed path — Engineering OS's own governance/tooling surface — maps to a new non-scaffolded sentinel id, `engineering-os-governance`, registered as a `status=exempt` row in `result-loop-requirements.tsv`/`project-type-roadmaps.tsv` so it does not pull in `check-scaling-extension.py`'s active-project documentation/pattern/skill coverage requirements), and only asks for one minimal declared PR-body field when derivation is genuinely ambiguous. This closes the semantic gap the 8-field checker was meant to catch without reviving it.

## Result Loop Contract fields

Every project type contract must define these fields:

1. `setup_command` — how to prepare the local environment.
2. `run_command` — how to run the project locally.
3. `visible_result` — how to view the actual result.
4. `creator_local_review` — how the human creator can run and inspect the app locally when they want to see progress.
5. `required_tests` — tests/lint/typecheck/e2e commands that must run.
6. `user_simulation` — how realistic user behavior is simulated for the app type.
7. `feedback_surfaces` — visual, operational, logical, console, network, and log feedback.
8. `performance_monitoring` — metrics and monitoring tools used to measure performance.
9. `acceptance_metrics` — measurable pass/fail criteria for the requested outcome.
10. `change_impact_measurement` — how the effect of a code change is measured against the previous result.
11. `telemetry_export` — how to export metadata-only telemetry to the archive.
12. `failure_repair_loop` — what the AI must do when tests, views, metrics, or monitoring fail.
13. `evidence_artifacts` — exact files, URLs, or artifacts to preserve for review.

## Local creator visibility requirement

Every application contract must include a local path that the human creator can run without depending only on CI. For web apps this is usually a local URL. For mobile apps it must be a device, simulator, emulator, or development build path. For desktop apps it must be a local packaged or dev-run app window. If the app cannot run locally, the contract must include an explicit reason and a preview alternative with artifacts.

The local path must define:

- exact setup command;
- exact run command;
- expected visible surface, such as URL, emulator, simulator, device, or desktop window;
- seed/demo data needed to see a representative flow;
- expected screenshots/videos/traces/logs generated after a run;
- how the creator can compare progress before and after a code change.

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
| Mobile local development | Expo development builds: https://docs.expo.dev/develop/development-builds/introduction/ | Require a production-like local development build, simulator, emulator, or device path for mobile apps. |
| Mobile and desktop user simulation | Appium introduction: https://appium.io/docs/en/latest/intro/ | Use driver/client-based automation to simulate user flows on mobile, desktop, web, or hybrid apps when applicable. |
| Electron desktop automation | Playwright Electron API: https://playwright.dev/docs/api/class-electron | Launch Electron apps, inspect windows, capture screenshots, forward console logs, and click through desktop UI flows. |
| Tauri desktop automation | Tauri WebDriver testing: https://tauri.app/develop/tests/webdriver/ | Require WebDriver-based e2e testing for Tauri desktop apps where applicable. |
| ML evaluation | MLflow model evaluation: https://mlflow.org/docs/latest/ml/evaluation/ | Require dataset/metric evaluation for ML tasks. |
| Agent/model evaluation | OpenAI Evals: https://platform.openai.com/docs/guides/evals | Require eval sets/graders for AI-agent behavior changes when applicable. |

## Project type matrix

| Project type | Required result-loop feedback |
|---|---|
| web-application | local run command, browser URL for creator review, Playwright e2e, visual comparison or waiver, Lighthouse CI, telemetry export, artifact upload. |
| mobile-application | install/run command, emulator/device/development build for creator review, Appium or stack-native user-flow automation, screenshot/video evidence, crash/log capture, performance metrics, change-impact comparison, telemetry export. |
| api-service / microservice | local service command, health endpoint, contract tests, integration tests, k6 or equivalent thresholds when performance-sensitive, OTel/Prometheus metrics, telemetry export. |
| cli-tool | install command, golden output tests, error-path tests, shell logs, telemetry export. |
| data-pipeline / ETL | fixture dataset, dry run, output validation, data quality checks, runtime metrics, telemetry export. |
| machine-learning | dataset fixture, training/inference command, MLflow or equivalent evaluation, metric thresholds, artifact capture, telemetry export. |
| ai-agent / RAG | eval set, trace/eval artifacts, retrieval quality checks, latency/cost/error metrics, failure repair loop, telemetry export. |
| computer-vision / video | fixture media, output artifact, visual review evidence, quality metrics, performance metrics, telemetry export. |
| browser-extension | local extension run/load path, Playwright/browser automation where applicable, screenshots/videos, console/network feedback, telemetry export. |
| desktop-application | local dev-run or packaged app window for creator review, framework-specific automation such as Playwright Electron, Tauri WebDriver, Appium, or native UI automation, screenshots/videos, console/log/crash capture, performance metrics, change-impact comparison, telemetry export. |

## Mobile and desktop minimum contract

Mobile and desktop app contracts must not be treated as weaker than web app contracts. They must include:

- local run instructions that open the actual app surface, not only unit tests;
- a creator-visible path for seeing progress on a simulator, emulator, device, or desktop window;
- automated user simulation for at least the main happy path and one failure path;
- screenshots or video after key flows;
- logs, console output, crash reports, or equivalent runtime diagnostics;
- performance metrics such as launch time, interaction latency, memory/CPU where practical, and error/crash rate;
- before/after comparison for code changes that affect user-visible behavior;
- telemetry export into the archive after meaningful runs.

## Enforcement design

Add a deterministic gate: `scripts/enforcement/check-result-loop-contract.py`.

The gate must:

- Load a manifest such as `scripts/enforcement/result-loop-requirements.tsv` or per-template `result-loop.yaml` files.
- Fail if any template/project type lacks a contract or explicit exemption.
- Fail if a Route Plan targets code/config/test changes without naming the selected result-loop contract.
- Fail if the selected contract omits any required field.
- Fail if UI/web/mobile/desktop contracts lack visual feedback, user simulation, creator-local review, or an explicit waiver.
- Fail if service/API/ML/AI/mobile/desktop contracts lack performance monitoring or metric thresholds where applicable.
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
- Redact or exclude evidence artifacts before export or archive when they may contain raw user/model text, shell commands, credentials, connector payloads, private transcript data, personal data, or other secrets.
