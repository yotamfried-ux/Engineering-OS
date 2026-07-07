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
| registry-coverage-backfill | open | P2 | Registry/manifest coverage. |
| monitoring-metrics-sufficiency | open | P2 | Monitoring metrics sufficiency. |
| project-8-real-run-evidence | blocked | P1 | Project 8 real-run evidence. |

## Current status matrix

| Area | Status | What is enforced or checked | Remaining gap |
|---|---|---|---|
| CLAUDE entrypoint and core navigation | Enforced | Gate: enforcement-tests entrypoint wiring. Owner: core-governance. Evidence: `CLAUDE.md`, `core/task-router.md`, and route fixtures are checked in CI. | Route semantic correctness remains review-based by design. |
| Canonical ownership / no policy sprawl | Enforced | Gate: `check-documentation-hygiene.sh`. Owner: docs-governance. Evidence: ownership manifest and documentation hygiene fixtures. | Deep semantic contradictions remain reviewer judgment. |
| Enforcement coverage inventory | Enforced | Gate: `check-readiness-audit.sh`. Owner: ops-readiness. Evidence: headings, statuses, gap links, checklist docs, and coverage rows are fixture-tested. | Inventory structure is checked; closure judgment remains review-based. |
| Audit freshness / status accuracy | Enforced | Gate: `check-known-gaps.sh`. Owner: ops-readiness. Evidence: `known-gaps.tsv` is cross-checked against this ledger. | Human decision to close a gap remains review-based. |
| Route Plan before writing | Enforced | Gate: pre-tool-use workflow gate plus `eos_select_plan`. Owner: workflow-governance. Evidence: workflow evidence and active-plan selection fixtures. | Plan-intent judgment remains review-based. |
| Route Plan quality | Enforced | Gate: `check-workflow-evidence.sh`. Owner: workflow-governance. Evidence: plan quality fixtures require concrete source and target evidence. | Intent quality beyond reliable matching remains review-based. |
| DoD completion | Enforced | Gate: plan-policy plus `check-workflow-evidence.sh`. Owner: delivery-governance. Evidence: DoD schema and verification-signal fixtures. | Deep DoD quality remains review-based. |
| Progress validation | Enforced | Gate: `check-workflow-evidence.sh`. Owner: progress-governance. Evidence: ordered start, mid, and pre-merge lifecycle fixtures. | Deep qualitative meaning remains review-based. |
| Connector selection | Enforced | Gate: `check-required-connectors.sh`. Owner: connector-governance. Evidence: manifest coverage and precision fixtures. | Right-connector judgment remains review-based. |
| Connector correctness / source-of-truth use | Enforced | Gate: `check-connector-evidence.sh`. Owner: connector-governance. Evidence: source/action/result/decision, result identifiers, and target linkage fixtures. | Deep semantic use remains review-based. |
| Template selection | Enforced | Gate: `check-required-templates.py`. Owner: template-governance. Evidence: template requirement manifest, coverage, waiver, and precision fixtures. | Right-template judgment remains review-based. |
| Pattern usage | Enforced | Gate: `check-required-patterns.sh`. Owner: pattern-governance. Evidence: registry-driven required-pattern rules and fixtures. | Pattern-fit judgment remains review-based. |
| Template/pattern rating lifecycle | Enforced | Gate: `check-template-pattern-ratings.sh` and `check-workflow-evidence.sh`. Owner: reuse-governance. Evidence: exact reusable asset feedback coverage fixtures. | Score truthfulness remains review-based. |
| Documentation/reference asset selection lifecycle | Enforced | Gate: documentation-asset-policy / `check-documentation-asset-evidence.sh`. Owner: asset-governance. Evidence: valid evidence, waiver, missing-field, placeholder, and broad-claim fixtures. | Best-source judgment remains review-based. |
| Skill selection | Enforced | Gate: `check-required-skills.sh`. Owner: skill-governance. Evidence: required-skill inventory coverage and precision fixtures. | Right-skill judgment remains review-based. |
| Skill runtime evidence | Enforced | Gate: `pre-tool-use-runtime-evidence.sh`. Owner: skill-governance. Evidence: runtime evidence tests. | Deep semantic use remains review-based. |
| RTK context optimization | Enforced | Gate: `check-required-skills.sh`, `session-setup.sh`, and `check-workflow-evidence.sh`. Owner: context-governance. Evidence: RTK selection and usage evidence fixtures. | Only auditable external impact evidence is enforced. |
| Graphify context graph | Enforced | Gate: `check-plan-scope.sh`. Owner: context-governance. Evidence: target-linked graph usage fixtures. | Qualitative graph accuracy remains review-based. |
| Claude memory / context carryover | Manual by design | Gate: manual session checklist with required review evidence. Owner: context-governance. Evidence: Checklist: docs/operations/memory-context-checklist.md and capability evidence. | No reliable runtime signal exists, so this remains manual by design. |
| Capability registry | Enforced | Gate: capability evidence policy plus `check-capability-staged-changes.sh`. Owner: capability-governance. Evidence: registry map and staged-change fixtures. | Stale declared capabilities are accepted by design to avoid false blocks. |
| Learning schema | Enforced | Gate: `enforce-learning.sh`. Owner: learning-governance. Evidence: learning schema tests. | Content quality is covered by learning closure. |
| Learning reuse | Enforced | Gate: Route Plan lesson reuse gate. Owner: learning-governance. Evidence: required and irrelevant citation fixtures. | Deep semantic relevance remains review-based. |
| Learning closure after bug/debug work | Enforced | Gate: `enforce-learning-capture.sh`. Owner: learning-governance. Evidence: concrete cause, evidence, regression, prevention, and waiver fixtures. | Truthfulness of closure claims remains review-based. |
| Claude run trace / experiment log | Enforced | Gate: `enforce-run-trace.sh`. Owner: trace-governance. Evidence: significant-run trigger and waiver-body fixtures. | Trace content depth remains review-based. |
| Positive/negative simulations | Enforced | Gate: `check-simulation-coverage.sh`. Owner: validation-governance. Evidence: simulation coverage map and coverage-required-gates fixtures. | Future coverage judgment remains review-based. |
| Tests/lint before commit | Enforced | Gate: `enforce-tests.sh`. Owner: validation-governance. Evidence: test contract and missing-tool environment fixtures. | Tool-choice judgment remains review-based. |
| Cleanup debug leftovers | Enforced | Gate: `enforce-quality.sh`. Owner: cleanup-governance. Evidence: quality enforcement tests. | None for these narrow cases. |
| Cleanup semantic hygiene | Enforced | Gate: semantic cleanup and import cleanup policies. Owner: cleanup-governance. Evidence: duplicate-definition and stale-reference policy gates. | Deeper semantic hygiene remains review-based. |
| Project install contract | Enforced | Gate: use-in-project output contract and install policy gate coverage. Owner: install-governance. Evidence: clean install and generated target behavior fixtures. | Deep runtime fidelity beyond fixtures remains review-based. |
| Result Loop Contract enforcement | Missing enforcement | Gate: `check-result-loop-contract.py` plus `result-loop-requirements.tsv` exist from merged PR #220 (`014c58f`) and `scripts/enforcement/tests/test-result-loop-contract.sh` passes against synthetic fixtures, but no CI workflow invokes the checker against a real PR's route plan — confirmed by a repo-wide grep showing zero references to the checker outside its own test file. Owner: ops-readiness. Evidence: `scripts/enforcement/check-result-loop-contract.py`; `scripts/enforcement/tests/test-result-loop-contract.sh`. | gap:result-loop-contract-enforcement — a real PR-gating workflow invocation, plus telemetry linkage and real-run evidence, remain open. |
| Scaling extension enforcement | Missing enforcement | Gate: `check-scaling-extension.py` plus `project-type-roadmaps.tsv`/`waiver-requirements.tsv` exist from merged PR #219 (`f19ce56`) and `scripts/enforcement/tests/test-scaling-extension.sh` passes against synthetic fixtures, but no CI workflow invokes the checker against a real PR — confirmed by a repo-wide grep showing zero references to the checker outside its own test file. Owner: ops-readiness. Evidence: `scripts/enforcement/check-scaling-extension.py`; `scripts/enforcement/tests/test-scaling-extension.sh`. | gap:scaling-extension-enforcement — a real PR-gating workflow invocation remains open. |
| Registry/manifest coverage | Missing enforcement | Gate: `check-scaling-extension.py` now requires every `kind=project` row in `template-requirements.tsv` to have a `project-type-roadmaps.tsv` entry, verified by `scripts/enforcement/tests/test-scaling-extension.sh`. Owner: registry-governance. Evidence: connector, template, and skill coverage checkers (`check-required-connectors.sh`, `check-required-templates.py`, `check-required-skills.sh`, all with `--check-coverage`) independently verified already-complete; the one real gap found (10 uncovered project-type templates) was backfilled with honest `status=deferred` rows. | gap:registry-coverage-backfill — the 10 deferred project types still need real roadmap research (required_evidence, result-loop/documentation/pattern/skill rows) before they can move to `status=active`. |
| Monitoring metrics sufficiency | Missing enforcement | Gate: telemetry exporter/importer/analyzer and their tests exist, but no gate requires real-run evidence before claiming sufficiency. Owner: ops-readiness. Evidence: `scripts/monitoring/export-telemetry-run.py`, `import-telemetry-run.py`, `analyze-telemetry-archive.py`, and their tests exist and pass; `docs/operations/runtime-telemetry-archive-audit-checklist.md`'s Project 8 and longitudinal-learning sections are unchecked. | gap:monitoring-metrics-sufficiency — cannot close until a real target-project run is imported and analyzed. |
| Project 8 real-run evidence | Missing enforcement | Gate: none — no real run has been performed. Owner: ops-readiness. Evidence: `docs/operations/runtime-telemetry-archive-audit-checklist.md` Project 8 checklist section entirely unchecked. | gap:project-8-real-run-evidence — blocked until the real-run experiment is actually performed; explicitly out of scope for this audit-reconciliation task. |
| Git/branch policy | Enforced | Gate: pr-policy plus hooks. Owner: merge-governance. Evidence: PR policy, merge readiness artifact, workflow-run validation, and merge checklist. | Live GitHub state checks remain human-reviewed. |
| PR review / external review | Enforced | Gate: `pr-policy` via `check-pr-review-evidence.sh`. Owner: review-governance. Evidence: structured external review or fallback self-review evidence fixtures. | Deep review quality remains review-based. |
| Merge safety | Manual by design | Gate: manual GitHub merge checklist plus workflow-run evidence. Owner: merge-governance. Evidence: Checklist: docs/operations/merge-readiness-checklist.md covering CI, threads, superseded PRs, and human approval. | The merge decision remains human by design. |
| Post-merge validation | Enforced | Gate: `post-merge-validation` workflow plus `check-post-merge-validation-contract.sh`. Owner: merge-governance. Evidence: fake-gh repair issue simulation and post-merge incident checklist. | Live failures are triaged manually by design. |
| Known gaps register | Enforced | Gate: `check-known-gaps.sh` plus `check-readiness-audit.sh` gap links. Owner: ops-readiness. Evidence: TSV, freshness ledger, known-gaps fixtures, and lifecycle coverage. | Lifecycle shape and matrix linkage are enforced; closure judgment remains review-based. |

## Definition of full operational readiness

Engineering OS can only be called fully operationally ready when every policy row is either:

1. **Enforced** by a deterministic hook, CI check, or runtime gate;
2. **Manual by design** with an explicit checklist and required review evidence;
3. **Waiver-gated** so the agent cannot silently skip it; or
4. **Explicitly listed as a gap** with priority, risk, and next action.

Anything merely documented but silently skippable is not operationally ready. This definition is now itself enforced: `check-readiness-audit.sh` fails CI on any matrix row that satisfies none of the four states.

## Highest-priority gaps by ROI

1. **Result Loop Contract gate wiring** — open gap; the checker, manifest, and fixtures exist and self-test correctly (PR #220), but no CI workflow invokes `check-result-loop-contract.py` against a real PR's route plan, so real PRs are not actually gated yet.
2. **Scaling gate wiring** — open gap; the checker, manifests, and fixtures exist and self-test correctly (PR #219), but no CI workflow invokes `check-scaling-extension.py` against a real PR, so real PRs are not actually gated yet.
3. **Registry/manifest coverage backfill** — open gap; connector/template/skill coverage checks already pass in full, but 10 `kind=project` templates lacked a project-type-roadmap entry until this backfill added honest `status=deferred` rows and a new fixture-tested coverage rule; those 10 still need real roadmap research before going `active`.
4. **Monitoring metrics sufficiency** — open gap; the telemetry exporter/importer/analyzer pipeline is implemented and tested, but no real target-project run has been imported yet, so sufficiency cannot be claimed.
5. **Project 8 real-run evidence** — blocked gap; the real-run experiment has not been performed and is explicitly out of scope for audit-reconciliation work; readiness claims must not get ahead of this.
6. **Selection coverage hardening** — closed by inventory-tied selection manifests, the registry-driven pattern gate, and the staged-change capability guard; maintain the manifests as inventories grow.
7. **Coverage map hardening** — covered by `coverage-required-gates.tsv`; maintain it whenever new gates are added.
8. **RTK runtime hardening** — covered structurally by RTK usage impact evidence and session setup checks; maintain it when RTK signals change.
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

This audit enforces its own classification contract: every matrix row is Enforced, Manual by design with an existing checklist doc, Waiver-gated, or linked to a non-closed known gap, validated by `scripts/enforcement/check-readiness-audit.sh` and fixtures in `scripts/enforcement/tests/test-readiness-audit.sh`. This update registers open Result Loop Contract and scaling enforcement gaps in the source of truth. It does not implement either gate and does not claim full readiness.
