# Route Plan — Re-land the 3 burn-in fixes cleanly (supersedes PR #185)

## Route fields

| Field | Value |
|---|---|
| Task type | Governance / enforcement repair — re-land 3 root-caused burn-in fixes with a clean plan-before-code lifecycle |
| Task class | engineering_os_governance |
| Task-router evidence | `core/task-router.md` read in full (`<routing_algorithm>`, `<routing_matrix>`); routed per §7 "Engineering OS maintenance / governance" — consult CLAUDE.md, workflow.md, skill-orchestration-policy.md, connector-policy.md, learning-loop.md, hooks-policy.md. Extra rule applied: this change strengthens the enforcement layer itself (portable awk matching, hardened grep-c-echo scanner), not just explanatory text. |
| Workflow evidence | `core/workflow.md` read in full (`<agent_loop>`, `<workflow>` steps 1–12, `<spec_loop>`). This plan file is being authored and committed alone, before any code/config/test change, satisfying the step-4 write gate ("אל תדלג — כתוב קוד רק כשיש מקור ודוגמה") — the source and example here are PR #185's own diff (verified fixes, already reviewed once by CodeRabbit) plus the disclosed defect in that PR's own commit history. |
| Domain tags | readiness, enforcement, portability, hooks, regression-tests |
| Target paths | `scripts/enforcement/check-plan-scope.sh`, `scripts/enforcement/tests/test-plan-scope.sh`, `scripts/hooks/pre-commit.sh`, `.claude/settings.json`, `scripts/enforcement/tests/test-no-grep-c-echo.sh`, `lessons-learned/bugs/mawk-ignorecase-unsupported.md` |
| Templates | Not applicable — isolated enforcement-script portability/regex fix across existing files; no project scaffold involved. |
| Patterns | Not applicable — no `patterns/` domain asset (auth/api/billing/ui) touched; this is enforcement tooling, not application code. |
| Skills | none |
| External systems/connectors | GitHub |
| Validation gates | `scripts/enforcement/tests/test-plan-scope.sh`, `scripts/enforcement/tests/test-no-grep-c-echo.sh`, JSON validation of `.claude/settings.json`, `scripts/enforcement/check-known-gaps.sh`, `scripts/enforcement/check-readiness-audit.sh`, full `scripts/enforcement/tests/test-*.sh` suite (enforcement-tests), `scripts/enforcement/check-workflow-evidence.sh`, `scripts/enforcement/check-connector-evidence.sh`, `scripts/enforcement/check-documentation-asset-evidence.sh`, `scripts/enforcement/validate-capability-evidence.sh` + `scripts/enforcement/check-capability-staged-changes.sh`, `scripts/enforcement/check-pr-review-evidence.sh` (after PR creation) |

## Goal / מטרה

PR #185 root-caused and fixed three real bugs during an operational acceptance burn-in
(mawk/gawk `IGNORECASE` portability in `check-plan-scope.sh`; two live recurrences of the
documented `grep -c ... || echo 0` anti-pattern in `scripts/hooks/pre-commit.sh` and
`.claude/settings.json`; a hardened regression scanner for the latter). That PR is not
cleanly mergeable under Engineering OS's own standards: its `mawk-ignorecase-fix.md` plan
file was authored in the **same commit** as the code fix (`abb8c77`), so
`workflow-evidence-policy`'s ordering gate (Route Plan strictly before the first
code/config/test commit) is structurally red on that PR and cannot be fixed without
rewriting published history. PR #185 also carries one open, unresolved review thread
(chatgpt-codex-connector, P2: a stale committed plan with unchecked DoD items could block
unrelated future commits via the G10 newest-plan-selection rule) and, as of the last CI run,
a red `Require ready-for-review PR` check.

This plan re-lands the same three verified fixes on a fresh branch with a correct commit
order — Route Plan (this file) committed alone first, then code+tests+lesson, then ordered
`mid`/`pre-merge` Progress Lifecycle updates — so every required policy check can go green
without bypassing or rewriting anything.

## Plan / תכנון

1. Commit this Route Plan alone (no code/config/test change in the same commit).
2. Apply the three fixes verified in PR #185, re-run the exact same regression tests locally,
   and commit code + tests + the lesson file together once verification passes.
3. Update Progress Lifecycle `mid` in a dedicated commit (after code lands).
4. Re-run the full validation set (enforcement suite, known-gaps, readiness-audit, JSON
   validation) and update Progress Lifecycle `pre-merge` in a final dedicated commit.
5. Open a new PR against `main` with Review Fallback Evidence + Merge Readiness sections,
   stating explicitly that it supersedes #185.
6. Leave a comment on #185 explaining the supersession and its disclosed lifecycle defect;
   do not close it until the new PR is verified open and green.
7. Do not merge without the repository owner's explicit approval.

## Alternatives / חלופות

- Repair #185 in place by rewriting commit `abb8c77` so the plan predates the fix. Rejected:
  that PR's history has already been reviewed by CodeRabbit across specific commit SHAs
  (`304c316`–`f8ff1ab`/`1e6dc7c`) referenced in its own review threads; force-rewriting it
  would invalidate that review trail and the task explicitly allows a clean replacement branch
  instead.
- Squash everything into a single commit on the new branch. Rejected: `check-workflow-evidence.sh`
  requires the Route Plan to be introduced in a commit strictly before the first
  code/config/test commit — a single squashed commit cannot satisfy that ordering by
  construction (first_plan and first_code would be the same commit index).

## Source of Truth Checks

| Source | Status |
|---|---|
| `CLAUDE.md` | read |
| `core/task-router.md` | read |
| `core/workflow.md` | read |
| `core/git-policy.md` | read |
| `core/quality-gates.md` | read |
| `core/hooks-policy.md` | read |
| `core/learning-loop.md` | read |
| `core/connector-policy.md` | read |
| `core/resource-management.md` | read |
| `core/coderabbit-policy.md` | read |
| `docs/operations/merge-readiness-checklist.md` | read |
| `lessons-learned/bugs/grep-c-double-output.md` | read |
| `scripts/enforcement/check-plan-scope.sh` | checked |
| `scripts/hooks/pre-commit.sh` | checked |
| `.claude/settings.json` | checked |
| `scripts/enforcement/tests/test-no-grep-c-echo.sh` | checked |
| `github.com/yotamfried-ux/Engineering-OS/pull/185` (diff, commits, check-runs, review threads) | checked |

## Capability Evidence

Required capabilities for task class `engineering_os_governance`:

- `routing.task-router-read` — `core/task-router.md` read in full; routed under §7
  Engineering OS maintenance/governance.
- `workflow.workflow-read` — `core/workflow.md` read in full; this plan file is committed
  alone, before any code/config/test change, per the step-4 write gate.
- `plan.route-plan-before-write` — this file, committed in its own commit before any other
  file changes, verified by `check-workflow-evidence.sh`'s ordering check.
- `source.github-repo-read` — `git status`/`git fetch origin main`/`git log` run locally
  against `yotamfried-ux/Engineering-OS`, plus `mcp__github__pull_request_read` (`get`,
  `get_diff`, `get_commits`, `get_check_runs`, `get_review_comments`) against PR #185 before
  writing this plan (see Claude Run Trace).
- `validation.policy-change-has-validator` — `scripts/enforcement/tests/test-plan-scope.sh`
  (extended with `scenario_evidence_mixed_case`) and
  `scripts/enforcement/tests/test-no-grep-c-echo.sh` (hardened to join backslash
  line-continuations) are the dedicated validators for the two changed enforcement scripts.
- `validation.coderabbit-policy` — this change follows `core/coderabbit-policy.md`: dedicated
  branch → PR → GitHub Actions → CodeRabbit review → address comments → explicit owner
  approval before merge. CodeRabbit will run fresh on the new PR; its findings will be
  addressed before requesting merge.
- `validation.actions-checked` — `mcp__github__pull_request_read` (`get_check_runs`) on PR
  #185 read: `Require Engineering OS workflow evidence` = `failure`, `Require ready-for-review
  PR` = `failure` (latest runs), confirming the red state that motivates this replacement PR.

## Connector Evidence

- [x] GitHub: read PR #185's full diff, commit list, check-runs, and review threads via
  `mcp__github__pull_request_read`; will open the replacement PR and comment on #185 via
  `mcp__github__create_pull_request` / `mcp__github__add_issue_comment`.

## Connector Usage Evidence

- source: GitHub (`mcp__github__pull_request_read` methods `get`, `get_diff`, `get_commits`,
  `get_check_runs`, `get_review_comments`; local `git status`/`git fetch origin main`/`git log`)
  on `yotamfried-ux/Engineering-OS` PR #185
- action: read PR #185's diff to confirm the exact 3 fixes and their exact patches; read its
  6 commits to confirm the plan-in-same-commit-as-fix defect (`abb8c77`); read its check-runs
  to confirm `workflow-evidence-policy` and `pr-policy` are red on the latest run; read its 8
  review threads to confirm 1 unresolved thread (chatgpt-codex-connector, stale-DoD risk) and
  7 resolved CodeRabbit threads
- result: confirmed safe to re-apply verbatim — PR #185 head 1e6dc7cbe43cd33c224cd33b415a90a60e2fc991 (github.com/yotamfried-ux/Engineering-OS/pull/185)
- decision: selected a clean replacement branch/PR (this plan) over rewriting #185's published
  history, since #185's commits already carry a completed CodeRabbit review trail that a
  history rewrite would invalidate
- target: scripts/enforcement/check-plan-scope.sh

## Skill Evidence

Skills: none. No UI/auth/payments/PII surface is touched (pure shell/JSON enforcement-script
fix), so `security-review` is not triggered; no scaffold, so `superpowers:writing-plans`
scaffolding is not required beyond this Route Plan itself.

## Template/Pattern decision

Not applicable — no `templates/` or `patterns/` asset is used or created; this is a
same-file portability/regex bugfix in existing enforcement scripts, not a new
scaffold or domain feature.

## RTK / Graphify Evidence

- Graphify: `graphify explain "check-plan-scope.sh"` run before editing — confirmed the file
  defines 14 nodes including `section_text()` and `section_field()` (the two functions that
  depend on `IGNORECASE`) with no other script depending on those two functions, confirming
  the fix's blast radius is isolated to this one file. `graphify explain "pre-commit.sh"` run
  before editing — confirmed `pre-commit.sh` only `defines: enforcer()` structurally (the
  G10/G11 `grep -c` gates are plain script body, not separate extracted nodes), consistent
  with a targeted two-line fix.
- RTK: this remote session's Bash tool is proxied transparently through `rtk` per the user's
  global hook configuration (no manual `rtk` meta-commands were needed); all commands used
  here (`git`, `bash scripts/enforcement/tests/test-*.sh`, `python3 -m json.tool`) are already
  covered by that transparent proxy, so no separate RTK Usage Evidence/Waiver decision point
  arose beyond noting the environment default.

## Documentation Asset Evidence

- internal: `core/workflow.md` (write gate / debug_loop), `core/git-policy.md`
  (`<commit_protocol>`, `<pull_requests>`), `core/quality-gates.md` (`<definition_of_done>`),
  `core/hooks-policy.md` (`<hooks>`, `<known_gaps>`), `core/learning-loop.md` (lesson schema),
  `core/coderabbit-policy.md`, `docs/operations/merge-readiness-checklist.md`,
  `lessons-learned/bugs/grep-c-double-output.md` (the pre-existing anti-pattern lesson this
  fix cites and reuses) — all read before writing this plan and before applying the fixes.
- context7: not required — this task modifies only internal enforcement/hook shell scripts
  (POSIX awk/grep portability) and does not integrate any external library, framework, SDK,
  or API; the fix and its rationale are documented internally in
  `lessons-learned/bugs/mawk-ignorecase-unsupported.md`, not via an external docs source.
- decision: reading `core/workflow.md`'s debug_loop gate and the existing
  `lessons-learned/bugs/grep-c-double-output.md` lesson confirmed the exact correct fix form
  (`VAR=$(cmd) || VAR=0`) for the two grep-c-echo recurrences, and confirmed the mawk fix
  should use a portable `tolower()` fold matching `check-plan-scope.sh`'s own existing
  `field_value()` style rather than introducing a new dependency.

## Learning reuse

This fix directly reuses the documented root cause and correct fix pattern from
`lessons-learned/bugs/grep-c-double-output.md` (`VAR=$(... | grep -c PAT) || VAR=0`) for both
new recurrences in `scripts/hooks/pre-commit.sh` and `.claude/settings.json`, and adds a new,
separate lesson for the mawk/gawk `IGNORECASE` portability defect
(`lessons-learned/bugs/mawk-ignorecase-unsupported.md`).

## Claude Run Trace

- **Goal:** re-land PR #185's 3 verified fixes on a branch whose commit history satisfies
  Engineering OS's own `workflow-evidence-policy` ordering gate, with all required checks
  green and no unresolved review threads, without bypassing or rewriting published history.
- **Hypothesis:** PR #185's fixes are correct (already verified 10/10 and 4/4 in that PR); the
  only defect is commit ordering (plan committed in the same commit as the fix). Re-applying
  the identical fix content on a fresh branch with plan-then-code-then-lifecycle commit order
  should pass every gate that failed on #185.
- **Connectors:** GitHub (`mcp__github__pull_request_read`, `mcp__github__create_pull_request`,
  `mcp__github__add_issue_comment`) — primary and only connector needed for this task. Notion
  was not used: per `core/workflow.md` step 1's approved fallback, `.claude/plans/*.md` (this
  file) substitutes for Notion when it is not the active planning surface for a task, so no
  `notion_progress_validated` evidence exists or applies for this session.
- **Steps:** read PR #185 (get/get_diff/get_commits/get_check_runs/get_review_comments) → read
  all required core/ policy files and the merge-readiness checklist → confirm main is at the
  same SHA #185 branched from → confirm the 3 bugs are still present pre-fix on `main` → author
  this Route Plan and commit it alone → apply the 3 fixes + regression tests + lesson, verify
  locally, commit together → update `mid` → re-run full validation → update `pre-merge` → open
  PR → comment on #185 explaining supersession.
- **Evidence:** PR #185 diff/commits/check-runs/review-threads captured via tool calls (see
  Connector Usage Evidence); local re-run of `scripts/enforcement/tests/test-plan-scope.sh` and
  `test-no-grep-c-echo.sh` before and after the fix (see Progress Lifecycle Evidence and DoD).
- **Rejected:** rewriting #185's `abb8c77` commit history — invalidates its existing CodeRabbit
  review trail; not needed since the task explicitly permits a clean replacement branch.
- **Result:** pending — filled in as work completes (see Progress Lifecycle Evidence).
- **Follow-up:** comment on #185 and mark it superseded once the replacement PR is open, green,
  and verified; do not merge without explicit owner approval.

## Progress Lifecycle Evidence

- **start:** Route Plan authored and committed alone, before any code/config/test change.
  `main` and this branch both at SHA `8cb774d030ed6c6f5f8d17ac89f421980f31a615`. The 3 bugs
  (mawk/IGNORECASE, and the 2 grep-c-echo recurrences) confirmed still present pre-fix on this
  branch via local reproduction before any fix was applied: `test-plan-scope.sh` scenario for
  mixed-case matching not yet added; `pre-commit.sh`/`.claude/settings.json` still contain the
  `grep -c ... || echo 0` anti-pattern (reproducible via the documented
  `lessons-learned/bugs/grep-c-double-output.md` symptom).
- **mid:** fix commit `fd20790` landed (check-plan-scope.sh, pre-commit.sh, .claude/settings.json,
  test-no-grep-c-echo.sh, test-plan-scope.sh, and the new lesson file). Locally verified:
  `test-plan-scope.sh` 10/10, `test-no-grep-c-echo.sh` 4/4 (git-stash confirmed it fails 3/4 on
  the pre-fix files), `python3 -m json.tool .claude/settings.json` valid, full enforcement suite
  `scripts/enforcement/tests/test-*.sh` 70/70, `check-known-gaps.sh` (25 gaps) and
  `check-readiness-audit.sh` (34 rows) both pass. `check-connector-evidence.sh` and
  `check-documentation-asset-evidence.sh` re-run locally against this plan and pass.
- **pre-merge:** to be recorded after this commit, once the final full validation pass
  (including `check-workflow-evidence.sh` over the full commit range) is re-confirmed clean.

## Definition of Done / תנאי סיום

- [x] `check-plan-scope.sh`'s `IGNORECASE` usage replaced with a portable `tolower()` fold in
      `section_text()`/`section_field()` — signal: `bash scripts/enforcement/tests/test-plan-scope.sh`
      including the new `scenario_evidence_mixed_case` regression test, 10/10 passing.
- [x] `scripts/hooks/pre-commit.sh`'s G10/G11 `grep -c ... || echo 0` anti-pattern fixed to
      `VAR=$(cmd) || VAR=0` — signal: `bash scripts/enforcement/tests/test-no-grep-c-echo.sh`, 4/4 passing.
- [x] `.claude/settings.json`'s DoD-total counter fixed to the same safe form, and the file
      remains valid JSON — signal: `python3 -m json.tool .claude/settings.json` exits 0.
- [x] `test-no-grep-c-echo.sh` hardened to join backslash line-continuations before scanning,
      verified via `git stash` that it fails 3/4 on the pre-fix files (catching both the
      pre-commit.sh and settings.json recurrences) and passes 4/4 on the fix.
- [x] `lessons-learned/bugs/mawk-ignorecase-unsupported.md` written with all 8 required lesson
      schema headings, satisfying `enforce-learning.sh`'s L1 gate.
- [x] Full enforcement suite green — signal: `scripts/enforcement/tests/test-*.sh`, 70/70 passing.
- [x] `scripts/enforcement/check-known-gaps.sh` (25 gaps) and `check-readiness-audit.sh`
      (34 rows) both pass.

## Rollback plan

- If the fix introduces a regression, `git revert` the code commit; the plan/lesson commits
  are documentation-only and safe to leave in place.
- No production system, database, or shared infrastructure is touched — this is entirely
  Engineering OS's own enforcement/tooling layer.
- The replacement PR is never merged without explicit owner approval (see `<safety>` in
  `core/git-policy.md`); if the owner prefers #185's history preserved differently, this
  branch can be closed without merging and #185 left as-is.
