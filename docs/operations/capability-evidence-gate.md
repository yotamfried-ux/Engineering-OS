# Capability Evidence Gate

## Purpose

The capability evidence gate is the first runtime/CI bridge from `core/capability-registry.yaml` into actual work plans.

It does not infer the task class automatically. Instead, it forces each changed Engineering OS plan to state:

- the selected `Task class` from `core/capability-registry.yaml`; and
- either a `Capability Evidence` section or a `Capability Waiver` section.

## Required plan format

```md
Task class: engineering_os_maintenance

## Capability Evidence

- `superpowers` — planning/review capability selected.
- `github` — connector used for repository evidence.
- `security-review` — required before merge, or documented waiver.
```

Table form is also accepted:

```md
| Field | Decision |
|---|---|
| Task class | engineering_os_maintenance |
```

## Waiver format

Use a waiver only when a capability or task class is not relevant:

```md
Task class: unclassified

## Capability Waiver

Reason: no registry task class maps to this documentation-only cleanup.
```

## Enforcement

- Script: `scripts/enforcement/validate-capability-evidence.sh`
- Tests: `scripts/enforcement/tests/test-capability-evidence.sh`
- PR workflow: `.github/workflows/capability-evidence-policy.yml`
- Target install: `scripts/install-policy-gates.sh` copies the workflow to target projects.

## Boundary

This gate is intentionally narrow. It verifies that routing evidence exists. It does not yet:

- auto-select task class;
- parse every required capability per task class;
- auto-install MCP connectors;
- block runtime tool calls based on selected task class.

The next step is to parse task-class requirements from `core/capability-registry.yaml` and compare them to the listed capability IDs.
