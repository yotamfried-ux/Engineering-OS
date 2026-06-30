# Connector Correctness Gate

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | governance, connectors, source-of-truth, evidence, tests |
| Target paths | scripts/enforcement/check-connector-evidence.sh, scripts/enforcement/tests/test-connector-evidence.sh, docs/operations/operational-readiness-audit.md |
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

- github: repository files and prior enforcement gates were read to select the correct connector enforcement point.
- notion: progress tracking is represented by the Route Plan fallback because no live Notion connector is available in this session.

## Connector Usage Evidence

- github: read `scripts/enforcement/check-connector-evidence.sh` and `scripts/enforcement/tests/test-connector-evidence.sh`; used that evidence to move usage evidence enforcement into the plan connector evidence gate.
- notion: unavailable; used this plan as the documented fallback progress tracker and kept the Notion requirement represented in the plan.

## Notion Progress Validation

- Planning checkpoint: this Route Plan records the scope before code changes.
- Mid-work checkpoint: CI/simulation failures were used to update this loop before merge.
- Pre-merge checkpoint: final CI, review threads, and expected SHA will be checked before merge.

## Skill Evidence

- superpowers
- security-review

## Source of Truth Checks

| Source | Status |
|---|---|
| CLAUDE.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| scripts/enforcement/check-connector-evidence.sh | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Template Gap Waiver

reason: this is an internal governance gate calibration and no project template applies.

## Progress Lifecycle Evidence

- start: plan created before changing code.
- mid: CI/simulation loop validated the checker and tests.
- pre-merge: final PR checks, review threads, expected head SHA, and CI will be verified before merge.

## Claude Run Trace

- goal: require evidence that selected connectors influenced the plan or implementation.
- hypothesis: connector evidence policy is the correct enforcement point for plan-level usage evidence because it already validates connector declaration evidence.
- connectors: github, notion fallback.
- steps: read connector gates and tests, add connector usage evidence requirement, update simulations, update audit, run CI, self-review, merge.
- evidence: CI.
- result: pending.
