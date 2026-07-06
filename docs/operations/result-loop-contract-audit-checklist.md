# Result Loop Contract Audit Checklist

Tracking plan: `docs/operations/result-loop-contract-plan.md`

Purpose: track the work needed to make long AI development sessions result-driven across project types. This checklist is not a readiness claim.

## Research references

- [x] Playwright trace viewer researched for traces, screenshots, DOM snapshots, console and network evidence.
- [x] Playwright visual comparisons researched for screenshot baselines and diffs.
- [x] Playwright videos researched for failed-flow artifacts.
- [x] OpenTelemetry concepts researched for logs, metrics, traces and instrumentation.
- [x] Prometheus overview researched for metrics collection and alerting.
- [x] Grafana dashboard docs researched for metrics visualization.
- [x] Lighthouse CI researched for web performance assertions.
- [x] k6 thresholds researched for load and performance criteria.
- [x] GitHub Actions artifacts researched for CI evidence transport.
- [x] Expo development builds researched for mobile runtime feedback and local creator review on device, simulator, or emulator.
- [x] Appium docs researched for mobile, desktop, web, and hybrid user-flow automation.
- [x] Playwright Electron docs researched for desktop app launch, screenshots, console logs, and UI interaction.
- [x] Tauri WebDriver docs researched for desktop app end-to-end testing.
- [x] MDN Learn Web Development researched for web project roadmap and local learning path.
- [x] Android app architecture researched for mobile app architecture roadmap.
- [x] Electron and Tauri start docs researched for desktop app roadmaps.
- [x] FastAPI tutorial researched for API/backend roadmap.
- [x] Click and Python packaging/venv docs researched for CLI roadmap.
- [x] Airflow best-practices docs researched for data-pipeline roadmap.
- [x] MLflow model evaluation researched for ML evaluation loops.
- [x] OpenAI Evals researched for AI-agent evaluation loops.

## Contract design

- [x] Define local run requirement.
- [x] Define visible result requirement.
- [x] Define creator local review requirement.
- [x] Define required tests requirement.
- [x] Define user simulation requirement.
- [x] Define visual feedback requirement.
- [x] Define operational and logical feedback requirement.
- [x] Define monitoring and performance measurement requirement.
- [x] Define acceptance metrics requirement.
- [x] Define code-change impact measurement requirement.
- [x] Define telemetry export requirement.
- [x] Define failure repair-loop requirement.
- [x] Define evidence artifact requirement.
- [x] Explicitly require mobile app result loops to include emulator, simulator, device, or development-build review.
- [x] Explicitly require desktop app result loops to include local app-window review and UI automation.

## Roadmap documentation

- [x] Create `docs/operations/project-type-roadmaps.md`.
- [x] Add roadmap entries for web, mobile, desktop, API/backend, full-stack, CLI, data pipeline, ML, AI/RAG, computer-vision/video, and browser-extension work.
- [x] Link each roadmap family to official documentation references.
- [x] Define required roadmap fields: official sources, creation path, local creator run path, user simulation, quality gates, result evidence, monitoring, change-impact measurement, and telemetry export.

## Audit tracking

- [x] Create result-loop contract plan.
- [x] Create result-loop audit checklist.
- [ ] Add source-of-truth operational readiness audit row.
- [ ] Add non-closed known gap for missing result-loop enforcement.
- [ ] Add regression test for result-loop planning references.

## Enforcement implementation

- [ ] Add result-loop contract schema or manifest.
- [ ] Map every template/project type to a result-loop contract or explicit exemption.
- [ ] Add deterministic result-loop contract gate.
- [ ] Add positive and negative fixtures for the gate.
- [ ] Wire the gate into enforcement-tests.
- [ ] Wire the gate into plan/write policy for long tasks and project work.
- [ ] Update `CLAUDE.md` / `core/workflow.md` to require result-loop contract selection when applicable.
- [ ] Add project-roadmap requirement to the result-loop gate.
- [ ] Fail CI when a template/project type lacks a roadmap entry or explicit exemption.
- [ ] Fail CI when a Route Plan selects a project type but does not name its roadmap entry.
- [ ] Fail CI when a roadmap entry lacks official source references.
- [ ] Fail CI when a roadmap entry lacks local creator run instructions.
- [ ] Fail CI when mobile or desktop roadmaps lack user simulation against the actual app surface.
- [ ] Fail CI when performance or monitoring metrics are missing for app, service, AI, ML, data, mobile, or desktop work.
- [ ] Fail CI when before/after change-impact measurement is missing for user-visible or output-affecting changes.
- [ ] Fail CI when telemetry export is missing from the selected roadmap.
- [ ] Add fixture that fails when a mobile contract lacks local creator review or user simulation.
- [ ] Add fixture that fails when a desktop contract lacks local app-window review or UI automation.
- [ ] Add fixture that fails when mobile or desktop contracts omit before/after change-impact metrics.

## Real-run evidence

- [ ] Run Project 8 using the new result-loop contract.
- [ ] Export telemetry bundle after the run.
- [ ] Import Project 8 telemetry into `telemetry-archive`.
- [ ] Review visual, operational, logical and performance evidence artifacts.
- [ ] Identify missing coverage from the real run.
- [ ] Convert severe or repeated missing coverage into follow-up work.
- [ ] Compare with at least one later target-project run before claiming broad readiness.

## Completion criteria

- [ ] Every applicable template/project type has a result-loop contract.
- [ ] Every applicable template/project type has a roadmap entry or explicit exemption.
- [ ] CI fails when a required roadmap is missing.
- [ ] CI fails when a selected contract omits run, view, local creator review, test, user simulation, feedback, monitoring, telemetry or repair fields.
- [ ] Mobile and desktop contracts prove the creator can run the app locally and inspect progress.
- [ ] Mobile and desktop contracts prove code changes are measured against the actual app surface, not only against unit tests.
- [ ] Project 8 has real result-loop evidence in the archive.
- [ ] At least one later comparison run exists.
- [ ] Monitoring sufficiency is backed by real runs, not planning claims.
