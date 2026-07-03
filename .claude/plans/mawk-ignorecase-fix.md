# Route Plan — Fix mawk/gawk IGNORECASE portability bug in check-plan-scope.sh

## Route fields

| Field | Value |
|---|---|
| Task type | Bug fix — enforcement script portability |
| Task class | engineering_os_governance |
| Task-router evidence | core/task-router.md read; routed per §7 Engineering OS maintenance/governance |
| Workflow evidence | core/workflow.md read; debug_loop gate followed (root cause before fix, regression test added) |
| Domain tags | enforcement, testing, governance |
| Target paths | scripts/enforcement/check-plan-scope.sh, scripts/enforcement/tests/test-plan-scope.sh, lessons-learned/bugs/mawk-ignorecase-unsupported.md |
| Templates | Not applicable |
| Patterns | Not applicable |
| Skills | none |
| External systems/connectors | GitHub |
| Validation gates | `scripts/enforcement/tests/test-plan-scope.sh` |

## Goal / מטרה

Fix `check-plan-scope.sh`'s dependency on gawk-only `IGNORECASE`, which mawk (Debian/Ubuntu's
default `/usr/bin/awk`) silently ignores, causing valid Graphify evidence to be falsely blocked
in any environment without gawk installed. Discovered during the Engineering OS operational
acceptance burn-in experiment (`.claude/plans/eos-acceptance-burnin.md`).

## Plan / תכנון

1. Reproduce the failure in isolation, confirm root cause (mawk vs gawk `IGNORECASE`).
2. Confirm CI passes on `ubuntu-latest` for the same commit (rules out a logic regression).
3. Rewrite `section_text`/`section_field` to use a portable `tolower()` fold instead of
   `IGNORECASE`, matching the existing `field_value()` style in the same file.
4. Add a regression scenario with a mixed-case heading/fields; verify it fails on the old code
   and passes on the fix via `git stash`.
5. Document the root cause in `lessons-learned/bugs/`.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-plan-scope.sh | read |
| scripts/enforcement/tests/test-plan-scope.sh | read |
| GitHub Actions run 28628591263 (enforcement-tests, main, HEAD 8cb774d) | checked via mcp__github__actions_list — conclusion=success |

## Connector Evidence

- [x] GitHub: checked enforcement-tests run 28628591263 on main HEAD 8cb774d030ed6c6f5f8d17ac89f421980f31a615 to rule out a logic regression before diagnosing the mawk root cause.

## Connector Usage Evidence

- source: GitHub Actions run 28628591263 via mcp__github__actions_list on yotamfried-ux/Engineering-OS
- action: checked the enforcement-tests workflow conclusion for the main branch HEAD commit
- result: conclusion=success on ubuntu-latest for commit 8cb774d030ed6c6f5f8d17ac89f421980f31a615, confirming CI is green upstream and the failure is environment-specific (mawk vs gawk), not a logic regression
- decision: selected the portable tolower() fix over changing enforcer exit-code semantics, since GitHub's own CI already proves the logic correct on a gawk-equipped runner
- target: scripts/enforcement/check-plan-scope.sh

## Capability Evidence

- `routing.task-router-read` — core/task-router.md §7 (Engineering OS maintenance/governance).
- `workflow.workflow-read` — core/workflow.md debug_loop gate followed: root cause identified
  before fix, regression test added, fix verified.
- `plan.route-plan-before-write` — this file, written before the fix commit.
- `source.github-repo-read` — GitHub Actions run history checked for the exact head SHA.
- `validation.policy-change-has-validator` — `test-plan-scope.sh` extended with
  `scenario_evidence_mixed_case`.
- `validation.coderabbit-policy` — this fix ships on the burn-in experiment's dedicated branch
  (`claude/eos-acceptance-burnin-o1birt`); CodeRabbit/CI review applies before merge to main.

## Claude Run Trace

- **Goal:** unblock the burn-in experiment's Part A enforcement-suite run by root-causing and
  fixing the one genuine failure.
- **Hypothesis:** environment-specific awk implementation difference, not a logic regression.
- **Connectors:** GitHub (`mcp__github__actions_list`) to check CI history for the same SHA.
- **Steps:** reproduce → isolate with a manual awk one-liner → confirm mawk lacks IGNORECASE →
  confirm CI green on ubuntu-latest for same SHA → grep for other IGNORECASE usages (none found
  outside this file) → rewrite with tolower() → add regression scenario → verify fail-then-pass
  via git stash → document lesson.
- **Evidence:** `awk 'BEGIN{IGNORECASE=1; if ("ABC"~/abc/) print "works"; else print "not
  supported"}'` printed "not supported"; `dpkg -l | grep awk` shows only mawk installed;
  `test-plan-scope.sh` went 8/9 → 10/10; git-stash before/after confirmed the new scenario
  fails on old code.
- **Rejected:** installing gawk as a workaround instead of fixing the script — rejected because
  the goal is a portable gate that works in any downstream project's environment, not one that
  requires a specific awk implementation to be present.
- **Result:** fixed; no other enforcement script depends on IGNORECASE.
- **Follow-up:** none — isolated, fully covered by regression test.

## Progress Lifecycle Evidence

- **start:** plan authored before staging the fix.
- **mid:** fix applied, test extended, 10/10 passing locally.
- **pre-merge:** N/A — folded into the burn-in experiment branch; merge gated on that
  experiment's own PR review, not a standalone merge.

## Definition of Done / תנאי סיום

- [x] Root cause identified with direct reproduction (mawk lacks gawk's IGNORECASE).
- [x] CI-vs-local discrepancy explained (ubuntu-latest ships gawk; this container does not).
- [x] Fix applied using a portable tolower() fold, consistent with existing code style.
- [x] Regression test added and confirmed to fail on pre-fix code, pass on the fix.
- [x] `lessons-learned/bugs/mawk-ignorecase-unsupported.md` written.
- [x] No other enforcement script affected (grep confirmed IGNORECASE isolated to this file).
