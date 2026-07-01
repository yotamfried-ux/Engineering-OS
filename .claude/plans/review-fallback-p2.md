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

- `routing.task-router-read` — task routing requirements were checked before selecting the review-governance gap.
- `workflow.workflow-read` — workflow requirements were checked before changing PR policy behavior.
- `plan.route-plan-before-write` — this plan was committed before the PR policy implementation commit.
- `source.github-repo-read` — GitHub source files were inspected before updating the workflow and audit files.
- `validation.policy-change-has-validator` — the policy change includes a deterministic PR workflow gate that validates review evidence.

## Connector Evidence

- github: checked `.github/workflows/pr-policy.yml`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md` before changes.

## Connector Usage Evidence

- source: github `.github/workflows/pr-policy.yml`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.
- action: inspected the current PR policy and review fallback gap.
- result: github showed the PR policy only blocks draft pull requests and does not require review evidence or fallback evidence.
- decision: added a PR body evidence gate that requires either external review evidence or review fallback evidence with concrete fields.
- target: .github/workflows/pr-policy.yml, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Progress Lifecycle Evidence

- start: plan committed before PR policy changes.
- mid: PR policy review evidence gate was committed after implementation began.
- pre-merge: this checkpoint was committed after the capability evidence repair.

## Source of Truth Checks

| Source | Status |
|---|---|
| .github/workflows/pr-policy.yml | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Claude Run Trace

- goal: close review fallback gap with deterministic PR evidence.
- hypothesis: requiring structured review or fallback evidence in PR body prevents vague manual review when external review is unavailable.
- result: PR policy now requires external review evidence or structured fallback evidence; known-gaps and audit mark the structural gap closed.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Current PR policy inspected.
- [x] Known gaps and audit inspected.
- [x] PR body review evidence gate committed.
- [x] Known gaps updated after policy gate.
- [x] Audit ledger and status row updated after policy gate.
- [x] Capability evidence expanded after CI failure.
- [x] Final checkpoint committed after capability evidence repair.
