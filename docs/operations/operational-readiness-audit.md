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
- Governance: branch/PR/review/CodeRabbit, merge approval, documentation cleanup, known gaps.

Coverage matrix contract: every row must name `Gate:`, `Owner:`, and `Evidence:` in the enforcement cell. If the gate is manual or missing, the evidence must name the manual review or gap evidence instead of being blank.

## Current status matrix

| Area | Status | What is enforced or checked | Remaining gap |
|---|---|---|---|
| CLAUDE entrypoint and core navigation | Enforced | Gate: enforcement-tests entrypoint wiring. Owner: core-governance. Evidence: CI checks keep `CLAUDE.md`, `core/task-router.md`, and template wiring present. | Semantic correctness of every route still needs review. |
| Canonical ownership / no policy sprawl | Enforced | Gate: `check-documentation-hygiene.sh`. Owner: docs-governance. Evidence: documentation ownership manifest, stale/deprecated checks, duplicate ownership checks, and `test-documentation-hygiene.sh`. | Deep semantic contradictions that do not touch deterministic ownership/deprecation signals still require review. |
| Enforcement coverage inventory | Enforced | Gate: readiness audit validator plus coverage-map simulation. Owner: ops-readiness. Evidence: CI validates required areas, statuses, priority gaps, gate, owner, evidence markers, and required simulation gates. | CI proves inventory coverage exists; status accuracy still needs review. |
| Audit freshness / status accuracy | Partially enforced | Gate: `check-known-gaps.sh`. Owner: ops-readiness. Evidence: `docs/operations/known-gaps.tsv` tracks open drift risks with owner, risk, mitigation, test, and closure. | Status accuracy still requires review when enforcement changes land. |
| Route Plan before writing | Enforced | Gate: pre-tool-use workflow gate. Owner: workflow-governance. Evidence: `test-workflow-evidence.sh` order cases. | Active-plan selection can still be semantically wrong in complex multi-task sessions. |
| Route Plan quality | Partially enforced | Gate: `check-workflow-evidence.sh`. Owner: workflow-governance. Evidence: `test-plan-quality.sh`, `test-plan-semantic-quality.sh`, and `test-workflow-evidence.sh`. | Deep semantic quality of the selected evidence still needs review beyond reliable target/source matching. |
| DoD completion | Enforced | Gate: plan-policy. Owner: delivery-governance. Evidence: checklist policy checks. | DoD quality is judgment-based. |
| Progress validation | Partially enforced | Gate: `check-workflow-evidence.sh`. Owner: progress-governance. Evidence: `test-progress-lifecycle.sh` plus connector evidence policy. | Structural start/mid/pre-merge checkpoints are enforced; deeper semantic proof of progress quality still needs review. |
| Connector selection | Partially enforced | Gate: `check-required-connectors.sh`. Owner: connector-governance. Evidence: required connector fields and runtime evidence checks. | Need broader task-class coverage as new connector-backed systems are added. |
| Connector correctness / source-of-truth use | Partially enforced | Gate: `check-connector-evidence.sh`. Owner: connector-governance. Evidence: Connector Usage Evidence is required to state source/action/result for declared connectors. | Structural influence evidence is enforced; the system still cannot fully prove deep semantic use of returned connector data. |
| Template selection | Partially enforced | Gate: template evidence/waiver gates. Owner: template-governance. Evidence: Route Plan template fields and waiver checks. | Required-template detection by task class/domain still needs expansion. |
| Pattern usage | Partially enforced | Gate: pattern read evidence gate. Owner: pattern-governance. Evidence: runtime pattern evidence checks. | Domain detection is path/name based and incomplete; generic files can still rely on advisory warnings. |
| Skill selection | Partially enforced | Gate: `check-required-skills.sh`. Owner: skill-governance. Evidence: required-skills and context-skill simulations. | Coverage must expand as new task classes and skills are added. |
| Skill runtime evidence | Enforced | Gate: `pre-tool-use-runtime-evidence.sh`. Owner: skill-governance. Evidence: runtime evidence tests. | Evidence proves recorded activation, not deep semantic use. |
| RTK context optimization | Partially enforced | Gate: `check-required-skills.sh`, blocking `session-setup.sh`, and `check-workflow-evidence.sh` RTK Usage Evidence. Owner: context-governance. Evidence: context-skill selection simulations, `test-rtk-session-blocking.sh`, and `test-rtk-usage-evidence.sh`. | Evidence now requires structural RTK source/action/result/decision impact for RTK-declared code changes; deeper semantic proof of actual reasoning impact remains future work. |
| Graphify context graph | Partially enforced | Gate: graphify evidence gate. Owner: context-governance. Evidence: graphify gate tests. | Evidence proves graphify ran, not that findings were actually used. |
| Claude memory / context carryover | Manual | Gate: manual workflow checklist. Owner: context-governance. Evidence: manual session review evidence and known-gaps manifest entry. | Runtime availability and evidence are not hard-checked across all environments. |
| Capability registry | Partially enforced | Gate: capability report and capability evidence policy. Owner: capability-governance. Evidence: capability-evidence-policy plus capability report generator. | Registry-to-runtime enforcement is still plan-level and needs stronger staged-change guards. |
| Learning schema | Enforced | Gate: `enforce-learning.sh`. Owner: learning-governance. Evidence: learning enforcement tests. | Semantic lesson quality still needs review. |
| Learning reuse | Enforced | Gate: Route Plan lesson reuse gate. Owner: learning-governance. Evidence: learning reuse checks. | Relevance is path/tag based, not deep semantic code understanding. |
| Learning closure after bug/debug work | Partially enforced | Gate: `enforce-learning-capture.sh`. Owner: learning-governance. Evidence: learning capture tests and learning closure marker tests. | Full closure now requires root cause, lesson, failed-solution when staged, and prevention/enforcement update or waiver; deeper semantic quality still needs review. |
| Claude run trace / experiment log | Partially enforced | Gate: workflow/connector evidence policies. Owner: trace-governance. Evidence: workflow-evidence-policy and connector-evidence-policy. | Not all significant agent runs are forced yet. |
| Positive/negative simulations | Partially enforced | Gate: `check-simulation-coverage.sh`. Owner: validation-governance. Evidence: `simulation-coverage.tsv`, extension rows under `simulation-coverage.d/`, `coverage-required-gates.tsv`, and `test-simulation-coverage.sh`. | Required gates are manifest-backed; remaining work is replacing explicit coverage waivers with dedicated fixtures where feasible. |
| Tests/lint before commit | Partially enforced | Gate: `enforce-tests.sh`. Owner: validation-governance. Evidence: pre-commit and CI enforcement-tests. | Missing tools can warn rather than fully fail in all ecosystems. |
| Cleanup debug leftovers | Enforced | Gate: `enforce-quality.sh`. Owner: cleanup-governance. Evidence: quality enforcement tests. | None for these narrow cases. |
| Cleanup semantic hygiene | Partially enforced | Gate: `check-semantic-cleanup.sh`. Owner: cleanup-governance. Evidence: `test-semantic-cleanup.sh` covers risky cleanup markers, disabled branches, simple Python unused imports, and waiver behavior. | Deeper dead code, duplicate logic, unused exports, and stale cleanup across all languages still need analyzers or waiver-gated checklist. |
| Project install contract | Enforced | Gate: use-in-project output contract. Owner: install-governance. Evidence: enforcement-tests install contract. | Validates contract shape, not every downstream behavior. |
| Git/branch policy | Partially enforced | Gate: pr-policy plus hooks. Owner: merge-governance. Evidence: pr-policy and live GitHub review. | GitHub connector operations and PR state still require live checks. |
| PR review / CodeRabbit / external review | Manual | Gate: manual review policy. Owner: review-governance. Evidence: PR comments/review thread evidence and known-gaps manifest entry. | CodeRabbit can be rate-limited and is not a hard universal gate. |
| Merge safety | Manual | Gate: manual GitHub merge checklist. Owner: merge-governance. Evidence: mergeability, checks, threads, expected SHA evidence. | Requires live GitHub/PR checks and human approval. |
| Post-merge validation | Enforced | Gate: `post-merge-validation` workflow plus `check-post-merge-validation-contract.sh`. Owner: merge-governance. Evidence: push-to-main validation workflow, failure-triggered repair issue path, and `test-post-merge-validation-contract.sh`. | Actual issue creation path is only exercised on a future failing main run. |
| Known gaps register | Enforced | Gate: `check-known-gaps.sh`. Owner: ops-readiness. Evidence: `docs/operations/known-gaps.tsv`, `test-known-gaps.sh`, and simulation coverage row `known-gaps-lifecycle`. | Lifecycle shape is enforced; gap accuracy and closure judgment still require review. |

## Definition of full operational readiness

Engineering OS can only be called fully operationally ready when every policy row is either:

1. **Enforced** by a deterministic hook, CI check, or runtime gate;
2. **Manual by design** with an explicit checklist and required review evidence;
3. **Waiver-gated** so the agent cannot silently skip it; or
4. **Explicitly listed as a gap** with priority, risk, and next action.

Anything merely documented but silently skippable is not operationally ready.

## Highest-priority gaps by ROI

1. **Coverage map hardening** — covered by `coverage-required-gates.tsv`; maintain it whenever new gates are added.
2. **RTK runtime hardening** — partially covered by RTK Usage Evidence; remaining work is deeper semantic proof of actual reasoning impact where reliable signals become available.
3. **Route Plan quality gate** — extend structural and target/source evidence checks into deeper semantic quality checks as reliable signals become available.
4. **Learning closure gate** — extend closure evidence from structural fields into deeper semantic validation as reliable signals become available.
5. **Progress lifecycle** — extend structural start/mid/pre-merge checkpoint evidence into deeper semantic progress validation as reliable signals become available.
6. **Connector correctness** — extend structural source/action/result evidence into deeper semantic proof of connector use when reliable signals become available.
7. **Simulation completeness** — maintained by `simulation-coverage.tsv`; remaining work is to replace explicit coverage waivers with dedicated fixtures where feasible.
8. **Post-merge validation** — covered by `post-merge-validation` workflow; remaining work is to observe the repair issue path on a future failing main run.
9. **Documentation hygiene** — covered by `check-documentation-hygiene.sh`; remaining work is deeper semantic contradiction detection beyond deterministic ownership/deprecation signals.
10. **Semantic cleanup** — partially covered by `check-semantic-cleanup.sh`; remaining work is deeper analyzers for dead code, duplicates, unused exports, and stale cleanup.

## Current audit scope

This audit now includes RTK Usage Evidence as a structural decision-impact gate. It does not claim full semantic proof that RTK changed reasoning outcomes.
