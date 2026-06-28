# Route Plan

## Route Plan

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | `core/task-router.md` read |
| Workflow evidence | `core/workflow.md` read |
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

> CodeRabbit is deferred (no subscription); the `validation.coderabbit-policy` ID is recorded only
> because the registry requires it for `engineering_os_governance`. CodeRabbit is intentionally
> excluded from the branch-protection required checks.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-merge-readiness.sh | Read |
| scripts/enforcement/tests/test-required-workflows-contract.sh | Read |
| docs/operations/main-required-checks.md | Read |
| .github/workflows/*.yml (job names) | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used for branch creation, repo/branch inspection, and PR/workflow checks. |

## Scope

Add committed, idempotent ops scripts that the repo owner runs with their own credentials to
(a) apply server-side branch protection on `main` with the 6 required check contexts, and
(b) prune merged + superseded branches. Update docs and add a regression test. This environment
cannot perform the GitHub admin API calls itself (proxy 403 / no MCP tool), so the scripts are
dry-run-by-default and verified here; real `--apply` is the owner's step.

## Definition of Done

- [x] `scripts/ops/apply-main-branch-protection.sh` added (dry-run verified, 6 contexts).
- [x] `scripts/ops/prune-merged-branches.sh` added (dry-run verified, refuses unknown branches).
- [x] `docs/operations/main-required-checks.md` updated with the context mapping + how-to.
- [x] `scripts/enforcement/tests/test-ops-branch-protection.sh` added and passing.
- [x] CI is green before merge.
