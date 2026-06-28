# E2E Learning + Skills Operational Simulations

## Goal

Add an end-to-end operational readiness simulation that proves the learning-loop reuse gate and skill-selection/runtime evidence gate work together after the recent merges.

## Plan

1. Verify the current installed-hook wiring for target projects.
2. Add a CI-enforced simulation suite under `scripts/enforcement/tests/`.
3. Simulate missing and valid learning reuse cases.
4. Simulate missing and valid required skill selection/evidence cases.
5. Simulate the installed target-project Write hook sequence.

## Alternatives

- Manual spot-check only — rejected because it does not protect future regressions.
- Separate tests for learning and skills only — rejected because operational readiness depends on the combined runtime flow.

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | learning-loop, skills, hooks, enforcement, runtime |
| Target paths | scripts/enforcement/tests |
| Templates | not required |
| Patterns | none |
| External systems/connectors | github |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests, plan-policy, connector-evidence-policy, workflow-evidence-policy, capability-evidence-policy, pr-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- `github` — repository files, current workflows, and current enforcement scripts were inspected before writing the simulation.

## Skill Evidence

- `superpowers` — planning-first workflow used: map current behavior, create route plan, add regression simulation.
- `security-review` — reviewed hook failure modes around runtime gates, evidence bypass, payment/webhook sensitivity, and temp-file safety.

## Source of Truth Checks

| Source | Status |
|---|---|
| GitHub repo files | checked |
| Existing enforcement tests workflow | checked |
| Runtime evidence hook | checked |
| Required skills checker | checked |
| Learning reuse gate | checked |

## Definition of Done

- [x] Current learning-loop enforcement mapped.
- [x] Current skill-selection/runtime evidence enforcement mapped.
- [x] Operational E2E simulation test added.
- [x] Test proves target install wiring includes runtime evidence and workflow gates.
- [x] Test proves missing learning reuse blocks and valid reuse allows.
- [x] Test proves missing required skill selection/evidence blocks and valid evidence allows.
- [x] GitHub Actions enforcement-tests pass on the PR.
