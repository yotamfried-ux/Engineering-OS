# Route Plan — Documentation Runtime State Reconciliation

## Route Plan

| Field | Decision |
|---|---|
| Task type | governance documentation reconciliation / deterministic stale-claim prevention / audit lifecycle update |
| Task class | `engineering_os_governance` |
| Domain tags | documentation-as-code, runtime truth, capabilities, review governance, testing, operational readiness |
| Plan Scope | standard |
| Planning Mode | user-authorized continuation after merged PR #255; implementation PR remains separately owner-gated |
| Target paths | `.claude/plans/documentation-runtime-state-drift.md`; `CLAUDE.md`; `README.md`; `core/coderabbit-policy.md`; `scripts/enforcement/check-documentation-hygiene.sh`; `scripts/enforcement/tests/test-documentation-hygiene.sh`; `docs/operations/live-state-claims.json`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md` |
| Task-router evidence | `core/task-router.md` routes entrypoint, core policy, validator, and readiness changes as `engineering_os_governance`. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, `core/documentation-policy.md`, and `core/coderabbit-policy.md` require plan-first work, canonical ownership, negative fixtures, exact-head review, owner approval, and post-merge proof. |
| Templates | waiver — this extends existing canonical documentation and enforcement paths, not a product scaffold |
| Architecture guides | `core/documentation-policy.md`; `docs/operations/documentation-ownership.tsv`; `docs/operations/operational-readiness-audit.md` |
| Patterns | none — no application implementation pattern owns documentation-state reconciliation |
| External systems/connectors | GitHub |
| Skills | `verification-before-completion`; `writing-plans` |
| Validation gates | documentation-hygiene fixtures; known-gaps; readiness audit; enforcement-tests; documentation, plan, workflow, connector, capability, cleanup, telemetry, pr-policy, live-state, review-thread, and post-merge gates |
| Evidence to check | `CLAUDE.md`; `README.md`; `core/capability-registry.yaml`; `core/coderabbit-policy.md`; `scripts/enforcement/check-documentation-hygiene.sh`; `scripts/enforcement/tests/test-documentation-hygiene.sh`; PR #255 head `97d56e2f5743b019145da600cf0914f6d092cd0f`; merge `0ee2dbee7a9ab58e86a11726021c30baca0faa22`; official Anthropic, GitHub Docs, and CodeRabbit sources |
| User decisions required | keep the Project 8 behavioral experiment and prompt blocked; do not merge this PR without a new explicit owner decision |

## Goal

Make active canonical documentation agree with executable runtime truth. The capability registry remains authoritative, the root README stops duplicating volatile counts, CodeRabbit review depends on current PR evidence with a structured fallback, and the existing documentation-hygiene gate blocks recurrence.

The same change registers PR #255 as the closure claim for `audit-live-state-verification`. `documentation-runtime-state-drift` remains open through this PR's own merge and post-merge proof.

## Non-negotiable behavior

1. `core/capability-registry.yaml` owns capability runtime status and scope.
2. Root README category descriptions contain no hand-maintained numeric inventories.
3. CodeRabbit feedback blocks when observed or pending; proven absence uses structured `Review Fallback Evidence`; no fabricated review claim is accepted.
4. Checks cover active canonical surfaces, not historical plans or research.
5. No Project 8 code, prompt, provider resource, secret, deployment, DNS, database, or production state changes.
6. Current-gap closure requires focused/full tests, exact-head CI, review, owner-approved merge, and post-merge validation.

## Plan

1. Align CLAUDE runtime wording with `runtime_enabled: true` and `runtime_scope: plan_level_write_gate`.
2. Remove volatile README counts and point to canonical inventories.
3. Align CodeRabbit policy with live availability and fallback evidence.
4. Extend the existing checker and positive/negative fixtures.
5. Register and live-validate PR #255 closure evidence.
6. Synchronize the registry and audit without closing the current implementation gap.
7. Run exact-head result loops and reconcile review before any merge decision.

## Alternatives

- Replace old counts with current counts — rejected because drift recurs.
- Generate README counts — rejected because the values add little operational value and create churn.
- Assume CodeRabbit is always available or always unavailable — rejected because review eligibility and service state are live external facts.
- Add another state manifest — rejected because canonical owners already exist.
- Rewrite historical plans — rejected because they are dated evidence, not active state owners.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `core/task-router.md` | read | The task is Engineering OS governance. |
| `core/workflow.md` | read | Plan-first result loops and exact evidence apply. |
| `core/documentation-policy.md` | read | Durable ideas have one owner and deterministic changes need fixtures. |
| `core/capability-registry.yaml` | checked | Runtime is enabled at `plan_level_write_gate`; `runtime planned` was stale. |
| `CLAUDE.md` | checked | Active capability and live-review/fallback wording are reconciled. |
| `README.md` | checked | Four volatile count snapshots were replaced by canonical inventory links. |
| `core/coderabbit-policy.md` | checked | Current review status and structured fallback are separate evidence branches. |
| `scripts/enforcement/check-documentation-hygiene.sh` | checked | The existing owner gate now enforces runtime, inventory, and review invariants. |
| `scripts/enforcement/tests/test-documentation-hygiene.sh` | checked | Fixtures cover all identified drift classes and existing ownership cases. |
| `github/docs/src/content-linter/lib/linting-rules/index.ts` | read | GitHub registers executable custom documentation rules. |
| `https://code.claude.com/docs/en/memory` | read | Shared project memory is active instruction context and must remain current. |
| `https://docs.coderabbit.ai/guides/code-review-overview` | read | Reviewer activity depends on live integration and eligible PR state. |

## Official Documentation Evidence

- `https://code.claude.com/docs/en/memory`
- `https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes`
- `https://docs.coderabbit.ai/guides/code-review-overview`
- `https://docs.coderabbit.ai/configuration/auto-review`
- `https://docs.coderabbit.ai/guides/configuration-overview`

## Official Repository Evidence

- `github/docs/src/content-linter/lib/linting-rules/index.ts`
- `github/docs/src/content-linter/lib/linting-rules/hardcoded-data-variable.ts`
- `anthropics/claude-code`

## Documentation Asset Evidence

- internal: the nine target paths plus `core/documentation-policy.md`, `core/capability-registry.yaml`, and `docs/operations/documentation-ownership.tsv`.
- context7: the official URLs and repository paths above were read directly; no external SDK is introduced.
- decision: use executable owners, remove count snapshots, model reviewer availability as live evidence, and enforce the result locally.

## Template Gap Waiver

reason: this task extends established canonical governance files and an existing documentation validator; no template owns it.

## Capability Evidence

- `routing.task-router-read` — routed as `engineering_os_governance`.
- `workflow.workflow-read` — plan-first result loops and post-merge proof apply.
- `plan.route-plan-before-write` — commit `13d6e8456b6c75db03eb31a8393a505adc3e8ac7` preceded every implementation write.
- `source.github-repo-read` — exact canonical files, PR #255, and official repositories were inspected.
- `validation.policy-change-has-validator` — every new rule has positive or negative fixture coverage.
- `validation.actions-checked` — exact-head and live-state workflows remain completion gates.
- `validation.coderabbit-policy` — observed review and fallback paths are represented without assumptions.

## Skill Evidence

- `verification-before-completion` — implementation, CI, review, merge, and closure remain separate claims.
- `writing-plans` — scope, alternatives, sources, validators, and lifecycle were recorded before writes.

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Verified PR #255 and merged main, read canonical and official repositories, created the branch/commits/PR, and supplies Actions/review evidence. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, `github/docs`, and `anthropics/claude-code`.
- action: merged PR #255; inspected canonical owners; researched official examples; implemented all nine scoped paths; opened PR #256.
- result: PR #256 head `971cb8aec150d45aee4e1341d4eea879978552d0` contains the complete scoped implementation; first CI exposed only evidence-label and lifecycle-order defects.
- decision: implemented canonical-source documentation and retained strict live-state/fallback enforcement instead of weakening gates.
- target: the nine paths in the Route Plan target list.

## Data / State Impact

Only documentation, validator code, fixtures, and metadata-only closure claims change. No application or provider state changes.

## Integration Impact

- CLAUDE reports the active capability gate.
- README categories link to live inventories.
- CodeRabbit review is availability-aware and fallback-gated.
- Documentation hygiene rejects the known contradictions.
- Live-state validation reconciles PR #255.
- Project 8 remains blocked.

## Validation Plan

- `bash scripts/enforcement/tests/test-documentation-hygiene.sh` and the canonical checker.
- known-gaps live-state, known-gaps, readiness, and full enforcement suites.
- exact-head policy workflows, artifact inspection, review-thread reconciliation, self-review, and post-merge validation.

## Claude Run Trace

- goal: prevent active documentation from contradicting executable runtime and reviewer state.
- hypothesis: narrow owner-based assertions and negative fixtures prevent recurrence without rewriting history.
- connectors: GitHub and official Anthropic, GitHub Docs, and CodeRabbit sources.
- steps: merge PR #255; inspect main; research; plan first; implement nine paths; synchronize audit; open PR #256; inspect first CI diagnostics.
- evidence: PR #255 head/merge; plan commit `13d6e8456b6c75db03eb31a8393a505adc3e8ac7`; PR #256 head `971cb8aec150d45aee4e1341d4eea879978552d0`; workflow-evidence run 1118 artifact `8530827195`.
- rejected: refreshed hard-coded counts, static reviewer assumptions, generated README churn, historical rewrites, and parallel registries.
- result: implementation is complete; the first external result loop identified evidence chronology and label corrections.

## Definition of Done

- [x] CLAUDE capability wording agrees with the registry.
- [x] Root README has no volatile numeric inventory snapshots in maintained category rows.
- [x] CodeRabbit policy requires current review or structured fallback and prohibits fabricated success.
- [x] Documentation-hygiene validator covers the three invariants on active canonical surfaces.
- [x] Positive and negative fixtures cover runtime, inventory, and reviewer drift.
- [ ] PR #255 live-state claim passes on the implementation branch.
- [x] Registry and audit record progress while the current gap stays open.
- [ ] Focused and full exact-head suites pass.
- [ ] Review findings and threads are reconciled.
- [ ] Owner-approved merge and post-merge validation complete before current-gap closure.

## Progress Lifecycle Evidence

- start: commit `13d6e8456b6c75db03eb31a8393a505adc3e8ac7` recorded exact scope, sources, alternatives, and validation before implementation.
- mid: commit `f361214ad7b6d81d6dc3128ab32d64e9c0a3e758` materially records the completed nine-path implementation and the first CI diagnostic after work began.
- pre-merge: commit `1e4657050e308d2fab905424354e43b923012f47` completed the scoped branch cleanup and preserved canonical navigation; no green-CI, review-clean, or merge-readiness claim is made before the external gates run.
