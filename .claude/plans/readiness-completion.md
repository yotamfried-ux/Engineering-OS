# Route Plan

## Route Plan

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Templates | Not required |
| Patterns | Not required |
| External systems/connectors | GitHub |
| Skills | none |
| Validation gates | enforcement-tests, workflow evidence, connector evidence, capability evidence, plan policy, PR policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

> CodeRabbit itself is deferred for this work (no active subscription/credits). The
> `validation.coderabbit-policy` capability is recorded here because the registry requires it for the
> `engineering_os_governance` class; the policy file (`core/coderabbit-policy.md`) remains the source of
> truth and is unchanged.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/git-policy.md | Read |
| core/capability-registry.yaml | Read |
| scripts/enforcement/check-workflow-evidence.sh | Read |
| scripts/enforcement/validate-capability-evidence.sh | Read |
| scripts/enforcement/check-merge-readiness.sh | Read |
| scripts/enforcement/patch-settings-runtime-evidence.sh | Read |
| scripts/use-in-project.sh | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used |

## Definition of Done

- `check-plan-scope.sh` is wired into the install/runtime flow (via `patch-settings-runtime-evidence.sh`)
  and proven by `scripts/enforcement/tests/test-plan-scope.sh`.
- Branch protection requirements are documented in `docs/operations/main-required-checks.md` and kept in
  sync with `check-merge-readiness.sh` by `test-required-workflows-contract.sh`.
- All required policy workflows are green and the changes merge to `main`.
