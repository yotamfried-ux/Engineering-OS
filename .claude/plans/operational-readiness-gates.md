# Route Plan: operational readiness gates

Branch: `fix/operational-readiness-gates`

## Route Plan

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task type | Engineering OS maintenance / enforcement hardening |
| Domain tags | workflow, connector evidence, merge gate, runtime evidence, hooks, CI |
| Task-router evidence | `core/task-router.md` routes Engineering OS governance/script/workflow changes through plan-first workflow and validator updates. |
| Workflow evidence | `core/workflow.md` requires plan-first execution, verification through tools, code review, and user-approved merge. |
| Templates | Not required; this is policy/enforcement infrastructure, not a target project scaffold. |
| Patterns | Not required; this changes deterministic gates, not app implementation patterns. |
| External systems/connectors | GitHub |
| Skills | None |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy, pr-policy, CodeRabbit/manual review |

## Capability Evidence

- `routing.task-router-read` — task routed as Engineering OS governance.
- `workflow.workflow-read` — workflow policy checked before writes.
- `plan.route-plan-before-write` — this plan exists before enforcement changes.
- `source.github-repo-read` — GitHub connector used to inspect PR #107, workflow failures, and source files.
- `validation.policy-change-has-validator` — this PR adds regression tests for the corrected gates.
- `validation.coderabbit-policy` — PR will be opened ready for review; if CodeRabbit is unavailable, manual review loop is recorded.

## Source of Truth Checks

| Source | Why it matters | Status |
|---|---|---|
| `CLAUDE.md` | Entrypoint, PR/change process, ownership. | Read |
| `core/task-router.md` | Deterministic routing for Engineering OS governance changes. | Read |
| `core/workflow.md` | Plan-first workflow and verification contract. | Read |
| `core/hooks-policy.md` | Deterministic enforcement, fail-closed behavior, known hook gaps. | Read |
| `.github/workflows/workflow-evidence-policy.yml` | Existing workflow evidence gate that failed on PR #107. | Read |
| `.github/workflows/connector-evidence-policy.yml` | Existing connector evidence gate that failed on PR #107. | Read |
| `scripts/enforcement/pre-tool-use-runtime-evidence.sh` | Runtime evidence write gate with known malformed JSON fail-open gap. | Read |
| `scripts/enforcement/enforce-workflow.sh` | Main workflow enforcer; now protected by a PreToolUse JSON guard before routing. | Read |
| `scripts/enforcement/tests/` | Existing enforcement tests extended with regressions. | Read |

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Used to inspect PR #107, workflow status, job logs, branch state, source files, and to commit this enforcement patch. |

## Skill Evidence

Not required; no external skill is needed for this deterministic enforcement patch.

## Scope

- Add a deterministic pre-merge/self-review checker that fails if required PR workflows failed or are still missing.
- Add tests proving the PR #107 failure pattern is no longer accepted by the checker.
- Make malformed or missing PreToolUse JSON fail closed in runtime/write gates and before workflow routing for enforcement-relevant tools.
- Add tests proving malformed JSON is blocked.

## Non-goals

- Do not change product architecture.
- Do not add new long-lived Markdown ownership files.
- Do not auto-configure GitHub branch protection, because repository settings are not represented as code here.
- Do not merge without explicit user approval.

## Definition of Done

- [x] Merge/readiness checker blocks failed workflow runs.
- [x] Checker passes when all required workflow runs are successful.
- [x] Runtime evidence pre-write gate fails closed on malformed hook JSON.
- [x] PreToolUse JSON guard blocks malformed JSON and missing write file_path / Bash command before workflow routing.
- [x] Enforcement tests cover the new negative and positive cases.
- [ ] PR is opened ready for review, not draft.
- [ ] CodeRabbit or manual review is recorded before merge.
