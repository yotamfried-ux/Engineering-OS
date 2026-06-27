# Capability Evidence Gate

## Purpose

The capability evidence gate is the runtime/CI bridge from `core/capability-registry.yaml` into actual work plans.

It does not infer the task class automatically. Instead, it forces each changed Engineering OS plan to state:

- the selected `Task class` from `core/capability-registry.yaml`; and
- evidence or a focused waiver for every capability listed under that task class's `required_capabilities`.

## Required plan format

```md
Task class: engineering_os_governance

## Capability Evidence

- `routing.task-router-read` — task router policy was checked before implementation.
- `workflow.workflow-read` — workflow policy was checked.
- `plan.route-plan-before-write` — plan existed before implementation changes.
- `source.github-repo-read` — repository files were inspected through GitHub.
- `validation.policy-change-has-validator` — validator/tests were updated.
- `validation.coderabbit-policy` — CodeRabbit status was checked or manual review fallback was recorded.
```

Table form is also accepted:

```md
| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
```

## Waiver format

Use a waiver only when a required capability or task class is not relevant:

```md
Task class: engineering_os_governance

## Capability Evidence

- `routing.task-router-read` — task router policy was checked.
- `workflow.workflow-read` — workflow policy was checked.
- `plan.route-plan-before-write` — plan existed before changes.
- `source.github-repo-read` — repository files were inspected.
- `validation.policy-change-has-validator` — validator/tests were updated.

## Capability Waiver

- `validation.coderabbit-policy` — reason: CodeRabbit is rate-limited, so the user-approved manual review fallback is used.
```

For `Task class: unclassified` or any unknown task class, a `Capability Waiver` with a reason is mandatory.

## Enforcement

- Script: `scripts/enforcement/validate-capability-evidence.sh`
- Tests: `scripts/enforcement/tests/test-capability-evidence.sh`
- PR workflow: `.github/workflows/capability-evidence-policy.yml`
- Target install: `scripts/install-policy-gates.sh` copies the workflow to target projects.

## Boundary

This gate verifies that the selected task class is connected to concrete required capabilities. It does not yet:

- auto-select task class;
- auto-install MCP connectors;
- request OAuth/secrets;
- block runtime tool calls based on selected task class.

The next step is to move from plan-level evidence matching to live evidence-ledger enforcement during tool use.
