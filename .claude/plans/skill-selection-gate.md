# Route Plan: skill selection gate

## Route Plan

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | `core/task-router.md` read. |
| Workflow evidence | `core/workflow.md` read. |
| Templates | Not required |
| Patterns | Not required |
| External systems/connectors | GitHub |
| Skills | None |
| Validation gates | enforcement-tests, workflow evidence, connector evidence, capability evidence, plan policy, PR policy, review |
| Target paths | scripts/enforcement, scripts/enforcement/tests, .claude/plans |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Source of Truth Checks

| Source | Status |
|---|---|
| `core/skill-orchestration-policy.md` | Read |
| `scripts/enforcement/pre-tool-use-runtime-evidence.sh` | Read |
| `scripts/enforcement/tests/test-skill-e2e.sh` | Read |
| `external-skills/README.md` | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for repo inspection, branch, commits, PR, and workflow checks. |

## Scope

Add deterministic skill-selection checks so task type/domain/path can require skills before implementation. This PR adds the checker, enforcement-test coverage, and the runtime wiring: `scripts/enforcement/pre-tool-use-runtime-evidence.sh` now invokes `check-required-skills.sh` against the active Route Plan and write target on every `Write/Edit/MultiEdit/NotebookEdit`, so a plan that fails to declare a required skill is denied at write time (not only in CI).

## Runtime Wiring

`pre-tool-use-runtime-evidence.sh` runs `check-required-skills.sh --plan <newest-plan> --target <file>` and emits the standard deny on failure, just before the existing declared-skill evidence block. Selection (are the right skills declared?) and evidence (were the declared skills run?) are now both enforced at runtime. Integration coverage lives in `scripts/enforcement/tests/test-runtime-evidence.sh` (blocks when a required skill is undeclared; allows when a `## Skill Selection Waiver` is present).

## Skill Selection Waiver

- `engineering_os_governance`: this task modifies the Engineering OS gate itself. Runtime coverage is provided by the new tests.

## Definition of Done

- [x] Current runtime skill-evidence gate is inspected.
- [x] Required skill selection checker is added.
- [x] Checker is wired into the runtime write hook (`pre-tool-use-runtime-evidence.sh`).
- [x] Tests prove UI/security/large-change/code/deprecated cases.
- [x] Integration test proves the runtime hook invokes the checker (block + waiver).
- [x] CI is checked before merge.
