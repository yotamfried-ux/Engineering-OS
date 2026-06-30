# Simulation Completeness Gate

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | governance, validation, simulations, CI, operational-readiness |
| Target paths | scripts/enforcement/simulation-coverage.tsv, scripts/enforcement/check-simulation-coverage.sh, scripts/enforcement/tests/test-simulation-coverage.sh, .github/workflows/enforcement-tests.yml, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | shell test pattern |
| External systems/connectors | github, notion |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: repository files, prior PR evidence, and CI workflow wiring were read to choose the simulation coverage enforcement point.
- notion: unavailable in this session; this Route Plan is the documented fallback progress tracker.

## Connector Usage Evidence

- github: read `docs/operations/operational-readiness-audit.md`, `.github/workflows/enforcement-tests.yml`, and recent PR evidence; used those results to select a manifest-backed validator rather than editing each gate individually.
- notion: unavailable; used this plan as fallback progress evidence and kept Notion progress validation represented explicitly.

## Notion Progress Validation

- Planning checkpoint: this Route Plan records scope before adding enforcement files.
- Mid-work checkpoint: validator/test design will be updated based on CI or review findings.
- Pre-merge checkpoint: final CI, review threads, expected head SHA, and remaining gaps will be checked before merge.

## Skill Evidence

- superpowers
- security-review

## Source of Truth Checks

| Source | Status |
|---|---|
| CLAUDE.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/hooks-policy.md | checked |
| docs/operations/operational-readiness-audit.md | checked |
| .github/workflows/enforcement-tests.yml | checked |

## Template Gap Waiver

reason: this is an internal governance/enforcement coverage change, not a project scaffold, so no project template applies.

## Progress Lifecycle Evidence

- start: plan created before changing enforcement files.
- mid: simulation validator/test loop will be validated through CI and, where possible, local reasoning over fixture behavior.
- pre-merge: final PR checks, review threads, expected head SHA, and CI will be verified before merge.

## Claude Run Trace

- goal: require explicit simulation coverage for every critical enforcement gate.
- hypothesis: a machine-readable simulation coverage manifest plus validator is the safest first ROI step because shell tests are heterogeneous and cannot be reliably inferred semantically from names alone.
- connectors: github, notion fallback.
- steps: read audit/workflow/test evidence; add simulation coverage manifest; add validator; add positive/negative/invalid/waiver validator tests; wire validator into enforcement-tests; update readiness audit; open PR; validate CI/reviews.
- evidence: GitHub file reads and CI after PR creation.
- rejected attempts: directly inferring every shell test case from test function names is too brittle; editing all existing gate tests at once is too broad for one loop.
- result: pending.
- follow-up enforcement: future gate additions must update the simulation coverage manifest or add a focused coverage waiver.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Simulation coverage approach selected from existing audit and CI workflow evidence.
- [x] Connector fallback documented because live Notion is unavailable in this session.
- [x] Validation gates identified for CI verification.
