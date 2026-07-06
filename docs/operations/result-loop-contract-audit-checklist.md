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
- [x] Expo development builds researched for mobile runtime feedback.
- [x] MLflow model evaluation researched for ML evaluation loops.
- [x] OpenAI Evals researched for AI-agent evaluation loops.

## Contract design

- [x] Define local run requirement.
- [x] Define visible result requirement.
- [x] Define required tests requirement.
- [x] Define visual feedback requirement.
- [x] Define operational and logical feedback requirement.
- [x] Define monitoring and performance measurement requirement.
- [x] Define acceptance metrics requirement.
- [x] Define telemetry export requirement.
- [x] Define failure repair-loop requirement.
- [x] Define evidence artifact requirement.

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
- [ ] CI fails when a required contract is missing.
- [ ] CI fails when a selected contract omits run, view, test, feedback, monitoring, telemetry or repair fields.
- [ ] Project 8 has real result-loop evidence in the archive.
- [ ] At least one later comparison run exists.
- [ ] Monitoring sufficiency is backed by real runs, not planning claims.
