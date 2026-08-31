# Route Plan — Make Bash enforcement tests produce trustworthy runtime evidence

## Route Plan

| Field | Decision |
|---|---|
| Task type | runtime evidence correctness defect plus critical review of automated-test truthfulness |
| Task class | `engineering_os_governance` |
| Domain tags | hooks, validation evidence, bash tests, G11, Stop, CI coverage |
| Plan Scope | focused implementation plus test-corpus audit |
| Planning Mode | implementation; fix the existing evidence recorder without changing G11 semantics, then verify that the repository actually executes the tests it counts |
| Task-router evidence | `core/task-router.md` routes Engineering OS hook/evidence work through governance/ops-readiness. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/hooks-policy.md`, `core/git-policy.md`, and `core/coderabbit-policy.md` require plan-first writes, executable regression evidence, focused PR review, exact-head CI, and explicit owner approval before merge. |
| Target paths | `.claude/plans/bash-tests-run-evidence.md`; `scripts/enforcement/post-tool-use-bash.sh`; `scripts/enforcement/run-enforcement-tests.sh`; `scripts/enforcement/tests/test-post-tool-use-bash-evidence.sh`; `.github/workflows/enforcement-tests.yml` |
| Templates | waiver — focused correction to an existing hook recorder and its regressions |
| Architecture guides | `core/hooks-policy.md`; `scripts/enforcement/hook-criticality.tsv` |
| Patterns | no matching reusable implementation pattern is required for this focused recorder correction |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion` |
| Validation gates | recorder regression; canonical runner failure propagation; hook classification; G11 consumer behavior; Stop consumer behavior; full enforcement suite; bypass-provider Python suite; exact-head CI; PR policy |
| Evidence to check | producer and consumers; canonical runner; dedicated regression; `.github/workflows/enforcement-tests.yml`; exact-head GitHub Actions; live review threads |
| User decisions required | owner approval before merge |

## Goal

A successful Engineering OS Bash enforcement suite must create `tests_run` evidence, while malformed input, non-test commands, failed/masked test output, and commands that merely mention a test path must not fabricate evidence. The repository's automated-test claim must also correspond to tests that are actually executed by CI rather than merely existing under `scripts/enforcement/tests/`.

## Scope

In scope: `post-tool-use-bash.sh`, a canonical failure-propagating Bash-suite runner, a dedicated executable regression suite, consumer execution for Stop/G11, exact-head CI evidence, and correcting a directly observed unexecuted Python test in the enforcement corpus.

Out of scope: changing G11 policy, changing `evidence.sh` ledger semantics, changing hook criticality/wiring, or treating deterministic fixture success as proof of production/runtime readiness.

### Gap-registration decision

The implementation bug is deterministically testable here, while the still-missing fresh Claude Code observation is runtime evidence rather than another implementation defect. This PR therefore does not create and immediately mitigate a duplicate readiness row. If fresh runtime evidence contradicts the deterministic result, that contradiction creates a canonical gap then.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `scripts/enforcement/post-tool-use-bash.sh` | read | Test recognition was a closed runner list and inspected only a leading output slice; Engineering OS Bash suites were invisible. |
| `scripts/hooks/pre-commit.sh` | read | G11 consumes `tests_run`; missing evidence can block a >2-code-file commit even after real Bash tests passed. |
| `scripts/enforcement/post-stop-hook.sh` | read | Stop reports `no successful test run` when the same evidence is absent. |
| `scripts/enforcement/hook-criticality.tsv` | read | The recorder is canonically `recorder / false_evidence_safe`; false-positive evidence is worse than a conservative false negative. |
| `.github/workflows/enforcement-tests.yml` | read | All `test-*.sh` suites are executed; Python tests require explicit wiring. |
| `.github/workflows/telemetry-handoff-tests.yml` | read | Four Python enforcement tests are explicitly executed there. |
| `scripts/enforcement/tests/test-bypass-provider-validation.py` | read | Contains a standalone `main()` with extensive provider-boundary/negative coverage; before this PR update it was imported as a helper but its standalone `main()` was not directly executed by CI. |
| `https://code.claude.com/docs/en/hooks` | checked | Official hooks reference supports using PostToolUse success only when the actual test process/runner failure status propagates. |
| `https://github.com/yotamfried-ux/Engineering-OS/commit/19add0b12408d66d2969eeda5f5e69a511c7fcf1` | checked | Exact `main` base was re-read before the first write. |
| `https://github.com/yotamfried-ux/Engineering-OS/pull/274` | checked | Exact-head CI and live PR metadata are the mutable validation/review source. |

## Design

1. Parse Bash `tool_response.stdout`/`stderr` explicitly when structured and preserve a conservative string fallback.
2. Keep graphify evidence behavior isolated from test-output handling.
3. Trust direct `bash scripts/enforcement/tests/test-*.sh` simple commands and direct invocation of one canonical `scripts/enforcement/run-enforcement-tests.sh` runner; do not infer arbitrary shell-loop control flow from regexes.
4. Make the canonical runner itself aggregate every discovered Bash suite and return non-zero if any suite fails.
5. Reject contradictory failure summaries before recording positive evidence and keep existing generic runner support while reading the output tail.
6. Exercise positive/negative recorder behavior plus actual Stop and G11 consumers.
7. Ensure the previously unexecuted standalone `test-bypass-provider-validation.py` is invoked directly by enforcement CI.

## Capability Evidence

- `routing.task-router-read` — `core/task-router.md` was consulted for the Engineering OS governance route.
- `workflow.workflow-read` — workflow, hook criticality, verification, review and merge contracts were read from the canonical core policies.
- `plan.route-plan-before-write` — this Route Plan existed before implementation and was materially updated after the last code/config/test change.
- `source.github-repo-read` — exact `main@19add0b12408d66d2969eeda5f5e69a511c7fcf1`, PR #274, workflow runs and live threads were read through GitHub.
- `validation.policy-change-has-validator` — `test-post-tool-use-bash-evidence.sh` executes recorder, runner, Stop and G11 positive/negative behavior.
- `validation.actions-checked` — GitHub Actions on exact heads were inspected after each implementation iteration; the test-corpus audit also changed `.github/workflows/enforcement-tests.yml` so the standalone provider suite is directly executed.
- `validation.coderabbit-policy` — live review findings were treated as blocking until fixed and reconciled; explicit owner approval remains a separate merge gate.

## Skill Evidence

- `writing-plans` — scope, source checks, non-goals and validation are explicit.
- `verification-before-completion` — deterministic fixture evidence, exact-head CI, live runtime evidence and merge evidence remain separate claims.

## Connector Evidence

- GitHub: used to read the exact repository base, create/update branch `fix/bash-tests-run-evidence`, open PR #274, inspect exact-head workflow runs/logs, inspect live review threads, and apply the CI/test-plan corrections.

## Connector Usage Evidence

- source: GitHub — `yotamfried-ux/Engineering-OS` main `19add0b12408d66d2969eeda5f5e69a511c7fcf1`, PR #274, exact-head Actions, and live review threads.
- action: traced `tests_run` from producer through Stop/G11; inspected review findings; audited Shell/Python test discovery and CI wiring; inspected policy failures on head `32aa799e4e71b9b80565bee8bd192bcaa4a3d11b`.
- result: GitHub exact-head `enforcement-tests` run 1637 passed on `01d439b827eab3861605d68c38f2c15a49ab6a67`; live PR #274 review found two P1 unsafe-shell-inference cases; live thread validation later reported `total=2, unresolved=0`; the test-corpus audit identified `scripts/enforcement/tests/test-bypass-provider-validation.py` as a standalone suite not directly executed by CI.
- decision: GitHub review and CI evidence changed the implementation: removed raw-loop semantic inference, added the canonical failure-propagating runner trust boundary, and added direct CI execution of `scripts/enforcement/tests/test-bypass-provider-validation.py` rather than counting file presence as coverage.
- target: `scripts/enforcement/post-tool-use-bash.sh`; `scripts/enforcement/run-enforcement-tests.sh`; `scripts/enforcement/tests/test-post-tool-use-bash-evidence.sh`; `.github/workflows/enforcement-tests.yml`.

## Documentation Asset Evidence

- internal: `core/hooks-policy.md`; `scripts/enforcement/hook-criticality.tsv`; producer/consumers; `.github/workflows/enforcement-tests.yml`; `.github/workflows/telemetry-handoff-tests.yml`; `scripts/enforcement/tests/test-bypass-provider-validation.py`.
- context7: not required because no external library/framework/SDK/API integration is being implemented; external hook semantics were checked in the official Claude Code hooks reference.
- decision: internal false-evidence-safe classification requires conservative evidence, while the official PostToolUse boundary supports direct failure-propagating process shapes only.

## Progress Lifecycle Evidence

- start: plan committed before code changes. Base is `19add0b12408d66d2969eeda5f5e69a511c7fcf1`; producer and both consumers were traced first.
- mid: structured/tail parsing and EOS direct-suite support were implemented. The first JSON fixture builder used `eval`; it was replaced before relying on CI. Initial raw-loop classification then received two P1 review findings: `set -e` could be disabled before the loop, and comments/strings could satisfy aggregate regexes. Both findings were accepted.
- pre-merge: After code/config commit `ee660c829c450dae29490da8ec56614add46975c`, GitHub exact-head evidence on `32aa799e4e71b9b80565bee8bd192bcaa4a3d11b` showed capability-evidence-policy run 1294, telemetry-handoff-tests run 541, semantic-cleanup-policy run 1068, import-cleanup-policy run 1068 and documentation-asset-policy run 1050 successful; PR-policy live thread validation reported `total=2, unresolved=0`; this checkpoint records those concrete results after the last code/config/test change without asserting a full-green merge state.

## Claude Run Trace

- goal: make successful Engineering OS Bash tests produce trustworthy `tests_run` evidence and ensure the automated-test claim reflects executed tests.
- hypothesis: the original defect is at the PostToolUse producer, but arbitrary shell text is not a safe place to infer failure propagation; a canonical executable runner provides a stronger trust boundary.
- steps: trace producer/consumers; add structured output parsing and focused regression; open PR; inspect CI; accept two P1 review findings; replace regex shell-loop inference with canonical runner; rerun full enforcement CI; audit Shell/Python test discovery; find one standalone Python suite not directly executed; wire it to CI; inspect exact policy failures; reconcile plan/PR evidence contracts.
- evidence: focused regression; canonical runner; exact-head `enforcement-tests` run 1637 on `01d439b...`; live PR review; direct CI wiring for the Python provider suite; exact policy diagnostics on `32aa799...`.
- result: deterministic implementation regression passed after the canonical-runner redesign; live review threads are reconciled; test discovery now directly executes the previously missed standalone Python provider suite. Fresh Claude Code runtime observation remains a distinct operational proof.

## Definition of Done — Implementation

- [x] Successful direct EOS Bash suite PostToolUse payload records `tests_run`.
- [x] Direct canonical runner invocation records `tests_run` only on a successful PostToolUse boundary.
- [x] Canonical runner returns non-zero if any supplied/discovered Bash suite fails.
- [x] Raw loops, including `set -e; set +e`, commented aggregate gates and `|| true`, cannot fabricate `tests_run`.
- [x] Malformed JSON, path mentions, failed output and masked generic runners do not record `tests_run`.
- [x] Existing pytest/npm evidence behavior remains covered.
- [x] Stop reports `tests passed` after valid evidence.
- [x] G11 blocks the same >2-code-file diff without evidence and accepts it with `tests_run`.
- [x] Full Bash enforcement suite passed on exact head `01d439b...` in run 1637 after the canonical-runner redesign.
- [x] Standalone `test-bypass-provider-validation.py` is directly wired into enforcement CI.
- [x] Both actionable P1 review threads were answered and resolved after focused regressions were added.
- [x] Plan evidence was reconciled after the last code/config/test change without converting merge prerequisites into completed implementation claims.

## Merge gates

Exact-head green CI across the required named workflows is a merge prerequisite evaluated from GitHub Actions for the final head. Explicit owner approval is a separate merge prerequisite and has not been granted in this conversation. Neither prerequisite is represented as an unchecked implementation checklist item.

Follow-up operational evidence outside implementation closure: observe a fresh Claude Code session running the canonical Engineering OS Bash suite and producing `tests_run`/`tests passed`. A deterministic green CI result is not relabeled as that live-runtime proof.

## Validation Plan

- Focused: `test-post-tool-use-bash-evidence.sh`, `test-hook-classification.sh`, `test-tests.sh`.
- Runner: success and mixed success/failure fixtures against `run-enforcement-tests.sh`.
- Consumers: actual `post-stop-hook.sh` and pre-commit G11 fixtures.
- Full Shell: every discovered `scripts/enforcement/tests/test-*.sh` through the canonical runner and existing grouped CI checks.
- Python: direct CI execution of `test-bypass-provider-validation.py`; the four telemetry Python suites remain explicitly exercised by `telemetry-handoff-tests`.
- External: exact-head CI, live review, explicit owner approval, expected-head merge, post-merge validation.
