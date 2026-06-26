# Managed Settings Deployment Proof

## Purpose

This runbook proves that the conservative Claude Code managed settings template has a safe deployment path and a real-workstation verification procedure.

This is a deployment proof, not a broader policy rollout. The source policy remains:

```text
templates/settings/claude-managed-lockdown.json
```

The template currently locks managed hooks and managed MCP server access. It allowlists only the approved `github-readonly` MCP profile.

## Current safety status

The current template sets `allowManagedHooksOnly: true`. Active deployment is blocked unless managed replacement hooks are deployed at the same managed scope.

Reason: `allowManagedHooksOnly: true` can block user/project hooks. Deploying it without managed replacements would disable local Engineering OS enforcement hooks instead of hardening them.

Therefore this runbook has two modes:

1. **Readiness proof** — safe today. Validate the template, confirm active deployment is blocked until managed hooks exist, and record the blocker.
2. **Active deployment proof** — future-only. Run only after a separate PR introduces and validates managed hook replacements.

## What this proof does

This proof verifies the following operational path:

```text
repository template -> safety preflight -> system managed settings path -> Claude Code status/permissions evidence -> rollback or restore
```

It is intentionally limited to one workstation and one file-based managed settings deployment.

## What this proof does not do

Do not use this runbook to:

- Copy the template into `.claude/settings.json`.
- Enable managed settings from `use-in-project.sh`.
- Add `allowManagedPermissionRulesOnly`.
- Lock skills, agents, or permission rules.
- Add MDM/Jamf/Kandji/Intune/GPO automation.
- Configure server-managed organization settings.
- Add new MCP servers beyond `github-readonly`.
- Deploy active managed settings when managed hook replacements are absent.

`allowManagedPermissionRulesOnly` remains deferred until a future PR provides a managed `permissions` block. Enabling permission-rule managed-only mode without managed rules can silently disable user/project permission expectations.

## Required source template

Before any workstation action, validate the repository template:

```bash
bash scripts/enforcement/tests/test-managed-settings-template.sh
```

Expected result:

```text
✅ managed settings template is valid
```

## Safety preflight

Run this preflight before copying any file into a managed settings path:

```bash
python3 - <<'PY'
import json
from pathlib import Path

settings = json.loads(Path("templates/settings/claude-managed-lockdown.json").read_text())
hooks = settings.get("hooks")
if settings.get("allowManagedHooksOnly") is True and not hooks:
    raise SystemExit(
        "STOP: allowManagedHooksOnly is true but no managed hooks are defined. "
        "Active deployment is blocked until managed hook replacements are available."
    )
print("✅ managed settings active deployment preflight passed")
PY
```

Expected result for the current template:

```text
STOP: allowManagedHooksOnly is true but no managed hooks are defined. Active deployment is blocked until managed hook replacements are available.
```

That STOP is a successful readiness proof result for the current Engineering OS state. It proves that the runbook will not deploy a configuration that disables existing project hooks.

## Deployment paths

Use the official file-based managed settings path for the local operating system.

Do not run the active deployment commands below until the safety preflight passes.

### Linux / WSL

```bash
sudo install -d /etc/claude-code
MANAGED_SETTINGS_PATH=/etc/claude-code/managed-settings.json
BACKUP_PATH=""
if [ -f "$MANAGED_SETTINGS_PATH" ]; then
  BACKUP_PATH="${MANAGED_SETTINGS_PATH}.backup.$(date +%Y%m%d%H%M%S)"
  sudo cp -p "$MANAGED_SETTINGS_PATH" "$BACKUP_PATH"
  echo "Backed up existing managed settings to: $BACKUP_PATH"
fi
sudo install -m 0644 templates/settings/claude-managed-lockdown.json "$MANAGED_SETTINGS_PATH"
```

### macOS

```bash
sudo install -d "/Library/Application Support/ClaudeCode"
MANAGED_SETTINGS_PATH="/Library/Application Support/ClaudeCode/managed-settings.json"
BACKUP_PATH=""
if [ -f "$MANAGED_SETTINGS_PATH" ]; then
  BACKUP_PATH="${MANAGED_SETTINGS_PATH}.backup.$(date +%Y%m%d%H%M%S)"
  sudo cp -p "$MANAGED_SETTINGS_PATH" "$BACKUP_PATH"
  echo "Backed up existing managed settings to: $BACKUP_PATH"
fi
sudo install -m 0644 templates/settings/claude-managed-lockdown.json "$MANAGED_SETTINGS_PATH"
```

## Verification commands

After copying the file, start a fresh Claude Code session and run:

```bash
claude doctor
```

Inside Claude Code, run:

```text
/status
/permissions
```

The proof is successful only when the operator can record evidence that managed settings are loaded from the managed/system source and that the expected managed controls are active.

## Expected managed controls

The deployed managed settings must preserve these expectations:

| Control | Expected value |
|---|---|
| `allowManagedHooksOnly` | `true`, only with managed hook replacements deployed |
| `allowManagedMcpServersOnly` | `true` |
| `strictPluginOnlyCustomization` | `hooks,mcp` only |
| `allowedMcpServers` | `github-readonly` only |
| managed `hooks` | required before active deployment |
| `allowManagedPermissionRulesOnly` | absent / deferred |
| `skills` lock | absent / deferred |
| `agents` lock | absent / deferred |

## Checksum evidence

Record the template checksum before deployment:

```bash
sha256sum templates/settings/claude-managed-lockdown.json
```

Record the deployed file checksum after deployment.

Linux / WSL:

```bash
sha256sum /etc/claude-code/managed-settings.json
```

macOS:

```bash
shasum -a 256 "/Library/Application Support/ClaudeCode/managed-settings.json"
```

The source and deployed checksums must match for this proof.

## Deployment Evidence Record

Fill this section after a real workstation proof. Do not commit secrets, tokens, screenshots containing private paths, or account identifiers.

```text
Date:
Operator:
Machine:
OS:
Claude Code version:
Managed settings path used:
Source template checksum:
Deployed file checksum:
Safety preflight result:
Existing managed settings file present: yes/no
Backup path, if created:
claude doctor result:
/status evidence:
/permissions evidence:
Rollback or restore tested: yes/no
Notes:
```

## Rollback or restore

If a backup was created, restore it. If no previous file existed, remove only the proof deployment artifact.

### Linux / WSL

Restore previous managed settings:

```bash
BACKUP_PATH="<paste the recorded backup path here>"
sudo cp -p "$BACKUP_PATH" /etc/claude-code/managed-settings.json
```

Remove proof artifact when there was no previous managed settings file:

```bash
sudo rm -f /etc/claude-code/managed-settings.json
```

### macOS

Restore previous managed settings:

```bash
BACKUP_PATH="<paste the recorded backup path here>"
sudo cp -p "$BACKUP_PATH" "/Library/Application Support/ClaudeCode/managed-settings.json"
```

Remove proof artifact when there was no previous managed settings file:

```bash
sudo rm -f "/Library/Application Support/ClaudeCode/managed-settings.json"
```

After rollback or restore, start a fresh Claude Code session and rerun:

```bash
claude doctor
```

Then run inside Claude Code:

```text
/status
/permissions
```

Record whether the managed settings source was restored or is no longer active.

## Failure modes

| Failure | Likely cause | Action |
|---|---|---|
| Safety preflight stops active deployment | `allowManagedHooksOnly` is true and managed hook replacements are absent | Treat as expected for the current template; add managed hook bundle in a separate PR before active deployment |
| Existing managed settings file would be overwritten | Workstation already has a managed policy | Back it up first and restore it during rollback |
| `/status` does not show managed/system settings | File path is wrong or Claude Code was not restarted | Recheck OS path and restart Claude Code |
| `/permissions` does not reflect expected managed controls | Wrong file was deployed or stale session | Compare checksums and restart |
| Claude Code refuses to start | Invalid JSON or unsupported setting key | Restore rollback, run template validator, retry |
| Unexpected permission behavior | Permission-rule lockdown was added too early | Remove `allowManagedPermissionRulesOnly` and keep permission rules deferred |

## Completion criteria

This PR step is complete when:

1. This runbook exists.
2. CI validates the runbook and policy boundaries.
3. The safety preflight blocks active deployment while managed hook replacements are absent.
4. Backup/restore instructions preserve any pre-existing managed settings file.

Full active deployment proof is complete only after a future PR adds managed hook replacements and the active deployment path is run on a real workstation with rollback or restore tested.
