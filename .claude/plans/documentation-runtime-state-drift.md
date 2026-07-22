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
| Task-router evidence | `core/task-router.md` routes changes to entrypoints, core policy, validators, and readiness sources as `engineering_os_governance`. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, `core/documentation-policy.md`, and `core/coderabbit-policy.md` require plan-first work, canonical ownership, negative fixtures, exact-head review, owner approval, and post-merge proof. |
| Templates | waiver — this is a focused extension of existing canonical documentation and enforcement paths, not a scaffolded product surface |
| Architecture guides | `core/documentation-policy.md`; `docs/operations/documentation-ownership.tsv`; `docs/operations/operational-readiness-audit.md` |
| Patterns | none — the task changes canonical documentation consistency enforcement rather than an application implementation domain |
| External systems/connectors | GitHub |
| Skills | `verification-before-completion`; `writing-plans` |
| Validation gates | documentation-hygiene fixtures; current canonical manifest; known-gaps; readiness audit; enforcement-tests; documentation-asset-policy; plan/workflow/connector/capability policies; cleanup policies; telemetry-handoff-tests; known-gaps-live-state; live review threads; post-merge validation |
| Evidence to check | `CLAUDE.md`; `README.md`; `core/capability-registry.yaml`; `core/coderabbit-policy.md`; `scripts/enforcement/check-documentation-hygiene.sh`; `scripts/enforcement/tests/test-documentation-hygiene.sh`; merged PR #255 head `97d56e2f5743b019145da600cf0914f6d092cd0f`; merge `0ee2dbee7a9ab58e86a11726021c30baca0faa22`; official Anthropic memory docs; official GitHub Docs repository content-linter code; official CodeRabbit configuration/review docs |
| User decisions required | keep the Project 8 behavioral experiment and prompt blocked; do not merge this implementation PR without a later explicit owner decision |

## Goal

Make canonical entrypoints describe executable runtime truth instead of copied snapshots. Reconcile the active capability write-gate, remove hand-maintained inventory counts from the root README, make CodeRabbit policy depend on live review availability with an exact structured fallback, and add deterministic negative fixtures that block the known contradictions from returning.

The same PR also adds a live claim for merged PR #255. `audit-live-state-verification` may close only if the dedicated workflow proves its exact reviewed head, merge commit, base containment, newest PR workflows, push workflows, and required check run. `documentation-runtime-state-drift` remains open until this PR is merged and validated on `main`.

## Non-negotiable behavior

1. `core/capability-registry.yaml` remains canonical for capability runtime status and scope.
2. `README.md` explains inventory categories but does not duplicate volatile numeric counts.
3. `core/coderabbit-policy.md` requires a live availability/result check: use CodeRabbit evidence when observed; otherwise require the existing structured fallback and never pretend a reviewer ran.
4. `CLAUDE.md` remains a slim pointer and does not define a competing runtime model.
5. Documentation consistency is enforced by a deterministic checker with positive and negative fixtures.
6. Historical plans/research may retain dated observations; active entrypoints, policies, registries, and audit state must agree with live executable truth.
7. No Project 8 code, prompt, provider state, secret, deployment, DNS, database, or production resource changes.
8. Gap closure requires implementation, fixtures, exact-head CI, review, owner-approved merge, and post-merge proof.

## Plan

1. Reconcile the CLAUDE capability row with `runtime_enabled: true` and `runtime_scope: plan_level_write_gate`.
2. Remove volatile numeric inventory counts from root README descriptions rather than replacing them with another hand-maintained snapshot.
3. Align CodeRabbit policy with capability evidence: live CodeRabbit review when available, structured external/manual fallback when unavailable, and explicit no-fabrication language.
4. Extend `check-documentation-hygiene.sh` with canonical runtime assertions and entrypoint stale-claim detection.
5. Extend `test-documentation-hygiene.sh` with fixtures for planned-vs-active capability drift, hard-coded README inventory counts, and unconditional/false CodeRabbit availability claims.
6. Search canonical entrypoints for equivalent active contradictions and correct only verified current-state defects.
7. Add the PR #255 live-state claim; close `audit-live-state-verification` only if live CI accepts it.
8. Update registry/audit progress without closing `documentation-runtime-state-drift` before its own merge/post-merge proof.
9. Run focused and full suites, open a ready-for-review PR, reconcile every valid finding, and keep merge owner-gated.

## Alternatives

- Replace `14` with the current count — rejected because the next file addition recreates drift.
- Generate README counts during every run — rejected for this small descriptive inventory because the numbers add little operational value and introduce generated-file churn.
- Treat CodeRabbit as permanently available — rejected because installation, auto-review configuration, service state, and PR eligibility are external and live.
- Treat CodeRabbit as permanently unavailable — rejected because PR #255 contains observed CodeRabbit review findings and official configuration supports automatic/manual review.
- Add a second documentation-state manifest — rejected because capability registry, README category descriptions, CodeRabbit policy, and the existing ownership manifest already have canonical owners.
- Scan every historical plan for dated wording — rejected because plans are temporary evidence; the gate targets active canonical surfaces and explicitly avoids rewriting history.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `core/task-router.md` | read | Entrypoint, core policy, validator, and readiness changes route as Engineering OS governance. |
| `core/workflow.md` | read | Plan-first result loops and exact evidence apply. |
| `core/documentation-policy.md` | read | Durable ideas have one canonical owner; deterministic policy changes need regression coverage. |
| `core/capability-registry.yaml` | checked | Runtime is enabled and scoped to `plan_level_write_gate`; `runtime planned` is stale. |
| `CLAUDE.md` | checked | Capability row contradicts the registry and CodeRabbit wording assumes one reviewer path. |
| `README.md` | checked | Multiple inventory rows contain volatile hand-maintained counts; the core count is already stale and the skills row count/list disagree. |
| `core/coderabbit-policy.md` | checked | It requires waiting for CodeRabbit without the fallback already permitted by capability evidence. |
| `scripts/enforcement/check-documentation-hygiene.sh` | checked | It validates ownership/path lifecycle but not runtime-state contradictions. |
| `scripts/enforcement/tests/test-documentation-hygiene.sh` | checked | Existing fixtures do not cover stale runtime claims, inventory counts, or reviewer-availability claims. |
| PR #255 | checked | Exact head passed all required PR gates; CodeRabbit findings were observed and resolved; merge commit is `0ee2dbee7a9ab58e86a11726021c30baca0faa22`. |
| `github/docs` content linter | read | GitHub registers custom deterministic documentation rules and includes a single-source rule against hard-coded data phrases. |
| Anthropic Claude Code memory docs | read | Project `CLAUDE.md` is shared, automatically loaded instruction context, so stale active-state wording can misroute later sessions. |
| CodeRabbit official docs | read | Review availability/configuration is external, configurable, and may be automatic or manually triggered; repository YAML is only one of several configuration sources. |

## Official Documentation Evidence

- `https://code.claude.com/docs/en/memory` — project memory is shared instruction context and should stay specific, organized, and current.
- `https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes` — README is the repository's primary orientation surface.
- `https://docs.coderabbit.ai/guides/code-review-overview` — reviews begin after repository integration and continue on eligible PR updates.
- `https://docs.coderabbit.ai/configuration/auto-review` — automatic review is configurable and manual `@coderabbitai review` remains available.
- `https://docs.coderabbit.ai/guides/configuration-overview` — repository, central, organization, and file-based settings have explicit precedence, so file absence alone does not prove unavailability.

## Official Repository Evidence

- `github/docs/src/content-linter/lib/linting-rules/index.ts` — GitHub registers custom documentation rules as executable lint checks.
- `github/docs/src/content-linter/lib/linting-rules/hardcoded-data-variable.ts` — GitHub's single-source rule rejects duplicated hard-coded product data in documentation.
- `anthropics/claude-code` — official Claude Code repository confirms the maintained product/runtime context used by the official memory documentation.

## Documentation Asset Evidence

- internal: `CLAUDE.md`, `README.md`, `core/documentation-policy.md`, `core/capability-registry.yaml`, `core/coderabbit-policy.md`, `docs/operations/documentation-ownership.tsv`, `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-documentation-hygiene.sh`, and `scripts/enforcement/tests/test-documentation-hygiene.sh`.
- context7: `https://code.claude.com/docs/en/memory`, `https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes`, `https://docs.coderabbit.ai/guides/code-review-overview`, `https://docs.coderabbit.ai/configuration/auto-review`, `https://github.com/github/docs`, and `https://github.com/anthropics/claude-code` were read directly; no third-party SDK is introduced.
- decision: use canonical executable state, remove low-value volatile counts, model external reviewer availability as a live evidence branch, and enforce the invariant with local fixtures.

## Template Gap Waiver

reason: this task changes established canonical governance files and an existing documentation-hygiene validator; no project template or scaffold owns the change.

## Capability Evidence

- `routing.task-router-read` — routed as `engineering_os_governance`.
- `workflow.workflow-read` — plan-first result loops and post-merge proof apply.
- `plan.route-plan-before-write` — this file is committed before any target documentation, checker, fixture, registry, or audit write.
- `source.github-repo-read` — exact main files, PR #255 state, and official repositories were inspected.
- `validation.policy-change-has-validator` — planned policy/documentation changes include deterministic negative fixtures.
- `validation.actions-checked` — exact-head and live-state workflows remain completion gates.
- `validation.coderabbit-policy` — observed CodeRabbit findings and fallback semantics are both reconciled rather than assumed.

## Skill Evidence

- `verification-before-completion` — stale claim discovery, implementation, fixture validation, exact-head CI, review, merge, and post-merge closure remain separate claims.
- `writing-plans` — exact targets, alternatives, official sources, validator behavior, and lifecycle gates were recorded before writes.

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Read exact canonical files on merged main, verified PR #255 head/merge/review state, inspected official GitHub and Anthropic repositories, and will supply exact Actions/review evidence for this branch. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, `github/docs`, and `anthropics/claude-code`.
- action: verified PR #255 and `main`; read canonical runtime/documentation/review sources; inspected official documentation-linter code; created this plan-first branch.
- result: branch `fix/documentation-runtime-state-drift` starts at merge `0ee2dbee7a9ab58e86a11726021c30baca0faa22`; exact target contradictions are listed in Source of Truth Checks.
- decision: selected removal of volatile inventory counts, active runtime wording sourced from the registry, and a live CodeRabbit-or-fallback policy with deterministic regression checks.
- target: `.claude/plans/documentation-runtime-state-drift.md`; `CLAUDE.md`; `README.md`; `core/coderabbit-policy.md`; `scripts/enforcement/check-documentation-hygiene.sh`; `scripts/enforcement/tests/test-documentation-hygiene.sh`; `docs/operations/live-state-claims.json`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`.

## Data / State Impact

Documentation, validator code, fixtures, and metadata-only gap claims change. No application data, secret value, Project 8 product code, provider resource, deployment, DNS, database, or production state changes.

## Integration Impact

- Always-loaded `CLAUDE.md` will describe the capability gate accurately.
- Root README will stop presenting volatile inventory snapshots as durable truth.
- CodeRabbit remains the preferred observed external reviewer, but unavailable/skipped review is handled through the existing structured fallback instead of fabricated success or indefinite blocking.
- Documentation hygiene will fail on reintroduced contradictions.
- The canonical live-state path will reconcile PR #255 before closing its implementation gap.
- Project 8 experiment remains blocked.

## Validation Plan

- `bash scripts/enforcement/tests/test-documentation-hygiene.sh`.
- `bash scripts/enforcement/check-documentation-hygiene.sh` against the repository root.
- `bash scripts/enforcement/tests/test-known-gaps-live-state.sh`, known-gaps, and readiness suites.
- `bash scripts/enforcement/run-all-tests.sh` through `enforcement-tests`.
- exact-head documentation, plan, workflow, connector, capability, cleanup, telemetry, pr-policy, and known-gaps-live-state workflows.
- live artifact inspection, review-thread reconciliation, structured self-review, and post-merge validation after any separately authorized merge.

## Claude Run Trace

- goal: prevent always-loaded and first-read documentation from contradicting executable runtime and external review state.
- hypothesis: canonical-source assertions plus negative fixtures catch stale active-state wording while removing volatile inventory snapshots prevents recurring count drift.
- connectors: GitHub; official Anthropic, GitHub Docs, and CodeRabbit sources.
- steps: merge PR #255; verify main; inspect active entrypoints and executable owners; research official docs/repos; create plan-first branch.
- evidence: PR #255 head `97d56e2f5743b019145da600cf0914f6d092cd0f`, merge `0ee2dbee7a9ab58e86a11726021c30baca0faa22`, canonical file SHAs, and official sources above.
- rejected: replacing stale numbers with new numbers, assuming CodeRabbit permanently connected/disconnected, rewriting historical plans, and creating parallel state owners.
- result: planning and source reconciliation are complete; implementation has not started.

## Definition of Done

- [ ] CLAUDE capability runtime wording is derived from and consistent with the registry.
- [ ] Root README contains no volatile numeric inventory counts for maintained directories.
- [ ] CodeRabbit policy requires live observed review or a concrete structured fallback, never fabricated availability.
- [ ] Documentation-hygiene validator enforces all three invariants and limits checks to canonical active surfaces.
- [ ] Positive and negative fixtures cover runtime status, inventory counts, and reviewer availability.
- [ ] PR #255 live-state claim passes and `audit-live-state-verification` closes with exact evidence.
- [ ] Registry and audit record progress without prematurely closing this implementation gap.
- [ ] Focused and full test suites pass on the final exact head.
- [ ] External review findings are reconciled and all threads are resolved.
- [ ] Merge remains blocked until explicit owner approval; post-merge validation is required before closure.

## Progress Lifecycle Evidence

- start: this plan is the first branch write and records exact scope, source hierarchy, alternatives, official documentation, official repository examples, and validation strategy before implementation.
- mid: not reached; will record the implementation and focused fixture checkpoint after target writes.
- pre-merge: not reached; will record exact-head CI, artifact, review, and self-review evidence before requesting owner approval.
