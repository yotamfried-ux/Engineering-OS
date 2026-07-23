# Route Plan — Hard Hook Fail-Closed

## Route Plan

| Field | Decision |
|---|---|
| Task type | security-sensitive governance bug fix and deterministic hook infrastructure hardening |
| Task class | `engineering_os_governance` |
| Domain tags | hooks, governance, security, shell, JSON, installer, testing, operational readiness |
| Plan Scope | standard |
| Planning Mode | implementation authorized; merge and canonical closure remain external owner gates |
| Target paths | `.claude/settings.json`; `scripts/enforcement/hook-criticality.tsv`; `scripts/enforcement/lib/hook-gate.sh`; `scripts/enforcement/lib/soft-hook-gate.sh`; `scripts/enforcement/check-hard-hook-contract.py`; `scripts/enforcement/patch-settings-runtime-evidence.sh`; `scripts/monitoring/require-telemetry-session.sh`; `scripts/enforcement/tests/test-hook-gate.sh`; `scripts/enforcement/tests/test-hook-classification.sh`; `scripts/enforcement/tests/test-hard-hook-fail-closed.sh`; `.claude/plans/hard-hook-fail-closed.md` |
| Task-router evidence | `core/task-router.md` routes hook, settings, enforcement, test, and governance changes through `engineering_os_governance`; security-sensitive review applies to protected-action failure behavior. |
| Workflow evidence | `core/workflow.md`, `core/git-policy.md`, `core/quality-gates.md`, and `core/hooks-policy.md` require plan-first work, Experiment → Failure analysis → Fix → Experiment, dedicated PR isolation, exact-head validation, and separate merge approval. |
| Templates | Existing canonical hook wrapper, registry, settings, and installer patterns are sufficient; no new template is introduced. |
| Architecture guides | `core/hooks-policy.md`; `docs/operations/operational-readiness-audit.md`; `docs/operations/known-gaps.tsv` |
| Patterns | Existing wrapper/enforcer/registry architecture under `scripts/enforcement/`; no parallel policy registry. |
| External systems/connectors | GitHub connector for exact repository, branch, PR, workflow, review, and compare evidence; official Claude Code documentation for hook input/output and blocking semantics. |
| Skills | `writing-plans`; `verification-before-completion`; `security-review` |
| Validation gates | focused wrapper tests; canonical classification/contract tests; nested-validator tests; settings/manifest tests; official clean-target installer tests; full enforcement suite; shell/Python checks; exact-head CI; current and outdated review-thread reconciliation |
| Evidence to check | `main` SHA `105ecd0d0dc72aa847d11b193190689dbda0dda8`; PR #261 state; `.claude/settings.json`; `scripts/enforcement/hook-criticality.tsv`; `scripts/enforcement/lib/hook-gate.sh`; `scripts/install-policy-gates.sh`; `scripts/use-in-project.sh`; `https://code.claude.com/docs/en/hooks`; exact PR workflow and review state |
| User decisions required | Explicit approval for this exact PR before merge; separate post-merge closure reconciliation before any `closed` status or live-state claim. |

## Goal

Make every hard/protected Claude Code hook fail closed when its wrapper, interpreter, enforcer, settings, registry, dependency, nested validator, deny conversion, input, or subprocess result cannot produce a trustworthy policy decision. Preserve fail-open behavior only for explicitly classified advisory and recorder units, and prove source/installed behavior through the official installer path.

## Scope

This task owns hard-hook failure semantics and the minimum wiring proof needed to reject a hard registry row without a real command. Broad parity across all repository boundaries remains in `gap:eos-repo-boundary-sync-drift`; bypass authorization remains in `gap:bypass-approval-provenance`.

## Non-goals

- No merge to `main`.
- No canonical gap closure or live-state claim.
- No modification or merge of PR #261.
- No bypass approval redesign.
- No broad repo-boundary parity closure.
- No Project 8 preparation or readiness claim.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `https://github.com/yotamfried-ux/Engineering-OS/commit/105ecd0d0dc72aa847d11b193190689dbda0dda8` | checked | Canonical base is exact `main`; PR #261 remains open and untouched. |
| `docs/operations/known-gaps.tsv` | checked | `hard-hook-fail-closed` is open, P0, owner `hooks-governance`; merge and post-merge proof remain closure requirements. |
| `docs/operations/operational-readiness-audit.md` | checked | The checklist requires missing infrastructure, malformed input, nested validation, settings wiring, converter/interpreter, unexpected exit, installed-target, CI, and review evidence. |
| `.claude/settings.json` | checked | Hard-looking commands use inconsistent direct/wrapper behavior while advisory and recorder commands intentionally remain soft. |
| `scripts/enforcement/hook-criticality.tsv` | checked | Hard units declare `fail_closed`, but the old shape does not own complete direct/nested source/install chains. |
| `scripts/enforcement/lib/hook-gate.sh` | checked | The old wrapper explicitly returns success when enforcer or converter infrastructure is unavailable. |
| `scripts/install-policy-gates.sh` | checked | Installed settings are patched and rendered through the official target installation path. |
| `https://code.claude.com/docs/en/hooks` | checked | Exit `2` is the deterministic blocking fallback; `PreToolUse` and `Stop` use different structured deny schemas. |

## Canonical Ownership Decision

Extend `scripts/enforcement/hook-criticality.tsv` as the single owner for event, matcher, unit, class, failure semantics, direct/nested wiring, parent, source/installed surface, dependencies, and deny mode. A deterministic validator compares that owner with settings and required files.

## Implementation Plan

1. Reproduce fail-open behavior with negative fixtures.
2. Extend the existing criticality registry without adding a parallel manifest.
3. Add a static contract validator for malformed registry/settings, missing or wrong hard commands, soft wrapping, missing files/dependencies, and nested chains.
4. Harden the runtime gate to validate input, canonical identity, dependencies, subprocess status/output, event-specific deny conversion, and exit-2 fallback.
5. Route direct hard commands through a missing-wrapper bootstrap; keep advisory/recorders explicitly soft and observable.
6. Preserve the official installer flow and validate the rendered target.
7. Run focused, grouped, full, exact-head, and live-review result loops.

## Negative Test Plan

1. valid hard success passes;
2. explicit policy denial blocks;
3. malformed input blocks;
4. invalid JSON blocks;
5. missing enforcer blocks;
6. missing wrapper blocks;
7. missing interpreter blocks;
8. missing nested validator blocks;
9. nested validator failure blocks;
10. required registry row missing blocks;
11. malformed registry blocks;
12. settings command missing blocks;
13. wrong settings target blocks;
14. dependency unavailable blocks;
15. deny converter failure blocks;
16. unexpected exit code blocks;
17. subprocess signal/termination blocks;
18. hard hook wrapped in soft failure is rejected;
19. advisory hook failure remains fail-open only with explicit classification;
20. recorder failure is observable and does not masquerade as policy success;
21. source repository behavior passes;
22. clean installed-target behavior passes.

## Installed-Target Validation

Create a fresh temporary git target, execute `scripts/install-policy-gates.sh` and the repository's existing installer suites with the branch checkout as `ENGINEERING_OS_HOME`, validate the rendered settings against the canonical contract, and execute representative valid, malformed, missing-enforcer, missing-interpreter, nested, advisory, and recorder cases from the target directory.

## Documentation Asset Evidence

- internal: `core/hooks-policy.md`; `docs/operations/operational-readiness-audit.md`; `scripts/enforcement/hook-criticality.tsv`; `scripts/install-policy-gates.sh`.
- context7: official vendor source `https://code.claude.com/docs/en/hooks` was used directly because Claude Code hook exit and JSON semantics are vendor-owned; no secondary Context7 interpretation replaced it.
- decision: use event-specific structured deny JSON when conversion succeeds and stderr plus exit `2` when infrastructure cannot produce trustworthy structured output.

## Claude Run Trace

- trace_source: GitHub connector reads/writes, exact commit history, workflow runs, review threads, and local focused test output.
- exact_token_usage_available: no.
- trace_boundary: this execution does not claim an independent Claude Code session trace; repository and provider evidence remain the auditable surrogate.

## Capability Evidence

- `routing.task-router-read` — `core/task-router.md` selected `engineering_os_governance`.
- `workflow.workflow-read` — workflow, git, and quality policies established the result-loop and lifecycle gates.
- `plan.route-plan-before-write` — this plan commit precedes code/config/test changes.
- `source.github-repo-read` — exact base, settings, registry, wrapper, installer, validators, audit, and tests were read through GitHub.
- `validation.policy-change-has-validator` — focused, negative, static-contract, nested, and installed-target suites are required outputs.
- `validation.coderabbit-policy` — external review is reconciled live; self-review is supplementary only.

## Skill Evidence

- `writing-plans` — separated ownership, runtime changes, source/install proof, negative cases, review, and external gates before code.
- `verification-before-completion` — keeps implementation, installed proof, exact-head CI, review, approval, merge, post-merge, and closure as separate claims.
- `security-review` — focuses review on fail-open branches, command/JSON handling, dependency trust, symlinks, path containment, stdout contamination, and exit/signal conversion.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Read exact `main` `105ecd0d0dc72aa847d11b193190689dbda0dda8`, verified PR #261 remains open, and isolated `fix/hard-hook-fail-closed`. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, exact `main`, PR #261, repository files, workflows, reviews, and compare state.
- action: verified live base and canonical owners before creating the dedicated plan-first branch.
- result: base `105ecd0d0dc72aa847d11b193190689dbda0dda8`; plan path `.claude/plans/hard-hook-fail-closed.md`; PR #261 head `28144667331c2c7dcda13bba8460a1c956e970ae` remains untouched.
- decision: selected the existing criticality registry plus runtime/static validation instead of a parallel registry or legacy-enforcer rewrite.
- target: `.claude/settings.json`; `scripts/enforcement/hook-criticality.tsv`; hard/soft runners; contract validator; installer patcher; telemetry preflight; tests.

## Progress Lifecycle Evidence

- start: exact `main` `105ecd0d0dc72aa847d11b193190689dbda0dda8`, open PR #261, canonical audit rows, settings, registry, wrapper, installer, tests, and official Claude Code blocking semantics were verified before the first implementation change.

- mid: implementation commit `20271e7bf8ce6a23dc99387c3838f8ccd0849cec` reproduced missing-enforcer, malformed-input, converter, nested-validator, settings-wiring, recorder, and installed-target failures; CodeRabbit P1 findings exposed wrapped telemetry-recorder detection and missing Notion progress wiring, and both root causes were corrected in the implementation tree.

## Definition of Done — Implementation Branch

- [ ] Complete direct and nested hard-hook map.
- [ ] Commit the Route Plan before implementation.
- [ ] Define one canonical chain ownership contract.
- [ ] Block every hard infrastructure uncertainty with a clear reason.
- [ ] Keep advisory/recorder behavior explicit and observable.
- [ ] Validate nested validators and dependencies.
- [ ] Validate hard registry rows against source and installed settings.
- [ ] Pass all required negative fixtures.
- [ ] Pass the official clean installed-target suite.
- [ ] Pass focused and full enforcement suites.
- [ ] Open a ready-for-review PR with complete evidence.
- [ ] Pass latest exact-head CI and reconcile every review thread.

## External Gates — Not Branch DoD

Explicit approval for PR #262, expected-head protected merge, post-merge workflows on canonical `main`, and a separate canonical audit/known-gaps closure PR remain outside this implementation branch.
