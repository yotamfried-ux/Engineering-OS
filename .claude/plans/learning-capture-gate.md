# Operational Readiness Audit + Learning Capture Gate

## Goal

Create a truthful operational-readiness audit for Engineering OS and close the first high-priority gap: bug/debug/incident work must produce a new lesson, a failed-solution record, or an explicit Learning Capture Waiver.

## Plan

1. Document operational readiness by category: principles, workflows, skills, templates, documentation, connectors, hooks, CI, and learning loop.
2. Add deterministic learning-capture enforcement for bug/debug/incident/rollback Route Plans.
3. Wire the new enforcement into the portable pre-commit hook.
4. Add regression simulations proving block/allow behavior.
5. Update learning-loop operational documentation to state the enforced boundary.

## Alternatives

- Claim full readiness without an audit — rejected because it hides partial/manual enforcement.
- Require lessons after every code change — rejected because the learning-loop policy says trivial one-line fixes do not require lessons.
- Require lessons only by convention — rejected because the user explicitly asked for operational enforcement.

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | learning-loop, enforcement, documentation, operational-readiness |
| Target paths | core, scripts/enforcement, scripts/hooks, docs/operations |
| Templates | not required |
| Patterns | none |
| External systems/connectors | github |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests, plan-policy, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- `github` — inspected current learning-loop, quality gates, pre-commit wiring, and enforcement workflows before changing policy/enforcement.

## Skill Evidence

- `superpowers` — used plan-first correction loop and regression-driven enforcement.
- `security-review` — reviewed waiver and hook behavior so the new gate cannot silently force unsafe or false lessons.

## Source of Truth Checks

| Source | Status |
|---|---|
| `core/learning-loop.md` | checked |
| `scripts/enforcement/enforce-learning.sh` | checked |
| `scripts/enforcement/check-learning-reuse.sh` | checked |
| `scripts/hooks/pre-commit.sh` | checked |
| `core/quality-gates.md` | checked |
| `scripts/enforcement/enforce-quality.sh` | checked |
| `.github/workflows/enforcement-tests.yml` | checked |

## Definition of Done

- [x] Operational readiness audit document added.
- [x] Learning capture gate added.
- [x] Pre-commit hook wires the new gate.
- [x] Tests prove bug/debug plans are blocked without lesson/failed-solution/waiver.
- [x] Tests prove non-learning tasks are not blocked.
- [x] Tests prove a waiver allows a justified no-lesson case.
- [x] Learning-loop operational documentation updated.
- [x] GitHub Actions pass on the PR.
