# Engineering OS Operational Readiness Audit

This audit is the source-of-truth status map for whether Engineering OS can honestly be called operationally ready. It does not replace `CLAUDE.md`; it audits the coverage of the policies that `CLAUDE.md` routes into.

## Readiness statuses

- **Enforced** — deterministic hook, CI, or runtime gate stops non-compliance.
- **Partially enforced** — some deterministic cases are checked, but important judgment or semantic cases remain manual.
- **Manual** — documented checklist/review exists, but no hard gate.
- **Waiver-gated** — skipping the requirement is allowed only with explicit waiver evidence.
- **Missing enforcement** — policy exists, but the system can silently skip it.
- **Not applicable** — no enforcement expected for this category.

## Coverage contract

This file is the coverage inventory for operational readiness. CI must fail if this audit stops covering one of the required areas below, because without a complete inventory the project cannot honestly claim full operational readiness.

Required coverage groups:

- Entry/navigation: `CLAUDE.md`, `core/`, canonical ownership.
- Planning/routing: Route Plan, task class, domain tags, DoD, evidence, progress validation.
- Selection/runtime: skills, templates, patterns, connectors, RTK, graphify, memory/context.
- Validation: tests, simulations, logs, CI, run trace, post-merge validation.
- Learning: root cause, lesson, failed-solution, prevention update or waiver.
- Governance: branch/PR/review/external review, merge approval, documentation cleanup, known gaps.

Coverage matrix contract: every row must name `Gate:`, `Owner:`, and `Evidence:` in the enforcement cell. If the gate is manual or missing, the evidence must name the manual review or gap evidence instead of being blank.

## Known gaps freshness ledger

This ledger is intentionally duplicated from `docs/operations/known-gaps.tsv` only for freshness enforcement. `scripts/enforcement/check-known-gaps.sh` fails CI if any `gap_id`, `status`, or `priority` here drifts from the TSV source of truth.

| gap_id | status | priority | audit row / readiness context |
|---|---|---|---|
| audit-freshness | closed | P0 | Audit freshness / status accuracy. |
| route-plan-semantic-quality | closed | P1 | Route Plan quality. |
| connector-semantic-use | closed | P1 | Connector correctness / source-of-truth use. |
| progress-semantic-lifecycle | closed | P1 | Progress validation. |
| learning-semantic-closure | closed | P1 | Learning closure after bug/debug work. |
| template-pattern-rating-lifecycle | mitigated | P1 | Template/pattern rating lifecycle. |
| documentation-asset-selection-lifecycle | open | P1 | Documentation/reference asset selection lifecycle. |
| rtk-semantic-use | mitigated | P2 | RTK context optimization. |
| graphify-semantic-use | closed | P2 | Graphify context graph. |
| semantic-cleanup-depth | closed | P2 | Cleanup semantic hygiene. |
| review-fallback | closed | P2 | PR review / external review. |
| post-merge-repair-observation | closed | P3 | Post-merge validation. |

## Current status matrix

| Area | Status | What is enforced or checked | Remaining gap |
|---|---|---|---|
| CLAUDE entrypoint and core navigation | Enforced | Gate: enforcement-tests entrypoint wiring. Owner: core-governance. Evidence: CI checks keep `CLAUDE.md`, `core/task-router.md`, and template wiring present. | Semantic correctness of every route still needs review. |
| Canonical ownership / no policy sprawl | Enforced | Gate: `check-documentation-hygiene.sh`. Owner: docs-governance. Evidence: documentation ownership manifest, stale/deprecated checks, duplicate ownership checks, and `test-documentation-hygiene.sh`. | Deep semantic contradictions that do not touch deterministic ownership/deprecation signals still require review. |
| Enforcement coverage inventory | Enforced | Gate: readiness audit validator plus coverage-map simulation. Owner: ops-readiness. Evidence: CI validates required areas, statuses, priority gaps, gate, owner, evidence markers, and required simulation gates. | CI proves inventory coverage exists; status accuracy is cross-checked against the known gaps ledger. |
| Audit freshness / status accuracy | Enforced | Gate: `check-known-gaps.sh`. Owner: ops-readiness. Evidence: `docs/operations/known-gaps.tsv` is cross-checked against this audit's Known gaps freshness ledger; missing rows, stale status/priority, duplicate rows, and audit-only rows fail `test-known-gaps.sh`. | Deep judgment about whether a human should close a gap still requires review, but merged status drift is blocked deterministically. |
| Route Plan before writing | Enforced | Gate: pre-tool-use workflow gate. Owner: workflow-governance. Evidence: `test-workflow-evidence.sh` order cases. | Active-plan selection can still be semantically wrong in complex multi-task sessions. |
| Route Plan quality | Enforced | Gate: `check-workflow-evidence.sh`. Owner: workflow-governance. Evidence: `test-plan-quality.sh`, `test-plan-semantic-quality.sh`, and `test-workflow-evidence.sh` require concrete Source of Truth evidence for changed targets or canonical sources. | Intent quality still needs review beyond reliable path/source matching. |
| DoD completion | Enforced | Gate: plan-policy. Owner: delivery-governance. Evidence: checklist policy checks. | DoD quality is judgment-based. |
| Progress validation | Enforced | Gate: `check-workflow-evidence.sh`. Owner: progress-governance. Evidence: `test-progress-lifecycle.sh` requires ordered lifecycle commits: start before code/config/test, mid after work begins, and pre-merge after the last code/config/test change. | Deep qualitative meaning of the progress notes still needs review, but structural backfill is blocked. |
| Connector selection | Partially enforced | Gate: `check-required-connectors.sh`. Owner: connector-governance. Evidence: required connector fields and runtime evidence checks. | Need broader task-class coverage as new connector-backed systems are added. |
| Connector correctness / source-of-truth use | Partially enforced | Gate: `check-connector-evidence.sh`. Owner: connector-governance. Evidence: Connector Usage Evidence requires source/action/result/decision for declared active connectors and target linkage for code/config/script changes. | Structural influence evidence is enforced; the system still cannot fully prove deep semantic use of returned connector data. |
| Template selection | Partially enforced | Gate: template evidence/waiver gates plus template/pattern rating lifecycle. Owner: template-governance. Evidence: Route Plan template fields, waiver checks, `template-pattern-ratings.tsv`, and `test-template-pattern-rating-evidence.sh`. | Required-template detection by task class/domain still needs expansion; long-term rating quality still needs review. |
| Pattern usage | Partially enforced | Gate: pattern read evidence gate plus template/pattern rating lifecycle. Owner: pattern-governance. Evidence: runtime pattern evidence checks, `check-template-pattern-ratings.sh`, and Route Plan rating evidence tests. | Domain detection is path/name based and incomplete; rating quality is structural, not fully semantic. |
| Template/pattern rating lifecycle | Partially enforced | Gate: `check-template-pattern-ratings.sh` and `check-workflow-evidence.sh` rating evidence. Owner: reuse-governance. Evidence: `docs/operations/template-pattern-ratings.tsv`, `test-template-pattern-ratings.sh`, and `test-template-pattern-rating-evidence.sh`. | Ratings are required structurally; deciding whether a score is truly accurate still requires review and future outcome data. |
| Documentation/reference asset selection lifecycle | Missing enforcement | Gate: known-gaps register. Owner: asset-governance. Evidence: `documentation-asset-selection-lifecycle` tracks missing deterministic selection evidence for project planning docs, architecture docs, integration docs, deployment docs, and domain reference docs. | Route Plans can still skip important documentation assets unless a future gate requires documentation asset evidence or waiver. |
| Skill selection | Partially enforced | Gate: `check-required-skills.sh`. Owner: skill-governance. Evidence: required-skills and context-skill simulations. | Coverage must expand as new task classes and skills are added. |
| Skill runtime evidence | Enforced | Gate: `pre-tool-use-runtime-evidence.sh`. Owner: skill-governance. Evidence: runtime evidence tests. | Evidence proves recorded activation, not deep semantic use. |
| RTK context optimization | Partially enforced | Gate: `check-required-skills.sh`, blocking `session-setup.sh`, and `check-workflow-evidence.sh` RTK Usage Evidence. Owner: context-governance. Evidence: context-skill selection simulations, `test-rtk-session-blocking.sh`, and `test-rtk-usage-evidence.sh`. | Evidence now requires structural RTK source/action/result/decision impact for RTK-declared code changes; deeper semantic proof of actual reasoning impact remains future work. |
| Graphify context graph | Enforced | Gate: `check-plan-scope.sh`. Owner: context-governance. Evidence: `test-graph-use.sh` blocks heading-only graph notes, missing target evidence, and wrong-target graph evidence while allowing structured target-linked graph use. | No remaining structural Graphify-use gap; qualitative accuracy of the graph finding still needs reviewer judgment. |
| Claude memory / context carryover | Manual | Gate: manual workflow checklist. Owner: context-governance. Evidence: manual session review evidence and known-gaps manifest entry. | Runtime availability and evidence are not hard-checked across all environments. |
| Capability registry | Partially enforced | Gate: capability report and capability evidence policy. Owner: capability-governance. Evidence: capability-evidence-policy plus capability report generator. | Registry-to-runtime enforcement is still plan-level and needs stronger staged-change guards. |
| Learning schema | Enforced | Gate: `enforce-learning.sh`. Owner: learning-governance. Evidence: learning enforcement tests. | Schema shape is enforced; content quality is covered by the closure gate. |
| Learning reuse | Enforced | Gate: Route Plan lesson reuse gate. Owner: learning-governance. Evidence: learning reuse checks. | Relevance is path/tag based, not deep semantic code understanding. |
| Learning closure after bug/debug work | Enforced | Gate: `enforce-learning-capture.sh`. Owner: learning-governance. Evidence: `test-learning-capture.sh` and `test-learning-quality-157.sh` require required sections plus concrete root cause, evidence, regression test, prevention, and enforcement/waiver content. | No remaining structural learning closure gap; truthfulness of the claim still needs reviewer judgment. |
| Claude run trace / experiment log | Partially enforced | Gate: workflow/connector evidence policies. Owner: trace-governance. Evidence: workflow-evidence-policy and connector-evidence-policy. | Not all significant agent runs are forced yet. |
| Positive/negative simulations | Partially enforced | Gate: `check-simulation-coverage.sh`. Owner: validation-governance. Evidence: `simulation-coverage.tsv`, extension rows under `simulation-coverage.d/`, `coverage-required-gates.tsv`, and `test-simulation-coverage.sh`. | Required gates are manifest-backed; remaining work is replacing explicit coverage waivers with dedicated fixtures where feasible. |
| Tests/lint before commit | Partially enforced | Gate: `enforce-tests.sh`. Owner: validation-governance. Evidence: pre-commit and CI enforcement-tests. | Missing tools can warn rather than fully fail in all ecosystems. |
| Cleanup debug leftovers | Enforced | Gate: `enforce-quality.sh`. Owner: cleanup-governance. Evidence: quality enforcement tests. | None for these narrow cases. |
| Cleanup semantic hygiene | Enforced | Gate: `semantic-cleanup-policy` and `import-cleanup-policy`. Owner: cleanup-governance. Evidence: duplicate-definition policy and stale-reference policy run in CI for PR changes. | No remaining structural cleanup-depth gap; deeper semantic judgment still needs review. |
| Project install contract | Enforced | Gate: use-in-project output contract. Owner: install-governance. Evidence: enforcement-tests install contract. | Validates contract shape, not every downstream behavior. |
| Git/branch policy | Partially enforced | Gate: pr-policy plus hooks. Owner: merge-governance. Evidence: pr-policy and live GitHub review. | GitHub connector operations and PR state still require live checks. |
| PR review / external review | Enforced | Gate: `pr-policy`. Owner: review-governance. Evidence: PR body requires external review evidence or structured self-review evidence. | Deep review quality still requires reviewer judgment, but missing evidence is blocked. |
| Merge safety | Manual | Gate: manual GitHub merge checklist. Owner: merge-governance. Evidence: mergeability, checks, threads, expected SHA evidence. | Requires live GitHub/PR checks and human approval. |
| Post-merge validation | Enforced | Gate: `post-merge-validation` workflow plus `check-post-merge-validation-contract.sh`. Owner: merge-governance. Evidence: push-to-main validation workflow, failure-triggered repair path, `test-post-merge-validation-contract.sh`, and fake-gh repair issue simulation. | The repair issue path is simulated safely; actual live negative main failures should still be reviewed when they occur. |
| Known gaps register | Enforced | Gate: `check-known-gaps.sh`. Owner: ops-readiness. Evidence: `docs/operations/known-gaps.tsv`, this audit's Known gaps freshness ledger, `test-known-gaps.sh`, and simulation coverage row `known-gaps-lifecycle`. | Lifecycle shape and audit freshness are enforced; the human decision to close a gap still needs review. |

## Definition of full operational readiness

Engineering OS can only be called fully operationally ready when every policy row is either:

1. **Enforced** by a deterministic hook, CI check, or runtime gate;
2. **Manual by design** with an explicit checklist and required review evidence;
3. **Waiver-gated** so the agent cannot silently skip it; or
4. **Explicitly listed as a gap** with priority, risk, and next action.

Anything merely documented but silently skippable is not operationally ready.

## Highest-priority gaps by ROI

1. **Documentation/reference asset selection** — add a deterministic gate for planning docs, architecture docs, integration docs, deployment docs, and domain reference docs.
2. **Coverage map hardening** — covered by `coverage-required-gates.tsv`; maintain it whenever new gates are added.
3. **RTK runtime hardening** — partially covered by RTK Usage Evidence; remaining work is deeper semantic proof of actual reasoning impact where reliable signals become available.
4. **Route Plan quality gate** — closed structurally by concrete source and target relevance checks; maintain it as policy evolves.
5. **Template/pattern rating lifecycle** — partially covered by ratings manifest and Route Plan rating evidence; remaining work is long-term score accuracy from real outcomes and wider asset coverage.
6. **Learning closure gate** — covered by `enforce-learning-capture.sh`; maintain content-quality fixtures whenever the lesson schema changes.
7. **Progress lifecycle** — covered by ordered progress lifecycle evidence; keep start/mid/pre-merge order tests active for future policy changes.
8. **Graphify context graph** — covered by target-linked graph usage evidence; maintain the negative fixtures when graph evidence policy changes.
9. **Connector correctness** — extend structural source/action/result evidence into deeper semantic proof of connector use when reliable signals become available.
10. **Simulation completeness** — maintained by `simulation-coverage.tsv`; remaining work is to replace explicit coverage waivers with dedicated fixtures where feasible.
11. **Post-merge validation** — covered by safe fake-gh repair issue simulation; keep observing future live negative main failures when they occur.
12. **Documentation hygiene** — covered by `check-documentation-hygiene.sh`; remaining work is deeper semantic contradiction detection beyond deterministic ownership/deprecation signals.
13. **Semantic cleanup** — covered by CI policy gates; maintain deeper hygiene checks when analyzers expand.

## Current audit scope

This audit now includes stricter Route Plan source/target semantic relevance, deterministic known-gaps freshness validation, ordered progress lifecycle validation, PR review evidence validation, learning closure content validation, target-linked Graphify usage validation, cleanup-depth CI policy validation, explicit tracking for documentation/reference asset selection, and safe simulated post-merge repair issue observation. It does not claim full intent-level validation beyond reliable path/source/status/commit-order/evidence-field matching.
