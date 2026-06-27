# Capability Registry Enforcement Runbook

## Purpose

`core/capability-registry.yaml` is the project-level decision source for task classes, required capabilities, and required evidence.

This runbook explains how to use and validate the registry today. It does **not** enable runtime enforcement by itself.

## Current status

| Area | Status |
|---|---|
| Registry shape | inventory-backed |
| Runtime hooks | not enabled from this registry yet |
| Target-project MCP auto-install | disabled |
| Managed settings activation | disabled |
| Broad MCP defaults | disallowed |

## Ownership chain

All capability decisions must follow this chain:

```text
CLAUDE.md → core/capability-registry.yaml → validator/test → runtime hook in a later PR
```

Do not define required capabilities only in a README, template, or plan file.

## Agent usage contract

At the start of a non-trivial task, the agent should:

1. Classify the task with `core/task-router.md`.
2. Find the matching `task_classes` entry in `core/capability-registry.yaml`.
3. Copy the required capabilities and required evidence into the Route Plan.
4. Record explicit waivers for capabilities that appear applicable but are not used.
5. Only then proceed to implementation.

For a broad request such as "build a SaaS", use `new_project_or_saas` until a more precise task class is selected.

## Validation

Run:

```bash
bash scripts/enforcement/tests/test-capability-registry.sh
```

The validator checks:

- registry status is `inventory_backed`;
- runtime is still disabled in this PR;
- MCP auto-install and managed runtime lockdown remain disabled;
- every documented service connector in `external-systems/README.md` is represented in `service_connectors`;
- every documented MCP connector in `external-systems/README.md` is represented in `mcp_connectors`;
- every documented external skill row is represented as active skill, LLM accelerator, or deprecated/reference-only entry;
- Nemotron is not counted as an active workflow skill;
- `frontend-design` is not active;
- required capability names resolve to entries under `capabilities`;
- broad MCP defaults such as `all` and `default` are not introduced.

## Runtime-enforcement boundary

This PR intentionally stops at an inventory-backed registry and validator.

A later PR may wire the registry into hooks, but only after it adds tests for:

- task-class selection from broad prompts;
- write blocking when required evidence is missing;
- waiver recording;
- clean installation into a target repo;
- MCP/managed-settings activation evidence.

## Change rules

When changing the registry:

1. Update `core/capability-registry.yaml`.
2. Update this runbook only if behavior or validation changed.
3. Update `scripts/enforcement/tests/test-capability-registry.sh` if a new invariant is introduced.
4. Do not update `CLAUDE.md` unless the navigation structure itself changes.
5. Do not update `external-skills/README.md` for engine reclassification here; that belongs to the Nemotron PR.
6. Do not update `external-systems/README.md` unless the service inventory itself changes.
