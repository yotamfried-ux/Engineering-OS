# Documentation Asset Policy Gate

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | enforcement, documentation-asset, governance |
| Target paths | scripts/enforcement/check-documentation-asset-evidence.sh, scripts/enforcement/tests/test-documentation-asset-evidence.sh, .github/workflows/documentation-asset-policy.yml, scripts/enforcement/simulation-coverage.d/documentation-asset-evidence.tsv, scripts/enforcement/coverage-required-gates.tsv |
| Templates | not required |
| Patterns | connector/workflow evidence validator pattern |
| External systems/connectors | github |
| Skills | engineering-route |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy, pr-policy, documentation-asset-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: read enforcement sources, workflows, and coverage manifests before implementation.

## Connector Usage Evidence

- source: github repo files scripts/enforcement/check-workflow-evidence.sh and .github/workflows/workflow-evidence-policy.yml.
- action: github reviewed the existing gate conventions and coverage manifest format.
- result: github confirmed the base.sha/head.sha diff pattern and the simulation-coverage.d fragment layout.
- target: scripts/enforcement/check-documentation-asset-evidence.sh
- decision: chose a separate dedicated checker and implemented the new gate without changing check-workflow-evidence.sh.

## Documentation Asset Evidence

- internal: scripts/enforcement/check-workflow-evidence.sh, .github/workflows/workflow-evidence-policy.yml, scripts/enforcement/check-connector-evidence.sh, scripts/enforcement/simulation-coverage.d/template-pattern-ratings.tsv, and docs/operations/known-gaps.tsv were read to mirror the exact per-gate conventions.
- context7: not required because this change implements internal Engineering OS enforcement logic in bash and python only and does not integrate or implement any external framework, SDK, API, or library behavior; no external documentation applies.
- decision: reading the existing workflow/connector validators confirmed that a separate dedicated gate (rather than extending the shared workflow checker) is the correct approach and defined the field/placeholder validation shape.

## Skill Evidence

- engineering-route: used to route this Engineering OS governance change and identify the required sources before editing.

## Template/Pattern Rating Evidence

- asset: connector/workflow evidence validator pattern.
- rating: 4 medium confidence after reuse.
- outcome: reused the bash+python section/field parsing shape for the new gate.
- decision: keep this pattern preferred for future per-gate evidence checkers.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/check-connector-evidence.sh | checked |
| scripts/enforcement/simulation-coverage.tsv | checked |
| scripts/enforcement/coverage-required-gates.tsv | checked |
| docs/operations/known-gaps.tsv | checked |

## Template Gap Waiver

reason: internal governance validator change; no project code template applies to an enforcement gate.

## Progress Lifecycle Evidence

- start: plan committed before any checker/test/workflow/coverage changes.

## Claude Run Trace

- goal: close the documentation-asset-selection-lifecycle gap with a dedicated deterministic gate.
- hypothesis: a separate checker + workflow + test enforces documentation asset evidence without perturbing check-workflow-evidence.sh.
- result: gate and tests drafted; validating locally before PR.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Sources inspected.
- [x] Ready for implementation and PR CI validation.
