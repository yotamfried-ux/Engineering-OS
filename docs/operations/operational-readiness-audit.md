# Engineering OS Operational Readiness Audit

This audit is the source-of-truth status map for whether Engineering OS can honestly be called operationally ready.

## Readiness statuses

- **Enforced** — deterministic hook, CI, or runtime gate stops non-compliance.
- **Partially enforced** — deterministic subset exists, but the remaining gap is tracked with `gap:<gap_id>`.
- **Manual** — vocabulary term only; plain Manual is not a terminal matrix state.
- **Manual by design** — human checklist and required review evidence.
- **Waiver-gated** — explicit waiver evidence is required.
- **Missing enforcement** — policy exists but can be skipped; must link a gap.
- **Not applicable** — no enforcement expected.

## Coverage contract

This file inventories operational-readiness coverage. Every row must remain classified as Enforced, Manual by design, Waiver-gated, Not applicable, or gap-linked.

## Known gaps freshness ledger

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
| connector-selection-coverage | closed | P2 | Connector selection. |
| connector-result-identifiers | closed | P2 | Connector correctness / source-of-truth use. |
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
| CLAUDE entrypoint and core navigation | Enforced | Gate: entrypoint wiring. Owner: core-governance. Evidence: CLAUDE/core checks. | Route semantics remain review-based by design. |
| Canonical ownership / no policy sprawl | Enforced | Gate: documentation hygiene. Owner: docs-governance. Evidence: ownership manifest tests. | Semantic contradiction review remains human. |
| Enforcement coverage inventory | Enforced | Gate: readiness audit. Owner: ops-readiness. Evidence: check-readiness-audit and fixtures. | Classification contract is enforced. |
| Audit freshness / status accuracy | Enforced | Gate: known gaps checker. Owner: ops-readiness. Evidence: known-gaps tests. | Closure decision remains review-based. |
| Route Plan before writing | Enforced | Gate: workflow gate. Owner: workflow-governance. Evidence: workflow tests. | gap:active-plan-selection — target-aware plan selection remains open. |
| Route Plan quality | Enforced | Gate: workflow evidence. Owner: workflow-governance. Evidence: semantic source tests. | Intent quality remains review-based. |
| DoD completion | Enforced | Gate: plan policy. Owner: delivery-governance. Evidence: checklist gate. | DoD quality remains review-based. |
| Progress validation | Enforced | Gate: workflow evidence. Owner: progress-governance. Evidence: lifecycle tests. | Qualitative note meaning remains review-based. |
| Connector selection | Enforced | Gate: required connectors. Owner: connector-governance. Evidence: connector-selection-rules.tsv plus inventory coverage tests. | Right-connector judgment remains review-based by design. |
| Connector correctness / source-of-truth use | Enforced | Gate: connector evidence. Owner: connector-governance. Evidence: source/action/result/decision, result identifiers, target linkage tests. | Deep semantic use remains review-based. |
| Template selection | Partially enforced | Gate: template evidence. Owner: template-governance. Evidence: template waiver and rating tests. | gap:template-selection-coverage — template inventory manifest is still open. |
| Pattern usage | Partially enforced | Gate: pattern evidence. Owner: pattern-governance. Evidence: rating lifecycle tests. | gap:pattern-required-manifest — required-pattern manifest is still open. |
| Template/pattern rating lifecycle | Enforced | Gate: rating lifecycle. Owner: reuse-governance. Evidence: template-pattern rating tests. | Score truthfulness remains review-based. |
| Documentation/reference asset selection lifecycle | Enforced | Gate: documentation asset policy. Owner: asset-governance. Evidence: documentation asset tests. | Best-source judgment remains review-based. |
| Skill selection | Partially enforced | Gate: required skills. Owner: skill-governance. Evidence: skill selection tests. | gap:skill-selection-coverage — skill inventory coverage is still open. |
| Skill runtime evidence | Enforced | Gate: runtime evidence. Owner: skill-governance. Evidence: runtime evidence tests. | Deep semantic use remains review-based. |
| RTK context optimization | Enforced | Gate: RTK evidence. Owner: context-governance. Evidence: RTK usage tests. | Hidden reasoning is not claimed. |
| Graphify context graph | Enforced | Gate: graph scope. Owner: context-governance. Evidence: graph target-link tests. | Graph finding accuracy remains review-based. |
| Claude memory / context carryover | Manual by design | Gate: checklist. Owner: context-governance. Evidence: Checklist: docs/operations/memory-context-checklist.md. | No reliable runtime signal is faked. |
| Capability registry | Partially enforced | Gate: capability evidence. Owner: capability-governance. Evidence: capability policy. | gap:capability-staged-guard — staged path capability guard is open. |
| Learning schema | Enforced | Gate: learning schema. Owner: learning-governance. Evidence: learning tests. | Content quality handled by closure gate. |
| Learning reuse | Enforced | Gate: lesson reuse. Owner: learning-governance. Evidence: reuse checks. | Relevance remains review-based. |
| Learning closure after bug/debug work | Enforced | Gate: learning capture. Owner: learning-governance. Evidence: quality fixtures. | Truthfulness remains review-based. |
| Claude run trace / experiment log | Partially enforced | Gate: run trace. Owner: trace-governance. Evidence: run-trace tests. | gap:run-trace-significant-scope — significant-run triggers remain open. |
| Positive/negative simulations | Partially enforced | Gate: simulation coverage. Owner: validation-governance. Evidence: simulation-coverage.tsv. | gap:simulation-waiver-fixtures — replaceable waivers remain open. |
| Tests/lint before commit | Partially enforced | Gate: test enforcer. Owner: validation-governance. Evidence: enforce-tests. | gap:tests-tool-environment-contract — missing-tool CI contract remains open. |
| Cleanup debug leftovers | Enforced | Gate: quality cleanup. Owner: cleanup-governance. Evidence: quality tests. | Narrow cleanup cases covered. |
| Cleanup semantic hygiene | Enforced | Gate: semantic cleanup CI. Owner: cleanup-governance. Evidence: cleanup workflows. | Deeper hygiene remains review-based. |
| Project install contract | Enforced | Gate: installer contract. Owner: install-governance. Evidence: use-in-project tests. | gap:install-downstream-behavior — downstream behavior tests remain open. |
| Git/branch policy | Partially enforced | Gate: PR policy. Owner: merge-governance. Evidence: merge readiness checks. | gap:merge-readiness-artifact — structured merge artifact remains open. |
| PR review / external review | Enforced | Gate: PR policy. Owner: review-governance. Evidence: PR body review evidence. | gap:pr-review-quality-schema — extracted review schema remains open. |
| Merge safety | Manual by design | Gate: merge checklist. Owner: merge-governance. Evidence: Checklist: docs/operations/merge-readiness-checklist.md. | gap:merge-readiness-artifact — artifact validation remains open. |
| Post-merge validation | Enforced | Gate: post-merge validation. Owner: merge-governance. Evidence: contract tests. | Live incidents use checklist review. |
| Known gaps register | Enforced | Gate: known gaps. Owner: ops-readiness. Evidence: known-gaps lifecycle tests. | Human closure decision remains review-based. |

## Definition of full operational readiness

Engineering OS can only be called fully operationally ready when every policy row is either Enforced, Manual by design, Waiver-gated, Not applicable, or explicitly listed as a gap with priority, risk, and next action.

## Highest-priority gaps by ROI

1. **Coverage map hardening** — keep required gates represented in simulation coverage.
2. **RTK runtime hardening** — maintain RTK impact evidence.
3. **Route Plan quality gate** — active plan targeting remains tracked.
4. **Learning closure gate** — keep concrete learning closure fixtures.
5. **Progress lifecycle** — keep ordered lifecycle validation.
6. **Connector correctness** — source/action/result/decision, identifiers, and target linkage are enforced.
7. **Simulation completeness** — gap:simulation-waiver-fixtures remains open.
8. **Post-merge validation** — safe repair simulation remains enforced.
9. **Documentation hygiene** — ownership and stale-doc gates remain enforced.
10. **Semantic cleanup** — cleanup CI remains enforced.

## Current audit scope

This audit enforces its own classification contract. Connector selection now uses manifest-backed inventory coverage; remaining selection gaps are template, pattern, skill, and capability hardening.
