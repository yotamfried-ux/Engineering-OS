# Managed Settings Deployment Proof

## Purpose

This runbook proves that the conservative Claude Code managed settings template can be deployed and verified on one real workstation.

This is a deployment proof, not a broader policy rollout. The source policy remains:

```text
templates/settings/claude-managed-lockdown.json
```

The template currently locks only managed hooks and managed MCP server access. It allowlists only the approved `github-readonly` MCP profile.

## What this proof does

This proof verifies the following operational path:

```text
repository template -> system managed settings path -> Claude Code status/permissions evidence -> rollback
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

`allowManagedPermissionRulesOnly` remains deferred until a future PR provides a managed `permissions` block. Enabling permission-rule managed-only mode without managed rules can silently disable user/project permission expectations.

## Required source template

Before deploying, validate the repository template:

```bash
bash scripts/enforcement/tests/test-managed-settings-template.sh
```

Expected result:

```text
✅ managed settings template is valid
```

## Deployment paths

Use the official file-based managed settings path for the local operating system.

### Linux / WSL

```bash
sudo install -d /etc/claude-code
sudo cp templates/settings/claude-managed-lockdown.json /etc/claude-code/managed-settings.json
sudo chmod 0644 /etc/claude-code/managed-settings.json
```

### macOS

```bash
sudo install -d "/Library/Application Support/ClaudeCode"
sudo cp templates/settings/claude-managed-lockdown.json "/Library/Application Support/ClaudeCode/managed-settings.json"
sudo chmod 0644 "/Library/Application Support/ClaudeCode/managed-settings.json"
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
| `allowManagedHooksOnly` | `true` |
| `allowManagedMcpServersOnly` | `true` |
| `strictPluginOnlyCustomization` | `hooks,mcp` only |
| `allowedMcpServers` | `github-readonly` only |
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
claude doctor result:
/status evidence:
/permissions evidence:
Rollback tested: yes/no
Notes:
```

## Rollback

Linux / WSL:

```bash
sudo rm -f /etc/claude-code/managed-settings.json
```

macOS:

```bash
sudo rm -f "/Library/Application Support/ClaudeCode/managed-settings.json"
```

After rollback, start a fresh Claude Code session and rerun:

```bash
claude doctor
```

Then run inside Claude Code:

```text
/status
/permissions
```

Record that the managed settings source is no longer active.

## Failure modes

| Failure | Likely cause | Action |
|---|---|---|
| `/status` does not show managed/system settings | File path is wrong or Claude Code was not restarted | Recheck OS path and restart Claude Code |
| `/permissions` does not reflect expected managed controls | Wrong file was deployed or stale session | Compare checksums and restart |
| Claude Code refuses to start | Invalid JSON or unsupported setting key | Restore rollback, run template validator, retry |
| Unexpected permission behavior | Permission-rule lockdown was added too early | Remove `allowManagedPermissionRulesOnly` and keep permission rules deferred |

## Completion criteria

This step is complete when:

1. This runbook exists.
2. CI validates the runbook and policy boundaries.
3. A real workstation proof fills the Deployment Evidence Record.
4. Rollback is tested.

The repository PR can merge after CI and review. The real workstation proof may be recorded after merge because CI cannot access a user's managed Claude Code installation.
