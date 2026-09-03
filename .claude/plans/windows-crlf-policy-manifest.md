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
| Skills | repository-native governance workflow; no external implementation skill required. |
| Validation gates | CRLF manifest regression; `git diff --check`; exact-head GitHub Actions; live review/thread reconciliation. |
| Evidence to check | reproduced CRLF bytes under `core.autocrlf=true`; target installer error; focused installer test; PR checks. |
| User decisions required | explicit approval received to create a branch and PR; merge requires a later explicit approval. |

## Source of Truth Checks

- `scripts/install-policy-gates.sh` owns policy dependency manifest parsing.
- `scripts/enforcement/policy-gate-dependencies.tsv` is the copied dependency inventory.
- `scripts/enforcement/tests/test-install-policy-gate-coverage.sh` is the existing installer regression suite.
- `.gitattributes` is the repository-level checkout newline contract.

## Capability Evidence

- The failure was reproduced from the user's Project 8 installation output.
- The local `~/.engineering-os` checkout contains the reported file, while the manifest contains 29 CRLF line endings and Git reports `core.autocrlf=true`.
- The implementation strips a trailing carriage return from both manifest fields and independently enforces LF checkout for shell and TSV files.
- The existing install-policy coverage suite is extended rather than creating a disconnected test.

## Connector Evidence

- GitHub is required to publish the branch, open the PR, inspect exact-head workflows, and reconcile review state.
- No external library or package documentation is involved.

## Connector Usage Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS` and merged PR #282.
- action: synchronized the local branch from merge commit `4f587e2640495c44e7757cbab9497640ab2cafc4` before creating the repair branch.
- result: the repair branch starts from the exact current `main` tree.
- decision: keep the change isolated in a new PR and require exact-head CI before requesting merge approval.
- target: `scripts/install-policy-gates.sh`, its focused test, and `.gitattributes`.

## Documentation Asset Evidence

- internal: installer source, dependency manifest, focused installer test, Git policy, hook policy, and Project 8 telemetry preflight.
- context7: not queried because no external API, library, or versioned dependency is changed.
- decision: implement the compatibility guarantee in executable code and repository attributes rather than prose-only documentation.

## Template Gap Waiver

No scaffold applies to a three-file installer compatibility repair. The existing installer and test suite are the canonical extension points.

## Progress Lifecycle Evidence

- start: Project 8 reached the latest `main`, but installation stopped after policy settings were refreshed and before user-level telemetry installation.
- mid: inspection proved the named dependency exists; the manifest had CRLF line endings produced by `core.autocrlf=true`, causing Bash to retain a hidden carriage return in the dependency path.
- mid: `install-policy-gates.sh` now strips a trailing carriage return from both manifest fields; `.gitattributes` keeps shell and TSV checkouts on LF; the existing installer suite rewrites its fixture to CRLF before exercising the positive path.
- mid: structural assertions and `git diff --check` pass. Direct Git Bash execution is unavailable in this Codex Windows sandbox because the process cannot create its signal pipe, so executable confirmation is delegated to exact-head GitHub Actions rather than claimed locally.
- pre-merge: pending focused CI, exact-head workflow completion, review reconciliation, and explicit owner merge approval.

## Definition of Done

- [x] Strip Windows carriage returns before validating manifest paths.
- [x] Add a CRLF manifest regression to the existing installer suite.
- [x] Add repository newline attributes for shell and TSV files.
- [ ] Pass focused installer validation on an environment where Bash execution is permitted.
- [ ] Pass exact-head required GitHub Actions.

## Live External Gates Before Merge

- [ ] Push the branch and open a ready-for-review PR.
- [ ] Confirm every required workflow succeeds on the exact PR head.
- [ ] Reconcile reviews and unresolved threads on the exact head.
- [ ] Obtain explicit owner approval for that exact head before merge.

## Claude Run Trace

- goal: make target-project installation deterministic on Windows Git Bash checkouts.
- evidence: user-provided failure output, local file existence, Git newline configuration, raw CRLF counts, installer source, and focused test source.
- boundary: this PR fixes installation compatibility only; it does not claim Project 8 qualification or behavioral-experiment readiness.
