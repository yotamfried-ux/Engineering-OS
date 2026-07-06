# Project Type Roadmaps

Purpose: provide official roadmap sources for building each common project type, then connect those sources to the Result Loop Contract. This file is not a claim that the roadmap gate is already enforced; enforcement is tracked in `docs/operations/result-loop-contract-audit-checklist.md`.

## Roadmap contract

Every applicable project template must map to a roadmap entry or an explicit exemption. A roadmap entry must define:

- official source references;
- creation path: how to start/build the project;
- local creator run path: how the human creator can open and inspect progress locally;
- user simulation path: how to simulate user behavior or real usage;
- quality gates: tests, lint, typecheck, security, accessibility, performance, or eval checks;
- result evidence: screenshots, videos, traces, logs, output files, reports, or eval artifacts;
- monitoring/performance metrics;
- before/after change-impact measurement;
- telemetry export path.

## Project type roadmaps

| Project type | Official roadmap sources | Required local/result loop |
|---|---|---|
| web-application | MDN Learn Web Development; Playwright trace/visual/video docs; Lighthouse CI configuration. | Local URL; browser e2e; screenshots/traces/videos; accessibility and performance checks; telemetry export. |
| mobile-application | Android app architecture; Expo development builds; Appium docs; Apple SwiftUI tutorials when targeting Apple platforms. | Device/simulator/emulator/development build; creator-visible run path; user-flow automation; screenshots/videos; crash/log capture; launch/latency/memory metrics; telemetry export. |
| desktop-application | Electron docs; Tauri start docs; Playwright Electron API; Tauri WebDriver docs; Appium where relevant. | Dev-run or packaged local app window; desktop UI automation; screenshots/videos/logs/crash reports; performance and before/after change-impact metrics; telemetry export. |
| api-service / backend | FastAPI tutorial/user guide or stack-equivalent official docs; OpenAPI docs where applicable; k6 thresholds; OpenTelemetry/Prometheus/Grafana. | Local service run command; health endpoint; contract/integration tests; load/performance thresholds when relevant; logs/metrics/traces; telemetry export. |
| full-stack application | Web roadmap plus API/backend roadmap plus database/migration docs for the selected stack. | Local full-stack run; seed/demo data; browser user flows crossing frontend/backend/database; traces/logs/screenshots/performance reports; telemetry export. |
| cli-tool | Python packaging/user environment docs; Click/Typer or selected CLI framework docs. | Install/run command; help output; golden-output tests; error-path tests; shell completion or argument validation where relevant; telemetry export. |
| data-pipeline / ETL | Airflow best practices or selected orchestrator docs; dbt/docs or selected data-quality framework docs where relevant. | Fixture dataset; dry run/backfill path; output/data-quality validation; runtime metrics; retry/failure behavior; telemetry export. |
| machine-learning | MLflow model evaluation docs; PyTorch/TensorFlow/scikit-learn official tutorials as selected by stack. | Dataset fixture; training/inference command; metric thresholds; artifact capture; before/after metric comparison; telemetry export. |
| ai-agent / RAG | OpenAI Evals docs; selected retrieval/vector-store/framework docs; OpenTelemetry where runtime behavior matters. | Eval set; trace/eval artifacts; retrieval-quality checks; latency/cost/error metrics; failure repair loop; telemetry export. |
| computer-vision / video | OpenCV tutorials; selected model/video framework docs; Result Loop visual review requirements. | Fixture media; output artifact; visual review evidence; quality metrics; runtime/performance metrics; telemetry export. |
| browser-extension | MDN WebExtensions docs plus Playwright/browser automation where applicable. | Local extension load path; browser automation; screenshots/videos/console/network feedback; telemetry export. |

## Enforcement requirement

The future gate must be called from the plan/write policy and CI. It must fail when:

- a project template has no roadmap entry and no explicit exemption;
- a route plan selects a project type but does not name its roadmap entry;
- the selected roadmap has no official source references;
- the selected roadmap lacks local creator run instructions;
- mobile or desktop roadmaps lack user simulation against the actual app surface;
- performance or monitoring metrics are missing for app, service, AI, ML, data, mobile, or desktop work;
- before/after change-impact measurement is missing for user-visible or output-affecting changes;
- telemetry export is missing.

## Source URLs

- MDN Learn Web Development: https://developer.mozilla.org/en-US/docs/Learn_web_development
- Android app architecture: https://developer.android.com/topic/architecture
- Expo development builds: https://docs.expo.dev/develop/development-builds/introduction/
- Apple SwiftUI tutorials: https://developer.apple.com/tutorials/swiftui
- Appium introduction: https://appium.io/docs/en/latest/intro/
- Electron documentation: https://www.electronjs.org/docs/latest/
- Playwright Electron API: https://playwright.dev/docs/api/class-electron
- Tauri start guide: https://tauri.app/start/
- Tauri WebDriver testing: https://tauri.app/develop/tests/webdriver/
- FastAPI tutorial/user guide: https://fastapi.tiangolo.com/tutorial/
- Click documentation: https://click.palletsprojects.com/en/stable/
- Python virtual environments and packages: https://docs.python.org/3/tutorial/venv.html
- Apache Airflow best practices: https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html
- MLflow model evaluation: https://mlflow.org/docs/latest/ml/evaluation/
- OpenAI Evals: https://platform.openai.com/docs/guides/evals
- OpenTelemetry concepts/signals: https://opentelemetry.io/docs/concepts/signals/
- Prometheus overview: https://prometheus.io/docs/introduction/overview/
- Grafana dashboards: https://grafana.com/docs/grafana/latest/visualizations/dashboards/
- k6 thresholds: https://grafana.com/docs/k6/latest/using-k6/thresholds/
- Lighthouse CI configuration: https://github.com/GoogleChrome/lighthouse-ci/blob/main/docs/configuration.md
