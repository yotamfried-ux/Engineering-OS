# Route Plan

| Field | Decision |
|---|---|
| Task type | governance validation |
| Task class | engineering_os_governance |
| Domain tags | governance, validation |
| Plan Scope | standard |
| Planning Mode | approved |
| Templates | not required because this is not a scaffold |
| Architecture guides | core/capability-registry.yaml |
| Patterns | scripts/enforcement tests |
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | enforcement-tests, pr-policy, connector-evidence-policy, workflow-evidence-policy, capability-evidence-policy, plan-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy |
| Evidence to check | exact-head CI |
| User decisions required | none |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Documentation Asset Evidence

- internal: core/task-router.md; core/capability-registry.yaml; scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh
- context7: not required because this is internal enforcement and does not implement or integrate an external library, SDK, API, or service.
- decision: internal validator and test assets confirmed that plan validation is the right enforcement layer for this change.

## Connector Evidence

GitHub used.

## Connector Usage Evidence

- source: GitHub connector.
- action: GitHub read and updated repository files.
- result: repository evidence files were added.
- target: .claude/plans/cvselect-evidence.md.
- decision: added evidence checkpoint.

## Skill Evidence

- superpowers used.

## Progress Lifecycle Evidence

- start: plan evidence added after implementation gaps were found by CI.
- mid: documentation and connector evidence were added for the changed enforcement files.
- pre-merge: exact-head CI is required before merge.
