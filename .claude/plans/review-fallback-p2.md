# P2

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

- `routing.task-router-read` — checked.
- `workflow.workflow-read` — checked.
- `plan.route-plan-before-write` — checked.
- `source.github-repo-read` — checked.
- `validation.policy-change-has-validator` — checked.
- `validation.coderabbit-policy` — checked.

## Connector Evidence

- github: checked .github/workflows/pr-policy.yml, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Connector Usage Evidence

- source: github .github/workflows/pr-policy.yml, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.
- action: github checked .github/workflows/pr-policy.yml and docs/operations.
- result: github showed P2 policy gap.
- decision: github implemented .github/workflows/pr-policy.yml update.
- target: .github/workflows/pr-policy.yml, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Progress Lifecycle Evidence

- start: plan committed before workflow changes.
- mid: workflow update committed after implementation began.
- pre-merge: this checkpoint was committed after final evidence wording.

## Source of Truth Checks

| Source | Status |
|---|---|
| .github/workflows/pr-policy.yml | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Claude Run Trace

- goal: close P2 gap.
- hypothesis: structured policy evidence blocks vague process.
- result: workflow and docs updated.

## DoD

- [x] Plan created before edits.
- [x] Workflow updated.
- [x] Docs updated.
- [x] Final checkpoint committed after final evidence wording.
