# Route Plan — User decision persistence and cross-repo handoff

| Field | Decision |
|---|---|
| Task type | bug / behavioral governance repair |
| Task class | engineering_os_governance |
| Domain tags | governance, workflow, state, human-in-the-loop, evaluation |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | `core/task-router.md` routes this as Engineering OS maintenance and requires unresolved user decisions to be surfaced rather than guessed. |
| Workflow evidence | `core/workflow.md` defines session state and structured task state but lacks an ask-once decision lifecycle. |
| Target paths | `CLAUDE.md`; `CLAUDE.template.md`; `core/user-decision-policy.md`; `experiments/claude-behavioral-eval/`; `scripts/enforcement/tests/`; `.claude/plans/fix-user-decision-persistence.md` |
| Templates | not required — this is a focused governance and evaluation repair. |
| Architecture guides | `core/workflow.md`; `core/task-router.md`; `core/precedence.md` |
| Patterns | existing behavioral-eval task packet, oracle, and fixture-test pattern |
| External systems/connectors | GitHub |
| Skills | not required |
| Validation gates | focused decision-policy fixture; behavioral evaluator mechanics; enforcement-tests; pr-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; plan-policy; documentation-asset-policy; semantic-cleanup-policy; import-cleanup-policy |
| Evidence to check | screenshot behavior; PR #247 B3 wording; current `CLAUDE.md`, workflow, task-router, behavioral evaluator/oracle/tests; exact-head Actions and review threads |
| User decisions required | none — the owner explicitly authorized implementing and merging the repair once verified. |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| User-provided screenshot and session report | checked | Claude repeatedly re-opened the same Project 8 attach/defer decision after the user submitted an answer. |
| PR #247 | checked | B3 requires cross-repository Project 8 work and remains open, which caused Claude to reinterpret the same choice on later turns. |
| `.claude/settings.json` | checked | `UserPromptSubmit` records telemetry only; no hook persists or interprets natural-language decisions. |
| `core/workflow.md` | read | State persistence exists for tasks and run traces, but there is no explicit decision lifecycle or repeated-question prohibition. |
| `core/task-router.md` | read | It correctly requires unresolved decisions to be surfaced, but does not distinguish unanswered from already answered/deferred decisions. |
| `experiments/claude-behavioral-eval/` | read | Artifact-based behavioral scoring exists and is the correct deterministic regression surface for this model-behavior bug. |

## Root Cause

The system has a one-way escalation rule — surface missing user decisions — but no closing transition after the user answers. It does not define a stable decision identity, accepted statuses, persistence target, cross-repo blocked/deferred handoff, or a condition under which the same question may be asked again. A hook cannot safely infer semantic equivalence between natural-language answers, so the repair must be a canonical workflow contract plus behavioral regression evidence rather than a fake parser.

## Implementation

1. Add a canonical `core/user-decision-policy.md` defining `unanswered → answered|deferred|blocked|superseded`, stable decision IDs, ask-once behavior, persistence rules, Plan Mode/read-only handling, and cross-repo handoff.
2. Add a concise mandatory pointer in `CLAUDE.md`, propagate it through `CLAUDE.template.md`, and register the new core owner in the navigation and conceptual-ownership tables.
3. Add a neutral behavioral task packet reproducing an unavailable second repository after the user has already chosen a separate-session handoff.
4. Extend the artifact evaluator with occurrence-count checks so a run can fail when the same decision question is logged more than once, rather than trusting final self-report.
5. Add positive and negative fixtures proving one ask passes, repeated asks fail, and deferred cross-repo state is accepted.
6. Run the full policy/review loop and merge only on the exact reviewed green head.

## Definition of Done

- [x] The canonical policy distinguishes unanswered decisions from answered/deferred/blocked decisions.
- [x] The policy forbids asking the same decision again unless the prior answer is ambiguous, contradictory, or invalidated by a material fact change.
- [x] Plan Mode/read-only sessions continue in-scope work without requiring a file write solely to remember the answer.
- [x] Cross-repo actions unavailable in the current workspace become a concrete deferred/blocked handoff, not a repeated prompt.
- [x] `CLAUDE.md` points to the canonical policy and registers its navigation/concept ownership.
- [x] `CLAUDE.template.md` propagates the policy to target-project setup.
- [x] The behavioral evaluator supports deterministic occurrence limits and malformed limits fail closed.
- [x] A neutral task packet and oracle cover the Project 8-style cross-repo decision loop.
- [x] Positive and negative executable regression fixtures exist for occurrence limits and the cross-repo scenario.
- [x] Merge remains blocked until every required workflow passes on the exact final head.
- [x] Merge remains blocked until CodeRabbit or documented fallback review is complete and live threads are resolved.
- [x] Owner authorization is conditional; only an exact-head squash merge is permitted after the gates above.

## Documentation Asset Evidence

- internal: `CLAUDE.md`, `CLAUDE.template.md`, `core/workflow.md`, `core/task-router.md`, `core/precedence.md`, PR #247, and `experiments/claude-behavioral-eval/README.md`.
- context7: not required because this repair is internal-only workflow state and evaluation logic; it does not implement, touch, use, or integrate an external library, framework, SDK, API, or service.
- decision: the concrete internal assets confirmed one canonical policy plus artifact-based evaluation; no natural-language decision parser was added to hooks.

## Capability Evidence

- `routing.task-router-read` — classified as Engineering OS governance/debugging.
- `workflow.workflow-read` — inspected the current state and agent-loop contracts.
- `plan.route-plan-before-write` — plan commit `b278144ca553d70054ec0af1aa4ff0425e8ad5ae` precedes every policy, evaluator, template, or test change.
- `source.github-repo-read` — inspected current main and PR #247 through GitHub.
- `validation.policy-change-has-validator` — occurrence-count evaluator coverage and policy fixtures are implemented.
- `validation.coderabbit-policy` — PR, exact-head CI, review, thread resolution, then owner-authorized merge.

## Connector Evidence

- GitHub: used to verify current `main`, PR #247, policy files, the evaluator harness, Actions, and review state.

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`.
- action: inspected main SHA `9c99081cc5476b752837a878c50bfae2e4880b3e`, PR #247, PR #248, `CLAUDE.md`, `CLAUDE.template.md`, `core/workflow.md`, `core/task-router.md`, and behavioral-eval assets.
- result: PR #248 head `2d9a79de3bc0bacc2d5b42671e246e997efba48d` added `core/user-decision-policy.md`, `experiments/claude-behavioral-eval/evaluate.py` occurrence checks, and `scripts/enforcement/tests/test-user-decision-persistence.sh`.
- decision: implemented a closed decision lifecycle while keeping escalation for genuinely unanswered decisions; limited hooks to telemetry rather than semantic guessing.
- target: `CLAUDE.md`; `CLAUDE.template.md`; `core/user-decision-policy.md`; `experiments/claude-behavioral-eval/`; `scripts/enforcement/tests/`.

## Claude Run Trace

- goal: prevent repeated AskUserQuestion loops after a user has already answered.
- hypothesis: a stable decision lifecycle plus occurrence-count behavioral evaluation closes the gap without unreliable semantic hook parsing.
- connectors: GitHub.
- steps: verify current main and PR #247; trace hook behavior; inspect workflow/task-router and eval harness; create plan-first branch; add canonical policy and target template entry; add occurrence evaluator and cross-repo fixtures; self-review the fixture and correct its oracle isolation/shell quoting before PR; open PR #248; read exact policy failures and correct their evidence contracts; continue exact-head review/CI; merge when verified.
- evidence: user screenshot, PR #247, PR #248, current source, plan-first commit, regression fixtures, Actions, and review threads.
- rejected: a PreToolUse hook that tries to parse natural-language answers — rejected because it cannot reliably identify semantic equivalence and would create new false-positive blockers.
- result: implementation and executable fixtures complete; first PR run correctly exposed plan/connector/documentation evidence formatting, corrected in this plan-only checkpoint.

## Progress Lifecycle Evidence

- start: branch created from exact `main` SHA `9c99081cc5476b752837a878c50bfae2e4880b3e`; Route Plan commit `b278144ca553d70054ec0af1aa4ff0425e8ad5ae` precedes every implementation/test change.
- mid: canonical lifecycle, entrypoint/template wiring, occurrence-count evaluator, task packet, oracle, and focused fixtures added. Structured self-review found and fixed a full-oracle fixture isolation bug and unsafe shell quoting before opening the PR.
- pre-merge: PR #248 opened at head `2d9a79de3bc0bacc2d5b42671e246e997efba48d`; first exact-head run identified connector, workflow, plan, and documentation evidence contract failures. This plan-only commit corrects those contracts before the next exact-head run; merge remains blocked.