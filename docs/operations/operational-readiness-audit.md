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
| Canonical ownership / no policy sprawl | Partially enforced | Gate: validate-orphans/docs policy. Owner: docs-governance. Evidence: core navigation/docs checks plus manual canonical review. | Duplicate/stale/split policy content across `.md` files is not fully detected. |
| Enforcement coverage inventory | Enforced | Gate: readiness audit validator plus coverage-map simulation. Owner: ops-readiness. Evidence: CI validates required areas, statuses, priority gaps, gate, owner, and evidence markers. | CI proves inventory coverage exists; status accuracy still requires review. |
| Route Plan before writing | Enforced | Gate: pre-tool-use workflow gate. Owner: workflow-governance. Evidence: `test-workflow-evidence.sh` order cases. | Active-plan selection can still be semantically wrong in complex multi-task sessions. |
| Route Plan quality | Partially enforced | Gate: `check-workflow-evidence.sh`. Owner: workflow-governance. Evidence: `test-plan-quality.sh`, `test-plan-semantic-quality.sh`, and `test-workflow-evidence.sh`. | Deep semantic quality of the selected evidence still needs review beyond reliable target/source matching. |
| DoD completion | Enforced | Gate: plan-policy. Owner: delivery-governance. Evidence: checklist policy checks. | DoD quality is judgment-based. |
| Progress validation | Partially enforced | Gate: connector/workflow trace policies. Owner: progress-governance. Evidence: connector evidence policy plus manual checkpoint review. | Full checkpoint lifecycle, start/middle/pre-merge, is not yet universally hard-checked. |
| Connector selection | Partially enforced | Gate: connector evidence policy. Owner: connector-governance. Evidence: required connector fields and runtime evidence checks. | Need broader task-class coverage and stronger proof that connector output influenced the work. |
| Connector correctness / source-of-truth use | Partially enforced | Gate: connector evidence policy plus manual review. Owner: connector-governance. Evidence: connector traces and reviewed plan use. | The system cannot fully prove semantic use of returned connector data. |
| Template selection | Partially enforced | Gate: template evidence/waiver gates. Owner: template-governance. Evidence: Route Plan template fields and waiver checks. | Required-template detection by task class/domain still needs expansion. |
| Pattern usage | Partially enforced | Gate: pattern read evidence gate. Owner: pattern-governance. Evidence: runtime pattern evidence checks. | Domain detection is path/name based and incomplete; generic files can still rely on advisory warnings. |
| Skill selection | Partially enforced | Gate: `check-required-skills.sh`. Owner: skill-governance. Evidence: required-skills and context-skill simulations. | Coverage must expand as new task classes and skills are added. |
| Skill runtime evidence | Enforced | Gate: `pre-tool-use-runtime-evidence.sh`. Owner: skill-governance. Evidence: runtime evidence tests. | Evidence proves recorded activation, not deep semantic use. |
| RTK context optimization | Enforced | Gate: `check-required-skills.sh` and blocking `session-setup.sh`. Owner: context-governance. Evidence: context-skill selection simulations and `test-rtk-session-blocking.sh`. | Evidence proves RTK availability and hook registration, not deep semantic use. |
| Graphify context graph | Partially enforced | Gate: graphify evidence gate. Owner: context-governance. Evidence: graphify gate tests. | Evidence proves graphify ran, not that findings were actually used. |
| Claude memory / context carryover | Manual | Gate: manual workflow checklist. Owner: context-governance. Evidence: manual session review evidence. | Runtime availability and evidence are not hard-checked across all environments. |
| Capability registry | Partially enforced | Gate: capability report and capability evidence policy. Owner: capability-governance. Evidence: capability-evidence-policy plus capability report generator. | Registry-to-runtime enforcement is still plan-level and needs stronger staged-change guards. |
| Learning schema | Enforced | Gate: `enforce-learning.sh`. Owner: learning-governance. Evidence: learning enforcement tests. | Semantic lesson quality still needs review. |
| Learning reuse | Enforced | Gate: Route Plan lesson reuse gate. Owner: learning-governance. Evidence: learning reuse checks. | Relevance is path/tag based, not deep semantic code understanding. |
| Learning closure after bug/debug work | Partially enforced | Gate: learning capture gates. Owner: learning-governance. Evidence: learning capture tests plus manual incident review. | Full closure package still needs stricter proof: root cause, failed-solution when applicable, prevention update or waiver. |
| Claude run trace / experiment log | Partially enforced | Gate: workflow/connector evidence policies. Owner: trace-governance. Evidence: workflow-evidence-policy and connector-evidence-policy. | Not all significant agent runs are forced yet. |
| Positive/negative simulations | Partially enforced | Gate: enforcement-tests suite. Owner: validation-governance. Evidence: `scripts/enforcement/tests/test-*.sh`. | Every policy row does not yet have explicit positive, negative, invalid, and waiver simulations. |
| Tests/lint before commit | Partially enforced | Gate: `enforce-tests.sh`. Owner: validation-governance. Evidence: pre-commit and CI enforcement-tests. | Missing tools can warn rather than fully fail in all ecosystems. |
| Cleanup debug leftovers | Enforced | Gate: `enforce-quality.sh`. Owner: cleanup-governance. Evidence: quality enforcement tests. | None for these narrow cases. |
| Cleanup semantic hygiene | Manual | Gate: manual cleanup checklist. Owner: cleanup-governance. Evidence: manual review evidence. | Dead code, duplicate logic, unused imports, speculative TODOs, and stale cleanup need analyzers or waiver-gated checklist. |
| Project install contract | Enforced | Gate: use-in-project output contract. Owner: install-governance. Evidence: enforcement-tests install contract. | Validates contract shape, not every downstream behavior. |
| Git/branch policy | Partially enforced | Gate: pr-policy plus hooks. Owner: merge-governance. Evidence: pr-policy and live GitHub review. | GitHub connector operations and PR state still require live checks. |
| PR review / CodeRabbit / external review | Manual | Gate: manual review policy. Owner: review-governance. Evidence: PR comments/review thread evidence. | CodeRabbit can be rate-limited and is not a hard universal gate. |
| Merge safety | Manual | Gate: manual GitHub merge checklist. Owner: merge-governance. Evidence: mergeability, checks, threads, expected SHA evidence. | Requires live GitHub/PR checks and human approval. |
| Post-merge validation | Missing enforcement | Gate: missing CI repair-loop gate. Owner: merge-governance. Evidence: gap evidence in this audit. | No automatic repair-loop trigger is enforced when main turns red after merge. |
| Known gaps register | Partially enforced | Gate: audit plus hooks policy. Owner: ops-readiness. Evidence: audit priority list and hooks-policy gaps. | Need one consistent lifecycle for gap owner, risk, mitigation, test, and closure. |

## Definition of full operational readiness

Engineering OS can only be called fully operationally ready when every policy row is either:

1. **Enforced** by a deterministic hook, CI check, or runtime gate;
2. **Manual by design** with an explicit checklist and required review evidence;
3. **Waiver-gated** so the agent cannot silently skip it; or
4. **Explicitly listed as a gap** with priority, risk, and next action.

Anything merely documented but silently skippable is not operationally ready.

## Highest-priority gaps by ROI

1. **Coverage map hardening** — expand the enforcement coverage inventory so every policy row has a named gate, owner, and CI-verified simulation.
2. **RTK runtime hardening** — extend RTK checks from availability and hook registration into deeper semantic use evidence where reliable signals become available.
3. **Route Plan quality gate** — extend structural and target/source evidence checks into deeper semantic quality checks as reliable signals become available.
4. **Learning closure gate** — require root cause plus lesson plus failed-solution when applicable plus prevention update or waiver.
5. **Progress lifecycle** — require start/mid/pre-merge progress validation evidence for non-trivial work.
6. **Connector correctness** — verify the right connector was selected and that returned evidence influenced the plan or implementation.
7. **Simulation completeness** — every new gate needs positive, negative, invalid, and waiver tests.
8. **Post-merge validation** — verify `main` after merge and open a repair loop if it turns red.
9. **Documentation hygiene** — detect duplicate/stale policy spread and force canonical ownership.
10. **Semantic cleanup** — add reliable analyzers/checklists for unused imports, dead code, duplicates, temporary code, and risky TODOs.

## Current PR scope

This PR addresses Route Plan quality by requiring source-of-truth checks to relate to concrete target paths or canonical routing/workflow sources.
