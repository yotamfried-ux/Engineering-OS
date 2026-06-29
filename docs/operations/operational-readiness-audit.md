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
| Skill runtime evidence | Enforced | Runtime evidence gate blocks declared skills without evidence. | Evidence quality is limited to recorded events, not deep semantic proof. |
| Learning schema | Enforced | `enforce-learning.sh` blocks malformed staged lessons and failed-solutions. | Semantic lesson quality still needs review beyond fixed schema. |
| Learning reuse | Enforced | Relevant existing lessons/failed-solutions must be listed in the Route Plan. | Relevance is based on paths/tags, not deep semantic code understanding. |
| Learning capture after bug/debug work | Enforced | Bug/debug/incident code changes require a staged complete bug lesson; failed-solutions are additional, not a substitute. | Semantic lesson quality still needs review beyond fixed schema. |
| Cleanup debug leftovers | Enforced | `enforce-quality.sh` blocks unambiguous debuggers and conflict markers. | Dead code, duplicate logic, unused imports, and speculative cleanup remain manual. |
| Cleanup semantic hygiene | Manual | Policy says to clean and verify. | Needs language/tool-specific analyzers or explicit manual checklist/waiver. |
| Tests/lint before commit | Partially enforced | Pre-commit runs stack-specific tests/lint where detected and blocks large unverified commits. | Missing tools can warn rather than fully block in all ecosystems. |
| Connector evidence and selection | Enforced for covered cases | Required connector selection is checked by task/domain/path; declared connectors require evidence; Notion progress validation is required for non-trivial work in installed target settings. | Coverage should expand as new connectors/task classes are added. |
| Template evidence and selection | Enforced for covered cases | Required template selection is checked by task/domain/path; declared templates still require read/usage evidence through the runtime evidence gate. | Coverage should expand as new templates/task classes are added. |
| RTK context optimization | Enforced as wiring contract | RTK policy is mandatory; CI checks the RTK policy, Bash hook wiring, SessionStart setup, and target-project install contract. | Runtime installation can still warn instead of block when the local machine lacks cargo/network. |
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

1. **Documentation hygiene** — detect duplicate/stale policy spread and force canonical ownership.
2. **Semantic cleanup** — add language-specific analyzers for unused imports/dead code where reliable.
3. **Pattern selection expansion** — expand domain detection and waiver behavior beyond current path/name rules.
4. **Connector/template coverage expansion** — add new rules as new task classes and project domains appear.
5. **RTK runtime hardening** — decide whether local RTK install failures should block or remain warnings on machines without cargo/network.

## Current PR scope

This PR addresses template selection enforcement and adds RTK contract enforcement coverage.
