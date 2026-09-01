# Route Plan — Harden automated-test evidence trust

## Route Plan

| Field | Decision |
|---|---|
| Task type | validation-governance hardening after critical test-corpus audit |
| Task class | `engineering_os_governance` |
| Domain tags | automated tests, CI truthfulness, simulation coverage, evidence levels, mutation testing, validation governance |
| Plan Scope | multi-stage hardening of test discovery, execution proof, semantic coverage and evidence reporting |
| Planning Mode | implementation planning only; do not treat this plan as closure evidence |
| Task-router evidence | `core/task-router.md` routes Engineering OS governance and validation work through the canonical workflow and quality gates. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, and the operational-readiness audit require plan-first writes, executable positive/negative evidence, exact-head CI, review reconciliation and owner approval before merge. |
| Target paths | `.claude/plans/test-evidence-trust-hardening.md`; `scripts/enforcement/check-simulation-coverage.sh`; `scripts/enforcement/tests/test-simulation-coverage.sh`; `scripts/enforcement/run-enforcement-tests.sh`; new test-corpus inventory/receipt tooling under `scripts/enforcement/`; `.github/workflows/enforcement-tests.yml`; test-evidence documentation and gap/audit metadata as required |
| Templates | waiver — focused governance hardening with no matching project template required |
| Architecture guides | `core/quality-gates.md`; `docs/operations/operational-readiness-audit.md` |
| Patterns | no existing reusable pattern is trusted until the new evidence model is defined |
| External systems/connectors | GitHub |
| Skills | `personal-context` |
| Validation gates | orphan-test detection; execution receipts; semantic simulation receipts; evidence-level classification; duplicate-run de-duplication; targeted fault injection; full enforcement suite; exact-head CI; PR policy |
| Evidence to check | test discovery, workflow wiring, executed-suite receipts, scenario receipts, CI artifacts, live provider boundaries and review threads |
| User decisions required | owner approval before merge; no runtime/experiment claim is implied by this work |

## Goal

Make a green Engineering OS test result mean something precise and auditable:

1. every executable test candidate is either run by an identified canonical runner or explicitly classified as a helper/non-test;
2. CI can prove which tests actually executed on the exact commit instead of inferring execution from file presence;
3. simulation coverage is satisfied by scenarios that actually ran and passed, not by tokens that merely appear in source comments or strings;
4. reports distinguish deterministic static/fixture/integration evidence from live-provider and real-runtime evidence;
5. critical P0/P1 protections demonstrate that their tests fail when the protected behavior is deliberately broken in a safe temporary copy.

The objective is stronger truthfulness, not a larger raw test count.

## Progress

- [x] Planning complete on the clean branch before implementation changes.
- [x] Implementation start authorized by the user's explicit instruction on 2026-09-01.
- [x] Midpoint verification recorded after the first implementation pass.
- [x] Final corrections completed after midpoint findings.
- [x] Final local verification completed on the final code state.
- [x] Pull request opened only after final local verification: PR #277.

Implementation-start checkpoint: work begins from `main@e5b761ce06a811fbd6f81991f3087f8f89744ef7` after this progress record is committed. The prior draft PR #275 is treated only as an implementation laboratory and evidence source; it is not the delivery branch.

Midpoint checkpoint: the first aggregate run reached the remote-handoff simulations after the existing corpus had remained green. It exposed two evidence-system issues to correct before final verification: concurrent aggregate attempts can overwrite a shared attempt log and invalidate its earlier checksum, and `test-multirepo-dispatch.sh` used GitHub-shaped origins that allowed a simulated required handoff to attempt an external push. Final corrections must use an isolated evidence directory per aggregate run and make the multirepo transport hermetic while preserving GitHub-shaped identity parsing.

Final local verification checkpoint: code commit `7c25ee7bcfa7267fdeaca7a37b103279f8ecc9e0` produced 121 exact-code execution receipts for 121 discovered standalone tests, with 121 passes, zero missing receipts, zero duplicate attempts in the clean release run, and 35 execution-backed simulation gates passing. The conservative evidence report classified 109 tests as static, 5 as fixture, 7 as integration, and none as live-provider or real-runtime. External log mutation found during verification was resolved by embedding checksum-bound output directly in each self-contained receipt; embedded-content tampering and concurrent-runner regressions pass.

## Findings that drive this plan

### 1. A standalone test file could exist without being directly executed

PR #274 found `scripts/enforcement/tests/test-bypass-provider-validation.py` with a standalone `main()` and meaningful provider-boundary coverage, but CI did not directly execute that suite before the PR. PR #274 fixed the specific file. The remaining systemic risk is that another test can be added later without any gate proving that it is wired to a runner.

### 2. Simulation coverage currently proves token presence, not executed semantics

`check-simulation-coverage.sh` accepts `covered:<token>` when `grep -Fq` finds the token in the declared test file. `test-simulation-coverage.sh` intentionally demonstrates this mechanism using fixture tokens that appear only in comments. This is useful traceability, but it is weaker than the word `covered` suggests and cannot prove that the scenario executed or asserted the intended behavior.

### 3. Evidence levels are easy to conflate

The current corpus contains static checks, fixture-driven checker tests, temporary-repository integration tests, live GitHub/provider checks and separate real-runtime qualifications. Names and raw pass counts do not consistently identify those levels. A green fixture test must not be presented as equivalent to a live provider or real Claude/Project 8 run.

### 4. Repeated execution can inflate perceived confidence

The same deterministic suite can run through focused jobs, grouped jobs and the aggregate runner. Repetition is useful for reliability, but three executions of one test are not three independent proofs. The reporting layer should distinguish unique tests/scenarios from attempts.

### 5. Critical gates lack a small, explicit fault-injection layer

Positive/negative fixtures show many expected cases, but the project does not yet have one canonical mechanism that safely changes a critical behavior in a temporary copy and proves that the intended regression suite detects the break. Targeted fault injection gives stronger evidence that a test protects the property it claims to protect.

## Gap-registration decision

Before implementation changes, re-read the latest `docs/operations/known-gaps.tsv` and avoid duplicate rows. If the risks are still unrepresented, register two canonical gaps:

- proposed `test-corpus-execution-completeness` — P1: executable test candidates can exist without a canonical execution owner or exact-run receipt;
- proposed `simulation-coverage-semantic-trust` — P2: source-token presence can satisfy simulation coverage without an executed passing scenario.

Evidence-level reporting, duplicate de-duplication and targeted fault injection are implementation deliverables under those risks unless the latest registry already owns them separately. Do not create extra gaps merely for bookkeeping.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `CLAUDE.md` | read | Repository-wide operating contract applied. |
| `core/task-router.md` | read | Routed as Engineering OS governance work. |
| `core/workflow.md` | read | Plan-first lifecycle and validation order applied. |
| `core/git-policy.md` | read | Clean branch and PR workflow applied. |
| `core/quality-gates.md` | read | Exact-head, review and completion boundaries applied. |
| `core/connector-policy.md` | read | GitHub reads/writes recorded below. |
| `core/coderabbit-policy.md` | read | Ready PR opened for automated review. |
| `.github/workflows/enforcement-tests.yml` | checked during PR #274 audit | Bash suites use a canonical runner; Python execution still depends on explicit workflow wiring rather than one corpus-wide ownership contract. |
| `scripts/enforcement/check-simulation-coverage.sh` | read | `covered:<token>` is validated with literal source search using `grep -Fq`. |
| `scripts/enforcement/tests/test-simulation-coverage.sh` | read | Its positive fixture contains only comment tokens, proving that current coverage is traceability rather than executed semantic proof. |
| `scripts/enforcement/run-enforcement-tests.sh` | checked during PR #274 | Canonical Bash runner can provide reliable suite-level exit status and is the right place to emit execution receipts. |
| `docs/operations/operational-readiness-audit.md` | read during audit | The audit already separates deterministic simulation from live/runtime closure and states that scenario quality remains reviewed. |
| `.claude/plans/test-evidence-trust-hardening.md` history | checked | Plan, implementation-start, midpoint and final checkpoints precede the PR; PR #277 is the delivery PR. |

## Design principles

1. **Execution must be observed, not guessed.** File existence, filename patterns and comments can discover candidates but cannot prove that a test ran.
2. **One canonical test identity.** Every test and scenario receives a stable ID so duplicate attempts can be recognized without inflating coverage counts.
3. **Receipts come from runners after success.** A scenario counts only when the runner records that the test process completed successfully and the specific assertion/scenario reported success.
4. **Evidence level is explicit.** Static, fixture, integration, live-provider and real-runtime evidence are separate categories and cannot silently substitute for each other.
5. **Fail closed on unknown executable tests.** A newly added executable test candidate with no declared owner/runner must fail CI instead of becoming a dead test.
6. **Helpers are allowed only when declared.** Python helper modules imported by tests must be classified as helpers so discovery does not force every support file to execute independently.
7. **Repeated attempts do not multiply proof.** Reports count unique tests/scenarios separately from attempts and retries.
8. **Fault injection is temporary and deterministic.** Mutations happen only in disposable copies/worktrees and never rewrite `main` or production/provider state.

## Phase 1 — Canonical test-corpus inventory and execution ownership

Create a machine-readable registry or generated manifest for the enforcement test corpus. It must classify at least:

- stable test ID;
- repository path;
- language/runtime;
- role: standalone test, helper module, fixture-only asset, or non-test;
- canonical runner/workflow owner;
- maximum evidence level the test can produce;
- whether the file is required to execute directly.

Add a deterministic checker that discovers candidate test files and fails when:

- a standalone Bash/Python test candidate is not represented;
- a standalone test has no canonical runner/workflow owner;
- the registry points to a missing file or nonexistent runner;
- a helper is incorrectly counted as a directly executed test;
- duplicate IDs or ambiguous ownership exist.

Acceptance evidence must include a negative fixture equivalent to the old `test-bypass-provider-validation.py` state: add a temporary standalone Python test candidate with a valid entrypoint but no owner and prove the checker fails.

## Phase 2 — Exact execution receipts

Extend canonical runners so CI produces a machine-readable execution artifact for the exact commit. Each receipt should include at minimum:

- test ID and path;
- exact repository/head SHA;
- canonical runner identity;
- attempt number;
- start/end or duration metadata;
- result: PR #277 opened from pre-PR head `2ea3b64738ca4355484169488e4ca6f3240ee63d`; exact-head workflow runs were queried and their concrete documentation findings drove this final metadata reconciliation.
- evidence level;
- emitted scenario IDs where applicable.

The receipt must be written by the runner after the child process result is known. A file being listed in a manifest is not an execution receipt.

Add a checker that compares discovery/ownership against receipts and fails when a required standalone test has no receipt for the exact run.

The CI summary must report both unique tests and attempts so repeated grouped/aggregate execution remains visible without being counted as independent coverage.

## Phase 3 — Replace token-presence simulation coverage with executed scenario receipts

Keep the existing positive/negative/invalid/waiver matrix, but change `covered:<token>` semantics to reference stable scenario IDs that are proven by the current execution artifact.

Required behavior:

- a scenario ID declared in the matrix must be emitted only after its assertion actually passes;
- comments, strings, fixture data or dead code containing the scenario ID cannot satisfy coverage;
- a test process that fails after emitting an early marker cannot produce a passing final receipt;
- a scenario receipt must be bound to the exact test ID, exact run and exact SHA;
- waiver and `none-by-design` semantics remain explicit and reviewed;
- missing, duplicated or wrong-test scenario receipts fail closed.

Regression cases must include the current weakness explicitly: a test file containing the expected scenario ID only in comments must fail semantic coverage.

## Phase 4 — Evidence-level model and reporting

Adopt five evidence levels for reporting and closure language:

- `static` — source/configuration structure only;
- `fixture` — real checker/enforcer against synthetic inputs;
- `integration` — multiple real local components, temporary repositories/installations/processes;
- `live-provider` — actual external provider state/API/workflow such as GitHub;
- `real-runtime` — actual Claude/target-project operational execution.

The level is a claim ceiling, not a score. A test can prove up to its declared level but cannot be presented as a higher level because its filename contains words such as `live` or `project8`.

Update the CI summary/artifact so a reviewer can immediately see how many unique tests/scenarios passed at each level and which higher-level claims still depend on separate qualification evidence.

## Phase 5 — Targeted fault injection for critical P0/P1 gates

Add a small deterministic fault-injection harness for a curated list of critical properties rather than adopting broad mutation testing across the entire repository.

Initial candidates:

- change a fail-closed decision to allow;
- alter a required exit code;
- bypass expected-head/SHA binding;
- suppress required evidence recording;
- skip a required nested validator;
- accept stale/incorrect execution receipts.

For each mutation, run the owning focused regression and require it to fail for the expected reason. The harness passes only when the mutation is detected.

Mutations must operate on temporary copies or generated fixtures. They must never commit mutated production code or contact mutable external providers.

## Phase 6 — CI integration and truthful summary

Integrate the new checks into `enforcement-tests` without weakening existing gates.

The final machine-readable CI artifact should show at least:

- discovered standalone tests;
- declared helpers/non-tests;
- required tests executed;
- unique tests passed/failed/skipped/waived;
- execution attempts and duplicate attempts;
- expected scenario IDs vs executed passing scenario IDs;
- evidence-level counts;
- orphan/unowned tests;
- fault-injection cases and whether the expected regression detected each mutation.

Human-facing output should use wording such as `unique deterministic suites passed` rather than treating raw rerun counts as independent proof.

## Phase 7 — Documentation, audit and closure

Document the evidence model and update the audit/registry only after implementation evidence exists.

Closure requires:

- focused positive/negative regressions for every new checker;
- the old comment-only simulation fixture no longer counting as semantic coverage;
- an orphan standalone test fixture failing CI;
- helper classification passing without false positives;
- exact-run receipts proving all required standalone tests executed;
- duplicate attempts reported but counted once as unique evidence;
- targeted critical mutations detected by their owning tests;
- full existing enforcement suite still green;
- exact-head named CI green;
- review reconciliation with zero unresolved actionable threads;
- explicit owner approval before merge;
- post-merge validation on canonical `main`.

No live-provider or real-runtime readiness gap is closed merely because these deterministic controls pass.

## Proposed implementation order

1. Reconcile/register the two proposed gaps only if they are not already represented.
2. Build corpus inventory and orphan-test checker.
3. Add runner execution receipts and exact-run completeness checker.
4. Convert simulation coverage from source tokens to executed scenario receipts.
5. Add evidence-level metadata and de-duplicated CI reporting.
6. Add targeted P0/P1 fault injection.
7. Run focused regressions, full suite and exact-head CI.
8. Reconcile external review.
9. Update audit/registry only with evidence that actually exists.
10. Stop for owner merge approval.

## Validation Plan

### Corpus ownership

- standalone Bash test with owner passes;
- standalone Python test with owner passes;
- orphan standalone Python test fails;
- declared helper module passes without direct-execution requirement;
- missing/duplicate/ambiguous registry entries fail.

### Execution receipts

- successful child test creates exact-SHA pass receipt;
- failed child cannot create pass receipt;
- stale-SHA receipt fails;
- missing required receipt fails;
- duplicate attempts remain visible but unique-test count stays one.

### Semantic simulation coverage

- executed positive/negative/invalid scenario receipts pass;
- scenario ID present only in a comment fails;
- scenario ID emitted by the wrong test fails;
- early marker followed by test failure fails;
- missing scenario receipt fails;
- explicit waiver/none-by-design rules still pass only when valid.

### Evidence levels

- fixture test cannot be reported as live-provider;
- live GitHub validation can be reported as live-provider only when the workflow actually queries live GitHub state;
- real-runtime remains separate from CI unless a real qualification artifact is explicitly supplied.

### Fault injection

- every curated mutation must make its owning regression fail;
- if a mutation survives, the plan remains incomplete and the missing regression is added before merge.

### Final verification

- canonical corpus inventory/receipt checks;
- full enforcement suite;
- telemetry-handoff tests where relevant;
- semantic/import/documentation/capability/workflow/connector policies as triggered by changed paths;
- exact-head CI;
- live review threads;
- owner approval;
- expected-head protected merge;
- post-merge validation.

## Completion statement allowed after implementation

After all phases pass, the project may claim that its deterministic automated-test evidence is complete, execution-backed, semantically linked and classified by evidence level for the covered corpus. It may not claim that live-provider or real-runtime behavior is proven unless those higher-level evidence sources were separately executed and validated.

## Capability Evidence

- `routing.task-router-read` — `core/task-router.md` was read and the task was routed as Engineering OS governance.
- `workflow.workflow-read` — `core/workflow.md` was read before the clean delivery branch was constructed.
- `plan.route-plan-before-write` — the remote branch history starts with the Route Plan, followed by a separate implementation-start checkpoint, before its first code/config/test change.
- `source.github-repo-read` — Git history, PR #274, draft PR #275, branch state, workflow runs, job logs and review state were read from the repository and GitHub.
- `validation.policy-change-has-validator` — the new receipt, simulation-coverage and fault-injection behavior has focused positive and negative regression suites.
- `validation.coderabbit-policy` — PR #277 is ready for review; CodeRabbit status and review threads are checked before merge.
- `validation.actions-checked` — PR #277 exact-head workflow runs were queried after opening; policy failures were read from their job logs and this documentation correction responds to those exact findings.

## Connector Evidence

- [x] GitHub was used to create the clean branch from exact `main` SHA `e5b761ce06a811fbd6f81991f3087f8f89744ef7`, publish the ordered commits, open PR #277, and inspect exact-head Actions and review state.
- [x] The repository files published before PR creation were compared by Git blob SHA with the locally verified state: 25 of 25 matched.
- [x] No test pushed to a production connector. The multirepo integration test preserves GitHub-shaped identity while redirecting transport to disposable local bare repositories.

## Connector Usage Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS`, PR #277 and commit `5abbc47be6332630a3936dc3a71653fd49ab97e6`.
- action: created the clean delivery branch and ordered commits; opened PR #277; read workflow runs, failed-job logs, CodeRabbit status and review threads.
- result: PR #277 opened after final local verification; exact-head CI started; the first policy pass identified missing canonical plan sections while CodeRabbit status succeeded and no review threads existed at that checkpoint.
- decision: the live workflow evidence changed the delivery approach: PR #277 will be superseded by a fresh branch whose canonical lifecycle section exists before its first code change; the multirepo implementation remains hermetic because connector evidence showed no production write was required.
- target: `scripts/enforcement/tests/test-multirepo-dispatch.sh`.

## Documentation Asset Waiver

- reason: no new user-facing documentation or reusable reference asset is required because the behavior is self-documented by the Route Plan, machine-readable evidence-level registry, receipt schema, CI summary and focused regressions.
- scope: internal enforcement runners, evidence receipts, simulation mappings and their regression tests only.
- risk: low documentation risk; the principal residual risk is misreading deterministic evidence as live/runtime proof, which is explicitly prevented by the evidence ceilings and claim boundary.

## Skill Evidence

`personal-context` was used only to recover the prior decisions, branch/PR state and the user's requested simple reporting style. It did not substitute for repository validation or provide implementation evidence.

## Claude Run Trace

- **Goal:** make the automated-test claim complete, execution-backed, de-duplicated and explicit about its limits.
- **Hypothesis:** canonical discovery plus exact-code receipts can prove that every standalone test ran; binding simulation cells to successful emitted output removes comment-only false coverage.
- **Steps:** create plan-only commit → record implementation start → publish first implementation → record midpoint findings → fix concurrency, receipt immutability and hermetic transport → run the final corpus → record final checkpoint → open PR #277 → inspect exact-head CI and review.
- **Evidence:** final code commit `7c25ee7bcfa7267fdeaca7a37b103279f8ecc9e0` produced 121 receipts for 121 discovered tests; 116 Bash and 5 Python suites passed; 35 simulation gates and 125 covered cells resolved through executed output; targeted fault injection passed.
- **Rejected:** source-token presence as semantic coverage; external log files as mutable receipt dependencies; repeated attempts as extra unique tests; live-provider or real-runtime claims without those executions.
- **Result:** implementation complete and PR #277 opened after the final technical checkpoint; exact-head Actions were inspected and their plan-format findings were reconciled without runtime-code changes.
- **Follow-up:** require the new exact-head CI run, zero unresolved actionable review threads and explicit owner approval; do not merge without approval. resolve any exact-head policy/review finding, obtain owner approval, and do not merge without it.

## Progress Lifecycle Evidence

- **start:** plan-only commit `b16d8a1c8956f0a6169af2fac6c3ea9670c4dfce` introduced this canonical lifecycle section before any code/config/test change. Dedicated start checkpoint `db03e17c5280b48f98edc5a2ad1e85cf11eee4c0` then authorized implementation from exact base `e5b761ce06a811fbd6f81991f3087f8f89744ef7`.
- **mid:** checkpoint `fa2a83aed14b0820d434e6b9c280a862ea78c0f6` was committed after the first implementation pass and before final corrections. It recorded concurrent receipt-log collision risk and a non-hermetic multirepo transport path.
- **pre-merge:** checkpoint `2ea3b64738ca4355484169488e4ca6f3240ee63d` recorded the final verified runtime state before PR #277 opened: 121/121 discovered tests passed with exact-code receipts, 35 execution-backed simulation gates and 125 covered cells passed, targeted fault injection passed, and multirepo transport was hermetic. This post-PR metadata reconciliation changes no runtime code; exact-head CI must rerun.

## Definition of Done

- [x] All standalone Bash and Python tests are discovered automatically: 121 found.
- [x] Every discovered test is owned by a canonical runner and produced an exact-code receipt: 121 of 121.
- [x] Repeated attempts are reported separately and unique tests are counted once.
- [x] All simulation-coverage entries use successful executed output rather than source-token presence: 35 gates and 125 covered cells passed.
- [x] Evidence ceilings are explicit: static 109, fixture 5, integration 7, live-provider 0, real-runtime 0.
- [x] Receipt tampering, stale/wrong bindings and six targeted weakening mutations are detected by focused regressions.
- [x] The full final local run passed: 116 Bash suites and 5 Python suites.
- [x] Clean remote chronology preserves plan → start → code → midpoint → corrections → final verification → PR.
- [x] PR #277 opened only after final local verification.
- [x] Exact-head Actions were checked and initial policy findings were reconciled in this plan-only correction.
