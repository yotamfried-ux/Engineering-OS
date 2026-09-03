# Route Plan — Windows CRLF policy manifest compatibility

Plan Scope: standard
Plan Timestamp: 2026-09-03T08:35:00Z
Planning Mode: approved

## Route Plan

| Field | Decision |
|---|---|
| Task type | installer correctness fix |
| Task class | `engineering_os_governance` |
| Domain tags | Windows, Git Bash, CRLF, installer, policy gates, target-project safety |
| Plan Scope | standard |
| Plan Timestamp | 2026-09-03T08:35:00Z |
| Planning Mode | approved |
| Task-router evidence | `core/task-router.md` routes enforcement and installer changes through the governance workflow and exact validation gates. |
| Workflow evidence | `core/workflow.md`, `core/git-policy.md`, `core/hooks-policy.md`, and `core/quality-gates.md` require plan-first history, a focused regression, exact-head CI, review reconciliation, and explicit approval before merge. |
| Target paths | `scripts/install-policy-gates.sh`; `scripts/enforcement/tests/test-install-policy-gate-coverage.sh`; `.gitattributes` |
| Templates | waiver — focused repair to an existing installer and its existing test suite. |
| Architecture guides | `core/hooks-policy.md`; `docs/operations/project8-telemetry-preflight.md` |
| Patterns | none — the fix is input normalization at an existing manifest boundary. |
| External systems/connectors | GitHub |
| Skills | `engineering-route` |
| Validation gates | CRLF manifest regression; `git diff --check`; exact-head GitHub Actions; live review/thread reconciliation. |
| Evidence to check | reproduced CRLF bytes under `core.autocrlf=true`; target installer error; focused installer test; PR checks. |
| User decisions required | explicit approval received to create a branch and PR; merge requires a later explicit approval. |

## Source of Truth Checks

| Source | Status | What it settled |
|---|---|---|
| `scripts/install-policy-gates.sh` | read | Owns policy dependency manifest parsing and the fail-closed path that stopped Project 8 installation. |
| `scripts/enforcement/policy-gate-dependencies.tsv` | checked | Contains the reported dependency and reproduced 29 CRLF line endings in the Windows checkout. |
| `scripts/enforcement/tests/test-install-policy-gate-coverage.sh` | read | Is the canonical installer regression suite and the correct location for the CRLF fixture. |
| `core/git-policy.md` | read | Requires branch, ready PR, exact-head CI, review reconciliation, and explicit approval before merge. |
| `docs/operations/project8-telemetry-preflight.md` | read | Keeps technical qualification separate from the later behavioral experiment. |

## Capability Evidence

- `routing.task-router-read` — `core/task-router.md` was read through the repository's required governance route for an installer/enforcement change.
- `workflow.workflow-read` — `core/workflow.md` and `core/git-policy.md` were read before the first branch commit and set the plan → code → progress → PR order.
- `plan.route-plan-before-write` — commit `183184b1ec74918b6196ea34479991daa9618e17` added this Route Plan to the remote branch before commits touching installer code or tests.
- `source.github-repo-read` — GitHub `main` at `4f587e2640495c44e7757cbab9497640ab2cafc4` and PR #283 exact-head state were read before evidence correction.
- `validation.policy-change-has-validator` — `scripts/enforcement/tests/test-install-policy-gate-coverage.sh` now converts the real install manifest fixture to CRLF before invoking the real installer.
- `validation.coderabbit-policy` — PR #283 is ready for review; exact-head review, comments, and threads will be reconciled before requesting explicit merge approval.

## Connector Evidence

- GitHub is required to publish the branch, open the PR, inspect exact-head workflows, and reconcile review state.
- No external library or package documentation is involved.

## Connector Usage Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS` and merged PR #282.
- action: synchronized the local branch from merge commit `4f587e2640495c44e7757cbab9497640ab2cafc4` before creating the repair branch.
- result: PR #283 starts from `4f587e2640495c44e7757cbab9497640ab2cafc4`; exact head `f3ad53af92f224911b0901b5ac18ec0bd025c548` passed `telemetry-handoff-tests` and exposed five concrete Route Plan evidence defects.
- decision: GitHub evidence changed the work by limiting the next commit to correcting capability IDs, source statuses, connector impact, checklist state, and the post-code checkpoint while leaving the CRLF implementation unchanged.
- target: `scripts/install-policy-gates.sh`, its focused test, and `.gitattributes`.

## Documentation Asset Evidence

- internal: `scripts/install-policy-gates.sh`; `scripts/enforcement/policy-gate-dependencies.tsv`; `scripts/enforcement/tests/test-install-policy-gate-coverage.sh`; `core/git-policy.md`; `core/hooks-policy.md`; `docs/operations/project8-telemetry-preflight.md`.
- context7: not queried because no external API, library, or versioned dependency is changed.
- decision: implement the compatibility guarantee in executable code and repository attributes rather than prose-only documentation.

## Template Gap Waiver

No scaffold applies to a three-file installer compatibility repair. The existing installer and test suite are the canonical extension points.

## Skill Evidence

- `engineering-route` — applied the repository-native task route for an Engineering OS governance change: source inspection, plan-first branch history, focused validator extension, exact-head CI, review reconciliation, and explicit owner approval before merge.

## Progress Lifecycle Evidence

- start: Project 8 reached the latest `main`, but installation stopped after policy settings were refreshed and before user-level telemetry installation.
- mid: inspection proved the named dependency exists; the manifest had CRLF line endings produced by `core.autocrlf=true`, causing Bash to retain a hidden carriage return in the dependency path.
- mid: `install-policy-gates.sh` now strips a trailing carriage return from both manifest fields; `.gitattributes` keeps shell and TSV checkouts on LF; the existing installer suite rewrites its fixture to CRLF before exercising the positive path.
- mid: structural assertions and `git diff --check` pass. Direct Git Bash execution is unavailable in this Codex Windows sandbox because the process cannot create its signal pipe, so executable confirmation is delegated to exact-head GitHub Actions rather than claimed locally.
- pre-merge: PR #283 opened at exact head `f3ad53af92f224911b0901b5ac18ec0bd025c548`; its first exact-head attempt passed `telemetry-handoff-tests` and returned concrete evidence-format failures, which were read from job logs and corrected in this post-code checkpoint without changing implementation.

## Definition of Done

- complete: strip Windows carriage returns before validating manifest paths.
- complete: add a CRLF manifest regression to the existing installer suite.
- complete: add repository newline attributes for shell and TSV files.
- external gate: focused executable validation and the required workflow set must pass on the final exact head before merge.

## Live External Gates Before Merge

- complete: branch published and ready-for-review PR #283 opened.
- required before merge: every required workflow succeeds on the final exact PR head.
- required before merge: reviews and unresolved threads are reconciled on that exact head.
- required before merge: explicit owner approval is obtained for that exact head.

## Claude Run Trace

- goal: make target-project installation deterministic on Windows Git Bash checkouts.
- evidence: user-provided failure output, local file existence, Git newline configuration, raw CRLF counts, installer source, and focused test source.
- boundary: this PR fixes installation compatibility only; it does not claim Project 8 qualification or behavioral-experiment readiness.

