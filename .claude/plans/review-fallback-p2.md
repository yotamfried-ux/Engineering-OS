# RF P2

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

- `routing.task-router-read` — routing policy checked.
- `workflow.workflow-read` — workflow policy checked.
- `plan.route-plan-before-write` — plan existed before workflow changes.
- `source.github-repo-read` — GitHub files inspected before edits.
- `validation.policy-change-has-validator` — PR policy validates required evidence.
- `validation.coderabbit-policy` — fallback review evidence is recorded in the PR.

## Connector Evidence

- github: checked PR policy, known gaps, and audit files.

## Connector Usage Evidence

- source: github PR policy, known gaps, and audit files.
- action: github inspection covered current policy and gap row.
- result: github showed review evidence was not hard-gated.
- decision: github evidence led to required evidence validation in the existing PR policy check.
- target: .github/workflows/pr-policy.yml, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Progress Lifecycle Evidence

- start: plan committed before workflow changes.
- mid: PR policy gate was committed after implementation began.
- pre-merge: this checkpoint was committed after connector evidence wording was fixed.

## Source of Truth Checks

| Source | Status |
|---|---|
| .github/workflows/pr-policy.yml | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Claude Run Trace

- goal: close review evidence gap.
- hypothesis: required structured evidence blocks vague manual review.
- result: PR policy, known gaps, and audit were updated.

## DoD

- [x] Plan created before edits.
- [x] Policy gate updated.
- [x] Known gaps updated.
- [x] Audit updated.
- [x] Connector usage evidence wording fixed.
- [x] Final checkpoint committed after connector evidence wording fix.
