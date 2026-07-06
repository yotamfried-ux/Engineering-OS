# Result Loop Contract Audit Checklist

Tracking plan: `docs/operations/result-loop-contract-plan.md`
Scaling procedure: `docs/operations/scaling-extension-procedure.md`
Roadmap catalog: `docs/operations/project-type-roadmaps.md`

Purpose: track the work needed to make long AI development sessions result-driven and scalable across project types. This checklist is not a readiness claim.

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
- [x] Unity Manual and Profiler researched for game-development roadmap and performance profiling.
- [x] Godot project organization docs researched for game-development project structure.
- [x] Unreal Engine documentation identified as a game-development source.
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
- [x] Add roadmap entries for web, mobile, desktop, game-development, API/backend, full-stack, CLI, data pipeline, ML, AI/RAG, computer-vision/video, and browser-extension work.
- [x] Link each roadmap family to official documentation references.
- [x] Define required roadmap fields: official sources, creation path, local creator run path, user simulation, quality gates, result evidence, monitoring, change-impact measurement, and telemetry export.

## Scaling procedure

- [x] Create `docs/operations/scaling-extension-procedure.md`.
- [x] Define a fixed extension path for new project types, documentation sources, reference repositories, templates, patterns, skills, code examples, and connectors.
- [x] Define the complete checklist for adding a new project type without one-off work.
- [x] Add game-development as the concrete scaling example.
- [x] Define manifest-driven target architecture for scalable extension.
- [ ] Add source-of-truth scaling audit row in `docs/operations/operational-readiness-audit.md`.
- [ ] Add non-closed known gap for missing scaling enforcement in `docs/operations/known-gaps.tsv`.

## Scaling category coverage

- [ ] Project types: every supported project type has a template row, roadmap row, result-loop contract row, and routing rule or explicit exemption.
- [ ] Templates: every `templates/<id>/` directory has a `template-requirements.tsv` row and a roadmap/result-loop mapping.
- [ ] Documentation: every required documentation source has source URL, reason, freshness/version note, target path, consult rule, fallback/waiver behavior, and audit linkage.
- [ ] Reference repositories: every approved reference repo has URL, owner/source type, relevance, supported template, license/usage note, freshness status, and validation evidence.
- [ ] Patterns: every required pattern family has an inventory row, usage rule, enforcement rule, or explicit exemption.
- [ ] Skills: every required skill has an inventory row, trigger rule, evidence rule, or explicit exemption.
- [ ] Code examples: every starter/example has a run path, validation path, owner/source, supported template, and stale/unverified status when not validated.
- [ ] Connectors: every connector-dependent workflow has a connector inventory entry, usage evidence requirement, fallback rule, and audit linkage.
- [ ] Telemetry: every new extension type defines how metadata-only telemetry is exported and imported into the archive.
- [ ] Waivers: every exemption has a reason, owner/context, scope, expiry or revisit trigger, and audit linkage.

## Scaling manifests to add

- [ ] Add `scripts/enforcement/project-type-roadmaps.tsv` for roadmap coverage by project type.
- [ ] Add `scripts/enforcement/result-loop-requirements.tsv` for required result-loop fields by project type.
- [ ] Add `scripts/enforcement/documentation-sources.tsv` for required official/trusted documentation sources.
- [ ] Add `scripts/enforcement/reference-repositories.tsv` for approved reference repositories and freshness/validation state.
- [ ] Add `scripts/enforcement/code-example-requirements.tsv` for example ownership, run path, validation path, and supported template.
- [ ] Add `scripts/enforcement/pattern-requirements.tsv` or equivalent inventory for required patterns.
- [ ] Add `scripts/enforcement/skill-requirements.tsv` or equivalent inventory for required skills.
- [ ] Add or extend connector inventory requirements for connector-dependent workflows.
- [ ] Document the schema for each manifest, including required columns and allowed exemption states.

## Scaling gate implementation

- [ ] Implement deterministic scaling gate, such as `scripts/enforcement/check-scaling-extension.py`.
- [ ] Reuse or extend existing template coverage checks so new template directories cannot bypass `template-requirements.tsv`.
- [ ] Fail CI when a new project type appears in templates, docs, route plans, or roadmap files without all required registry mappings.
- [ ] Fail CI when roadmap rows lack official source references.
- [ ] Fail CI when documentation sources lack reason, freshness/version note, consult rule, or fallback/waiver behavior.
- [ ] Fail CI when reference repositories lack license/usage note, relevance, freshness status, or validation evidence.
- [ ] Fail CI when code examples lack a run path or validation path.
- [ ] Fail CI when patterns or skills are referenced by workflows without inventory/rule coverage.
- [ ] Fail CI when connector-dependent workflows lack connector evidence requirements or fallback behavior.
- [ ] Fail CI when telemetry export is missing from a new project type, template, or result-loop contract.
- [ ] Fail CI when a waiver/exemption is malformed, unscoped, or not linked to audit/known gaps.
- [ ] Fail CI when audit marks a scaling item complete before the corresponding enforcement artifact exists.

## Scaling fixtures and regression tests

- [ ] Add positive fixture: a fully registered project type passes scaling enforcement.
- [ ] Add negative fixture: a new template directory without `template-requirements.tsv` row fails.
- [ ] Add negative fixture: a new project type without roadmap row fails.
- [ ] Add negative fixture: a roadmap row without official sources fails.
- [ ] Add negative fixture: documentation source without freshness/version note or consult rule fails.
- [ ] Add negative fixture: reference repository without license/usage/freshness status fails.
- [ ] Add negative fixture: code example without run/validation path fails.
- [ ] Add negative fixture: pattern/skill referenced by workflow without inventory coverage fails.
- [ ] Add negative fixture: connector-dependent workflow without connector evidence rule fails.
- [ ] Add negative fixture: waiver without scope/reason/audit link fails.
- [ ] Add game-development fixture proving playable local surface, gameplay simulation, visual evidence, performance metrics, and telemetry are required.
- [ ] Wire scaling fixtures into `enforcement-tests`.

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
- [ ] Fail CI when game-development roadmaps lack local playable surface, gameplay simulation, visual evidence, performance metrics, or change-impact comparison.
- [ ] Fail CI when performance or monitoring metrics are missing for app, service, AI, ML, data, mobile, desktop, or game work.
- [ ] Fail CI when before/after change-impact measurement is missing for user-visible or output-affecting changes.
- [ ] Fail CI when telemetry export is missing from the selected roadmap.
- [ ] Add scaling-extension requirement to the result-loop gate.
- [ ] Fail CI when a new template directory is added without a template requirement row.
- [ ] Fail CI when a new project type is named in docs or route plans but lacks a roadmap entry or explicit exemption.
- [ ] Fail CI when a new reference repository lacks source, license/usage note, relevance, and freshness status.
- [ ] Fail CI when a code example lacks a run or validation path.
- [ ] Fail CI when audit marks scaling complete before enforcement artifacts exist.
- [ ] Add fixture that fails when a mobile contract lacks local creator review or user simulation.
- [ ] Add fixture that fails when a desktop contract lacks local app-window review or UI automation.
- [ ] Add fixture that fails when mobile or desktop contracts omit before/after change-impact metrics.
- [ ] Add fixture that fails when game-development lacks a playable local surface and performance metrics.

## Real-run evidence

- [ ] Run Project 8 using the new result-loop contract.
- [ ] Export telemetry bundle after the run.
- [ ] Import Project 8 telemetry into `telemetry-archive`.
- [ ] Review visual, operational, logical and performance evidence artifacts.
- [ ] Identify missing coverage from the real run.
- [ ] Convert severe or repeated missing coverage into follow-up work.
- [ ] Compare with at least one later target-project run before claiming broad readiness.
- [ ] Run a scaling simulation that adds a new dummy project type and proves enforcement accepts a complete registration.
- [ ] Run a scaling simulation that adds an incomplete project type and proves enforcement rejects it.
- [ ] Run a scaling simulation for adding a documentation source, reference repository, and code example.

## Completion criteria

- [ ] Every applicable template/project type has a result-loop contract.
- [ ] Every applicable template/project type has a roadmap entry or explicit exemption.
- [ ] Every extension type has a fixed add/update path and enforcement rule or explicit exemption.
- [ ] Every scaling manifest exists and has schema validation.
- [ ] CI fails when a required roadmap is missing.
- [ ] CI fails when scaling additions bypass registries/manifests.
- [ ] CI fails when docs, reference repos, examples, patterns, skills, or connectors are added without required metadata and enforcement coverage.
- [ ] CI fails when a selected contract omits any required field from the plan: `setup_command`, `run_command`, `visible_result`, `creator_local_review`, `required_tests`, `user_simulation`, `feedback_surfaces`, `performance_monitoring`, `acceptance_metrics`, `change_impact_measurement`, `telemetry_export`, `failure_repair_loop`, or `evidence_artifacts`.
- [ ] Mobile and desktop contracts prove the creator can run the app locally and inspect progress.
- [ ] Mobile and desktop contracts prove code changes are measured against the actual app surface, not only against unit tests.
- [ ] Game-development contracts prove a playable local surface, automated gameplay simulation, visual evidence, and performance metrics.
- [ ] Scaling simulations prove both complete additions and rejected incomplete additions.
- [ ] Project 8 has real result-loop evidence in the archive.
- [ ] At least one later comparison run exists.
- [ ] Monitoring sufficiency is backed by real runs, not planning claims.
