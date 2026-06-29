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

## Current status matrix

| Area | Status | What is enforced or checked | Remaining gap |
|---|---|---|---|
| CLAUDE entrypoint and core navigation | Enforced | CI checks keep `CLAUDE.md`, `core/task-router.md`, and template wiring present. `CLAUDE.md` remains the entrypoint and points to canonical core policies. | Semantic correctness of every route still needs review. |
| Canonical ownership / no policy sprawl | Partially enforced | `CLAUDE.md` contains a conceptual ownership table; `validate-orphans.sh` checks core navigation coverage; docs policy catches some missing READMEs/TBDs. | Duplicate/stale/split policy content across `.md` files is not fully detected. |
| Enforcement coverage inventory | Enforced | This audit is validated by CI for required readiness areas, allowed statuses, and required priority gaps. | CI proves inventory coverage exists; status accuracy still requires review and evidence. |
| Route Plan before writing | Enforced | Write/Edit gate stops code writes without a current Route Plan with required sections. | Active-plan selection can still be semantically wrong in complex multi-task sessions. |
| Route Plan quality | Partially enforced | Required fields such as task class, skills/templates/connectors/evidence are checked by policy workflows and runtime evidence gates. | The plan can still be shallow or technically present but weak. |
| DoD completion | Enforced | Plan-policy and pre-commit gates check incomplete DoD flows in covered cases. | DoD quality is judgment-based. |
| Progress validation | Partially enforced | Connector/run-trace policy requires progress validation evidence for connector-related enforcement traces; workflow requires project tracking or approved fallback. | Full checkpoint lifecycle, start/middle/pre-merge, is not yet universally hard-checked. |
| Connector selection | Partially enforced | Task/domain/path rules require covered connectors; connector policy checks sensitive config mistakes; runtime evidence checks declared connectors. | Need broader task-class coverage and stronger proof that connector output influenced the work. |
| Connector correctness / source-of-truth use | Partially enforced | GitHub, project-tracking, Context7, Sentry, Postman, and Figma-style connector decisions can be represented in Route Plan and trace evidence. | The system cannot fully prove semantic use of returned connector data. |
| Template selection | Partially enforced | Template fields/evidence/waiver are required in plans and installed policy workflows. | Required-template detection by task class/domain still needs expansion. |
| Pattern usage | Partially enforced | Runtime gate checks known domains against `patterns/<domain>/` reads. | Domain detection is path/name based and incomplete; generic files can still rely on advisory warnings. |
| Skill selection | Partially enforced | `check-required-skills.sh` requires task/domain/path-specific skills such as UI, security, graphify, and superpowers. | Coverage must expand as new task classes and skills are added. |
| Skill runtime evidence | Enforced | `pre-tool-use-runtime-evidence.sh` checks declared skills for evidence. | Evidence proves recorded activation, not deep semantic use. |
| RTK context optimization | Partially enforced | RTK is represented in the capability registry and audit; project install and SessionStart wiring are expected to preserve context tooling. | Runtime RTK use/fallback still needs stronger positive and negative simulations, especially when graphify is unavailable or insufficient. |
| Graphify context graph | Partially enforced | G7 checks writes when `graphify-out/graph.json` exists but graphify has not been queried this session. | Evidence proves graphify ran, not that findings were actually used. |
| Claude memory / context carryover | Manual | Workflow documents memory/context recovery as part of session behavior. | Runtime availability and evidence are not hard-checked across all environments. |
| Capability registry | Partially enforced | Registry has task classes/capabilities and CI validates expected anchors through capability report generation. | Registry-to-runtime enforcement is still plan-level and needs stronger staged-change guards. |
| Learning schema | Enforced | `enforce-learning.sh` checks malformed staged lessons and failed-solutions. | Semantic lesson quality still needs review. |
| Learning reuse | Enforced | Relevant existing lessons/failed-solutions must be listed in the Route Plan. | Relevance is path/tag based, not deep semantic code understanding. |
| Learning closure after bug/debug work | Partially enforced | Learning capture gates require covered bug/debug/incident work to record lessons in covered cases. | Full closure package still needs stricter proof: root cause, failed-solution when applicable, prevention update or waiver. |
| Claude run trace / experiment log | Partially enforced | Enforcement/connector/simulation changes require a Route Plan run trace with fields for goal, hypothesis, connectors, steps, evidence, rejected attempts, result, and follow-up. | Not all significant agent runs are forced through trace yet. |
| Positive/negative simulations | Partially enforced | Existing `scripts/enforcement/tests/test-*.sh` suites cover many gates and CI runs them all. | Every policy row does not yet have explicit positive, negative, invalid, and waiver simulations. |
| Tests/lint before commit | Partially enforced | Pre-commit runs stack-specific tests/lint where detected and checks large unverified commits. | Missing tools can warn rather than fully fail in all ecosystems. |
| Cleanup debug leftovers | Enforced | `enforce-quality.sh` checks unambiguous debuggers and conflict markers. | None for these narrow cases. |
| Cleanup semantic hygiene | Manual | Policy says to clean and verify. | Dead code, duplicate logic, unused imports, speculative TODOs, and stale cleanup need analyzers or waiver-gated checklist. |
| Project install contract | Enforced | CI installs Engineering OS into a temp project and checks expected hooks/files/workflows. | Validates contract shape, not every downstream behavior. |
| Git/branch policy | Partially enforced | Hooks enforce common branch/process rules; policy requires dedicated branch and no unsafe merge. | GitHub connector operations and PR state still require live checks. |
| PR review / CodeRabbit / external review | Manual | `coderabbit-policy.md` requires branch, PR, Actions, CodeRabbit review when available, comment handling, and explicit approval. | CodeRabbit can be rate-limited and is not a hard universal gate. |
| Merge safety | Manual | Policy requires mergeability, green checks, handled review threads, expected head SHA, and explicit approval. | Requires live GitHub/PR checks and human approval. |
| Post-merge validation | Missing enforcement | Main CI runs after merge. | No automatic repair-loop trigger is enforced when main turns red after merge. |
| Known gaps register | Partially enforced | `core/hooks-policy.md` has known gaps; this audit lists highest-priority gaps. | Need one consistent lifecycle for gap owner, risk, mitigation, test, and closure. |

## Definition of full operational readiness

Engineering OS can only be called fully operationally ready when every policy row is either:

1. **Enforced** by a deterministic hook, CI check, or runtime gate;
2. **Manual by design** with an explicit checklist and required review evidence;
3. **Waiver-gated** so the agent cannot silently skip it; or
4. **Explicitly listed as a gap** with priority, risk, and next action.

Anything merely documented but silently skippable is not operationally ready.

## Highest-priority gaps by ROI

1. **Coverage map hardening** — keep this audit complete and CI-validated so no policy/skill/template/connector/RTK area disappears from the inventory.
2. **RTK runtime hardening** — prove RTK activation/use/fallback through positive and negative simulations, not only documentation.
3. **Route Plan quality gate** — require stronger task-class, evidence, connector, skill, template, progress tracking, and lesson reuse coverage before writing.
4. **Learning closure gate** — require root cause plus lesson plus failed-solution when applicable plus prevention update or waiver.
5. **Progress lifecycle** — require start/mid/pre-merge progress validation evidence for non-trivial work.
6. **Connector correctness** — verify the right connector was selected and that returned evidence influenced the plan or implementation.
7. **Simulation completeness** — every new gate needs positive, negative, invalid, and waiver tests.
8. **Post-merge validation** — verify `main` after merge and open a repair loop if it turns red.
9. **Documentation hygiene** — detect duplicate/stale policy spread and force canonical ownership.
10. **Semantic cleanup** — add reliable analyzers/checklists for unused imports, dead code, duplicates, temporary code, and risky TODOs.

## Current PR scope

This PR addresses the first gap: making the operational-readiness coverage map complete and CI-validated without creating a new Markdown policy file.
