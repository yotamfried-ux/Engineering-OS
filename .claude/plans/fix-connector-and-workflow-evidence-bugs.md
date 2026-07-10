# Fix two enforcement bugs found during project-8 discovery

| Field | Value |
|---|---|
| Task type | Bug fix / debugging — two Engineering OS enforcement script defects |
| Task class | engineering_os_governance |
| Domain tags | governance, testing, connectors, workflow-evidence |
| Plan Scope | standard |
| Planning Mode | staged — this plan is committed alone, before any code/config change; the fix + regression tests land in a dedicated follow-up commit |
| Templates | not applicable — no templates/ asset covers enforcement-script bug fixes |
| Architecture guides | not applicable — no docs/architecture-guides/ entry covers enforcement-script internals |
| Patterns | not applicable — no patterns/ asset covers enforcement-script regression fixes |
| External systems/connectors | GitHub |
| Skills | not required |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, documentation-asset-policy, plan-policy |
| Evidence to check | scripts/enforcement/check-connector-evidence.sh, scripts/enforcement/check-workflow-evidence.sh, their existing and new regression test files, minimal standalone reproduction scripts run this session (not committed) |
| User decisions required | none — scope was fully specified by the user; merge itself still requires the user's explicit approval per coderabbit-policy.md |
| Task-router evidence | core/task-router.md's bug/debugging routing entry consulted (`<routing_matrix>` § 2); Sentry step waived — not applicable, since these are static logic bugs in local shell/regex enforcement scripts discovered via direct code reading and minimal repro scripts, not deployed runtime errors any Sentry project monitors |
| Workflow evidence | core/workflow.md steps 1-9 and core/debugging-policy.md's `<debug_loop>` followed: read both checker scripts and their existing tests fully before touching anything, reproduced each bug with a minimal standalone fixture first (debug_loop step 7), only then wrote the fix, then added the fixture as a permanent regression test |
| Target paths | scripts/enforcement/check-connector-evidence.sh, scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-connector-evidence.sh, scripts/enforcement/tests/test-workflow-evidence.sh |

## Context

During `yotamfried-ux/project-8` discovery work (PR #3), two real bugs were found in Engineering OS's own freshly-installed enforcement scripts:

1. `check-connector-evidence.sh`'s `field()` fallback regex returned the field-name alternation match (`m.group(1)`) instead of the actual captured value, so a plan using prose `External systems/connectors: GitHub, Supabase, Vercel` (rather than a markdown table row) had its declared connectors misread as the literal string `"systems/connectors"`. This forced a workaround in project-8's plan document just to get the buggy extractor to resolve against real evidence.
2. `check-workflow-evidence.sh`'s "Route Plan must be committed before the first code/config/test change" ordering check walks every commit in `base..head`, including commits inherited from another branch/PR (e.g. via a legitimate fast-forward merge) that predate the branch's own Route Plan commit. If any inherited commit touches a file outside `docs/`/`README.md`/`CHANGELOG.md`/`LICENSE` (e.g. root `CLAUDE.md`), it's misclassified as "this PR's own code committed before its own plan," even when the branch's actual authored work is correctly plan-first.

Both were worked around locally in project-8 (a same-content squash commit instead of a real fast-forward, and workaround wording in the connector evidence text) rather than fixed at the source. This PR fixes both at the source, with regression tests proving the old behavior failed and the new behavior passes, and without weakening either gate's enforcement of its actual invariant.

## Affected Surfaces

- `scripts/enforcement/check-connector-evidence.sh` and `check-workflow-evidence.sh` (the two enforcement checkers themselves).
- `scripts/enforcement/tests/test-connector-evidence.sh` and `test-workflow-evidence.sh` (their regression suites).
- Every downstream project (including `project-8`) that installs these gates via `scripts/install-policy-gates.sh` — they will pick up the fix on their next sync, not automatically.

## Data/State Impact

None. Both scripts are stateless text/git analyzers; no persisted data, database, or application state is touched.

## Integration Impact

- `.github/workflows/connector-evidence-policy.yml` and `workflow-evidence-policy.yml` invoke these scripts in CI on every PR to any project that installs the policy gates — this PR changes their behavior for future PRs, not retroactively for already-merged history.
- `scripts/install-policy-gates.sh` copies these scripts verbatim into target projects; no change needed there, since it already copies whatever is on `main` at sync time.

## Validation Plan

- Reproduce each bug with a minimal standalone fixture before writing any fix (done, see Claude Run Trace).
- Add a failing regression fixture to the existing test file for each bug; confirm it fails on unmodified code.
- Apply the minimal fix; confirm the new fixture passes and all pre-existing fixtures in both files still pass.
- Run the full local `scripts/enforcement/tests/*.sh` sweep.
- Open the PR and confirm GitHub Actions CI is green.
- Address CodeRabbit review comments or justify why not applicable.

## Open Questions

None currently open. If CodeRabbit or CI surfaces something requiring a design decision, it will be raised to the user before proceeding, per this repo's precedence rules.

## Capability Evidence

- `routing.task-router-read`: read `core/task-router.md` in full this session (`<routing_algorithm>` and `<routing_matrix>` § 2, bug/debugging).
- `workflow.workflow-read`: read `core/workflow.md` (`<workflow>`, steps 1-10) and `core/debugging-policy.md` (`<debug_loop>`) in full this session.
- `plan.route-plan-before-write`: this plan file is committed alone, before the fix/test commit — see Progress Lifecycle Evidence below.
- `source.github-repo-read`: read all 3 open PRs on `yotamfried-ux/Engineering-OS` (#199, #200, #201) via `mcp__github__list_pull_requests` to confirm no overlap with this work before branching.
- `validation.policy-change-has-validator`: this PR's actual change is two new regression-test fixtures per bug (in the existing `scripts/enforcement/tests/test-connector-evidence.sh` and `test-workflow-evidence.sh` files) plus the minimal fixes they require — the validator is the change.
- `validation.coderabbit-policy`: `core/coderabbit-policy.md` read in full this session; this PR follows its flow (dedicated branch → PR → CI → CodeRabbit review → address comments → explicit user approval before merge) and is not merged without that approval.

## Connector Evidence

- GitHub: used to check for existing open PRs/branches before starting (avoid duplicate/conflicting work), and to open this PR, observe its CI, and read/resolve review feedback.

## Connector Usage Evidence

- source: GitHub — `yotamfried-ux/Engineering-OS` open PR list, `scripts/enforcement/check-connector-evidence.sh`, `scripts/enforcement/check-workflow-evidence.sh`, and their existing test files
- action: listed open PRs to check for overlap; read both checker scripts and their existing tests in full; ran the existing test suites against the unmodified scripts to establish a clean baseline
- action: reproduced both bugs with minimal standalone fixtures outside the test suite first, confirming each bug's exact failure mode before writing any fix
- result: confirmed no open PR touches these files (PRs #199/#200/#201 checked via GitHub); confirmed bug 1's exact symptom (`ERROR_FOR_AGENT: ... must mention declared connector systems/connectors`) and bug 2's exact symptom (`ERROR_FOR_AGENT: Route Plan must be committed before the first code/config/test change`) on unmodified `scripts/enforcement/check-connector-evidence.sh` and `scripts/enforcement/check-workflow-evidence.sh`
- decision: fixed `check-connector-evidence.sh`'s `field()` to capture the value via a named group immune to the field-name pattern's own capturing groups; added an opt-in, git-verified "Inherited base commit" / "Inherited base reason" marker to `check-workflow-evidence.sh` so a branch can honestly declare a pre-existing inherited boundary without weakening the ordering rule for its own new commits
- target: scripts/enforcement/check-connector-evidence.sh, scripts/enforcement/check-workflow-evidence.sh

## Documentation Asset Evidence

- internal: scripts/enforcement/check-connector-evidence.sh, scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-connector-evidence.sh, scripts/enforcement/tests/test-workflow-evidence.sh, core/task-router.md, core/workflow.md, core/debugging-policy.md, core/coderabbit-policy.md, core/capability-registry.yaml, core/quality-gates.md
- context7: not required this session because no new library, framework, SDK, or external API was adopted or upgraded — both fixes are self-contained Python-in-bash regex/logic changes to existing internal scripts, with no external dependency surface to check docs for
- decision: reading the existing test files' exact helper conventions (`mk`/`put`/`ci`/`ok`/`no` in test-connector-evidence.sh, `write_good_plan`/`expect_pass`/`expect_fail` in test-workflow-evidence.sh) directly shaped how the new regression fixtures were written, so they extend the existing suites in-place rather than introducing a parallel test convention

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | read |
| core/workflow.md | read |
| core/debugging-policy.md | read |
| scripts/enforcement/check-connector-evidence.sh | checked |
| scripts/enforcement/check-workflow-evidence.sh | checked |
| scripts/enforcement/tests/test-connector-evidence.sh | checked |
| scripts/enforcement/tests/test-workflow-evidence.sh | checked |

## DoD

- [x] Bug 1 reproduced with a new regression fixture that fails on unmodified `check-connector-evidence.sh` (`bash scripts/enforcement/tests/test-connector-evidence.sh`).
- [x] Bug 1 fixed in `check-connector-evidence.sh`'s `field()` function; the same fixture now passes.
- [x] Bug 1's existing 15 fixtures in `test-connector-evidence.sh` still all pass — enforcement not weakened.
- [x] Bug 2 reproduced with a minimal standalone fixture and a new regression fixture in `test-workflow-evidence.sh` that fails on unmodified `check-workflow-evidence.sh`.
- [x] Bug 2 fixed via an opt-in, git-verified "Inherited base commit" marker; the passing fixture now passes, and 5 new fail-case fixtures (no marker, invalid SHA, marker at/after the plan commit, own code still before own plan despite a valid marker, marker without a concrete reason) all still correctly fail.
- [x] Bug 2's existing 7 fixtures in `test-workflow-evidence.sh` (code-without-plan, plan-and-code-same-commit, plan-before-code, missing-router-evidence, missing-source-checks, missing-skill-evidence, template-gap-no-waiver/with-waiver) still all pass — enforcement not weakened.
- [x] Full local enforcement test sweep (all `scripts/enforcement/tests/*.sh`, 83 files) run and green.

Follow-up (tracked outside this checklist until observed with real evidence, not pre-checked): confirm GitHub Actions CI is green on the opened PR, and address CodeRabbit review comments or justify why not applicable, before requesting merge approval.

## Progress Lifecycle Evidence

- start: this plan committed alone, before any code/config/test change, with both bugs already reproduced via minimal standalone fixtures (not committed) proving the exact failure mode of each.

## Claude Run Trace

- goal: fix the two Engineering OS enforcement bugs discovered during project-8 discovery, with regression tests proving old-behavior-fails / new-behavior-passes, without weakening either gate.
- hypothesis (bug 1): `field()`'s fallback regex returns the wrong capture group because `name_re` itself contains a capturing group; fixing it to use a named group should extract the real value regardless of `name_re`'s internal structure.
- hypothesis (bug 2): the ordering check has no way to distinguish "commits inherited from another branch" from "this branch's own commits"; an explicit, git-verified marker naming the inherited boundary — validated as a real ancestor that itself precedes the branch's own plan commit — should let legitimate inheritance through without opening a path for a branch to mislabel its own code.
- steps: read both checkers and their tests fully; listed open PRs to avoid overlap; reproduced each bug with a minimal standalone script; wrote failing regression fixtures in the existing test files; applied the minimal fix for each; re-ran the fixtures to confirm the fail-before/pass-after transition; ran the full local enforcement test sweep; will open the PR, observe CI, and address any CodeRabbit feedback before requesting merge approval.
- evidence: see DoD above; exact commands and outputs are in the PR body and this session's tool history.
- result: pending CI on the opened PR.
