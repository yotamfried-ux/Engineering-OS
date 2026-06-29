# Operational Readiness Coverage Loop

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | governance, documentation, workflow, testing, hooks, rtk, connectors, skills |
| Target paths | docs/operations/operational-readiness-audit.md, .github/workflows/enforcement-tests.yml |
| Templates | not required |
| Patterns | existing enforcement workflow and operational audit structure |
| External systems/connectors | github |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy |

## Connector Evidence

- github: repository files, PR state, CI runs, and failed workflow logs were checked.

## Skill Evidence

- superpowers: plan first, test, fix, retest loop.
- security-review: self-review of CI gate behavior and merge safety.

## Source of Truth Checks

| Source | Status |
|---|---|
| CLAUDE.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| .github/workflows/workflow-evidence-policy.yml | checked |
| .github/workflows/connector-evidence-policy.yml | checked |
| docs/operations/operational-readiness-audit.md | checked |
| .github/workflows/enforcement-tests.yml | checked |

## Claude Run Trace

- goal: make the readiness coverage inventory complete and test-backed.
- hypothesis: the existing audit document is the right owner; the gap is CI coverage validation.
- connectors: github.
- steps: inspect failed checks, identify missing route-plan evidence, add plan first, then apply audit and CI updates.
- evidence: CI should pass connector and workflow evidence gates after plan-first commit order.
- rejected: planless config change.
- result: pending CI.
- follow-up: inspect logs and continue repair loop if CI fails.
- progress_validated: fallback plan file updated.

## Definition of Done

- [ ] Audit is the readiness coverage inventory.
- [ ] Audit covers RTK, graphify, skills, templates, connectors, learning, progress, run trace, cleanup, review, post-merge, docs hygiene, and known gaps.
- [ ] CI validates required rows and statuses.
- [ ] CI passes.
- [ ] Self-review completed before merge.
