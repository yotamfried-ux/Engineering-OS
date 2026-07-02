# Engineering OS Operational Readiness Audit

This audit is the source-of-truth status map for whether Engineering OS can honestly be called operationally ready. It does not replace `CLAUDE.md`; it audits the coverage of the policies that `CLAUDE.md` routes into.

## Readiness statuses

- **Enforced** — deterministic hook, CI, or runtime gate stops non-compliance.
- **Partially enforced** — some deterministic cases are checked, but important judgment or semantic cases remain manual. A matrix row may hold this status only with an explicit `gap:<gap_id>` link to a non-closed row in `docs/operations/known-gaps.tsv`.
- **Manual** — vocabulary term for a documented checklist/review without a hard gate. Plain `Manual` is not a terminal matrix state: a manual row must be classified **Manual by design** with a checklist, or become a tracked gap.
- **Manual by design** — deliberately human: an explicit checklist doc plus required review evidence, never silently skippable, and never faked with an unreliable runtime signal.
- **Waiver-gated** — skipping the requirement is allowed only with explicit waiver evidence.
- **Missing enforcement** — policy exists, but the system can silently skip it. A matrix row may hold this status only with an explicit `gap:<gap_id>` link.
- **Not applicable** — no enforcement expected for this category.

Classification is enforced deterministically by `scripts/enforcement/check-readiness-audit.sh`: unlinked partial rows, plain `Manual` matrix rows, checklist-less Manual-by-design rows, deferred language without a gap link, and non-closed gaps hidden from the matrix all fail CI.

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
| template-pattern-rating-lifecycle | closed | P1 | Template/pattern rating lifecycle. |
| documentation-asset-selection-lifecycle | closed | P1 | Documentation/reference asset selection lifecycle. |
| rtk-semantic-use | closed | P2 | RTK context optimization. |
| graphify-semantic-use | closed | P2 | Graphify context graph. |
| semantic-cleanup-depth | closed | P2 | Cleanup semantic hygiene. |
| review-fallback | closed | P2 | PR review / external review. |
| post-merge-repair-observation | closed | P3 | Post-merge validation. |
| connector-selection-coverage | open | P2 | Connector selection. |
| connector-result-identifiers | open | P2 | Connector correctness / source-of-truth use. |
| template-selection-coverage | open | P2 | Template selection. |
| pattern-required-manifest | open | P2 | Pattern usage. |
| skill-selection-coverage | open | P2 | Skill selection. |
| capability-staged-guard | open | P1 | Capability registry. |
| run-trace-significant-scope | open | P1 | Claude run trace / experiment log. |
| simulation-waiver-fixtures | open | P2 | Positive/negative simulations. |
| tests-tool-environment-contract | open | P2 | Tests/lint before commit. |
| active-plan-selection | open | P1 | Route Plan before writing. |
| pr-review-quality-schema | open | P2 | PR review / external review. |
| merge-readiness-artifact | open | P1 | Git/branch policy and merge safety. |
| install-downstream-behavior | open | P2 | Project install contract. |

## Current status matrix

| Area | Status | What is enforced or checked | Remaining gap |
|---|---|---|---|
| CLAUDE entrypoint and core navigation | Enforced | Gate: enforcement-tests entrypoint wiring. Owner: core-governance. Evidence: CI checks keep `CLAUDE.md`, `core/task-router.md`, and template wiring present; route fixtures run in `test-agent-eval-corpus.sh`. | Route semantic correctness is review-based by design on top of the deterministic wiring and route fixtures. |
| Canonical ownership / no policy sprawl | Enforced | Gate: `check-documentation-hygiene.sh`. Owner: docs-governance. Evidence: documentation ownership manifest, stale/deprecated checks, duplicate ownership checks, and `test-documentation-hygiene.sh`. | Deep semantic contradictions beyond deterministic ownership/deprecation signals are review-based by design: PR reviewers check that a changed policy does not contradict its canonical owner. |
| Enforcement coverage inventory | Enforced | Gate: `check-readiness-audit.sh` plus coverage-map simulation. Owner: ops-readiness. Evidence: CI validates required areas, statuses, gap links, checklist docs, deferred-language bans, gate, owner, evidence markers, and required simulation gates; fixtures in `test-readiness-audit.sh`. | Inventory coverage and row classification are validated deterministically; status accuracy is cross-checked against the known gaps ledger. |
| Audit freshness / status accuracy | Enforced | Gate: `check-known-gaps.sh`. Owner: ops-readiness. Evidence: `docs/operations/known-gaps.tsv` is cross-checked against this audit's Known gaps freshness ledger; missing rows, stale status/priority, duplicate rows, audit-only rows, and closed gaps without test and evidence artifacts fail `test-known-gaps.sh`. | The human decision to close a gap is review-based by design; merged status drift and artifact-free closures are blocked deterministically. |
| Route Plan before writing | Enforced | Gate: pre-tool-use workflow gate. Owner: workflow-governance. Evidence: `test-workflow-evidence.sh` order cases. | gap:active-plan-selection — newest-plan-by-file-time selection can pick the wrong plan in multi-task sessions; target-aware fail-closed selection is registered as an open gap. |
| Route Plan quality | Enforced | Gate: `check-workflow-evidence.sh`. Owner: workflow-governance. Evidence: `test-plan-quality.sh`, `test-plan-semantic-quality.sh`, and `test-workflow-evidence.sh` require concrete Source of Truth evidence for changed targets or canonical sources. | Intent quality beyond reliable path/source matching is review-based by design. |
| DoD completion | Enforced | Gate: plan-policy. Owner: delivery-governance. Evidence: checklist policy checks. | DoD quality is review-based by design; structural checklist completion is blocked deterministically. |
| Progress validation | Enforced | Gate: `check-workflow-evidence.sh`. Owner: progress-governance. Evidence: `test-progress-lifecycle.sh` requires ordered lifecycle commits: start before code/config/test, mid after work begins, and pre-merge after the last code/config/test change. | Deep qualitative meaning of the progress notes is review-based by design; structural backfill is blocked. |
| Connector selection | Partially enforced | Gate: `check-required-connectors.sh`. Owner: connector-governance. Evidence: required connector fields and runtime evidence checks. | gap:connector-selection-coverage — selection rules cover nine connectors; manifest-driven inventory coverage is registered as an open gap. Right-connector judgment stays review-based by design. |
| Connector correctness / source-of-truth use | Partially enforced | Gate: `check-connector-evidence.sh`. Owner: connector-governance. Evidence: Connector Usage Evidence requires source/action/result/decision for declared active connectors and target linkage for code/config/script changes. | gap:connector-result-identifiers — result evidence accepts free prose without concrete identifiers. Deep semantic use of returned connector data is review-based by design; hidden-reasoning proof is never claimed. |
| Template selection | Partially enforced | Gate: template evidence/waiver gates plus template/pattern rating lifecycle. Owner: template-governance. Evidence: Route Plan template fields, waiver checks, `template-pattern-ratings.tsv`, and `test-template-pattern-rating-evidence.sh`. | gap:template-selection-coverage — required-template detection maps eleven of roughly twenty-six inventory templates. |
| Pattern usage | Partially enforced | Gate: pattern read evidence gate plus template/pattern rating lifecycle. Owner: pattern-governance. Evidence: runtime pattern evidence checks, `check-template-pattern-ratings.sh`, and Route Plan rating evidence tests. | gap:pattern-required-manifest — required-pattern detection lacks a registry-driven manifest; read evidence and exact rating feedback are enforced today. |
| Template/pattern rating lifecycle | Enforced | Gate: `check-template-pattern-ratings.sh` and `check-workflow-evidence.sh` rating evidence. Owner: reuse-governance. Evidence: `docs/operations/template-pattern-ratings.tsv`, `test-template-pattern-ratings.sh`, and `test-template-pattern-rating-evidence.sh` require exact declared asset coverage, confidence, outcome, decision, or waiver. | Score truthfulness is review-based by design; missing, partial, extra, or unrelated reusable asset feedback is blocked. |
| Documentation/reference asset selection lifecycle | Enforced | Gate: documentation-asset-policy / `check-documentation-asset-evidence.sh`. Owner: asset-governance. Evidence: `test-documentation-asset-evidence.sh` covers valid evidence, valid waiver, missing fields, and placeholder rejection. | Best-source judgment is review-based by design; structurally skipping documentation/reference asset evidence on code/config/test changes is blocked. |
| Skill selection | Partially enforced | Gate: `check-required-skills.sh`. Owner: skill-governance. Evidence: required-skills and context-skill simulations. | gap:skill-selection-coverage — rules cover five skills; inventory-tied coverage is registered as an open gap. |
| Skill runtime evidence | Enforced | Gate: `pre-tool-use-runtime-evidence.sh`. Owner: skill-governance. Evidence: runtime evidence tests. | Evidence proves recorded activation; deep semantic use is review-based by design. |
| RTK context optimization | Enforced | Gate: `check-required-skills.sh`, blocking `session-setup.sh`, and `check-workflow-evidence.sh` RTK Usage Evidence. Owner: context-governance. Evidence: context-skill selection simulations, `test-rtk-session-blocking.sh`, and `test-rtk-usage-evidence.sh` require prior assumption, finding, impact, target, confidence, limitation, and explicit waiver coverage. | Hidden reasoning is unprovable by design and is never claimed; only auditable external impact evidence is enforced, and generic RTK mentions or missing impact records are blocked. |
| Graphify context graph | Enforced | Gate: `check-plan-scope.sh`. Owner: context-governance. Evidence: `test-graph-use.sh` blocks heading-only graph notes, missing target evidence, and wrong-target graph evidence while allowing structured target-linked graph use. | Qualitative accuracy of the graph finding is review-based by design; structural target linkage is enforced. |
| Claude memory / context carryover | Manual by design | Gate: manual session checklist with required review evidence. Owner: context-governance. Evidence: Checklist: docs/operations/memory-context-checklist.md plus `memory_context_checked_or_waived` capability evidence for context/large-repo task classes. | No reliable cross-environment runtime signal exists, so no runtime check is faked; the checklist requires recorded availability, artifact-cited carryover claims, explicit waivers, and reviewer confirmation. |
| Capability registry | Partially enforced | Gate: capability report and capability evidence policy. Owner: capability-governance. Evidence: capability-evidence-policy plus capability report generator. | gap:capability-staged-guard — a staged-change guard from changed paths to implied capabilities is registered as an open gap. |
| Learning schema | Enforced | Gate: `enforce-learning.sh`. Owner: learning-governance. Evidence: learning enforcement tests. | Schema shape is enforced; content quality is covered by the closure gate. |
| Learning reuse | Enforced | Gate: Route Plan lesson reuse gate. Owner: learning-governance. Evidence: learning reuse checks. | Relevance matching is path/tag based; deep semantic relevance is review-based by design. |
| Learning closure after bug/debug work | Enforced | Gate: `enforce-learning-capture.sh`. Owner: learning-governance. Evidence: `test-learning-capture.sh` and `test-learning-quality-157.sh` require required sections plus concrete root cause, evidence, regression test, prevention, and enforcement/waiver content. | Truthfulness of the closure claim is review-based by design; shallow lesson content is blocked. |
| Claude run trace / experiment log | Partially enforced | Gate: workflow/connector evidence policies. Owner: trace-governance. Evidence: workflow-evidence-policy, connector-evidence-policy, run-trace gate, and direct run-trace waiver fixture coverage. | gap:run-trace-significant-scope — the deterministic definition of a significant agent run and waiver-body validation are registered as an open gap. |
| Positive/negative simulations | Partially enforced | Gate: `check-simulation-coverage.sh`. Owner: validation-governance. Evidence: `simulation-coverage.tsv`, extension rows under `simulation-coverage.d`, `coverage-required-gates.tsv`, and `test-simulation-coverage.sh` reject stale deferred coverage language. | gap:simulation-waiver-fixtures — two waived cells are replaceable with dedicated fixtures, and by-design cells need an explicit non-waivable token. |
| Tests/lint before commit | Partially enforced | Gate: `enforce-tests.sh`. Owner: validation-governance. Evidence: pre-commit and CI enforcement-tests. | gap:tests-tool-environment-contract — a declared stack with a missing tool warns instead of failing, in CI as well; the environment contract is registered as an open gap. |
| Cleanup debug leftovers | Enforced | Gate: `enforce-quality.sh`. Owner: cleanup-governance. Evidence: quality enforcement tests. | None for these narrow cases. |
| Cleanup semantic hygiene | Enforced | Gate: `semantic-cleanup-policy` and `import-cleanup-policy`. Owner: cleanup-governance. Evidence: duplicate-definition policy and stale-reference policy run in CI for PR changes. | Deeper semantic hygiene judgment is review-based by design; structural cases run in CI. |
| Project install contract | Enforced | Gate: use-in-project output contract. Owner: install-governance. Evidence: enforcement-tests install contract. | gap:install-downstream-behavior — downstream runtime behavior in a generated target project beyond contract shape is registered as an open gap. |
| Git/branch policy | Partially enforced | Gate: pr-policy plus hooks. Owner: merge-governance. Evidence: pr-policy, `check-merge-readiness.sh` workflow-run validation, and live GitHub review per Checklist: docs/operations/merge-readiness-checklist.md. | gap:merge-readiness-artifact — deterministic base/head/approval PR-body evidence is registered as an open gap; live GitHub state checks are review-based by design per the merge readiness checklist. |
| PR review / external review | Enforced | Gate: `pr-policy`. Owner: review-governance. Evidence: PR body requires external review evidence or structured self-review evidence. | gap:pr-review-quality-schema — a fixture-tested minimum review-quality schema is registered as an open gap; deep review quality is review-based by design, and missing evidence is blocked. |
| Merge safety | Manual by design | Gate: manual GitHub merge checklist plus `check-merge-readiness.sh` workflow-run evidence. Owner: merge-governance. Evidence: Checklist: docs/operations/merge-readiness-checklist.md covering mergeability, required CI for the exact head SHA, review threads, superseded PRs, and captured human approval. | gap:merge-readiness-artifact — the deterministic PR-body artifact is registered as an open gap; the merge decision itself is human by design and is never automated. |
| Post-merge validation | Enforced | Gate: `post-merge-validation` workflow plus `check-post-merge-validation-contract.sh`. Owner: merge-governance. Evidence: push-to-main validation workflow, failure-triggered repair path, `test-post-merge-validation-contract.sh`, fake-gh repair issue simulation, and Checklist: docs/operations/post-merge-incident-checklist.md for live failures. | Live negative main failures are triaged per the incident checklist and reviewed by a human by design; the repair issue path is simulated deterministically. |
| Known gaps register | Enforced | Gate: `check-known-gaps.sh` plus `check-readiness-audit.sh` gap links. Owner: ops-readiness. Evidence: `docs/operations/known-gaps.tsv`, this audit's Known gaps freshness ledger, `test-known-gaps.sh`, and simulation coverage row `known-gaps-lifecycle`; every non-closed gap must be referenced by a matrix row. | Lifecycle shape, audit freshness, closure artifacts, and matrix linkage are enforced; the human decision to close a gap is review-based by design. |

## Definition of full operational readiness

Engineering OS can only be called fully operationally ready when every policy row is either:

1. **Enforced** by a deterministic hook, CI check, or runtime gate;
2. **Manual by design** with an explicit checklist and required review evidence;
3. **Waiver-gated** so the agent cannot silently skip it; or
4. **Explicitly listed as a gap** with priority, risk, and next action.

Anything merely documented but silently skippable is not operationally ready. This definition is now itself enforced: `check-readiness-audit.sh` fails CI on any matrix row that satisfies none of the four states.

## Highest-priority gaps by ROI

1. **Selection coverage hardening** — gap:connector-selection-coverage, gap:template-selection-coverage, gap:pattern-required-manifest, gap:skill-selection-coverage, and gap:capability-staged-guard move selection rules to inventory-tied manifests with fixtures.
2. **Coverage map hardening** — covered by `coverage-required-gates.tsv`; maintain it whenever new gates are added.
3. **RTK runtime hardening** — covered structurally by required RTK usage impact evidence and mandatory session setup contract; maintain it when RTK signals change.
4. **Route Plan quality gate** — closed structurally by concrete source and target relevance checks; active-plan targeting is tracked as gap:active-plan-selection.
5. **Template/pattern rating lifecycle** — closed structurally by exact declared asset coverage, confidence, outcome, decision, and waiver evidence; score truthfulness remains a review-quality concern.
6. **Learning closure gate** — covered by `enforce-learning-capture.sh`; maintain content-quality fixtures whenever the lesson schema changes.
7. **Progress lifecycle** — covered by ordered progress lifecycle evidence; keep start/mid/pre-merge order tests active for future policy changes.
8. **Graphify context graph** — covered by target-linked graph usage evidence; maintain the negative fixtures when graph evidence policy changes.
9. **Connector correctness** — structural source/action/result evidence is enforced; concrete result identifiers are tracked as gap:connector-result-identifiers.
10. **Simulation completeness** — maintained by `simulation-coverage.tsv`; stale deferred coverage notes are blocked, and replaceable waived cells are tracked as gap:simulation-waiver-fixtures.
11. **Post-merge validation** — covered by safe fake-gh repair issue simulation; live failures are triaged per docs/operations/post-merge-incident-checklist.md.
12. **Documentation hygiene** — covered by `check-documentation-hygiene.sh`; deeper semantic contradiction detection is review-based by design.
13. **Semantic cleanup** — covered by CI policy gates; maintain deeper hygiene checks when analyzers expand.
14. **Trace and test contracts** — gap:run-trace-significant-scope, gap:tests-tool-environment-contract, and gap:active-plan-selection harden run tracing, tool contracts, and plan selection.
15. **Governance evidence** — gap:pr-review-quality-schema, gap:merge-readiness-artifact, and gap:install-downstream-behavior harden review, merge, and install evidence.

## Current audit scope

This audit now enforces its own classification contract: every matrix row is Enforced, Manual by design (with an existing checklist doc), Waiver-gated, or linked to a non-closed known gap, validated by `scripts/enforcement/check-readiness-audit.sh` with fixtures in `scripts/enforcement/tests/test-readiness-audit.sh`. It also includes stricter Route Plan source/target semantic relevance, deterministic known-gaps freshness and closure-artifact validation, ordered progress lifecycle validation, PR review evidence validation, learning closure content validation, exact reusable asset feedback evidence, auditable RTK impact evidence, target-linked Graphify usage validation, cleanup-depth CI policy validation, simulation coverage freshness checks, explicit tracking for documentation/reference asset selection, and safe simulated post-merge repair issue observation. It does not claim hidden chain-of-thought validation beyond reliable path/source/status/commit-order/evidence-field matching.
