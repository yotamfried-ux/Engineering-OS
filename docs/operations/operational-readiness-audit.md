# Engineering OS Operational Readiness Audit

This audit is the source-of-truth status map for whether Engineering OS can honestly be called operationally ready.

## Readiness statuses

- **Enforced** — deterministic hook/CI/runtime gate blocks non-compliance.
- **Partially enforced** — some deterministic cases are blocked, but important judgment cases remain manual.
- **Manual** — documented checklist/review exists, but no hard gate.
- **Missing enforcement** — policy exists, but the system can silently skip it.
- **Not applicable** — no enforcement expected for this category.

## Current status matrix

| Area | Status | What is enforced | Remaining gap |
|---|---|---|---|
| CLAUDE entrypoint and routing | Enforced | CI checks keep `CLAUDE.md`, `core/task-router.md`, and template wiring present. | Semantic correctness of every route still needs review. |
| Route Plan before writing | Enforced | Write/Edit gate blocks code writes without a current Route Plan with required sections. | Active-plan selection can still be improved for complex multi-task sessions. |
| DoD completion | Enforced | Plan-policy blocks unchecked changed plans; pre-commit blocks marking code complete while DoD remains unchecked. | DoD quality is still judgment-based. |
| Skill selection | Enforced | `check-required-skills.sh` requires task/domain/path-specific skills. | Rule coverage should expand as new skills are added. |
| Skill runtime evidence | Enforced | `pre-tool-use-runtime-evidence.sh` blocks declared skills without evidence. | Evidence quality is limited to recorded events, not deep semantic proof. |
| Learning schema | Enforced | `enforce-learning.sh` blocks malformed staged lessons and failed-solutions. | Only applies when a lesson/failed-solution is actually created. |
| Learning reuse | Enforced | `check-learning-reuse.sh` blocks work when relevant existing lessons/failed-solutions are not listed in the Route Plan. | Relevance is based on paths/tags, not deep semantic code understanding. |
| Learning capture after bug/debug work | Missing enforcement before this PR | None. | Add a gate requiring a new lesson, failed-solution, or explicit waiver for bug/debug/incident/rollback Route Plans. |
| Cleanup debug leftovers | Enforced | `enforce-quality.sh` blocks unambiguous debuggers and conflict markers. | Dead code, duplicate logic, unused imports, and speculative cleanup remain manual. |
| Cleanup semantic hygiene | Manual | Policy says to clean and verify. | Needs language/tool-specific analyzers or explicit manual checklist/waiver. |
| Tests/lint before commit | Partially enforced | Pre-commit runs stack-specific tests/lint where detected and blocks large unverified commits. | Missing tools can warn rather than fully block in all ecosystems. |
| Connector evidence | Partially enforced | Connector policy and CI require connector evidence in Route Plans when connectors are declared. | Selection of every required connector for every task is not yet fully deterministic. |
| Template evidence | Partially enforced | Workflow policy requires template fields/evidence/waiver in plans. | Automatic required-template selection by task class is incomplete. |
| Pattern usage | Partially enforced | Runtime gate checks known domains against `patterns/<domain>/` reads. | Domain detection is path/name based and incomplete. |
| Documentation structure | Partially enforced | Documentation policy blocks missing READMEs/TBDs in governed areas. | Duplicate docs, stale docs, and policy sprawl are not fully detected. |
| Project install contract | Enforced | CI installs Engineering OS into a temp project and checks expected hooks/files. | Only validates the expected contract, not every downstream project behavior. |
| Git/branch policy | Partially enforced | Hooks enforce branch/process rules in common paths. | Some GitHub-hosted actions and connector operations still require human/process discipline. |
| Code review | Manual/limited | Manual review and CI are used; CodeRabbit can help when available. | CodeRabbit is rate/credit limited and cannot be treated as a hard universal gate. |

## Definition of full operational readiness

Engineering OS can only be called fully operationally ready when every policy row is either:

1. **Enforced** by a deterministic hook, CI check, or runtime gate;
2. **Manual by design** with an explicit checklist and required review evidence; or
3. **Waiver-gated** so the agent cannot silently skip it.

Anything merely documented but silently skippable is not operationally ready.

## Highest-priority gaps

1. **Learning capture obligation** — bug/debug/incident/rollback work must create a lesson, create a failed-solution record, or explicitly waive capture.
2. **Connector selection** — task classes should require specific source-of-truth connectors, not only evidence after declaration.
3. **Template selection** — task classes/domains should require template search/selection or waiver.
4. **Documentation hygiene** — detect duplicate/stale policy spread and force canonical ownership.
5. **Semantic cleanup** — add language-specific analyzers for unused imports/dead code where reliable.

## Current PR scope

This PR addresses only gap 1: learning capture obligation.
