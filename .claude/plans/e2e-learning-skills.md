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
| Templates | none |
| Patterns | none |
| External systems/connectors | github |
| Skills | superpowers, security-review |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

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
- [ ] Operational E2E simulation test added.
- [ ] Test proves target install wiring includes runtime evidence and workflow gates.
- [ ] Test proves missing learning reuse blocks and valid reuse allows.
- [ ] Test proves missing required skill selection/evidence blocks and valid evidence allows.
- [ ] GitHub Actions enforcement-tests pass on the PR.
