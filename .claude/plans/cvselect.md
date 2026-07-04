# Route Plan - CV external-system selection

| Field | Decision |
|---|---|
| Task type | governance enforcement |
| Task class | engineering_os_governance |
| Domain tags | governance, external-systems, enforcement |
| Plan Scope | standard |
| Planning Mode | approved |
| Templates | not required because this is not a project scaffold |
| Architecture guides | external-systems/README.md; core/capability-registry.yaml |
| Patterns | existing scripts/enforcement check/test pattern |
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | enforcement-tests, pr-policy, connector-evidence-policy, workflow-evidence-policy, capability-evidence-policy, plan-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy |
| Evidence to check | validator checks route plans; test fixture covers the new rule; exact-head CI |
| User decisions required | none |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`
- `registry.service-connector-selected`

## Connector Evidence

GitHub was used for repository state and file updates.

## Connector Usage Evidence

- source: GitHub connector.
- action: GitHub read route, registry, validator, and test files.
- result: scripts/enforcement/validate-capability-evidence.sh and scripts/enforcement/tests/test-capability-evidence.sh were updated.
- target: core/external-system-selection-policy.md; scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh; .claude/plans/cvselect.md.
- decision: updated validation evidence.

## Skill Evidence

- superpowers used for plan-first and verification discipline.

## Progress Lifecycle Evidence

- start: Route Plan created before code, policy, or test changes.
- mid: added policy, validator logic, and a regression test fixture.
- mid: narrowed connector evidence to the active GitHub connector.
- pre-merge: validator, test, policy, and evidence updates are complete; exact-head CI is required before merge.
