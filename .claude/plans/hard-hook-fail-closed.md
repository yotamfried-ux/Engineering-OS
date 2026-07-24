# Route Plan — Hard Hook Fail-Closed

## Route Plan

| Field | Decision |
|---|---|
| Task type | security-sensitive governance bug fix and deterministic hook infrastructure hardening |
| Task class | `engineering_os_governance` |
| Domain tags | hooks, governance, security, shell, JSON, installer, testing, operational readiness |
| Plan Scope | standard |
| Planning Mode | implementation authorized; merge and canonical closure remain external owner gates |
| Target paths | `.claude/settings.json`; `scripts/enforcement/hook-criticality.tsv`; `scripts/enforcement/lib/hook-gate.sh`; `scripts/enforcement/lib/soft-hook-gate.sh`; `scripts/enforcement/check-hard-hook-contract.py`; `scripts/enforcement/patch-settings-runtime-evidence.sh`; `scripts/enforcement/post-tool-use-notion-progress.sh`; `scripts/monitoring/require-telemetry-session.sh`; `scripts/enforcement/tests/test-hard-hook-fail-closed.sh`; `scripts/enforcement/tests/test-hard-hook-symlinks.sh`; `scripts/enforcement/tests/test-hook-classification.sh`; `scripts/enforcement/tests/test-hook-gate.sh`; `scripts/enforcement/tests/test-operational-learning-skills.sh`; `scripts/enforcement/tests/test-project8-telemetry-readiness.sh`; `scripts/enforcement/tests/test-required-connectors.sh`; `.claude/plans/hard-hook-fail-closed.md` |
| Task-router evidence | `core/task-router.md` routes hook, settings, enforcement, test, and governance changes through `engineering_os_governance`; protected-action failure behavior also requires security-sensitive review. |
| Workflow evidence | `core/workflow.md`, `core/git-policy.md`, `core/quality-gates.md`, and `core/hooks-policy.md` require plan-first work, Experiment → Failure analysis → Fix → Experiment, dedicated PR isolation, exact-head CI, review reconciliation, and separate merge approval. |
| Templates | Existing canonical hook wrapper, registry, settings, and installer patterns are sufficient; no new template is introduced. |
| Architecture guides | `core/hooks-policy.md`; `docs/operations/operational-readiness-audit.md`; `docs/operations/known-gaps.tsv` |
| Patterns | Extend the existing wrapper/enforcer/registry architecture; do not create a parallel policy registry. |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion`; `security-review` |
| Validation gates | focused wrapper tests; canonical classification/contract tests; nested validator tests; settings/manifest tests; official clean-target installer tests; full enforcement suite; shell/Python checks; exact-head CI; live review reconciliation |
| Evidence to check | canonical `main`; PR #261 live state; audit and known-gap rows; checked-in settings; criticality registry; wrappers; installer/patcher; official Claude Code hook semantics; exact PR workflow and review state |
| User decisions required | explicit approval for this exact PR before merge; separate post-merge closure reconciliation before any `closed` status or live-state claim |

## Goal

Make every hard/protected Claude Code hook fail closed whenever its wrapper, interpreter, enforcer, registry, settings wiring, dependency, nested validator, input, subprocess result, or deny conversion cannot produce a trustworthy decision. Preserve fail-open behavior only for units explicitly classified as advisory or recorder, and prove the same contract in source and a clean installed target.

## Scope

This task owns hard-hook failure semantics and the minimum settings validation required to reject a hard registry row without a real command. Broad repository-boundary parity remains in `gap:eos-repo-boundary-sync-drift`; approval provenance remains in `gap:bypass-approval-provenance`.

## Non-goals

- No merge to `main`.
- No canonical gap closure or live-state claim.
- No modification or merge of PR #261.
- No adjacent-gap implementation.
- No Project 8 preparation or readiness claim.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `core/task-router.md` | read | Routes the task through `engineering_os_governance` and security-sensitive controls. |
| `core/workflow.md` | read | Requires plan-first result loops, evidence checkpoints, exact-head CI, and review reconciliation. |
| `docs/operations/known-gaps.tsv` | checked | `hard-hook-fail-closed` is open, P0, owner `hooks-governance`; merge and post-merge proof remain closure requirements. |
| `docs/operations/operational-readiness-audit.md` | checked | Requires infrastructure uncertainty, malformed input, nested validation, settings wiring, converter/interpreter failures, source/installed proof, CI, and review evidence. |
| `.claude/settings.json` | validated | Hard commands use the shared hard gate; advisory/recorder commands reject malformed responses before recording evidence; Read recorder count fallback and warning control flow remain single-valued and statically valid. |
| `scripts/enforcement/hook-criticality.tsv` | validated | Owns class, semantics, wiring, parent, surface, dependencies, and deny mode. |
| `scripts/enforcement/lib/hook-gate.sh` | validated | Converts untrusted hard-hook outcomes into blocking behavior and validates only the requested direct row before its required chain. |
| `scripts/enforcement/post-tool-use-notion-progress.sh` | validated | Records installed Notion progress only after a valid Notion event and object response. |
| `scripts/monitoring/require-telemetry-session.sh` | validated | Accepts direct and soft-wrapped `pre_tool_use` recorders only with a complete shell token boundary, including a valid command terminator but excluding prefix collisions. |
| `scripts/enforcement/tests/test-operational-learning-skills.sh` | validated | Installed-hook fixtures send complete Claude Code `PreToolUse` identity and interpret structured deny JSON as a block even when the wrapper exits `0`. |
| `scripts/enforcement/tests/test-required-connectors.sh` | validated | Installed Notion recorder failures are proven observable through stderr while remaining fail-open and recording no evidence. |
| `https://code.claude.com/docs/en/hooks` | read | Exit `2` is the blocking fallback; `PreToolUse` and `Stop` use different structured denial schemas. |

## Canonical Ownership Decision

Extend `scripts/enforcement/hook-criticality.tsv` as the single owner of event, matcher, unit, class, failure semantics, direct/nested wiring, parent, source/installed surface, dependencies, and deny mode. Validate the registry against settings and required files instead of adding a parallel manifest.

## Implementation Plan

1. Reproduce fail-open behavior with negative fixtures.
2. Extend the existing criticality registry.
3. Add a static source/installed contract validator.
4. Harden the runtime gate for input, canonical identity, dependencies, nested validators, subprocess status/output, event-specific conversion, and exit-2 fallback.
5. Route direct hard settings through a missing-wrapper bootstrap; keep advisory/recorder behavior explicit and observable.
6. Preserve the official installer and validate the rendered target.
7. Run focused, full, exact-head, and review result loops.

## Negative Test Plan

1. valid hard-hook success passes;
2. explicit policy denial blocks with a reason;
3. malformed input blocks;
4. invalid JSON blocks;
5. missing enforcer blocks;
6. missing wrapper blocks;
7. missing interpreter blocks;
8. missing required nested validator blocks;
9. nested validator failure blocks;
10. required registry row missing blocks;
11. malformed registry blocks;
12. settings command missing blocks;
13. wrong settings target blocks;
14. dependency unavailable blocks;
15. deny converter failure blocks;
16. unexpected exit code blocks;
17. signal termination blocks;
18. soft-wrapped hard command is rejected;
19. advisory failure remains fail-open only under explicit classification;
20. recorder failure is observable and does not create false policy evidence;
21. source repository behavior passes;
22. official clean installed-target behavior passes;
23. symlinked hard unit blocks in static and runtime validation;
24. symlinked required dependency blocks in static and runtime validation;
25. symlinked directory component blocks in static and runtime validation;
26. malformed source Notion response records no evidence;
27. malformed installed Notion response records no evidence;
28. valid installed Notion response records `notion_progress_validated`;
29. a missing sibling hard unit does not block the healthy requested unit;
30. `-- pre_tool_use_extra` does not satisfy telemetry recorder completeness;
31. a valid `-- pre_tool_use;` shell token satisfies installed recorder completeness;
32. Read recorder zero-count fallback produces one integer and no `grep -c ... || echo` static match;
33. installed learning/skill hook fixtures use valid `PreToolUse` JSON and preserve allow/deny assertions;
34. installed simulations interpret `permissionDecision=deny` and `decision=block` as blocking outcomes even with exit `0`;
35. malformed installed Notion input returns fail-open, emits an observable warning, and leaves the evidence ledger empty.

## Installed-Target Validation

Create a fresh temporary git target, run the official Engineering OS installer with the branch checkout as `ENGINEERING_OS_HOME`, validate rendered settings against the canonical installed surface, and execute representative valid, malformed-input, missing-enforcer, missing-interpreter, advisory, recorder, Notion, telemetry-token, operational-learning, and symlink/path-integrity cases from the target directory. No proof may rely on a file present only in the source repository unless it is an intentional installed-surface dependency declared by the registry.

## Documentation Asset Evidence

- internal: `core/hooks-policy.md`; `docs/operations/operational-readiness-audit.md`; `scripts/enforcement/hook-criticality.tsv`; `scripts/install-policy-gates.sh`.
- context7: the official vendor source `https://code.claude.com/docs/en/hooks` was used directly because hook exit and JSON semantics are vendor-owned; no secondary Context7 interpretation replaced it.
- decision: use event-specific structured deny JSON when conversion succeeds and stderr plus exit `2` when infrastructure cannot produce trustworthy structured output.

## Claude Run Trace

- trace_source: GitHub connector reads/writes, exact commit history, workflow runs, review threads, and focused test outputs.
- exact_token_usage_available: no.
- trace_boundary: no independent Claude Code session trace is claimed; repository and provider evidence are the auditable surrogate.

## Capability Evidence

- `routing.task-router-read` — `core/task-router.md` selected `engineering_os_governance`.
- `workflow.workflow-read` — workflow, git, quality, and hook policies established the result loop and lifecycle gates.
- `plan.route-plan-before-write` — the initial Route Plan commit precedes implementation changes.
- `source.github-repo-read` — exact base, settings, registry, wrapper, installer, validators, audit, and tests were read through GitHub.
- `validation.policy-change-has-validator` — focused, negative, static, nested, symlink, Notion, telemetry-token, sibling-isolation, installed-fixture, structured-deny, and installed-target validators are required outputs.
- `validation.coderabbit-policy` — external review is reconciled live; self-review remains supplemental only.

## Skill Evidence

- `writing-plans` — separated canonical ownership, runtime changes, installed proof, negative tests, review, and external gates before implementation.
- `verification-before-completion` — keeps implementation, installed proof, exact-head CI, review, approval, merge, post-merge proof, and gap closure as separate claims.
- `security-review` — focuses on fail-open branches, false evidence, input/output handling, path containment, pre-resolution symlink rejection, dependency trust, sibling isolation, stdout contamination, and exit/signal conversion.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Read canonical base and owners, verified PR #261 remained open, created `fix/hard-hook-fail-closed`, opened PR #262, and inspected exact-head workflows and review threads. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, canonical `main`, PR #261, PR #262, repository files, workflows, reviews, and compare state.
- action: verified the live base, selected existing canonical owners, isolated plan-first implementation, analyzed exact failing jobs and review findings, and applied regression-backed fixes.
- result: base `105ecd0d0dc72aa847d11b193190689dbda0dda8`; plan-first branch `fix/hard-hook-fail-closed`; implementation PR #262; CodeRabbit findings and full-suite failures were reproduced and corrected without touching PR #261.
- decision: selected the existing criticality registry plus runtime/static validation and official installer path rather than a parallel registry or legacy-enforcer rewrite.
- target: `.claude/settings.json`; `scripts/enforcement/lib/hook-gate.sh`; `scripts/enforcement/check-hard-hook-contract.py`; `scripts/enforcement/patch-settings-runtime-evidence.sh`; `scripts/enforcement/post-tool-use-notion-progress.sh`; `scripts/monitoring/require-telemetry-session.sh`; `scripts/enforcement/tests/test-hard-hook-symlinks.sh`; `scripts/enforcement/tests/test-hook-gate.sh`; `scripts/enforcement/tests/test-operational-learning-skills.sh`; `scripts/enforcement/tests/test-project8-telemetry-readiness.sh`; `scripts/enforcement/tests/test-required-connectors.sh`.

## Progress Lifecycle Evidence

- start: exact `main` `105ecd0d0dc72aa847d11b193190689dbda0dda8`, open PR #261, canonical audit rows, settings, registry, wrapper, installer, tests, and official Claude Code semantics were verified before implementation.
- mid: implementation commit `20271e7bf8ce6a23dc99387c3838f8ccd0849cec` and review-fix head `78532bc88f83316b3c38c54469c9233f9635d647` produced connector-evidence-policy run `1185` / ID `30055497133`, workflow-evidence-policy run `1174` / ID `30055497134`, pr-policy run `1710` / ID `30055497123`, and enforcement-tests run `1406` / ID `30055497151` failures. Focused results were `test-hook-gate.sh` 19/19, `test-hook-classification.sh` 10/10, and `test-hard-hook-fail-closed.sh` 15/15. Concise reproduction run `30066756835`, job `89399127583`, isolated `test-hard-hook-symlinks.sh` at 5/6 and identified the generic runtime symlink diagnostic as the failing assertion.
- review correction: CodeRabbit/Codex findings identified wrapped telemetry-recorder detection, missing `notion_progress_validated` wiring, an unregistered task-class phrase, post-resolution symlink checking, eager sibling validation, and a missing right-hand telemetry token boundary. Each finding received a regression-backed code or plan correction.
- full-suite correction: diagnostic run `30067314701`, job `89400713667`, identified `test-hook-classification.sh` false evidence for a malformed Notion response. Dedicated installed recorder validation and source validation corrections passed `test-hook-classification.sh`, `test-required-connectors.sh`, and `test-hard-hook-fail-closed.sh` in run `30067753511`, job `89401937648`.
- M–R correction: enforcement-tests run `1422` / ID `30067844734`, job `89402198469`, reached group M–R and failed `test-no-grep-c-echo.sh`; concise run `30068000890`, job `89402640376`, proved the initial `.claude/settings.json` grep-count anti-pattern. A later exact-head M–R failure was isolated by run `30069316223`, artifact `8587388095`: `grep -c ... || true` still spanned to a later `|| echo` in the same serialized command. The Read recorder now uses `TOTAL=$(grep -cE ... ) || TOTAL=0` and an `if` warning branch. Validation run `30069461978`, job `89407030984`, passed `test-no-grep-c-echo.sh` and every M–R suite before creating canonical commit `e21a4476fcd05b764e6dfdf653a96e695aede825` and removing the temporary workflow.
- merge-ref correction: enforcement-tests run `1430` / ID `30068511235`, job `89404140702`, failed `Verify Project 8 telemetry readiness suite` on the PR merge ref. Diagnostic run `30068649859`, job `89404550355`, artifact `8587143140`, isolated `preflight_detects_soft_wrapped_recorder`: the valid installed command rendered `-- pre_tool_use;`, so the whitespace/end-only boundary rejected a legitimate shell terminator. The matcher now accepts complete shell terminators while `pre_tool_use_extra` remains blocked. Validation run `30068730740`, job `89404793738`, passed the Project 8 telemetry and hook-gate suites and created canonical commit `ad2b1bacf7031a2410abc23bb0e847f420fc719f` without the temporary workflow.
- installed-fixture correction: enforcement-tests run `1443` / ID `30069573045`, job `89407390392`, passed every pre-suite plus A–F and G–L, then failed M–R. Merge-ref diagnostic run `30069657208`, job `89407689015`, artifact `8587517437`, isolated `test-operational-learning-skills.sh`: the installed allow fixture omitted `hook_event_name`, so the hard wrapper correctly rejected untrusted JSON before policy evaluation. The shell and Python payload builders now send `hook_event_name=PreToolUse`. Validation run `30069788262`, job `89408070943`, completed successfully; `test-operational-learning-skills.sh` and every M–R suite passed, commit `ce02595d35e8085c855c680f48f20c30712f6ca3` was created, and `.github/workflows/tmp-hard-hook-merge-mr-debug.yml` was removed before push.
- structured-deny correction: merge-ref diagnostic run `30070153259`, job `89409148182`, artifact `8587697506`, showed that an installed hard wrapper returned valid deny JSON with exit `0`, while the simulator treated exit `0` as allow. Commit `31a95c99f1f5760d6ac595107af93eaa267c5b1a` parses structured output and treats `permissionDecision=deny` or `decision=block` as a block; temporary workflow removal commit `2a4211011024b2d552ef053681abdda691171b69` restored a canonical diff.
- observable-recorder correction: M–R diagnostic run `30070608917`, job `89410484738`, artifact `8587867448`, isolated the stale `install_patch_surfaces_notion_errors` string assertion. Commit `46ecf89686a1f3c7d3c8ae1d1fcf8f56c84658cb` replaced it with runtime proof that malformed Notion input exits fail-open, emits the `soft-hook-gate.sh` warning, and records no evidence; temporary workflow removal commit `cde69e3e6da727b4d79abac5eb3c1072e1ad9aae` restored a canonical diff.
- pre-merge: enforcement-tests run `1458` / ID `30070850082` / job `89411204247` concluded success on canonical head `cde69e3e6da727b4d79abac5eb3c1072e1ad9aae`. Every pre-suite, A–F, G–L, M–R, S–Z, the repeated all-suite pass, router, CLAUDE entrypoint, project template, capability report, readiness audit, result-loop, scaling, and clean use-in-project contract step passed. Review reconciliation recorded 11 total threads and 0 unresolved. PR #261 was open and unmerged when this terminal checkpoint was recorded.

## Definition of Done — Implementation Branch

- [x] Complete the direct and nested hard-hook map.
- [x] Commit the Route Plan before implementation.
- [x] Define one canonical chain ownership contract.
- [x] Block hard infrastructure uncertainty with a clear reason.
- [x] Keep advisory and recorder behavior explicit and observable.
- [x] Validate nested validators and declared dependencies.
- [x] Validate hard registry rows against source and installed settings.
- [x] Add required negative runtime and wiring fixtures.
- [x] Add official clean-target installation execution.
- [x] Add static and runtime symlink traversal regressions.
- [x] Add source and installed Notion false-evidence regressions.
- [x] Add sibling-isolation and telemetry-token-boundary regressions.
- [x] Add valid installed `PreToolUse` identity fixtures.
- [x] Add structured-deny and observable-recorder regression coverage.
- [x] Open ready-for-review PR #262 with implementation evidence.
- [x] Integrate concrete CodeRabbit findings with regression coverage.

## External Gates — Not Branch DoD

Fresh exact-head provider CI, reconciliation and resolution of every current or outdated review thread, explicit approval for PR #262, expected-head protected merge, post-merge workflows on canonical `main`, and a separate canonical audit/known-gaps closure PR remain outside this implementation branch. The gap stays open and no live-state claim is added here.
