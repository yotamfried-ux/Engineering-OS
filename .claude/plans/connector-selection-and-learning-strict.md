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
7. Enforce the Claude run-trace document with a deterministic gate and simulations.

## Alternatives

- Only document connector selection — rejected because documented-only policy is not operational readiness.
- Require every connector for every task — rejected because it creates noise and blocks trivial work.
- Keep learning capture as one-of-three — rejected because it lets a real bug fix skip full learning-loop requirements.
- Leave Claude run traces as documentation only — rejected because connector/enforcement experiments would remain skippable.

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | connectors, learning-loop, enforcement, notion, operational-readiness, run-trace |
| Target paths | scripts/enforcement, docs/operations, .claude/plans, scripts/hooks |
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

- `github` — inspected current connector policy, runtime evidence gate, learning capture gate, tests, and PR #125 status.
- `notion` — required by policy for non-trivial planning/progress tracking. This environment does not expose a Notion write connector, so the PR enforces `notion` and `notion_progress_validated` evidence rather than creating the external Notion page here.

## Notion Progress Validation

- Current validation checkpoint: implementation plan was created in this Route Plan and must be mirrored/validated in Notion by the agent environment that has Notion access.
- Required ongoing updates: before implementation, after tests, and before merge.
- Evidence key expected by runtime: `connector_used notion` plus `notion_progress_validated`.

## Skill Evidence

- `superpowers` — plan-first correction loop, regression simulations, and verification-first behavior.
- `security-review` — reviewed hook bypass semantics, waiver boundaries, connector source-of-truth enforcement, and run-trace evidence requirements.

## Claude Run Trace

- goal: make Claude-run experiments inspectable and enforceable, especially connector-selection experiments.
- hypothesis: enforcement/connector/simulation changes should fail without a Route Plan trace and pass only when the trace records evidence, rejected attempts, connector decisions, and follow-up enforcement.
- connectors: github was used to inspect/update PR #125 and CI status; notion is required by policy but unavailable in this environment, so this PR enforces `notion_progress_validated` for environments that have Notion access.
- steps: add `enforce-run-trace.sh`, add `test-run-trace.sh`, wire the gate into pre-commit, update `claude-run-trace.md` with an enforcement contract, rerun CI.
- evidence: simulations cover missing trace, partial trace, complete connector trace, unrelated doc change, invalid trace doc, and valid trace doc.
- rejected: documentation-only trace policy was rejected because it would not block connector/enforcement experiments.
- result: run-trace enforcement is now part of the same deterministic suite as connector selection and learning capture.
- follow-up: expand trace rules when new experiment classes or connector domains are added.

## Source of Truth Checks

| Source | Status |
|---|---|
| GitHub repo current `main` | checked |
| `core/connector-policy.md` | checked |
| `scripts/enforcement/pre-tool-use-runtime-evidence.sh` | checked |
| `scripts/enforcement/enforce-learning-capture.sh` | checked |
| `scripts/enforcement/tests/test-learning-capture.sh` | checked |
| `docs/operations/claude-run-trace.md` | checked |
| `scripts/hooks/pre-commit.sh` | checked |

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
- [x] Run trace enforcement gate added.
- [x] Run trace simulations added, including connector-specific trace coverage.
- [x] GitHub Actions validation run observed and remaining failures are being corrected in this PR.
