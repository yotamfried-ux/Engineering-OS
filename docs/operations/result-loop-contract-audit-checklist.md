# Result Loop Contract Audit Checklist

Tracking plan: `docs/operations/result-loop-contract-plan.md`
Scaling procedure: `docs/operations/scaling-extension-procedure.md`
Roadmap catalog: `docs/operations/project-type-roadmaps.md`

Purpose: track the work needed to make long AI development sessions result-driven and scalable across project types. This checklist is not a readiness claim.

**Per-PR declaration cross-reference:** see `docs/operations/operational-work-history.md` and `gap:operational-work-history-foundation` for the resolved decision on the per-PR result-loop declaration dimension — it is satisfied by a CI-generated artifact/gate, not by wiring `check-route-plan-contract.sh`'s 8-field Route Plan requirement into CI.

**2026-07-10 reconciliation note:** `docs/operations/known-gaps.tsv` and `docs/operations/operational-readiness-audit.md` mark `result-loop-contract-enforcement` and `scaling-extension-enforcement` `closed`, but several sections below were still fully unchecked, contradicting that status. This pass re-verified every item against the actual current enforcer code (`scripts/enforcement/check-result-loop-contract.py`, `scripts/enforcement/check-scaling-extension.py`) and by running both checkers plus `scripts/enforcement/tests/test-result-loop-contract.sh` and `scripts/enforcement/tests/test-scaling-extension.sh` locally against `main` (all passed, all negative fixtures genuinely rejected). Items are now checked only where a concrete artifact/test backs them; genuinely unimplemented items stay unchecked. This does **not** reopen `result-loop-contract-enforcement` or `scaling-extension-enforcement` — their gap-level closure bar was already explicit that some narrower items (e.g. `check-route-plan-contract.sh` staying unwired) were intentionally left open. It also does not touch `monitoring-metrics-sufficiency` (open) or `project-8-real-run-evidence` (blocked), which remain the reason the real-run sections below stay unchecked.

## Per-PR declaration dimension (result-loop-contract-enforcement)

- [x] Implementation exists: `derive_result_loop_contract` in `scripts/monitoring/collect-pr-work-history.py`, validated by `scripts/enforcement/check-operational-work-history-evidence.sh`.
- [x] Fixture tests pass: `scripts/enforcement/tests/test-collect-pr-work-history.sh` and `scripts/enforcement/tests/test-operational-work-history-evidence.sh` cover derived, declared-valid, missing/ambiguous, unknown-id, placeholder, declared-unrelated-to-diff, not-required, stale-artifact, and PR-body-cannot-override cases.
- [x] Real positive PR evidence exists: [PR #239](https://github.com/yotamfried-ux/Engineering-OS/pull/239) — governance-only diff, CI green, artifact derived `selected_result_loop_contract=engineering-os-governance`.
- [x] Real negative PR evidence exists: [PR #240](https://github.com/yotamfried-ux/Engineering-OS/pull/240) — genuinely ambiguous diff, no declaration, real `pr-policy` failure with the expected `ERROR_FOR_AGENT` reproduced across two CI runs, closed without merging.
- [x] Review threads resolved and CI green on both: PR #239's chatgpt-codex-connector classification-bug thread and CodeRabbit markdown-lint thread are both resolved; CI green on PR #239 (enforcement-tests, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy); PR #240's only real failure was the intended result-loop-contract one, all other real gates green.

`gap:result-loop-contract-enforcement` in `docs/operations/known-gaps.tsv` is closed — all rows above are checked.

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
- [x] Add source-of-truth scaling audit row in `docs/operations/operational-readiness-audit.md`.
- [x] Add non-closed known gap for missing scaling enforcement in `docs/operations/known-gaps.tsv`.

## Scaling category coverage

> Not re-checked row-by-row in this pass. `check-scaling-extension.py` enforces roadmap/result-loop/documentation/pattern/skill coverage for every `status=active` roadmap row (verified: 22 active + 1 exempt rows, 0 deferred, local run clean) and rejects unregistered template directories unconditionally, but it does not validate every field these bullets describe (e.g. "audit linkage" or "expiry/revisit trigger" on waivers) and coverage for non-active rows is not required. Treat this section as a genuine, narrower inventory-completeness gap, not as blocking `scaling-extension-enforcement`'s closure — see the notes on that gap in `docs/operations/known-gaps.tsv`.

- [ ] Project types: every supported project type has a template row, roadmap row, result-loop contract row, and routing rule or explicit exemption.
- [ ] Templates: every `templates/<id>/` directory has a `template-requirements.tsv` row and a roadmap/result-loop mapping.
- [ ] Documentation: every required documentation source has source URL, reason, freshness/version note, target path, consult rule, fallback/waiver behavior, and audit linkage.
- [ ] Reference repositories: every approved reference repo has URL, owner/source type, relevance, supported template, license/usage note, freshness status, and validation evidence.
- [ ] Patterns: every required pattern family has an inventory row, usage rule, enforcement rule, or explicit exemption.
- [ ] Skills: every required skill has an inventory row, trigger rule, evidence rule, or explicit exemption.
- [ ] Code examples: every starter/example has a run path, validation path, owner/source, supported template, and stale/unverified status when not validated.
- [ ] Connectors: every connector-dependent workflow has a connector inventory entry, usage evidence requirement, fallback rule, and audit linkage.
- [ ] Telemetry: every new extension type defines how metadata-only telemetry is exported and imported into the telemetry store.
- [ ] Waivers: every exemption has a reason, owner/context, scope, expiry or revisit trigger, and audit linkage.

## Scaling manifests to add

- [x] Add `scripts/enforcement/project-type-roadmaps.tsv` for roadmap coverage by project type.
- [x] Add `scripts/enforcement/result-loop-requirements.tsv` for required result-loop fields by project type.
- [x] Add `scripts/enforcement/documentation-sources.tsv` for required official/trusted documentation sources.
- [x] Add `scripts/enforcement/reference-repositories.tsv` for approved reference repositories and freshness/validation state.
- [x] Add `scripts/enforcement/code-example-requirements.tsv` for example ownership, run path, validation path, and supported template.
- [x] Add `scripts/enforcement/pattern-requirements.tsv` or equivalent inventory for required patterns.
- [x] Add `scripts/enforcement/skill-requirements.tsv` or equivalent inventory for required skills.
- [x] Add or extend connector inventory requirements for connector-dependent workflows.
- [x] Document the schema for each manifest, including required columns and allowed exemption states.

## Scaling gate implementation

> Re-verified 2026-07-10 by reading `scripts/enforcement/check-scaling-extension.py` in full and running it plus `scripts/enforcement/tests/test-scaling-extension.sh` locally against `main` (both pass, all 7 negative fixtures reject as expected).

- [x] Implement deterministic scaling gate, such as `scripts/enforcement/check-scaling-extension.py`.
- [x] Reuse or extend existing template coverage checks so new template directories cannot bypass `template-requirements.tsv`. — enforced unconditionally (`unregistered template directory` + `kind=project template lacks project-type-roadmap row` checks).
- [x] Fail CI when a new project type appears in templates, docs, route plans, or roadmap files without all required registry mappings. — enforced (`project type referenced without roadmap`, `lacks result loop/documentation/pattern/skill coverage`).
- [ ] Fail CI when roadmap rows lack official source references. — not enforced as a specific field check; only generic non-empty-cell validation applies.
- [x] Fail CI when documentation sources lack reason, freshness/version note, consult rule, or fallback/waiver behavior. — enforced (`source_url`/`freshness_note`/`consult_rule`/`fallback_or_waiver`, min length 4).
- [ ] Fail CI when reference repositories lack license/usage note, relevance, freshness status, or validation evidence. — `reference-repositories.tsv` only gets generic status/non-empty-cell validation; no field-specific rule exists yet.
- [ ] Fail CI when code examples lack a run path or validation path. — same gap as reference repositories; no field-specific rule exists yet.
- [x] Fail CI when patterns or skills are referenced by workflows without inventory/rule coverage. — enforced (per-project pattern/skill coverage check).
- [ ] Fail CI when connector-dependent workflows lack connector evidence requirements or fallback behavior. — `connector-workflow-requirements.tsv` only gets generic validation; no field-specific rule exists yet.
- [x] Fail CI when telemetry export is missing from a new project type, template, or result-loop contract. — enforced, but by the sibling `check-result-loop-contract.py` gate (`telemetry_export` field requires the literal `scripts/monitoring/export-telemetry-run.sh` path), not by the scaling checker itself.
- [ ] Fail CI when a waiver/exemption is malformed, unscoped, or not linked to audit/known gaps. — only `exemption_state` enum membership is validated; audit/known-gaps linkage is not checked.
- [ ] Fail CI when audit marks a scaling item complete before the corresponding enforcement artifact exists. — no such meta-check exists in any current script.

## Scaling fixtures and regression tests

> Re-verified 2026-07-10 by running `scripts/enforcement/tests/test-scaling-extension.sh` locally; each `expect_reject` case below was confirmed to actually reject.

- [x] Add positive fixture: a fully registered project type passes scaling enforcement.
- [x] Add negative fixture: a new template directory without `template-requirements.tsv` row fails. (`missing-template`)
- [x] Add negative fixture: a new project type without roadmap row fails. (`missing-roadmap`, `missing-project-type-roadmap`)
- [ ] Add negative fixture: a roadmap row without official sources fails. — no such fixture exists.
- [x] Add negative fixture: documentation source without freshness/version note or consult rule fails. (`missing-docs-metadata`)
- [ ] Add negative fixture: reference repository without license/usage/freshness status fails. — no such fixture exists.
- [ ] Add negative fixture: code example without run/validation path fails. — no such fixture exists.
- [x] Add negative fixture: pattern/skill referenced by workflow without inventory coverage fails. (`missing-pattern-skill`)
- [ ] Add negative fixture: connector-dependent workflow without connector evidence rule fails. — no such fixture exists.
- [ ] Add negative fixture: waiver without scope/reason/audit link fails. — no such fixture exists.
- [x] Add game-development fixture proving playable local surface, gameplay simulation, visual evidence, performance metrics, and telemetry are required. (`missing-game-evidence`)
- [x] Wire scaling fixtures into `enforcement-tests`. — `test-scaling-extension.sh` runs in the `test-[s-z]*.sh` group step and the full aggregate `test-*.sh` sweep.

## Audit tracking

- [x] Create result-loop contract plan.
- [x] Create result-loop audit checklist.
- [x] Add source-of-truth operational readiness audit row.
- [x] Add non-closed known gap for missing result-loop enforcement.
- [ ] Add regression test for result-loop planning references. — no dedicated regression test exists that checks this checklist/plan stays in sync with `known-gaps.tsv`; this reconciliation pass was manual.

## Enforcement implementation

> Re-verified 2026-07-10 by reading `scripts/enforcement/check-result-loop-contract.py` in full and running it plus `scripts/enforcement/tests/test-result-loop-contract.sh` locally against `main` (both pass, all 6 negative fixtures reject as expected). Roughly half of the items below are genuinely enforced; the rest are real, narrower gaps left open by design or not yet implemented — none of them block `result-loop-contract-enforcement`'s gap-level closure, which already scoped `check-route-plan-contract.sh` as intentionally unwired.

- [x] Add result-loop contract schema or manifest.
- [x] Map every template/project type to a result-loop contract or explicit exemption.
- [x] Add deterministic result-loop contract gate.
- [x] Add positive and negative fixtures for the gate.
- [x] Wire the gate into enforcement-tests.
- [ ] Wire the gate into plan/write policy for long tasks and project work. — `check-route-plan-contract.sh`'s 8-field Route Plan requirement stays unwired by design (see `docs/operations/known-gaps.tsv`'s `result-loop-contract-enforcement` row).
- [ ] Update `CLAUDE.md` / `core/workflow.md` to require result-loop contract selection when applicable. — confirmed via direct search: neither file mentions "result loop" or "result-loop" anywhere.
- [x] Add project-roadmap requirement to the result-loop gate. — `check()` cross-validates both directions: every active roadmap row needs a matching active, `not_exempt` result-loop row, and every active result-loop row needs a matching active roadmap row.
- [x] Fail CI when a template/project type lacks a roadmap entry or explicit exemption. — enforced by the sibling scaling gate (`check-scaling-extension.py`), not this gate directly.
- [ ] Fail CI when a Route Plan selects a project type but does not name its roadmap entry. — this is `check-route-plan-contract.sh` territory, which stays unwired by design.
- [ ] Fail CI when a roadmap entry lacks official source references. — same unenforced field-level gap noted under "Scaling gate implementation."
- [x] Fail CI when a roadmap entry lacks local creator run instructions. — enforced via the paired `result-loop-requirements.tsv` row's `creator_local_review` field (cross-validated by `project_type_id`), not as a literal field on `project-type-roadmaps.tsv` itself.
- [x] Fail CI when mobile or desktop roadmaps lack user simulation against the actual app surface. — enforced via `check_project`'s mobile/desktop-specific `user_simulation` token requirements on the paired result-loop row.
- [x] Fail CI when game-development roadmaps lack local playable surface, gameplay simulation, visual evidence, performance metrics, or change-impact comparison. — enforced across both gates: `check-scaling-extension.py` checks the roadmap row's `required_evidence` for playable/gameplay/visual/performance/telemetry tokens, `check-result-loop-contract.py`'s game-development extra rules cover visible_result/user_simulation/feedback_surfaces/performance_monitoring, and the universal `change_impact_measurement` field covers change-impact comparison for every type including game-development.
- [x] Fail CI when performance or monitoring metrics are missing for app, service, AI, ML, data, mobile, desktop, or game work. — `performance_monitoring` is a universal required field for every project type.
- [x] Fail CI when before/after change-impact measurement is missing for user-visible or output-affecting changes. — `change_impact_measurement` is a universal required field for every project type.
- [x] Fail CI when telemetry export is missing from the selected roadmap. — `telemetry_export` is a universal required field plus a literal-phrase check for the export script path.
- [ ] Add scaling-extension requirement to the result-loop gate. — not literally true: the two gates are separate scripts that both read `project-type-roadmaps.tsv` independently; neither calls or requires the other.
- [x] Fail CI when a new template directory is added without a template requirement row. — enforced by the scaling gate's unconditional `unregistered template directory` check.
- [ ] Fail CI when a new project type is named in docs or route plans but lacks a roadmap entry or explicit exemption. — only checked for templates/result-loop/documentation/pattern/skill manifest references, not for arbitrary prose mentions in docs or Route Plans.
- [ ] Fail CI when a new reference repository lacks source, license/usage note, relevance, and freshness status. — same unenforced field-level gap noted under "Scaling gate implementation."
- [ ] Fail CI when a code example lacks a run or validation path. — same unenforced field-level gap noted under "Scaling gate implementation."
- [ ] Fail CI when audit marks scaling complete before enforcement artifacts exist. — no such meta-check exists in any current script.
- [x] Add fixture that fails when a mobile contract lacks local creator review or user simulation. — `mobile-no-local-review` fixture in `test-result-loop-contract.sh` confirmed rejected locally.
- [ ] Add fixture that fails when a desktop contract lacks local app-window review or UI automation. — no such fixture exists.
- [ ] Add fixture that fails when mobile or desktop contracts omit before/after change-impact metrics. — no such fixture exists.
- [x] Add fixture that fails when game-development lacks a playable local surface and performance metrics. — `game-no-playable` fixture in `test-result-loop-contract.sh` confirmed rejected locally.

## Real-run evidence

> Unchanged in this pass. All items below require an actual real target-project run, which is exactly the scope of `monitoring-metrics-sufficiency` (open, P2) and `project-8-real-run-evidence` (blocked, P1) in `docs/operations/known-gaps.tsv`. This reconciliation pass does not perform a real run and does not close either of those gaps.

- [ ] Run the first real target-project using the new result-loop contract.
- [ ] Export telemetry bundle after the run.
- [ ] Import first real-run telemetry into `telemetry-store`.
- [ ] Review visual, operational, logical and performance evidence artifacts.
- [ ] Identify missing coverage from the real run.
- [ ] Convert severe or repeated missing coverage into follow-up work.
- [ ] Compare with at least one later target-project run before claiming broad readiness.
- [ ] Run a scaling simulation that adds a new dummy project type and proves enforcement accepts a complete registration. — note: this is distinct from the existing fixtures, which mutate/remove data from *existing* real project types rather than adding a new one; still not done.
- [ ] Run a scaling simulation that adds an incomplete project type and proves enforcement rejects it.
- [ ] Run a scaling simulation for adding a documentation source, reference repository, and code example.

## Completion criteria

> Unchanged in this pass. Most CI-enforcement-only criteria below now hold for every `status=active` project type (see "Scaling gate implementation" and "Enforcement implementation" above), but this section represents full completion, which also requires the "Scaling category coverage" inventory audit and the real-run evidence blocked on `monitoring-metrics-sufficiency` / `project-8-real-run-evidence`. Left fully unchecked rather than partially checked to avoid implying broad readiness that isn't true yet.

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
- [ ] First real target-project run has real result-loop evidence in the telemetry store.
- [ ] At least one later comparison run exists.
- [ ] Monitoring sufficiency is backed by real runs, not planning claims.
