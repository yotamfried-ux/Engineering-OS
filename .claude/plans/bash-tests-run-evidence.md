# Route Plan — Make Bash enforcement tests produce trustworthy runtime evidence

## Route Plan

| Field | Decision |
|---|---|
| Task type | runtime evidence correctness defect found during full project audit |
| Task class | `engineering_os_governance` |
| Domain tags | hooks, validation evidence, bash tests, G11, Stop |
| Plan Scope | focused |
| Planning Mode | implementation; fix the existing evidence recorder without changing G11 semantics |
| Task-router evidence | `core/task-router.md` routes Engineering OS hook/evidence work through governance/ops-readiness. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/hooks-policy.md`, `core/git-policy.md`, and `core/coderabbit-policy.md` require plan-first writes, executable regression evidence, focused PR review, exact-head CI, and explicit owner approval before merge. |
| Target paths | `.claude/plans/bash-tests-run-evidence.md`; `scripts/enforcement/post-tool-use-bash.sh`; `scripts/enforcement/tests/test-post-tool-use-bash-evidence.sh`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md` |
| Templates | waiver — focused correction to an existing hook recorder and its regressions |
| Architecture guides | `core/hooks-policy.md`; `scripts/enforcement/hook-criticality.tsv` |
| Patterns | none — no reusable implementation pattern is introduced |
| External systems/connectors | GitHub; official Claude Code hooks reference |
| Skills | `writing-plans`; `verification-before-completion` |
| Validation gates | recorder regression; hook classification; G11 consumer behavior; Stop consumer behavior; known-gaps freshness; full enforcement suite; exact-head CI |
| Evidence to check | PostToolUse only fires after successful tool completion; Bash `tool_response` is structured; current recorder truncates response to 2,000 leading characters and does not recognize `scripts/enforcement/tests/test-*.sh` |
| User decisions required | owner approval before merge |

## Goal

A successful Engineering OS Bash enforcement suite must create `tests_run` evidence, while malformed input, non-test commands, failed/masked test output, and commands that merely mention a test path must not fabricate evidence.

## Scope

In scope: `post-tool-use-bash.sh`, a dedicated executable regression suite, the canonical gap row, and the audit freshness ledger required by the gap registry.

Out of scope: changing G11 policy, changing `evidence.sh` ledger semantics, changing hook criticality/wiring, or treating deterministic fixture success as proof of production readiness.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `scripts/enforcement/post-tool-use-bash.sh` | read | Test recognition is a closed runner list and converts `tool_response` to a string truncated to the first 2,000 characters. Engineering OS Bash suites are invisible. |
| `scripts/hooks/pre-commit.sh` | read | G11 consumes `tests_run`; missing evidence can block a >2-code-file commit even after real Bash tests passed. |
| `scripts/enforcement/post-stop-hook.sh` | read | Stop reports `no successful test run` when the same evidence is absent. |
| `scripts/enforcement/tests/test-hook-classification.sh` | read | Exercises malformed PostToolUse Bash input only; there is no positive regression proving `tests_run` can be recorded. |
| `scripts/enforcement/hook-criticality.tsv` | read | The recorder is canonically `recorder / false_evidence_safe`; the fix must remain conservative. |
| Claude Code hooks reference | checked | `PostToolUse` runs after a tool completes successfully and passes structured `tool_input` and `tool_response`; Bash output shape includes stdout/stderr. |
| GitHub | checked | `main` was re-read at `19add0b12408d66d2969eeda5f5e69a511c7fcf1` before the first write. |

## Design

1. Parse Bash `tool_response.stdout`/`stderr` explicitly when the response is structured; preserve a conservative fallback for legacy/string payloads.
2. Keep graphify evidence behavior isolated from test-output handling.
3. Recognize direct Engineering OS enforcement-suite invocations and the repository's canonical all-suite loop shape.
4. Require explicit successful suite summaries (`N passed, 0 failed` or the canonical all-suite success marker) before recording `tests_run`; do not accept a mere path mention or ambiguous failure output.
5. Preserve existing generic runner support while reading the relevant tail/full structured output rather than only the first 2,000 characters.
6. Add an executable regression that proves positive and negative evidence behavior and exercises the Stop/G11 consumers without changing their implementation.

## Capability Evidence

- `routing.task-router-read` — governance/hook evidence task.
- `workflow.route-plan-before-write` — this plan is committed before code changes.
- `source.github-repo-read` — exact base SHA re-read before planning.
- `validation.policy-change-has-validator` — the bug gets an executing regression, not a string-only assertion.

## Skill Evidence

- `writing-plans` — scope, source checks, non-goals and validation are explicit.
- `verification-before-completion` — local/fixture evidence, CI evidence, live runtime evidence and merge evidence remain separate claims.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Read `main@19add0b`, recorder, consumers, registry, policy and existing tests before writing this plan. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS` at `19add0b12408d66d2969eeda5f5e69a511c7fcf1`.
- action: traced `tests_run` from producer through ledger consumers and existing regressions.
- result: producer blindness is real; G11 and Stop are consumers, not the root cause; positive recorder coverage is missing.
- decision: fix the producer and add consumer-facing regressions rather than weakening G11 or changing Stop wording.
- target: `scripts/enforcement/post-tool-use-bash.sh`; `scripts/enforcement/tests/test-post-tool-use-bash-evidence.sh`.

## Documentation Asset Evidence

- internal: `core/hooks-policy.md`; `scripts/enforcement/hook-criticality.tsv`.
- external: official Claude Code hooks reference (`https://code.claude.com/docs/en/hooks`) for PostToolUse success timing and structured Bash output shape.
- decision: no Context7 package/library lookup is required; this is a shell hook contract correction.

## Progress Lifecycle Evidence

- start: plan committed before code changes. Base is `19add0b12408d66d2969eeda5f5e69a511c7fcf1`; root cause and both consumers were traced before writing.

## Definition of Done — Implementation

- [ ] A successful direct `bash scripts/enforcement/tests/test-*.sh` PostToolUse payload records `tests_run`.
- [ ] A canonical full-suite Bash loop with an explicit successful aggregate summary records `tests_run`.
- [ ] Malformed JSON, non-test commands, path mentions/echoes, ambiguous failed output, and masked failures do not record `tests_run`.
- [ ] Existing pytest/npm/cargo/go/jest/vitest/yarn evidence behavior remains covered.
- [ ] Stop observes `tests passed` after valid evidence.
- [ ] G11 accepts `tests_run` for a >2-code-file staged change without changing G11 itself.
- [ ] The gap is represented in `known-gaps.tsv` and the audit freshness ledger stays synchronized.
- [ ] Focused regressions and the full enforcement suite pass; live runtime closure remains separate until observed in a fresh Claude Code session.

## Validation Plan

- Focused: `test-post-tool-use-bash-evidence.sh`, `test-hook-classification.sh`, `test-tests.sh`, `test-known-gaps.sh`.
- Consumers: execute `post-stop-hook.sh` against a fixture ledger; execute installed/pre-commit G11 fixture with >2 code files and `tests_run` present.
- Full: every `scripts/enforcement/tests/test-*.sh` suite.
- External: exact-head CI, live review, explicit owner approval, expected-head merge, post-merge validation.
