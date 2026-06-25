# Route Plan: Enforce Workflow Evidence Gate

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance / governance |
| Domain tags | governance, workflow, ci, enforcement, learning-loop, templates, skills |
| Templates | none — internal policy gate change |
| Architecture guides | core/hooks-policy.md, core/task-router.md, core/workflow.md |
| Patterns | scripts/enforcement/check-connector-evidence.sh, scripts/enforcement/tests/test-connector-evidence.sh |
| External systems/connectors | none |
| Skills | superpowers-verify |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, plan-policy, pr-policy |
| Task-router evidence | Engineering OS maintenance route requires workflow, connector, learning-loop and hooks policy review |
| Workflow evidence | workflow requires plan, source checks, templates/patterns, skills, validation and learning closure |

## Source of Truth Checks

| Need | Source checked | Result |
|---|---|---|
| Current connector route-plan enforcement | scripts/enforcement/check-connector-evidence.sh | validates plan existence and connector evidence only |
| Installed target workflows | scripts/install-policy-gates.sh | currently installs pr, plan, connector gates |
| CI contract | .github/workflows/enforcement-tests.yml | target install contract excludes workflow evidence policy |

## Skill Evidence

- [x] superpowers-verify planned for final review through regression tests and CI contract updates.

## Template Gap Waiver

No reusable project scaffold template is needed for this internal policy gate. This PR adds an enforcement pattern.

## Implementation Checklist

- [x] Add workflow evidence checker script.
- [x] Add regression tests.
- [x] Add GitHub Actions workflow for target repos.
- [x] Install the new workflow in target projects.
- [x] Update clean-install contract.
