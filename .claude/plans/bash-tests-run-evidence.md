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
| Target paths | `.claude/plans/bash-tests-run-evidence.md`; `scripts/enforcement/post-tool-use-bash.sh`; `scripts/enforcement/tests/test-post-tool-use-bash-evidence.sh` |
| Templates | waiver — focused correction to an existing hook recorder and its regressions |
| Architecture guides | `core/hooks-policy.md`; `scripts/enforcement/hook-criticality.tsv` |
| Patterns | no matching reusable implementation pattern is required for this focused recorder correction |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion` |
| Validation gates | recorder regression; hook classification; G11 consumer behavior; Stop consumer behavior; full enforcement suite; exact-head CI; PR policy |
| Evidence to check | `scripts/enforcement/post-tool-use-bash.sh`; `scripts/enforcement/tests/test-post-tool-use-bash-evidence.sh`; exact-head GitHub Actions run `enforcement-tests` 1632 |
| User decisions required | owner approval before merge |

## Goal

A successful Engineering OS Bash enforcement suite must create `tests_run` evidence, while malformed input, non-test commands, failed/masked test output, and commands that merely mention a test path must not fabricate evidence.

## Scope

In scope: `post-tool-use-bash.sh`, a dedicated executable regression suite, consumer execution for Stop/G11, and exact-head CI evidence.

Out of scope: changing G11 policy, changing `evidence.sh` ledger semantics, changing hook criticality/wiring, or treating deterministic fixture success as proof of production/runtime readiness.

### Gap-registration decision

The opening plan proposed adding a new readiness-registry row before the fix. After reading the canonical gap contract and observing the regression on exact-head CI, that would mix two different claims: the implementation bug is deterministically testable and fixed here, while the still-missing fresh Claude Code observation is runtime evidence, not another implementation defect. This PR therefore does **not** create and immediately mitigate a new readiness gap. It keeps the live-runtime claim explicitly unclosed in this plan/PR, and the broader operational-readiness audit remains authoritative for real-run readiness. If the fresh runtime observation contradicts this deterministic result, that observation must create a new canonical gap rather than retroactively redefining this regression.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `scripts/enforcement/post-tool-use-bash.sh` | read | Test recognition was a closed runner list and converted `tool_response` to a string truncated to the first 2,000 characters. Engineering OS Bash suites were invisible. |
| `scripts/hooks/pre-commit.sh` | read | G11 consumes `tests_run`; missing evidence can block a >2-code-file commit even after real Bash tests passed. |
| `scripts/enforcement/post-stop-hook.sh` | read | Stop reports `no successful test run` when the same evidence is absent. |
| `scripts/enforcement/tests/test-hook-classification.sh` | read | Exercises malformed PostToolUse Bash input only; there was no positive regression proving `tests_run` could be recorded. |
| `scripts/enforcement/hook-criticality.tsv` | read | The recorder is canonically `recorder / false_evidence_safe`; the fix must remain conservative. |
| `https://code.claude.com/docs/en/hooks` | checked | Official hooks reference: `PostToolUse` runs after successful tool completion and Bash responses expose structured output fields; this supports using the success boundary only for direct, failure-propagating command shapes. |
| `https://github.com/yotamfried-ux/Engineering-OS/commit/19add0b12408d66d2969eeda5f5e69a511c7fcf1` | checked | Exact `main` base was re-read before the first write. |
| `https://github.com/yotamfried-ux/Engineering-OS/pull/274` | checked | Exact-head CI and live PR metadata are the mutable source for validation/review state. |

## Design

1. Parse Bash `tool_response.stdout`/`stderr` explicitly when the response is structured; preserve a conservative fallback for legacy/string payloads.
2. Keep graphify evidence behavior isolated from test-output handling.
3. Recognize direct Engineering OS enforcement-suite invocations and the repository's canonical all-suite loop shape.
4. For a direct suite, rely on the PostToolUse success boundary plus an unwrapped simple-command shape and reject contradictory failure output; do not require every suite to print one artificial summary format. For a multi-suite loop, additionally require the canonical aggregate success marker after a failure-propagating loop.
5. Preserve existing generic runner support while reading the relevant output tail rather than only the first 2,000 characters and rejecting explicit failure summaries before positive markers.
6. Add an executable regression that proves positive and negative evidence behavior and exercises the Stop/G11 consumers without changing their implementation.

## Capability Evidence

- `routing.task-router-read` — `core/task-router.md` was consulted for the Engineering OS governance route.
- `workflow.workflow-read` — `core/workflow.md`, `core/hooks-policy.md`, `core/quality-gates.md`, and `core/coderabbit-policy.md` were read for the workflow, hook criticality, verification, and review contracts.
- `plan.route-plan-before-write` — this Route Plan was committed before the recorder/test implementation commits.
- `source.github-repo-read` — exact `main@19add0b12408d66d2969eeda5f5e69a511c7fcf1` and PR #274 live state were read through GitHub.
- `validation.policy-change-has-validator` — `scripts/enforcement/tests/test-post-tool-use-bash-evidence.sh` executes positive/negative recorder cases and real Stop/G11 consumers.
- `validation.coderabbit-policy` — `core/coderabbit-policy.md` governs this ready-for-review PR; live threads were checked and merge remains blocked on explicit owner approval.

## Skill Evidence

- `writing-plans` — scope, source checks, non-goals and validation are explicit.
- `verification-before-completion` — deterministic fixture evidence, exact-head CI, live runtime evidence and merge evidence remain separate claims.

## Connector Evidence

- GitHub: used to read the exact repository base, create branch `fix/bash-tests-run-evidence`, open PR #274, inspect exact-head workflow runs, and inspect live review threads.

## Connector Usage Evidence

- source: GitHub — `yotamfried-ux/Engineering-OS` main commit `19add0b12408d66d2969eeda5f5e69a511c7fcf1`, PR #274, and Actions run `enforcement-tests` 1632 on head `75d57f29c41b909117573d8ea3d8e2a259900e03`.
- action: traced `tests_run` from `scripts/enforcement/post-tool-use-bash.sh` through `scripts/enforcement/post-stop-hook.sh` and `scripts/hooks/pre-commit.sh`; then observed exact-head CI and live review-thread state.
- result: exact-head `enforcement-tests` run 1632 completed successfully on `75d57f29c41b909117573d8ea3d8e2a259900e03`; no review threads were present at that check; policy workflows correctly rejected incomplete plan/PR evidence rather than the implementation regression.
- decision: selected a producer-only correction, kept G11/Stop/ledger semantics unchanged, and updated this plan to satisfy the exact capability/documentation/progress contracts exposed by CI instead of weakening those gates.
- target: `scripts/enforcement/post-tool-use-bash.sh`; `scripts/enforcement/tests/test-post-tool-use-bash-evidence.sh`.

## Documentation Asset Evidence

- internal: `core/hooks-policy.md`; `scripts/enforcement/hook-criticality.tsv`; `scripts/enforcement/post-tool-use-bash.sh`; `scripts/hooks/pre-commit.sh`; `scripts/enforcement/post-stop-hook.sh`; `scripts/enforcement/tests/test-hook-classification.sh`.
- context7: not required because this change does not implement, upgrade, or integrate an external library, framework, SDK, API, or service; the only external behavior contract needed was checked directly in the official Claude Code hooks reference at `https://code.claude.com/docs/en/hooks`.
- decision: the internal hook classification required a conservative false-evidence-safe producer, while the official PostToolUse success boundary justified accepting only direct failure-propagating EOS suite shapes without inventing a universal output format.

## Progress Lifecycle Evidence

- start: plan committed before code changes. Base is `19add0b12408d66d2969eeda5f5e69a511c7fcf1`; root cause and both consumers were traced before writing.
- mid: recorder implementation parses structured Bash output, recognizes direct EOS suites and the canonical aggregate loop, rejects explicit failure summaries, and keeps graphify behavior isolated. The first regression draft used `eval` to construct multiline JSON fixtures; review of the test itself found that quoting could become part of the result, so the fixture builder was replaced with environment-backed Python JSON serialization before any CI claim.
- pre-merge: PR #274 exact head `75d57f29c41b909117573d8ea3d8e2a259900e03` completed `enforcement-tests` run 1632 successfully, including the newly auto-discovered `test-post-tool-use-bash-evidence.sh`. The same head correctly failed capability/documentation/workflow/connector/plan/PR policy checks because this plan/PR evidence was incomplete; those failures are the reason for this post-code plan update. Live review threads were checked and none were present. No merge or fresh-Claude-runtime claim is made.

## Claude Run Trace

- goal: make Engineering OS's own successful Bash enforcement suites produce trustworthy `tests_run` evidence without weakening G11 or fabricating evidence from command mentions/masked failures.
- hypothesis: the defect is entirely at the PostToolUse producer: recognize only failure-propagating EOS suite command shapes, parse structured output instead of a 2,000-character leading string, and reject contradictory failure summaries; existing Stop and G11 consumers should then behave correctly without implementation changes.
- steps: read the producer, ledger and both consumers; inspect current hook classification and regression coverage; commit the Route Plan; implement structured/tail parsing and EOS command classification; add positive/negative recorder fixtures plus executing Stop/G11 fixtures; replace an unsafe `eval` fixture builder after reviewing the test itself; open PR #274; inspect exact-head CI; reconcile policy failures against their canonical checkers rather than weakening them.
- evidence: `scripts/enforcement/tests/test-post-tool-use-bash-evidence.sh`; exact-head GitHub Actions `enforcement-tests` run 1632 on `75d57f29c41b909117573d8ea3d8e2a259900e03`; live PR #274 metadata/thread check.
- result: deterministic implementation regression is green. Fresh Claude Code runtime observation and merge/post-merge evidence remain separate and are not claimed here.

## Definition of Done — Implementation

- [x] A successful direct `bash scripts/enforcement/tests/test-*.sh` PostToolUse payload records `tests_run` in the dedicated regression.
- [x] A canonical full-suite Bash loop with an explicit successful aggregate summary records `tests_run` in the dedicated regression.
- [x] Malformed JSON, non-test commands, path mentions/echoes, failed output, and masked failures do not record `tests_run` in the dedicated regression.
- [x] Existing pytest and npm evidence behavior is covered alongside the EOS cases; the pre-existing recorder keeps cargo/go/jest/vitest/yarn matching unchanged.
- [x] Stop executes against the valid fixture ledger and reports `tests passed`.
- [x] G11 executes against the same >2-code-file staged diff, blocks with no verification evidence, and allows it after `tests_run` exists without a G11 implementation change.
- [x] The focused regression is auto-discovered by `.github/workflows/enforcement-tests.yml`, and exact-head `enforcement-tests` run 1632 is green on `75d57f29c41b909117573d8ea3d8e2a259900e03`.
- [x] Canonical gap ownership was reviewed after implementation evidence: this PR does not create an immediately-mitigated duplicate readiness row; any contradiction from fresh runtime evidence must be registered as a new gap then.

Follow-up evidence, deliberately outside the implementation checklist: obtain a fresh Claude Code session observation of a real Engineering OS Bash suite producing `tests_run`/`tests passed`; keep PR #274 unmerged until exact-head policy checks, review and explicit owner approval satisfy the repository merge contract.

## Validation Plan

- Focused: `test-post-tool-use-bash-evidence.sh`, `test-hook-classification.sh`, `test-tests.sh`.
- Consumers: execute `post-stop-hook.sh` against a fixture ledger; execute pre-commit G11 against >2 staged code files with and without `tests_run`.
- Full: every auto-discovered `scripts/enforcement/tests/test-*.sh` suite through `enforcement-tests`.
- External: exact-head CI, live review, explicit owner approval, expected-head merge, post-merge validation.
