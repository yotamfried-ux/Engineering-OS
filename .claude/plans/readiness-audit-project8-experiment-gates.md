# Route Plan — Self-Contained Readiness Audit and Project 8 Gates

## Route Plan

| Field | Decision |
|---|---|
| Task type | governance audit / documentation correction / deterministic audit validation |
| Task class | `engineering_os_governance` |
| Domain tags | governance, workflow, observability, security, testing, documentation |
| Plan Scope | standard |
| Planning Mode | user-authorized audit hardening; merge remains subject to separate explicit owner approval |
| Target paths | `.claude/plans/readiness-audit-project8-experiment-gates.md`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`; `scripts/enforcement/check-readiness-audit.sh`; `scripts/enforcement/tests/test-readiness-audit.sh` |
| Task-router evidence | `core/task-router.md` was read; changes to Engineering OS policy, readiness truth, deterministic validators, and target-project adoption are routed as `engineering_os_governance`. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, and `core/coderabbit-policy.md` require plan-first work, source-of-truth checks, result loops, exact-head CI/review, and owner approval before merge. |
| Templates | waiver — no project scaffold owns a focused update to the existing canonical readiness audit, registry, and validator |
| Architecture guides | `docs/operations/runtime-telemetry-archive-plan.md`; `docs/operations/remote-multirepo-telemetry-hooks.md`; `docs/operations/project8-telemetry-preflight.md` |
| Patterns | `patterns/observability/README.md`; `patterns/security/README.md`; `patterns/testing/README.md` |
| External systems/connectors | GitHub |
| Skills | `security-review`; `verification-before-completion`; `writing-plans` |
| Validation gates | enforcement-tests; pr-policy; plan-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; documentation-asset-policy; semantic-cleanup-policy; import-cleanup-policy; telemetry-handoff-tests |
| Evidence to check | `CLAUDE.md`; `core/capability-registry.yaml`; `core/quality-gates.md`; `patterns/README.md`; `patterns/registry.yaml`; Engineering OS PR #254; `yotamfried-ux/project-8/CLAUDE.md@f282f5e9889d956e54fc0803938915fd86a58158`; `yotamfried-ux/project-8/scripts/enforcement/check-no-markdown.py@51970629f3c3af32cb73bea0aab676874478248d`; exact-head Actions and review threads; official Anthropic, GitHub, AWS, Google SRE, OpenTelemetry, Vercel, Supabase, Prisma, Playwright, and W3C documentation |
| User decisions required | no Project 8 behavioral experiment and no experiment prompt until every registered gap is closed, full-readiness validation passes, live state is rechecked, and Yotam explicitly approves the start; explicit Yotam approval also remains required before merge or production changes |

## Goal

Make `docs/operations/operational-readiness-audit.md` independently understandable and executable by a capable LLM or human reviewer with no prior chat context. The audit must explain the system, repositories, terminology, evidence rules, dependency order, gap lifecycle, experiment boundary, and exact closure bars while remaining synchronized with `known-gaps.tsv` and enforced by deterministic tests.

## User Decision Applied

The Project 8 behavioral experiment must not begin merely because the telemetry preflight is available. It remains blocked until every registered gap is `closed`, the full-readiness assertion succeeds, live GitHub state is fresh, and the owner explicitly authorizes the run.

Technical qualification sessions are not the behavioral experiment. They may perform bounded, non-product validation needed to prove hook installation, attribution, transport, archive import, privacy, and repeatability. They must not implement Project 8 features, receive the future workload prompt, or be counted as experiment results.

The Supabase/Vercel migration and full-feature/UI acceptance requirements are the future experiment workload contract. They are not a pre-start readiness defect, because resolving them is the work the future experiment is intended to evaluate.

## Plan

1. Re-read the audit as a context-free LLM and identify every undefined term, hidden assumption, circular dependency, stale claim, and missing source.
2. Add system purpose, repository boundaries, non-negotiable decisions, glossary, source hierarchy, evidence standard, LLM execution procedure, snapshot metadata, and a dependency-ordered closure plan.
3. Separate pre-experiment readiness gaps from the future Project 8 workload acceptance contract.
4. Register missing current gaps: audit self-containment, documentation/runtime state drift, and pattern evidence maturity.
5. Update the canonical checker and fixture suite so the self-contained sections cannot silently disappear.
6. Run exact-head CI and review, fix every real finding, and keep merge owner-gated.

## Alternatives

- Rely on this conversation as context — rejected because chat is not durable or available to another LLM.
- Keep Project 8 workload completion as a pre-start gap — rejected because that would require completing the experiment before starting it.
- Allow the full experiment after only prompt cleanup and telemetry preflight — rejected by the user's explicit decision that every registered gap must be closed first.
- Add a second readiness document — rejected because duplicate ownership would create drift.
- Add prose without validator coverage — rejected because future edits could remove the self-contained contract while CI remained green.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `CLAUDE.md` | read | Defines Engineering OS as a workflow/hooks/patterns/skills framework and says durable rules must live in repository files, not chat. |
| `core/task-router.md` | read | The task is Engineering OS governance and operational-readiness work. |
| `core/workflow.md` | read | Plan-first, evidence-backed result loops and post-merge validation apply. |
| `core/quality-gates.md` | read | Tool evidence, exact current code, tests, and self-review are required; it also contains a stale CodeRabbit availability claim. |
| `core/git-policy.md` | read | Ready-for-review PR, expected head SHA, named CI checks, threads, and owner approval are required. |
| `core/coderabbit-policy.md` | read | External review or a structured fallback must be reconciled before merge. |
| `docs/operations/known-gaps.tsv` | checked | The registry now separates technical qualification from the future Product 8 workload and registers audit self-containment, documentation drift, and pattern maturity. |
| `docs/operations/operational-readiness-audit.md` | checked | The rewritten audit now defines Engineering OS, Project 8, evidence, terminology, dependencies, qualification, experiment blocking, and the future workload contract. |
| `scripts/enforcement/check-readiness-audit.sh` | checked | It now requires the context-free sections and provides strict `--assert-full-ready` semantics. |
| `scripts/enforcement/tests/test-readiness-audit.sh` | checked | It contains positive and negative fixtures for self-containment and full-readiness behavior. |
| `CLAUDE.md` and `core/capability-registry.yaml` | compared | CLAUDE says capability runtime is planned while the registry says runtime is active at the Route Plan/write gate. |
| `README.md` | checked | It says `core/` has 14 policy files although current navigation contains more entries. |
| `core/quality-gates.md` | checked | It says CodeRabbit is not connected despite the active review policy and observed PR reviews. |
| `patterns/README.md` and `patterns/registry.yaml` | checked | All patterns are candidates with no proven active production pattern, creating a maturity gap distinct from registry ownership drift. |
| `yotamfried-ux/project-8/CLAUDE.md@f282f5e9889d956e54fc0803938915fd86a58158` | checked | Current target main still contains local Engineering OS coaching. |
| `yotamfried-ux/project-8/scripts/enforcement/check-no-markdown.py@51970629f3c3af32cb73bea0aab676874478248d` | checked | Project 8 PR #9 adds the product-only Markdown boundary and remains unmerged. |

## Official Documentation Evidence

- Claude Code memory and project instructions: `https://code.claude.com/docs/en/memory`
  - Project `CLAUDE.md` files are persistent context, not hard enforcement.
  - Anthropic recommends specific, concise, structured, consistent instructions and periodic removal of stale or conflicting rules.
  - Decision: the audit must be self-contained, explicit, contradiction-free, and backed by hooks/checkers for non-negotiable behavior.
- Claude Code hooks: `https://code.claude.com/docs/en/hooks`
  - `PreToolUse` blocking requires `exit 2` or a valid deny decision.
  - Decision: hard-hook infrastructure failures must fail closed and qualification sessions must verify installed behavior.
- GitHub status checks and protected branches: `https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks` and `https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches`
  - Required checks and review state belong to exact commits and branches.
  - Decision: audit closure must cite exact live state, not PR prose or stale summaries.
- AWS Well-Architected Operational Excellence: `https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/operational-excellence.html` and `https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/learn-share-and-improve.html`
  - Operational readiness depends on preparation, feedback loops, validated insights, metrics reviews, and shared knowledge.
  - Decision: pattern maturity and readiness claims require real evidence and reproducible feedback, not inventory alone.
- Google SRE monitoring guidance: `https://sre.google/sre-book/monitoring-distributed-systems/` and `https://sre.google/workbook/monitoring/`
  - Monitoring supports rational decisions about system changes and uses multiple evidence signals.
  - Decision: telemetry qualification must prove decision-useful coverage, not merely file creation.
- OpenTelemetry signals and instrumentation: `https://opentelemetry.io/docs/concepts/signals/` and `https://opentelemetry.io/docs/concepts/instrumentation/`
  - Observability requires instrumentation that emits measurable signals.
  - Decision: the audit distinguishes instrumentation presence, transport success, archived evidence, and behavioral conclusions.
- Vercel, Supabase, Prisma, Playwright, and W3C official references remain embedded in the future Project 8 workload acceptance contract.

## Documentation Asset Evidence

- internal: `CLAUDE.md`, `README.md`, `core/capability-registry.yaml`, `core/quality-gates.md`, `core/pattern-lifecycle.md`, `patterns/README.md`, `patterns/registry.yaml`, `docs/operations/operational-readiness-audit.md`, `docs/operations/known-gaps.tsv`, `docs/operations/project8-telemetry-preflight.md`, `docs/operations/remote-multirepo-telemetry-hooks.md`, and `docs/operations/runtime-telemetry-archive-audit-checklist.md`.
- context7: primary official sources were read directly rather than through a library resolver, including `https://code.claude.com/docs/en/memory`, `https://code.claude.com/docs/en/hooks`, `https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks`, `https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/operational-excellence.html`, `https://sre.google/sre-book/monitoring-distributed-systems/`, and `https://opentelemetry.io/docs/concepts/instrumentation/`; no external SDK or library integration is implemented by this governance change.
- decision: the exact internal owner files and primary official references changed the plan by requiring a context-free audit, strict full-readiness mode, qualification/experiment separation, documentation-drift registration, and evidence-backed pattern maturity.

## Template Gap Waiver

reason: this task hardens an existing governance audit and validator; no project scaffold owns or improves the change.

## Capability Evidence

- `routing.task-router-read` — routed as `engineering_os_governance`.
- `workflow.workflow-read` — plan-first evidence and result-loop behavior applied.
- `plan.route-plan-before-write` — commit `26d028f5609ac041aca7655a075669d7a3ee7ced` expanded target paths before checker, test, registry, and audit hardening commits.
- `source.github-repo-read` — GitHub supplied live repository, PR, commit, Actions, and review-thread evidence.
- `validation.policy-change-has-validator` — the self-contained audit contract is enforced by `scripts/enforcement/check-readiness-audit.sh` and its fixture suite.
- `validation.actions-checked` — exact-head run 29888507643 reached the new readiness suite and exposed a real failure; associated policy runs identified Route Plan evidence defects that are corrected here.
- `validation.coderabbit-policy` — all new live review findings remain merge gates.

## Skill Evidence

- `security-review` — applied to hook failure semantics, bypass provenance, secrets, RLS, telemetry privacy, provider identity, and experiment contamination.
- `verification-before-completion` — audit structure, implementation closure, technical qualification, future experiment, and workload outcomes remain separate claims.
- `writing-plans` — the expanded plan preceded the expanded implementation and now records the resulting CI evidence.

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Source of truth for Engineering OS and Project 8 files, PR state, exact head SHAs, workflow conclusions, changed paths, merged history, and review threads. |

## Connector Usage Evidence

- source: GitHub connector for Engineering OS PR #254, Project 8 main, and Project 8 PR #9.
- action: inspected canonical audit, registry, validator, fixtures, entrypoint, capability registry, README, quality-gates policy, pattern lifecycle, pattern inventory, target guidance, exact files on PR #9, current PR state, and exact-head workflows.
- result: `docs/operations/operational-readiness-audit.md`, `docs/operations/known-gaps.tsv`, `scripts/enforcement/check-readiness-audit.sh`, and `scripts/enforcement/tests/test-readiness-audit.sh` now implement the context-free contract; exact head `f670998462372742f2a1c7d5d3b46962e275b8f9` produced enforcement-tests run 1330 and policy runs 1103/1114/752, exposing readiness and Route Plan evidence defects without changing Product 8.
- decision: updated the canonical audit and checker, added the missing gap rows, blocked the behavioral experiment until all gaps close, kept technical qualification separate, and moved Product 8 workload requirements out of the pre-start registry.
- target: `.claude/plans/readiness-audit-project8-experiment-gates.md`, `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-readiness-audit.sh`, and `scripts/enforcement/tests/test-readiness-audit.sh`.

## Template/Pattern Rating Evidence

- asset: `patterns/observability/README.md`
- rating: 4
- confidence: high
- outcome: distinct instrumentation, transport, archive, qualification, and behavioral-analysis layers were retained instead of being conflated.
- decision: keep this pattern for telemetry qualification and evidence separation.

- asset: `patterns/security/README.md`
- rating: 5
- confidence: high
- outcome: fail-closed behavior, secret boundaries, trusted identity, and uncoached-target requirements shaped the closure bars.
- decision: require this pattern for enforcement and target-isolation fixes.

- asset: `patterns/testing/README.md`
- rating: 5
- confidence: high
- outcome: context-free negative fixtures and strict readiness fixtures were added instead of relying on prose review.
- decision: retain this pattern as the validator baseline.

## Data / State Impact

Governance documentation and validator fixtures only. No telemetry bundle, secret, Project 8 database, provider resource, deployment, runtime hook implementation, or application feature is changed.

## Integration Impact

- A new LLM receives an explicit system map, glossary, source hierarchy, execution procedure, and dependency order.
- The checker prevents removal of critical self-contained sections.
- No behavioral experiment may begin while any registered gap remains non-closed.
- Technical qualification sessions are explicitly separated from the behavioral experiment.
- Supabase/Vercel and feature requirements remain preserved as the future experiment workload contract rather than an impossible pre-start gap.

## Validation Plan

- `bash scripts/enforcement/check-known-gaps.sh`
- `bash scripts/enforcement/check-readiness-audit.sh`
- `bash scripts/enforcement/check-documentation-hygiene.sh`
- `bash scripts/enforcement/tests/test-known-gaps.sh`
- `bash scripts/enforcement/tests/test-readiness-audit.sh`
- `bash scripts/enforcement/run-all-tests.sh`
- exact-head GitHub Actions and review-thread inspection
- context-free self-review: answer from the audit alone what the system is, what blocks the experiment, what order to fix, what evidence closes each gap, and what the future workload must do

## Claude Run Trace

- goal: make the canonical readiness audit complete, contradiction-free, and executable without conversation context.
- hypothesis: explicit context, source precedence, evidence semantics, glossary, phases, and deterministic fixture coverage will let a capable LLM continue safely without hidden assumptions.
- connectors: GitHub; official vendor documentation.
- steps: inspect current audit and validator; compare entrypoint/runtime/docs/pattern state; apply owner decision; expand plan scope; update registry, audit, checker, and fixtures; inspect exact-head CI; correct evidence-contract failures; continue experiment-fix-verify until clean.
- evidence: Engineering OS PR #254, commits `26d028f5609ac041aca7655a075669d7a3ee7ced` through `f670998462372742f2a1c7d5d3b46962e275b8f9`, enforcement-tests run 1330, workflow-evidence run 1103, connector-evidence run 1114, documentation-asset run 752, Project 8 exact files, and official references above.
- rejected: conversation-dependent audit; prompt generation now; workload-before-experiment circularity; second audit owner; prose-only guard; weakening failing gates.
- result: the context-free audit is implemented; the latest exact-head result loop exposed readiness and plan-evidence defects that are being corrected before any completion claim.

## Definition of Done

- [x] The user decision is recorded: no behavioral experiment or prompt until every registered gap is closed and strict full-readiness is verified.
- [x] Audit metadata, system context, glossary, source hierarchy, LLM procedure, evidence standard, dependency phases, and future workload boundary are present.
- [x] Missing self-containment, documentation-drift, and pattern-maturity gaps are registered in `docs/operations/known-gaps.tsv`.
- [x] `scripts/enforcement/check-readiness-audit.sh` implements `--assert-full-ready` and validates the context-free contract.
- [x] `scripts/enforcement/tests/test-readiness-audit.sh` names concrete positive and negative fixtures for context loss and non-closed gaps.
- [x] Exact-head enforcement-tests run 1330 and policy runs 1103/1114/752 were inspected; their concrete failures were routed into this correction.

## Live External Gates Before Merge

The task is not complete and this PR must not merge until all named exact-head checks pass on the final head, every live review thread is resolved or reconciled, structured context-free self-review is recorded, the PR body names the final expected head SHA and evidence, and Yotam gives explicit merge approval.

## Progress Lifecycle Evidence

- start: `aad4519e27386c33d5d49f635776e9c78e8e8e04` created the original plan before audit and registry edits; commit `26d028f5609ac041aca7655a075669d7a3ee7ced` expanded the target scope before the new checker and fixture changes.
- middle: commits `67a094f55c1f6d4eb6e3d2c6da57e023b28c1568`, `f186a5ae35d7c45930091d09e7d0275b7e64ae60`, `c40661d27f8ad37d71b8625bb4ac2531677601c2`, and `2318591b7f2ee5181c63a41b99758a34fd200160` implemented checker, fixtures, registry, and audit; formatting repairs landed in `df09ac144acb2da20a2512ab8be4d6babf93ae7e` and `f670998462372742f2a1c7d5d3b46962e275b8f9`.
- pre-merge: exact head `f670998462372742f2a1c7d5d3b46962e275b8f9` was evaluated by enforcement-tests run 1330 and policy runs 1103/1114/752; the failures were inspected and this plan now records concrete sources, documentation evidence, connector decision impact, ratings, verification signals, and lifecycle checkpoints. Merge remains blocked pending the next exact-head run and review.
