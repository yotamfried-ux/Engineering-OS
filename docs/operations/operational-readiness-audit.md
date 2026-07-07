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

Classification is enforced by `scripts/enforcement/check-readiness-audit.sh`.

## Coverage contract

Every coverage row must name `Gate:`, `Owner:`, and `Evidence:`. Manual-by-design rows must name a checklist. Missing or partial rows must link a non-closed gap.

Required coverage groups:

- Entry/navigation: `CLAUDE.md`, `core/`, canonical ownership.
- Planning/routing: Route Plan, task class, domain tags, DoD, evidence, progress validation.
- Selection/runtime: skills, templates, patterns, connectors, RTK, graphify, memory/context.
- Validation: tests, simulations, logs, CI, run trace, post-merge validation.
- Learning: root cause, lesson, failed-solution, prevention update or waiver.
- Governance: branch/PR/review/external review, merge approval, documentation cleanup, known gaps.

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
| template-selection-coverage | closed | P2 | Template selection. |
| pattern-required-manifest | closed | P2 | Pattern usage. |
| skill-selection-coverage | closed | P2 | Skill selection. |
| capability-staged-guard | closed | P1 | Capability registry. |
| run-trace-significant-scope | closed | P1 | Claude run trace / experiment log. |
| simulation-waiver-fixtures | closed | P2 | Positive/negative simulations. |
| tests-tool-environment-contract | closed | P2 | Tests/lint before commit. |
| active-plan-selection | closed | P1 | Route Plan before writing. |
| pr-review-quality-schema | closed | P2 | PR review / external review. |
| merge-readiness-artifact | closed | P1 | Git/branch policy and merge safety. |
| install-downstream-behavior | closed | P2 | Project install contract. |
| result-loop-contract-enforcement | open | P1 | Result Loop Contract enforcement. |
| scaling-extension-enforcement | open | P1 | Scaling extension enforcement. |
| claude-operational-behavior-evidence | open | P1 | Claude operational behavior and Engineering OS influence evidence. |
| registry-coverage-backfill | open | P2 | Registry/manifest coverage. |
| monitoring-metrics-sufficiency | open | P2 | Monitoring metrics sufficiency. |
| project-8-real-run-evidence | blocked | P1 | Project 8 real-run evidence. |

## Current status matrix

| Area | Status | What is enforced or checked | Remaining gap |
|---|---|---|---|
| CLAUDE entrypoint and core navigation | Enforced | Gate: enforcement-tests. Owner: core-governance. Evidence: `CLAUDE.md`, `core/task-router.md`, and route fixtures. | Review-based semantic correctness. |
| Canonical ownership / no policy sprawl | Enforced | Gate: `check-documentation-hygiene.sh`. Owner: docs-governance. Evidence: hygiene fixtures. | Review-based semantic contradictions. |
| Enforcement coverage inventory | Enforced | Gate: `check-readiness-audit.sh`. Owner: ops-readiness. Evidence: this audit and fixtures. | Closure judgment remains review-based. |
| Audit freshness / status accuracy | Enforced | Gate: `check-known-gaps.sh`. Owner: ops-readiness. Evidence: `known-gaps.tsv` ledger matching. | Human closure judgment remains review-based. |
| Route Plan before writing | Enforced | Gate: pre-tool-use workflow gate plus `eos_select_plan`. Owner: workflow-governance. Evidence: active-plan fixtures. | Plan intent remains review-based. |
| Route Plan quality | Enforced | Gate: `check-workflow-evidence.sh`. Owner: workflow-governance. Evidence: concrete source/target fixtures. | Deep intent quality remains review-based. |
| DoD completion | Enforced | Gate: plan-policy plus `check-workflow-evidence.sh`. Owner: delivery-governance. Evidence: DoD fixtures. | Deep DoD meaning remains review-based. |
| Progress validation | Enforced | Gate: `check-workflow-evidence.sh`. Owner: progress-governance. Evidence: ordered lifecycle fixtures. | Deep qualitative meaning remains review-based. |
| Connector selection | Enforced | Gate: `check-required-connectors.sh`. Owner: connector-governance. Evidence: manifest coverage fixtures. | Right-connector judgment remains review-based. |
| Connector correctness / source-of-truth use | Enforced | Gate: `check-connector-evidence.sh`. Owner: connector-governance. Evidence: source/action/result/decision fixtures. | Deep semantic use remains review-based. |
| Template selection | Enforced | Gate: `check-required-templates.py`. Owner: template-governance. Evidence: template manifest fixtures. | Right-template judgment remains review-based. |
| Pattern usage | Enforced | Gate: `check-required-patterns.sh`. Owner: pattern-governance. Evidence: registry-driven fixtures. | Pattern-fit judgment remains review-based. |
| Template/pattern rating lifecycle | Enforced | Gate: `check-template-pattern-ratings.sh` and `check-workflow-evidence.sh`. Owner: reuse-governance. Evidence: reusable asset feedback fixtures. | Score truthfulness remains review-based. |
| Documentation/reference asset selection lifecycle | Enforced | Gate: documentation-asset-policy / `check-documentation-asset-evidence.sh`. Owner: asset-governance. Evidence: asset evidence fixtures. | Best-source judgment remains review-based. |
| Skill selection | Enforced | Gate: `check-required-skills.sh`. Owner: skill-governance. Evidence: skill inventory fixtures. | Right-skill judgment remains review-based. |
| Skill runtime evidence | Enforced | Gate: `pre-tool-use-runtime-evidence.sh`. Owner: skill-governance. Evidence: runtime evidence tests. | Deep semantic use remains review-based. |
| RTK context optimization | Enforced | Gate: `check-required-skills.sh`, `session-setup.sh`, and `check-workflow-evidence.sh`. Owner: context-governance. Evidence: RTK usage impact fixtures. | Only auditable external impact evidence is enforced. |
| Graphify context graph | Enforced | Gate: `check-plan-scope.sh`. Owner: context-governance. Evidence: graph usage evidence fixtures. | Qualitative graph accuracy remains review-based. |
| Claude memory / context carryover | Manual by design | Gate: manual session checklist. Owner: context-governance. Evidence: Checklist: docs/operations/memory-context-checklist.md and capability evidence. | No reliable runtime signal exists. |
| Capability registry | Enforced | Gate: capability evidence policy and `check-capability-staged-changes.sh`. Owner: capability-governance. Evidence: staged-change fixtures. | Stale declared capabilities accepted by design. |
| Learning schema | Enforced | Gate: `enforce-learning.sh`. Owner: learning-governance. Evidence: learning schema tests. | Content quality is covered by learning closure. |
| Learning reuse | Enforced | Gate: Route Plan lesson reuse gate. Owner: learning-governance. Evidence: citation fixtures. | Deep semantic relevance remains review-based. |
| Learning closure after bug/debug work | Enforced | Gate: `enforce-learning-capture.sh`. Owner: learning-governance. Evidence: cause/evidence/regression/prevention fixtures. | Truthfulness remains review-based. |
| Claude run trace / experiment log | Enforced | Gate: `enforce-run-trace.sh`. Owner: trace-governance. Evidence: significant-run trigger and waiver fixtures. | Trace content depth remains review-based. |
| Claude operational behavior evidence | Missing enforcement | Gate: `check-operational-behavior-evidence.sh` and its fixture test exist, but the checker is not yet wired into a real PR gate. Owner: ops-readiness. Evidence: `scripts/enforcement/tests/test-operational-behavior-evidence.sh`. | gap:claude-operational-behavior-evidence — wire into a real PR gate so significant Claude work records behavior, Engineering OS influence, efficiency, friction, quality, usage surrogate, and next improvements before merge. |
| Positive/negative simulations | Enforced | Gate: `check-simulation-coverage.sh`. Owner: validation-governance. Evidence: coverage fixtures. | Future coverage judgment remains review-based. |
| Tests/lint before commit | Enforced | Gate: `enforce-tests.sh`. Owner: validation-governance. Evidence: tool-environment fixtures. | Tool-choice judgment remains review-based. |
| Cleanup debug leftovers | Enforced | Gate: `enforce-quality.sh`. Owner: cleanup-governance. Evidence: quality tests. | None for narrow cases. |
| Cleanup semantic hygiene | Enforced | Gate: semantic cleanup and import cleanup policies. Owner: cleanup-governance. Evidence: policy gates. | Deeper semantic hygiene remains review-based. |
| Project install contract | Enforced | Gate: use-in-project output contract and install policy gate coverage. Owner: install-governance. Evidence: generated-target fixtures. | Deep runtime fidelity remains review-based. |
| Result Loop Contract enforcement | Missing enforcement | Gate: `check-result-loop-contract.py` exists and self-tests, but no CI workflow invokes it against real PR content. Owner: ops-readiness. Evidence: `scripts/enforcement/check-result-loop-contract.py`. | gap:result-loop-contract-enforcement — wire checker into real PR gating. |
| Scaling extension enforcement | Missing enforcement | Gate: `check-scaling-extension.py` exists and self-tests, but no CI workflow invokes it against real PR content. Owner: ops-readiness. Evidence: `scripts/enforcement/check-scaling-extension.py`. | gap:scaling-extension-enforcement — wire checker into real PR gating. |
| Registry/manifest coverage | Missing enforcement | Gate: `check-scaling-extension.py` now requires project templates to have roadmap entries. Owner: registry-governance. Evidence: scaling extension fixtures. | gap:registry-coverage-backfill — 10 deferred project types need real roadmap research before active status. |
| Monitoring metrics sufficiency | Missing enforcement | Gate: telemetry exporter/importer/analyzer and tests exist, but no real target-project run has been imported. Owner: ops-readiness. Evidence: telemetry archive tests. | gap:monitoring-metrics-sufficiency — cannot close until a real target-project run is imported and analyzed. |
| Project 8 real-run evidence | Missing enforcement | Gate: none. Owner: ops-readiness. Evidence: Project 8 checklist not completed. | gap:project-8-real-run-evidence — blocked until the real-run experiment is performed. |
| Git/branch policy | Enforced | Gate: pr-policy plus hooks. Owner: merge-governance. Evidence: merge readiness artifact. | Live state checks remain human-reviewed. |
| PR review / external review | Enforced | Gate: `pr-policy` via `check-pr-review-evidence.sh`. Owner: review-governance. Evidence: review fixtures. | Deep review quality remains review-based. |
| Merge safety | Manual by design | Gate: manual GitHub merge checklist. Owner: merge-governance. Evidence: Checklist: docs/operations/merge-readiness-checklist.md covering CI, threads, and approval. | The merge decision remains human by design. |
| Post-merge validation | Enforced | Gate: `post-merge-validation` workflow and `check-post-merge-validation-contract.sh`. Owner: merge-governance. Evidence: fake-gh repair issue simulation. | Live failures use the incident checklist. |
| Known gaps register | Enforced | Gate: `check-known-gaps.sh` plus `check-readiness-audit.sh`. Owner: ops-readiness. Evidence: TSV and ledger fixtures. | Closure judgment remains review-based. |

## Definition of full operational readiness

Engineering OS can only be called fully operationally ready when every policy row is either:

1. **Enforced** by a deterministic hook, CI check, or runtime gate;
2. **Manual by design** with an explicit checklist and required review evidence;
3. **Waiver-gated** so the agent cannot silently skip it; or
4. **Explicitly listed as a gap** with priority, risk, and next action.

Anything merely documented but silently skippable is not operationally ready.

## Highest-priority gaps by ROI

1. **Claude operational behavior evidence** — open gap; usage-only tracking is insufficient. Significant Claude runs must record behavior, Engineering OS influence, efficiency, friction/false positives, quality signals, usage surrogate, and next system improvement before merge.
2. **Result Loop Contract gate wiring** — open gap; wire `check-result-loop-contract.py` into real PR gating.
3. **Scaling gate wiring** — open gap; wire `check-scaling-extension.py` into real PR gating.
4. **Registry/manifest coverage backfill** — open gap; 10 deferred project types still need real roadmap research before active status.
5. **Monitoring metrics sufficiency** — open gap; the telemetry exporter/importer/analyzer pipeline is implemented and tested, but no real target-project run has been imported yet.
6. **Project 8 real-run evidence** — blocked gap; the real-run experiment has not been performed.
7. **Coverage map hardening** — covered by `coverage-required-gates.tsv`; maintain it whenever new gates are added.
8. **RTK runtime hardening** — covered structurally by RTK usage impact evidence and session setup checks.
9. **Route Plan quality gate** — closed structurally by concrete source and target relevance checks.
10. **Template/pattern rating lifecycle** — closed structurally by exact declared asset coverage and feedback evidence.
11. **Learning closure gate** — covered by `enforce-learning-capture.sh`; maintain content-quality fixtures when the lesson schema changes.
12. **Progress lifecycle** — covered by ordered progress lifecycle evidence.
13. **Graphify context graph** — covered by target-linked graph usage evidence.
14. **Connector correctness** — source/action/result/decision evidence, concrete result identifiers, and target linkage are enforced by `check-connector-evidence.sh`.
15. **Simulation completeness** — maintained by `simulation-coverage.tsv`.
16. **Post-merge validation** — covered by safe fake-gh repair issue simulation; live failures use the incident checklist.
17. **Documentation hygiene** — covered by `check-documentation-hygiene.sh`.
18. **Semantic cleanup** — covered by CI policy gates.
19. **Trace and test contracts** — covered by significant-run and missing-tool environment contracts.
20. **Governance evidence** — review and merge evidence are covered by `check-pr-review-evidence.sh`.
21. **Install downstream behavior** — covered by manifest-driven policy-gate dependency copy and generated-target fixtures.

## Current audit scope

This audit enforces its own classification contract through `scripts/enforcement/check-readiness-audit.sh`. This update registers Claude operational behavior evidence as a distinct open gap and adds a fixture-tested checker, but it does not claim full PR-gate wiring, Project 8 evidence, monitoring sufficiency, or full readiness.
