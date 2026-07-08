# Project Type Roadmaps

Purpose: provide official roadmap sources for building each common project type, then connect those sources to the Result Loop Contract. This file is not a claim that the roadmap gate is already enforced; enforcement is tracked in `docs/operations/result-loop-contract-audit-checklist.md`.

Scaling procedure: `docs/operations/scaling-extension-procedure.md` defines how to add new project types, documentation, reference repositories, templates, patterns, skills, and code examples without reinventing the OS.

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
| game-development | Unity Manual and Profiler; Unreal Engine docs; Godot project organization/performance docs; engine-specific test and automation docs. | Editor play mode or local build; creator-visible game surface; gameplay/user simulation through engine tests, input playback, bots, or automation; screenshots/videos/replays/logs/profiler traces; FPS/frame-time/memory/load-time/crash metrics; before/after gameplay and performance comparison; telemetry export. |
| api-service / backend | FastAPI tutorial/user guide or stack-equivalent official docs; OpenAPI docs where applicable; k6 thresholds; OpenTelemetry/Prometheus/Grafana. | Local service run command; health endpoint; contract/integration tests; load/performance thresholds when relevant; logs/metrics/traces; telemetry export. |
| full-stack application | Web roadmap plus API/backend roadmap plus database/migration docs for the selected stack. | Local full-stack run; seed/demo data; browser user flows crossing frontend/backend/database; traces/logs/screenshots/performance reports; telemetry export. |
| cli-tool | Python packaging/user environment docs; Click/Typer or selected CLI framework docs. | Install/run command; help output; golden-output tests; error-path tests; shell completion or argument validation where relevant; telemetry export. |
| data-pipeline / ETL | Airflow best practices or selected orchestrator docs; dbt/docs or selected data-quality framework docs where relevant. | Fixture dataset; dry run/backfill path; output/data-quality validation; runtime metrics; retry/failure behavior; telemetry export. |
| machine-learning | MLflow model evaluation docs; PyTorch/TensorFlow/scikit-learn official tutorials as selected by stack. | Dataset fixture; training/inference command; metric thresholds; artifact capture; before/after metric comparison; telemetry export. |
| ai-agent / RAG | OpenAI Evals docs; selected retrieval/vector-store/framework docs; OpenTelemetry where runtime behavior matters. | Eval set; trace/eval artifacts; retrieval-quality checks; latency/cost/error metrics; failure repair loop; telemetry export. |
| computer-vision / video | OpenCV tutorials; selected model/video framework docs; Result Loop visual review requirements. | Fixture media; output artifact; visual review evidence; quality metrics; runtime/performance metrics; telemetry export. |
| browser-extension | MDN WebExtensions docs plus Playwright/browser automation where applicable. | Local extension load path; browser automation; screenshots/videos/console/network feedback; telemetry export. |
| admin-dashboard | Refine documentation; TanStack Table docs; Tremor component docs; Cloudflare Access docs. | Local Refine admin URL; role-matrix and bulk-export Playwright e2e; table/export screenshots and traces; slow-query and export-latency metrics; before/after query-latency comparison; telemetry export. |
| crm-system | Gmail API guides; Twenty CRM developer docs; Supabase Row Level Security docs; Microsoft Graph Mail API docs. | Local CRM URL; pipeline and email-sync Playwright e2e; pipeline board and timeline screenshots and traces; email-sync-lag and query-time metrics; before/after pipeline-query comparison; telemetry export. |
| saas-platform | Stripe Billing/Subscriptions docs; Supabase Auth and RLS docs; Clerk Organizations docs; Next.js docs. | Local tenant admin URL; tenant-isolation and billing Playwright e2e; billing portal screenshots and Stripe webhook traces; tenant-query-latency and webhook-processing metrics; before/after tenant-query comparison; telemetry export. |
| marketplace | Stripe Connect docs; Medusa commerce docs; Stripe Identity docs; Algolia InstantSearch docs. | Local marketplace URL; checkout and payout Playwright e2e; checkout and dispute-flow screenshots and traces; checkout-error and payout-failure-rate metrics; before/after checkout-latency comparison; telemetry export. |
| booking-system | Google Calendar API guides; Cal.com developer docs; Microsoft Graph Calendar API docs; RFC 5545 (iCalendar); Stripe Payment Intents docs. | Local booking URL; concurrent-booking and calendar-sync Playwright e2e; availability-calendar screenshots and iCal traces; booking-failure and reminder-error-rate metrics; before/after conflict-guard-latency comparison; telemetry export. |

## Enforcement requirement

The future gate must be called from the plan/write policy and CI. It must fail when:

- a project template has no roadmap entry and no explicit exemption;
- a route plan selects a project type but does not name its roadmap entry;
- the selected roadmap has no official source references;
- the selected roadmap lacks local creator run instructions;
- mobile or desktop roadmaps lack user simulation against the actual app surface;
- game-development roadmaps lack local playable surface, gameplay simulation, visual evidence, performance metrics, and change-impact comparison;
- performance or monitoring metrics are missing for app, service, AI, ML, data, mobile, desktop, or game work;
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
- Unity Manual: https://docs.unity3d.com/Manual/index.html
- Unity Profiler: https://docs.unity3d.com/Manual/Profiler.html
- Unreal Engine documentation: https://dev.epicgames.com/documentation/en-us/unreal-engine
- Godot project organization: https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html
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
- Refine documentation: https://refine.dev/docs/
- TanStack Table: https://tanstack.com/table/latest/docs/introduction
- Tremor components: https://www.tremor.so/docs/getting-started/installation
- Cloudflare Access: https://developers.cloudflare.com/cloudflare-one/policies/access/
- Gmail API guides: https://developers.google.com/gmail/api/guides
- Twenty CRM developer docs: https://twenty.com/developers
- Supabase Row Level Security: https://supabase.com/docs/guides/database/row-level-security
- Microsoft Graph Mail API: https://learn.microsoft.com/en-us/graph/api/resources/mail-api-overview
- Stripe Billing/Subscriptions: https://stripe.com/docs/billing/subscriptions/overview
- Supabase Auth: https://supabase.com/docs/guides/auth
- Clerk Organizations: https://clerk.com/docs/organizations/overview
- Next.js documentation: https://nextjs.org/docs
- Stripe Connect: https://stripe.com/docs/connect
- Medusa documentation: https://docs.medusajs.com
- Stripe Identity: https://stripe.com/docs/identity
- Algolia InstantSearch: https://www.algolia.com/doc/guides/building-search-ui/what-is-instantsearch/js/
- Google Calendar API: https://developers.google.com/calendar/api/guides/overview
- Cal.com developer docs: https://cal.com/docs
- Microsoft Graph Calendar API: https://learn.microsoft.com/en-us/graph/api/resources/calendar
- RFC 5545 — iCalendar: https://datatracker.ietf.org/doc/html/rfc5545
- Stripe Payment Intents: https://stripe.com/docs/payments/payment-intents
