# Route Plan - CV external-system selection

| Field | Decision |
|---|---|
| Task type | governance enforcement |
| Task class | engineering_os_governance |
| Domain tags | governance, external-systems, computer-vision, enforcement |
| Plan Scope | standard |
| Planning Mode | approved |
| Templates | not required because this is not a project scaffold |
| Architecture guides | external-systems/README.md; core/capability-registry.yaml |
| Patterns | existing scripts/enforcement check/test pattern |
| External systems/connectors | GitHub; supervision |
| Skills | superpowers |
| Validation gates | enforcement-tests, pr-policy, connector-evidence-policy, workflow-evidence-policy, capability-evidence-policy, plan-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy |
| Evidence to check | task-router domain tags; external-systems index; capability registry; exact-head CI |
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

GitHub used for repository state and PR checks.

## Connector Usage Evidence

- source: GitHub connector.
- action: verified current routing and external-system inventory.
- result: selected domain-specific external-system selection enforcement.
- target: core and scripts/enforcement files.
- decision: first enforced domain is Computer Vision -> Supervision or explicit waiver.

## Progress Lifecycle Evidence

- start: Route Plan created before code, policy, or test changes.
