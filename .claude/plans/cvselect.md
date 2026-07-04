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
| Evidence to check | validator enforces CV route plans; test fixture fails without supervision; exact-head CI |
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
- action: read current routing, registry, validator, and test files.
- result: selected validator-based domain enforcement instead of a separate script after new script writes were blocked.
- target: core/external-system-selection-policy.md; scripts/enforcement/validate-capability-evidence.sh; scripts/enforcement/tests/test-capability-evidence.sh.
- decision: first enforced domain is Computer Vision -> Supervision or explicit waiver.

## Skill Evidence

- superpowers used for plan-first and verification discipline.

## Progress Lifecycle Evidence

- start: Route Plan created before code, policy, or test changes.
- mid: added external-system selection policy, added CV -> supervision enforcement inside validate-capability-evidence.sh, and added a negative regression fixture to test-capability-evidence.sh proving CV plans without supervision/waiver fail.
