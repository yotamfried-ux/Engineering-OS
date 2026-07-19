# Route Plan — User decision persistence and cross-repo handoff

| Field | Decision |
|---|---|
| Task type | bug / behavioral governance repair |
| Task class | engineering_os_governance |
| Domain tags | governance, workflow, state, human-in-the-loop, evaluation |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | `core/task-router.md` routes this as Engineering OS maintenance and requires unresolved user decisions to be surfaced rather than guessed. |
| Workflow evidence | `core/workflow.md` defines session state and structured task state but lacked an ask-once decision lifecycle. |
| Target paths | `CLAUDE.md`; `CLAUDE.template.md`; `core/user-decision-policy.md`; `experiments/claude-behavioral-eval/`; `scripts/enforcement/tests/`; `.claude/plans/fix-user-decision-persistence.md` |
| Templates | not required — this is a focused governance and evaluation repair. |
| Architecture guides | `core/workflow.md`; `core/task-router.md`; `core/precedence.md` |
| Patterns | existing behavioral-eval task packet, oracle, and fixture-test pattern |
| External systems/connectors | GitHub |
| Skills | not required |
| Validation gates | focused decision-policy fixture; behavioral evaluator mechanics; enforcement-tests; pr-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; plan-policy; documentation-asset-policy; semantic-cleanup-policy; import-cleanup-policy |
| Evidence to check | `core/user-decision-policy.md`; `.claude/settings.json`; `experiments/claude-behavioral-eval/README.md`; PR #247; PR #248 Actions and review threads |
| User decisions required | none — the owner explicitly authorized implementing and merging the repair once verified. |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `.claude/settings.json` | checked | `UserPromptSubmit` records telemetry only; no hook persists or interprets natural-language decisions. |
| `core/workflow.md` | read | State persistence exists for tasks and run traces, but there was no explicit decision lifecycle or repeated-question prohibition. |
| `core/task-router.md` | read | It correctly requires unresolved decisions to be surfaced, but did not distinguish unanswered from already answered/deferred decisions. |
| `experiments/claude-behavioral-eval/README.md` | read | Artifact scoring and operator-observed traces are the regression surface; complete alternatives are needed for ready versus blocked handoffs. |
| `https://github.com/yotamfried-ux/Engineering-OS/pull/247` | validated | The open B3 cross-repository item reproduced the distinction between unfinished work and an already-answered execution-context decision. |
| `https://github.com/yotamfried-ux/Engineering-OS/pull/248` | validated | Two live review rounds identified destination visibility, self-authored interaction evidence, packet leakage, temp-file safety, blocked-hand-off acceptance, approved handoff-type coverage, and mandatory metadata coverage. |

## Root Cause

The system had a one-way escalation rule — surface missing user decisions — but no closing transition after the user answered. It did not define a stable decision identity, accepted statuses, a destination-readable or safely blocked cross-repository handoff, or a condition under which the same question may be asked again. A hook cannot safely infer semantic equivalence between natural-language answers, so the repair uses a canonical workflow contract plus externally observed behavioral regression evidence rather than a semantic parser.

## Implementation

1. Add a canonical `core/user-decision-policy.md` defining `unanswered → answered|deferred|blocked|superseded`, stable decision IDs, ask-once behavior, Plan Mode/read-only handling, and checklist semantics.
2. Require every cross-repository handoff to preserve mandatory source/destination metadata and satisfy one complete alternative: `deferred` with a destination-readable issue/PR/file/shared-tracker `handoff_ref`, or `blocked` with a safe copyable `handoff_block` when destination persistence is unavailable.
3. Add a concise mandatory pointer in `CLAUDE.md`, propagate it through `CLAUDE.template.md`, and register the new core owner in navigation and conceptual ownership.
4. Add a neutral behavioral task packet that supplies only the ordinary work request and the user's already-selected separate-session decision.
5. Extend the evaluator with occurrence checks and `required_all_any` complete-alternative checks while requiring `interaction-log.md` to be derived by the operator/harness from the actual trace.
6. Add positive and negative fixtures for repeated prompts, all mandatory metadata, approved ready handoff types, blocked fallback, operator-observed trace provenance, malformed rules, packet neutrality, and secure temporary outputs.
7. Run the full policy/review loop and squash-merge only on the exact reviewed green head.

## Definition of Done

- [x] The canonical policy distinguishes unanswered decisions from answered/deferred/blocked decisions.
- [x] The policy forbids asking the same decision again unless the prior answer is ambiguous, contradictory, or invalidated by a material fact change.
- [x] Plan Mode/read-only sessions continue in-scope work without requiring a file write solely to remember the answer.
- [x] Cross-repository state preserves `decision`, `source_repo`, `destination_repo`, `next_action`, and `source_ref` in every path.
- [x] Ready handoffs accept destination issue, destination PR, destination file, or verified shared tracker and require a real `handoff_ref`.
- [x] Environments without destination persistence use `status: blocked`, `handoff_persistence: blocked`, and a safe `handoff_block` instead of inventing a URL.
- [x] Destination sessions are instructed to discover handoff issues/PRs/files before asking about deferred work.
- [x] `CLAUDE.md` points to the canonical policy and registers its navigation/concept ownership.
- [x] `CLAUDE.template.md` propagates the policy to target-project setup.
- [x] The behavioral evaluator supports deterministic occurrence limits and complete alternative groups; malformed rules fail closed.
- [x] The task packet contains no evaluation artifact names, oracle IDs, or scoring instructions.
- [x] Interaction occurrence evidence is operator/harness-observed rather than model-authored.
- [x] Positive and negative executable fixtures cover ready, blocked, missing-metadata, mixed-invalid, repeated-prompt, provenance, and security cases.
- [x] Touched test scripts use their secure `mktemp -d` workspace instead of predictable `/tmp` output files.
- [x] Merge remains blocked until every required workflow passes on the exact final head.
- [x] Merge remains blocked until live review findings are fixed and all threads are resolved.
- [x] Owner authorization is conditional; only an exact-head squash merge is permitted after the gates above.

## Documentation Asset Evidence

- internal: `CLAUDE.md`, `CLAUDE.template.md`, `core/workflow.md`, `core/task-router.md`, `core/precedence.md`, `core/user-decision-policy.md`, and `experiments/claude-behavioral-eval/README.md`.
- context7: not required because this repair is internal-only workflow state and evaluation logic; it does not implement, touch, use, or integrate an external library, framework, SDK, API, or service.
- decision: the concrete internal assets and PR #248 review established one canonical lifecycle, complete ready/blocked handoff alternatives, and externally observed behavioral evidence; no semantic decision parser was added to hooks.

## Capability Evidence

- `routing.task-router-read` — classified as Engineering OS governance/debugging.
- `workflow.workflow-read` — inspected the current state and agent-loop contracts.
- `plan.route-plan-before-write` — plan commit `b278144ca553d70054ec0af1aa4ff0425e8ad5ae` precedes every policy, evaluator, template, or test change.
- `source.github-repo-read` — inspected current main, PR #247, PR #248, Actions, and review threads through GitHub.
- `validation.policy-change-has-validator` — occurrence-count, complete-alternative, packet-neutrality, mandatory-metadata, ready/blocked, provenance, and security fixtures are implemented.
- `validation.coderabbit-policy` — CodeRabbit and two rounds of live chatgpt-codex-connector findings were read and fixed before resolution/merge.

## Connector Evidence

- GitHub: used to verify current `main`, PR #247, PR #248, policy files, Actions, CodeRabbit findings, and live review threads.

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`.
- action: inspected main SHA `9c99081cc5476b752837a878c50bfae2e4880b3e`, PR #247, PR #248, workflow diagnostics, CodeRabbit comments, and both live chatgpt-codex-connector review rounds.
- result: PR #248 code/test head `ece4b358a7ce8b74ab70798c8288273bee72d4ae` updated `core/user-decision-policy.md`, `evaluate.py`, `oracle.tsv`, `README.md`, and both focused test scripts to align the canonical policy and evaluator.
- decision: implemented complete ready-or-blocked handoff alternatives, accepted every policy-approved durable type, required all source/destination metadata, and retained external interaction-trace evidence.
- target: `core/user-decision-policy.md`; `experiments/claude-behavioral-eval/evaluate.py`; `experiments/claude-behavioral-eval/oracle.tsv`; `scripts/enforcement/tests/test-claude-behavioral-eval.sh`; `scripts/enforcement/tests/test-user-decision-persistence.sh`.

## Claude Run Trace

- goal: prevent repeated AskUserQuestion loops after a user has already answered, including across repository/session boundaries.
- hypothesis: a stable decision lifecycle, one complete ready-or-blocked handoff alternative, and externally observed occurrence evidence close the gap without unreliable semantic hook parsing.
- connectors: GitHub.
- steps: verify current main and PR #247; trace hook behavior; inspect workflow/task-router and eval harness; create plan-first branch; add canonical policy and target template entry; add occurrence evaluator and fixtures; open PR #248; read exact CI diagnostics; fix evidence contracts; accept first live review findings; add durable destination discovery; externalize trace capture; neutralize the task packet; secure temp outputs; accept second live review findings; add `required_all_any`; align blocked fallback, approved handoff types, and mandatory metadata; record this post-code checkpoint.
- evidence: user screenshot, PR #247, PR #248, plan-first commit, code/test head `ece4b358a7ce8b74ab70798c8288273bee72d4ae`, Actions diagnostics, CodeRabbit, and live review threads.
- rejected: a PreToolUse hook that tries to parse natural-language answers — rejected because it cannot reliably identify semantic equivalence and would create new false-positive blockers.
- result: every known CI and review finding has an implementation/test correction; exact-head validation and final thread resolution follow this checkpoint.

## Progress Lifecycle Evidence

- start: branch created from exact `main` SHA `9c99081cc5476b752837a878c50bfae2e4880b3e`; Route Plan commit `b278144ca553d70054ec0af1aa4ff0425e8ad5ae` precedes every implementation/test change.
- mid: canonical lifecycle, entrypoint/template wiring, occurrence evaluator, neutral packet, oracle, and focused fixtures were added; structured self-review corrected fixture isolation and shell quoting before PR creation.
- pre-merge: after code/test head `ece4b358a7ce8b74ab70798c8288273bee72d4ae`, the second live review round was mapped to complete ready/blocked alternatives, all approved durable handoff types, and mandatory metadata enforcement. This plan checkpoint follows the last implementation change; merge remains gated by exact-head workflows and zero unresolved threads.