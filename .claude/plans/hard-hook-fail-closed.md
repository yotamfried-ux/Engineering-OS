# Route Plan — Hard Hook Fail-Closed

## Route Plan

| Field | Decision |
|---|---|
| Task type | security-sensitive governance bug fix and deterministic hook infrastructure hardening |
| Task class | `engineering_os_governance` |
| Domain tags | hooks, governance, security, shell, JSON, installer, testing, operational readiness |
| Plan Scope | standard |
| Planning Mode | implementation authorized; merge and canonical closure remain external owner gates |
| Target paths | `.claude/settings.json`; `scripts/enforcement/hook-criticality.tsv`; `scripts/enforcement/lib/hook-gate.sh`; `scripts/enforcement/lib/soft-hook-gate.sh`; `scripts/enforcement/check-hard-hook-contract.py`; `scripts/enforcement/patch-settings-runtime-evidence.sh`; `scripts/monitoring/require-telemetry-session.sh`; `scripts/enforcement/tests/test-hard-hook-fail-closed.sh`; `scripts/enforcement/tests/test-hard-hook-symlinks.sh`; `scripts/enforcement/tests/test-hook-classification.sh`; `scripts/enforcement/tests/test-hook-gate.sh`; `scripts/enforcement/tests/test-project8-telemetry-readiness.sh`; `.claude/plans/hard-hook-fail-closed.md` |
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
| `.claude/settings.json` | validated | Hard commands use the shared hard gate and advisory/recorder commands remain explicitly soft. |
| `scripts/enforcement/hook-criticality.tsv` | validated | Owns class, semantics, wiring, parent, surface, dependencies, and deny mode. |
| `scripts/enforcement/lib/hook-gate.sh` | validated | Converts untrusted hard-hook outcomes and infrastructure failures into deterministic blocking behavior. |
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
25. symlinked directory component blocks in static and runtime validation.

## Installed-Target Validation

Create a fresh temporary git target, run the official Engineering OS installer with the branch checkout as `ENGINEERING_OS_HOME`, validate rendered settings against the canonical installed surface, and execute representative valid, malformed-input, missing-enforcer, missing-interpreter, advisory, recorder, and symlink/path-integrity cases from the target directory. No proof may rely on a file present only in the source repository unless it is an intentional installed-surface dependency declared by the registry.

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
- `validation.policy-change-has-validator` — focused, negative, static, nested, symlink, and installed-target validators are required outputs.
- `validation.coderabbit-policy` — external review is reconciled live; self-review remains supplemental only.

## Skill Evidence

- `writing-plans` — separated canonical ownership, runtime changes, installed proof, negative tests, review, and external gates before implementation.
- `verification-before-completion` — keeps implementation, installed proof, exact-head CI, review, approval, merge, post-merge proof, and gap closure as separate claims.
- `security-review` — focuses on fail-open branches, input/output handling, path containment, pre-resolution symlink rejection, dependency trust, stdout contamination, and exit/signal conversion.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Read canonical base and owners, verified PR #261 remained open, created `fix/hard-hook-fail-closed`, opened PR #262, and inspected exact-head workflows and review threads. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, canonical `main`, PR #261, PR #262, repository files, workflows, reviews, and compare state.
- action: verified the live base, selected existing canonical owners, isolated plan-first implementation, analyzed exact failing jobs and review findings, and applied regression-backed fixes.
- result: base `105ecd0d0dc72aa847d11b193190689dbda0dda8`; plan-first branch `fix/hard-hook-fail-closed`; implementation PR #262; CodeRabbit findings reproduced and corrected without touching PR #261.
- decision: selected the existing criticality registry plus runtime/static validation and official installer path rather than a parallel registry or legacy-enforcer rewrite.
- target: `.claude/settings.json`; `scripts/enforcement/lib/hook-gate.sh`; `scripts/enforcement/check-hard-hook-contract.py`; `scripts/enforcement/patch-settings-runtime-evidence.sh`; `scripts/monitoring/require-telemetry-session.sh`; `scripts/enforcement/tests/test-hard-hook-symlinks.sh`; `scripts/enforcement/tests/test-project8-telemetry-readiness.sh`.

## Progress Lifecycle Evidence

- start: exact `main` `105ecd0d0dc72aa847d11b193190689dbda0dda8`, open PR #261, canonical audit rows, settings, registry, wrapper, installer, tests, and official Claude Code semantics were verified before implementation.
- mid: implementation commit `20271e7bf8ce6a23dc99387c3838f8ccd0849cec` and review-fix head `78532bc88f83316b3c38c54469c9233f9635d647` produced connector-evidence-policy run `1185` / ID `30055497133`, workflow-evidence-policy run `1174` / ID `30055497134`, pr-policy run `1710` / ID `30055497123`, and enforcement-tests run `1406` / ID `30055497151` failures. Focused results were `test-hook-gate.sh` 19/19, `test-hook-classification.sh` 10/10, and `test-hard-hook-fail-closed.sh` 15/15. Concise reproduction run `30066756835`, job `89399127583`, isolated `test-hard-hook-symlinks.sh` at 5/6 and identified the generic runtime symlink diagnostic as the failing assertion.
- review correction: CodeRabbit/Codex findings identified wrapped telemetry-recorder detection, missing `notion_progress_validated` wiring, an unregistered task-class phrase, and post-resolution symlink checking. Each finding received a regression-backed code or plan correction.
- rerun trigger: workflow-generated commit `42ed4f13e8cb0be978ab507d83ef9ad3a8a175e4` passed `test-hard-hook-symlinks.sh` and `test-project8-telemetry-readiness.sh`, removed the temporary diagnostic workflow, and normal connector commit `51676f153c412d02ec3d93405c29692057ca92f8` created provider-visible runs.
- pre-merge: head `51676f153c412d02ec3d93405c29692057ca92f8` recorded seven successful policy workflows, workflow-evidence run `1179` / ID `30066999169` schema diagnostics, pr-policy run `1716` / ID `30066999143` blocked only by live threads, and enforcement-tests run `1411` / ID `30066999208` reached G–L after Project 8 telemetry success. Review reconciliation reached 9 total threads and 0 unresolved.

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
- [x] Open ready-for-review PR #262 with implementation evidence.
- [x] Integrate concrete CodeRabbit findings with regression coverage.

## External Gates — Not Branch DoD

Fresh exact-head provider CI, reconciliation and resolution of every current or outdated review thread, explicit approval for PR #262, expected-head protected merge, post-merge workflows on canonical `main`, and a separate canonical audit/known-gaps closure PR remain outside this implementation branch. The gap stays open and no live-state claim is added here.
