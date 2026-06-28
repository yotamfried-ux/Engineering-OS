# Connector Selection Gate + Strict Learning Capture

## Goal

Close the next operational-readiness gap: connector/source-of-truth selection must be enforced by task/domain/path, not only after a connector is declared. Also tighten learning capture so bug/debug/incident work cannot bypass the learning loop by staging only a failed-solution or a waiver when a real lesson is required.

## Plan

1. Add a required-connector selection checker for Route Plans and write targets.
2. Wire required connector selection into installed target-project runtime settings.
3. Require Notion planning and progress-validation evidence for non-trivial implementation work, not just initial plan creation.
4. Tighten the learning capture gate so bug/debug/incident/rollback code changes require a staged complete lesson; failed-solutions are additional evidence, not a substitute for the lesson.
5. Add regression simulations for connector selection and strict learning capture.
6. Document Claude run tracing so experiments can be reviewed and learned from.

## Alternatives

- Only document connector selection — rejected because documented-only policy is not operational readiness.
- Require every connector for every task — rejected because it creates noise and blocks trivial work.
- Keep learning capture as one-of-three — rejected because it lets a real bug fix skip full learning-loop requirements.

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | connectors, learning-loop, enforcement, notion, operational-readiness |
| Target paths | scripts/enforcement, docs/operations, .claude/plans |
| Templates | not required |
| Patterns | none |
| External systems/connectors | github, notion |
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

- `github` — inspected current connector policy, runtime evidence gate, learning capture gate, and tests.
- `notion` — required by policy for non-trivial planning/progress tracking. This environment does not expose a Notion write connector, so the PR enforces `notion` and `notion_progress_validated` evidence rather than creating the external Notion page here.

## Notion Progress Validation

- Current validation checkpoint: implementation plan was created in this Route Plan and must be mirrored/validated in Notion by the agent environment that has Notion access.
- Required ongoing updates: before implementation, after tests, and before merge.
- Evidence key expected by runtime: `connector_used notion` plus `notion_progress_validated`.

## Skill Evidence

- `superpowers` — plan-first correction loop, regression simulations, and verification-first behavior.
- `security-review` — reviewed hook bypass semantics, waiver boundaries, and connector source-of-truth enforcement.

## Source of Truth Checks

| Source | Status |
|---|---|
| GitHub repo current `main` | checked |
| `core/connector-policy.md` | checked |
| `scripts/enforcement/pre-tool-use-runtime-evidence.sh` | checked |
| `scripts/enforcement/enforce-learning-capture.sh` | checked |
| `scripts/enforcement/tests/test-learning-capture.sh` | checked |

## Definition of Done

- [x] Connector policy and runtime evidence gate mapped.
- [x] Required connector selection checker added.
- [x] Installed target-project settings wire connector selection.
- [x] Notion progress validation requirement enforced for non-trivial implementation work.
- [x] Learning capture gate tightened so bug/debug/incident code requires a complete lesson.
- [x] Tests prove failed-solution alone no longer satisfies bug learning capture.
- [x] Tests prove waiver cannot bypass a real bug/debug capture requirement.
- [x] Tests prove required connectors are selected by task/domain/path.
- [x] Tests prove Notion planning plus progress validation is required for non-trivial work.
- [x] Experiment/run trace documentation exists.
- [ ] GitHub Actions pass on the PR.
