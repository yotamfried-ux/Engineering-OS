# Capability Verification Framework

## Purpose

`capability-verify.sh` generates a single report for Engineering OS capabilities across four classes:

- skills and engines, via `scripts/skill-bootstrap.sh --json`
- MCP connectors, via `core/capability-registry.yaml` and `core/mcp-servers.md`
- service connector documentation, via `core/capability-registry.yaml`
- templates, via `core/capability-registry.yaml`

The report is verification-only. It does not auto-install MCP connectors, request OAuth, or change managed settings.

## Command

```bash
ENGINEERING_OS_HOME=/path/to/Engineering-OS \
  bash /path/to/Engineering-OS/scripts/capability-verify.sh \
  --output ENGINEERING_OS_CAPABILITIES.md
```

JSON output is available for tests and future automation:

```bash
ENGINEERING_OS_HOME=/path/to/Engineering-OS \
  bash /path/to/Engineering-OS/scripts/capability-verify.sh --json
```

## Target install behavior

`use-in-project.sh` now writes `ENGINEERING_OS_CAPABILITIES.md` into the target project. `ENGINEERING_OS_SETUP.md` points the user to that report instead of maintaining a static checklist for a few hand-picked tools.

## Status meanings

| Status | Meaning |
|---|---|
| `present` | Capability appears configured or installed in the current environment. |
| `missing` | Required local asset is missing. |
| `requires_auth` | Connector is known but needs auth/OAuth/secret before use. |
| `documented` | Service connector documentation exists in Engineering OS. |
| `missing_doc` | Registry references documentation that does not exist. |

## Boundaries

This framework intentionally does not:

- install MCP connectors automatically;
- grant write access to connectors;
- bypass OAuth or secret setup;
- decide which conditional connector is required for a task;
- enforce task routing at runtime.

The future runtime step is: selected task class → required capabilities from `core/capability-registry.yaml` → evidence ledger/hook enforcement.
