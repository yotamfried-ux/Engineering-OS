# Route Plan — Documentation Runtime State Reconciliation

## Route Plan

| Field | Decision |
|---|---|
| Task type | governance documentation reconciliation / deterministic stale-claim prevention / audit and gap-contract refinement |
| Task class | `engineering_os_governance` |
| Domain tags | documentation-as-code, runtime truth, capabilities, review governance, telemetry integrity, merge evidence, testing, operational readiness |
| Plan Scope | standard |
| Planning Mode | user-authorized continuation after merged PR #255; implementation PR remains owner-gated |
| Target paths | `.claude/plans/documentation-runtime-state-drift.md`; `CLAUDE.md`; `README.md`; `core/coderabbit-policy.md`; `scripts/enforcement/MANIFEST.tsv`; `scripts/enforcement/check-documentation-hygiene.sh`; `scripts/enforcement/tests/test-documentation-hygiene.sh`; `docs/operations/documentation-ownership.tsv`; `docs/operations/live-state-claims.json`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md` |
| Task-router evidence | `core/task-router.md` routes entrypoint, policy, validator, and readiness changes as `engineering_os_governance`. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, `core/documentation-policy.md`, and `core/coderabbit-policy.md` require plan-first work, fixtures, exact-head review, owner approval, and post-merge proof. |
| Templates | waiver — this extends existing canonical documentation and enforcement paths |
| Architecture guides | `core/documentation-policy.md`; `docs/operations/documentation-ownership.tsv`; `docs/operations/operational-readiness-audit.md` |
| Patterns | none — no application pattern owns documentation-state reconciliation |
| External systems/connectors | GitHub |
| Skills | `verification-before-completion`; `writing-plans` |
| Validation gates | documentation-hygiene fixtures; known-gaps; readiness; enforcement-tests; documentation, plan, workflow, connector, capability, cleanup, telemetry, pr-policy, live-state, review-thread, and post-merge gates |
| Evidence to check | `CLAUDE.md`; `README.md`; `core/capability-registry.yaml`; `scripts/enforcement/MANIFEST.tsv`; telemetry plan/analyzer/importer owners; merge-readiness checker/tests; PR #255 head `97d56e2f5743b019145da600cf0914f6d092cd0f`; merge `0ee2dbee7a9ab58e86a11726021c30baca0faa22`; PR #256 live head must be fetched from GitHub after every update. Head `9740ad810198d28e287872497a88dec9e7a2c95f` is the last verified audit checkpoint before this update and is historical after any later commit. |
| User decisions required | keep Project 8 and its prompt blocked; do not merge PR #256 without new explicit approval |

## Goal

Align active documentation with executable runtime truth and make every remaining readiness gap independently actionable. The capability registry remains authoritative, README stops duplicating volatile counts, CodeRabbit uses current PR evidence with structured fallback, and the canonical audit/registry distinguish documentation drift, hook wiring, fail-closed behavior, bypass authorization, pattern ownership/evidence, telemetry import integrity, first-run versus longitudinal sufficiency, exact-head merge evidence, Project 8 blindness, and final readiness semantics.

PR #255 remains registered as a closed live claim. PR #256 now contains both its original documentation implementation and a user-requested refinement of the readiness contracts. Registration does not close any newly identified implementation gap.

## Non-negotiable behavior

1. Capability runtime status comes from `core/capability-registry.yaml` and its executable gate; descriptive manifests must agree.
2. Maintained README inventory rows contain no volatile numeric snapshots and point to canonical owners.
3. Observed or pending CodeRabbit feedback blocks; proven absence uses structured fallback; fabricated success is forbidden.
4. Checks cover active canonical surfaces, not historical plans.
5. First-run monitoring usefulness and longitudinal reproducibility remain separate states.
6. Hook settings parity and hard-hook failure semantics remain separate gaps.
7. Archive import integrity and real-run usefulness remain separate gaps.
8. Machine merge evidence must use the exact expected head and latest workflow attempt; human approval remains separate.
9. No Project 8 or provider-state change.
10. Current-gap closure requires complete scope, tests, exact-head CI, review, owner-approved merge, and post-merge evidence.

## Plan

1. Align CLAUDE runtime wording.
2. Remove README count snapshots.
3. Align CodeRabbit availability/fallback policy.
4. Extend the existing checker and fixtures for the original documentation invariants.
5. Register and live-validate PR #255 closure.
6. Read the audit-touched runtime, enforcement, telemetry, pattern, merge, and target-boundary owners.
7. Refine each gap so risk, owner, boundary, test surface, closure bar, dependency, and evidence are non-overlapping.
8. Register newly discovered import-integrity and exact-head/latest-attempt merge gaps without claiming implementation.
9. Synchronize registry, ledger, matrix, dependency phases, checklists, priorities, and current scope.
10. Run exact-head result loops, reconcile review, and keep PR #256 unmerged pending explicit approval.

## Alternatives

- Refresh copied counts — rejected because drift recurs.
- Assume permanent reviewer availability/unavailability — rejected because it is live state.
- Keep broad gaps that mix implementation, wiring, documentation, and evidence — rejected because partial fixes could create false closure.
- Hide import integrity inside monitoring usefulness — rejected because corrupted input can invalidate every later finding.
- Treat a PR-body head field as proof that workflow results belong to that head — rejected because workflow metadata and attempt ordering must be validated independently.
- Rewrite historical plans — rejected because they are dated evidence.
- Add a second gap registry — rejected because canonical owners already exist.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `core/task-router.md` | read | Engineering OS governance route. |
| `core/workflow.md` | read | Plan-first result loops apply. |
| `core/documentation-policy.md` | read | One owner plus deterministic fixtures. |
| `core/capability-registry.yaml` | checked | Active `plan_level_write_gate`; old planned wording was stale. |
| `scripts/enforcement/MANIFEST.tsv` | checked | Still describes the active capability registry as non-runtime; retained as an explicit open documentation drift item. |
| `.claude/settings.json` | checked | Checked-in Engineering OS settings are one of four required wiring surfaces. |
| `scripts/monitoring/patch-settings-runtime-evidence.sh` | checked | Direct-mode installation can add runtime-evidence hooks that are absent from checked-in settings. |
| `scripts/enforcement/lib/hook-gate.sh` | checked | Wrapper infrastructure failures can return success on hard paths. |
| `scripts/enforcement/pre-tool-use-runtime-evidence.sh` | checked | Required nested validation can be conditionally skipped when a validator is absent. |
| `scripts/enforcement/lib/evidence.sh` | checked | A truthy environment variable is not approval provenance. |
| `patterns/registry.yaml` | checked | Registry lifecycle state conflicts with an independent ratings view. |
| `docs/operations/template-pattern-ratings.tsv` | checked | Ratings can report active usage not represented by the registry. |
| `scripts/monitoring/export-telemetry-run.py` | checked | Export creates bundle checksums and identity metadata. |
| `scripts/monitoring/telemetry_handoff.py` | checked | Shared handoff validation verifies checksums and run identity. |
| `scripts/monitoring/import-telemetry-run.py` | checked | Direct import does not independently invoke the full shared integrity contract. |
| `scripts/monitoring/analyze-telemetry-archive.py` | checked | Active wording mixes first-run usefulness with later comparison requirements. |
| `scripts/enforcement/check-merge-readiness.sh` | checked | Checker does not require expected head or deterministically select latest attempts. |
| `scripts/enforcement/tests/test-operational-readiness-gates.sh` | checked | Existing merge-readiness fixtures omit head, timestamps, and rerun ordering. |
| `https://github.com/yotamfried-ux/project-8/pull/9` | checked | Exact product-only boundary is strong; required Azure workflow failure and fresh-session proof remain blockers. |
| `CLAUDE.md` | checked | Runtime and live-review/fallback wording reconciled. |
| `README.md` | checked | Count snapshots replaced by live inventory links. |
| `core/coderabbit-policy.md` | checked | Observed review and fallback are explicit branches. |
| `scripts/enforcement/check-documentation-hygiene.sh` | checked | Original three invariants enforced on active surfaces. |
| `scripts/enforcement/tests/test-documentation-hygiene.sh` | checked | Positive and negative drift fixtures added. |
| `github/docs/src/content-linter/lib/linting-rules/index.ts` | read | Executable custom documentation rules. |
| `https://code.claude.com/docs/en/memory` | read | Shared project memory must remain current. |
| `https://docs.coderabbit.ai/guides/code-review-overview` | read | Review depends on live integration and PR state. |

## Official Documentation Evidence

- `https://code.claude.com/docs/en/memory`
- `https://code.claude.com/docs/en/hooks`
- `https://docs.github.com/en/rest/actions/workflow-runs`
- `https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes`
- `https://docs.coderabbit.ai/guides/code-review-overview`
- `https://docs.coderabbit.ai/configuration/auto-review`
- `https://docs.coderabbit.ai/guides/configuration-overview`

## Official Repository Evidence

- `github/docs/src/content-linter/lib/linting-rules/index.ts`
- `github/docs/src/content-linter/lib/linting-rules/hardcoded-data-variable.ts`
- `anthropics/claude-code`
- `actions/github-script`
- `octokit/rest.js`

## Documentation Asset Evidence

- internal: `CLAUDE.md`, `README.md`, `core/capability-registry.yaml`, `core/coderabbit-policy.md`, `scripts/enforcement/MANIFEST.tsv`, hook/settings/bypass/pattern/telemetry/merge owners and tests, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.
- context7: the exact Anthropic, GitHub, CodeRabbit, GitHub REST, `github/docs`, and `anthropics/claude-code` references above were read directly; no external SDK is introduced.
- decision: executable owners define active state; every gap owns one failure class; documentation, implementation, wiring, integrity, live evidence, longitudinal evidence, and human approval are not interchangeable.

## Template Gap Waiver

reason: this is a focused extension of canonical governance files and the existing documentation checker.

## Capability Evidence

- `routing.task-router-read` — `engineering_os_governance`.
- `workflow.workflow-read` — plan-first and post-merge proof applied.
- `plan.route-plan-before-write` — `13d6e8456b6c75db03eb31a8393a505adc3e8ac7` preceded the original implementation; this updated checkpoint records the user-authorized audit refinement before any further implementation gap is attempted.
- `source.github-repo-read` — canonical and official repositories inspected.
- `validation.policy-change-has-validator` — original rules have fixtures; newly registered implementation gaps name their required positive/negative surfaces without claiming those tests already exist.
- `validation.actions-checked` — exact-head/live-state gates remain required after every update.
- `validation.coderabbit-policy` — live review and fallback both represented.

## Skill Evidence

- `verification-before-completion` — registration, implementation, CI, review, merge, post-merge, and live evidence are distinct.
- `writing-plans` — scope, alternatives, sources, validation, dependencies, and lifecycle recorded.

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Verified PR #255/main, read canonical and official repositories, inspected PR #256 live state and Actions, updated the canonical audit/registry, and reviewed the new CodeRabbit finding. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, `yotamfried-ux/project-8`, `github/docs`, and `anthropics/claude-code`.
- action: inspected runtime, enforcement, telemetry, pattern, merge, and target-boundary owners; refined canonical gap contracts; ran CI loops; read the exact failed gates and current review thread.
- result: commits `b55b9e6685150e9204e0349b5a8c06b1f3d074c9` through `9740ad810198d28e287872497a88dec9e7a2c95f` updated `.claude/plans/documentation-runtime-state-drift.md`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`; known-gaps-live-state runs 21 and 23 passed while enforcement runs 1357 and 1359 identified and isolated the registry and readiness-row contract errors.
- decision: updated canonical evidence and kept strict validators unchanged instead of weakening gates or claiming closure.
- target: `.claude/plans/documentation-runtime-state-drift.md`; `CLAUDE.md`; `README.md`; `core/coderabbit-policy.md`; `scripts/enforcement/check-documentation-hygiene.sh`; `scripts/enforcement/tests/test-documentation-hygiene.sh`; `docs/operations/live-state-claims.json`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`.

## Data / State Impact

Documentation, validator code, fixtures, and metadata-only claims only; no application/provider state.

## Integration Impact

The audit and registry now distinguish documentation truth, hook wiring, hard failure semantics, bypass provenance, pattern ownership/maturity, telemetry import integrity/usefulness/repeatability, target blindness, exact-head merge evidence, and terminal readiness. Project 8 remains blocked.

## Validation Plan

- focused documentation-hygiene checker/fixtures;
- known-gaps and readiness audit validators after every registry/matrix change;
- live-state, full enforcement, and all named non-self workflows on the exact current PR head;
- current review-thread inspection and resolution;
- exact-head artifact/body reconciliation, self-review, owner approval, and post-merge validation before any closure.

## Claude Run Trace

- goal: prevent active documentation or broad gap definitions from contradicting executable runtime and evidence truth.
- hypothesis: one owner and one closure class per gap, backed by deterministic registry/audit synchronization, prevents false partial closure.
- connectors: GitHub and official Anthropic, GitHub Docs, GitHub REST, and CodeRabbit sources.
- steps: merge PR #255; inspect main; research; plan first; implement original documentation fixes; read all audit-touched owners; refine gaps; add two missing gaps; synchronize audit; run CI; fix the invalid test path and canonical row-name regressions; reconcile the plan-review finding; correct concrete source, connector, lifecycle, and target evidence.
- evidence: PR #255 head/merge; original plan commit `13d6e8456b6c75db03eb31a8393a505adc3e8ac7`; original reviewed head `e8afab8b20f9fa21e6cc63f0dc5df32809c4b0e8`; registry/audit commits `b55b9e6685150e9204e0349b5a8c06b1f3d074c9`, `e784cae2a3ca42345a77e467d412578db6c70464`, `e7356cb129dc149bf315486472ae50d19bf489ea`, `7babd728d44eb6520eb0ce8a06a9c6f2b81a35ac`, `0b72af909765f4dd1e6423184e20b79571e6efac`, `dfe82f93d9f039eb7aa2b8e2c3d4fb723c65c100`, and `9740ad810198d28e287872497a88dec9e7a2c95f`; known-gaps-live-state runs 21 and 23 succeeded; enforcement runs 1357 and 1359 reached readiness after known-gaps passed.
- rejected: copied state, static reviewer assumptions, broad overlapping gaps, import-integrity inference, wrong-head CI inference, historical rewrites, and validator weakening.
- result: canonical gap contracts and audit coverage are updated; exact-head validation must restart after this plan commit; PR #256 remains unmerged and no newly registered gap is closed.
- follow-up: this session's continuation closes the remaining MANIFEST.tsv and telemetry-terminology checklist items (see "Continuation checkpoint" below) on branch `claude/operational-readiness-eos-c6ykfs`; exact-head CI, review, owner-approved merge, and post-merge validation remain before `documentation-runtime-state-drift` closes.

## Definition of Done

- [x] CLAUDE runtime wording agrees with registry.
- [x] README inventory rows contain no numeric snapshots.
- [x] CodeRabbit policy requires current review or structured fallback.
- [x] Checker covers all three original active-surface invariants.
- [x] Fixtures cover original runtime, inventory, and reviewer drift.
- [x] PR #255 live claim is retained and validated.
- [x] Audit-touched implementation, settings, telemetry, pattern, merge, and Project 8 boundary owners were read.
- [x] Existing gap risks, owners, boundaries, priorities, tests, closure bars, dependencies, and evidence were refined.
- [x] `telemetry-archive-import-integrity` and `merge-readiness-exact-head-and-attempt-ordering` were registered separately.
- [x] Registry, ledger, matrix, phases, checklists, priorities, and current scope were synchronized.
- [x] CI-discovered registry and matrix contract errors were corrected without weakening validators.
- [x] The stale PR #256 plan checkpoint finding was reconciled without pretending a self-referential commit SHA can be embedded in the commit itself.
- [x] Concrete source, connector result/decision/target, and lifecycle evidence satisfy the existing workflow contracts.

## Live External Gates Before Merge

PR #256 remains unmerged. After this plan update, its exact live head, all named non-self workflow results and latest attempts, review threads, PR body, Operational Work History, and Merge Readiness evidence must be re-fetched and reconciled. Explicit Yotam approval is still absent. After any authorized merge, post-merge validation on `main` is required; none of the expanded implementation gaps closes merely because its definition was registered.

## Progress Lifecycle Evidence

- start: commit `13d6e8456b6c75db03eb31a8393a505adc3e8ac7` recorded the original documentation-reconciliation scope, sources, alternatives, and validation before implementation.
- mid: commit `836f1538a9873cc109d159adc790891debc35c60` recorded the original implementation checkpoint after all nine target paths and first CI diagnostics existed.
- pre-review checkpoint: commit `890e535da3c5a69951986ad92d436113f6fc0c08` completed the original six review-driven checker and fixture corrections.
- audit-refinement checkpoint: commits `b55b9e6685150e9204e0349b5a8c06b1f3d074c9` through `7babd728d44eb6520eb0ce8a06a9c6f2b81a35ac` recorded the user-authorized expanded gap definitions, new gap registration, and two CI-driven contract corrections.
- pre-merge: commit `0b72af909765f4dd1e6423184e20b79571e6efac` recorded the plan-scope reconciliation after the last original code/config/test change; the subsequent documentation-only evidence corrections preserve the blocked, unmerged state.
- continuation-start: recorded this session's scope on branch `claude/operational-readiness-eos-c6ykfs` before any code/config/test change — MANIFEST.tsv reconciliation, telemetry-terminology guard, canonical ownership rows, and bidirectional fixtures for the remaining `documentation-runtime-state-drift` checklist items.
- continuation-mid: commit `bb96bcd` implemented the MANIFEST.tsv fix, the bidirectional hygiene-checker regressions (including the missing-row and sentence-scoped telemetry checks added after CodeRabbit/Codex review of the first push), the ownership rows, and 7 new fixtures; it also fixed a real pre-existing contradiction found in `docs/operations/runtime-telemetry-archive-plan.md` (line 385 wrongly required a second run to close the first-run-only `monitoring-metrics-sufficiency` gate). Local `test-documentation-hygiene.sh` (27/27), `test-capability-registry.sh`, `check-known-gaps.sh`, `check-readiness-audit.sh`, and `shellcheck -S error` all passed on this commit.
- continuation-pre-merge: after commit `bb96bcd` is the last code/config/test change in this round, this checkpoint records that PR #260's exact head is being re-verified against live GitHub Actions and review threads (CodeRabbit and Codex both reviewed the earlier `3cc78f5` push and raised valid findings, all addressed in `bb96bcd`) before requesting Yotam's explicit merge approval; no merge occurs without that approval and post-merge validation on the new `main` commit.

## Continuation checkpoint — MANIFEST.tsv, telemetry terminology, ownership, fixtures (this session)

PR #257/#259 closed `merge-readiness-exact-head-and-attempt-ordering` (verified live: `enforcement-tests` 1388, `known-gaps-live-state` 32, `post-merge-validation` 90 all `success` on merge commit `df01a8fea10df999572ab11466613e31a8c1a003`, which is current `main`). This continuation closes checklist items 4–7 of `documentation-runtime-state-drift` (bringing completion to 7 of 8) on branch `claude/operational-readiness-eos-c6ykfs`, based on that exact `main` commit.

### Source of Truth Checks (this continuation)

| Source | Status | Finding / decision |
|---|---|---|
| `scripts/enforcement/MANIFEST.tsv` row 23 | checked | Said `NONE ... non-runtime, no enforcer yet` for `core/capability-registry.yaml`, contradicting both the registry itself (`runtime_enabled: true`) and `CLAUDE.md`'s navigation table (`test-capability-registry.sh (coverage), active plan-level write gate`). |
| `scripts/enforcement/tests/test-capability-registry.sh` | checked | Exists, validates registry content/coverage, but never reads `MANIFEST.tsv` — nothing previously caught the drift above. |
| `docs/operations/project8-telemetry-preflight.md`, `runtime-telemetry-archive-plan.md`, `runtime-telemetry-archive-audit-checklist.md`, `scripts/monitoring/analyze-telemetry-archive.py` | checked | First-run vs longitudinal vocabulary is already consistent across all four; no existing contradiction found, but nothing enforced that it stay that way. |
| `docs/operations/documentation-ownership.tsv` | checked | Had no row for `scripts/enforcement/MANIFEST.tsv` or telemetry terminology; added `enforcer-registry` (owner `hooks-governance`) and `telemetry-terminology` (owner `observability-governance`). |

### Implementation

1. `scripts/enforcement/MANIFEST.tsv` — row 23 now names `scripts/enforcement/tests/test-capability-registry.sh` and describes the active plan-level write gate, matching `CLAUDE.md` and the registry.
2. `scripts/enforcement/check-documentation-hygiene.sh` — added a bidirectional MANIFEST↔registry check (fails if MANIFEST says NONE/non-runtime while the registry is active, or if MANIFEST claims an active enforcer while the registry is inactive), and a telemetry-terminology guard (fails a longitudinal-sufficiency claim without nearby multi-run evidence, or a first-run claim that wrongly demands a second run).
3. `scripts/enforcement/tests/test-documentation-hygiene.sh` — added fixture files (MANIFEST.tsv + 4 telemetry docs) to the base `make_repo`, plus 4 new fixtures/assertions: `manifest_stale_rejects_non_runtime_wording`, `manifest_overclaim_rejects_active_enforcer`, `telemetry_longitudinal_unsupported_fails`, `telemetry_first_run_overreach_fails`.
4. `docs/operations/documentation-ownership.tsv` — added `enforcer-registry` and `telemetry-terminology` rows.
5. `docs/operations/operational-readiness-audit.md` — checked off checklist items 4–7 for `gap:documentation-runtime-state-drift` with concrete evidence; updated the matrix row and "Current audit scope" narrative; left checklist item 8 (exact-head CI/review/merge/post-merge) unchecked.
6. `docs/operations/known-gaps.tsv` — updated row 44 notes to describe this branch's contribution; status remains `open`.

No historical `.claude/plans/*.md` or past checkpoint evidence was rewritten.

### Validation (local, this session)

- `bash scripts/enforcement/check-documentation-hygiene.sh --root "$(pwd)" --manifest docs/operations/documentation-ownership.tsv` → passed (27 ownership rows).
- `bash scripts/enforcement/tests/test-documentation-hygiene.sh` → all 24 fixtures passed, including the 4 new ones, both directions.
- `bash scripts/enforcement/tests/test-capability-registry.sh` → passed, unaffected.
- `bash scripts/enforcement/check-known-gaps.sh` → passed (48 gaps).
- `bash scripts/enforcement/check-readiness-audit.sh` → passed (55 readiness rows).
- `bash scripts/enforcement/tests/test-known-gaps.sh`, `test-readiness-audit.sh` → passed.
- Full local loop over every `scripts/enforcement/tests/test-*.sh` → all green, no regressions.

### Remaining before closure

Exact-head CI on the pushed branch, CodeRabbit review (or documented structured fallback) with every thread resolved, explicit Yotam approval before merge, then post-merge validation of `enforcement-tests`/`known-gaps-live-state`/`post-merge-validation` on the new `main` commit — only then does `known-gaps.tsv` flip to `closed` and checklist item 8 gets checked, following the same two-step (implementation PR → closure PR) pattern already used for `merge-readiness-exact-head-and-attempt-ordering` (PR #257 → PR #259).
