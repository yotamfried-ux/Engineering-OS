# Review Fallback P2

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Target paths | .github/workflows/pr-policy.yml, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | not required |
| External systems/connectors | github |
| Skills | none |
| Validation gates | pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy, enforcement-tests |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`

## Connector Evidence

- github: checked `.github/workflows/pr-policy.yml`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md` before changes.

## Connector Usage Evidence

- source: github `.github/workflows/pr-policy.yml`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.
- action: inspected the current PR policy and review fallback gap.
- result: github showed the PR policy only blocks draft pull requests and does not require review evidence or fallback evidence.
- decision: add a PR body evidence gate that requires either external review evidence or review fallback evidence with concrete fields.
- target: .github/workflows/pr-policy.yml, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Progress Lifecycle Evidence

- start: plan committed before PR policy changes.

## Source of Truth Checks

| Source | Status |
|---|---|
| .github/workflows/pr-policy.yml | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Claude Run Trace

- goal: close review fallback gap with deterministic PR evidence.
- hypothesis: requiring structured review or fallback evidence in PR body prevents vague manual review when external review is unavailable.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Current PR policy inspected.
- [x] Known gaps and audit inspected.
