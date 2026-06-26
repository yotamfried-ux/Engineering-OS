#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
RUNBOOK="$ROOT/docs/operations/managed-settings-deployment-proof.md"
TEMPLATE="$ROOT/templates/settings/claude-managed-lockdown.json"

test -f "$RUNBOOK"
test -f "$TEMPLATE"

python3 - "$RUNBOOK" "$TEMPLATE" <<'PY'
import json
import sys
from pathlib import Path

runbook = Path(sys.argv[1]).read_text(encoding="utf-8")
settings = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

required_runbook_terms = [
    "templates/settings/claude-managed-lockdown.json",
    "repository template -> safety preflight -> system managed settings path -> Claude Code status/permissions evidence -> rollback or restore",
    "Do not use this runbook to:",
    "Copy the template into `.claude/settings.json`.",
    "Enable managed settings from `use-in-project.sh`.",
    "Add `allowManagedPermissionRulesOnly`.",
    "allowManagedPermissionRulesOnly` remains deferred",
    "Active deployment is blocked until managed hook replacements are available.",
    "Do not run the active deployment commands below until the safety preflight passes.",
    "hooks = settings.get(\"hooks\")",
    "if settings.get(\"allowManagedHooksOnly\") is True and not hooks:",
    "sudo install -d /etc/claude-code",
    "/etc/claude-code/managed-settings.json",
    "BACKUP_PATH=\"\"",
    "sudo cp -p \"$MANAGED_SETTINGS_PATH\" \"$BACKUP_PATH\"",
    "BACKUP_PATH=\"<paste the recorded backup path here>\"",
    "sudo install -d \"/Library/Application Support/ClaudeCode\"",
    "/Library/Application Support/ClaudeCode/managed-settings.json",
    "claude doctor",
    "/status",
    "/permissions",
    "sha256sum templates/settings/claude-managed-lockdown.json",
    "Deployment Evidence Record",
    "Rollback or restore",
    "Full active deployment proof is complete only after a future PR adds managed hook replacements",
]

for term in required_runbook_terms:
    if term not in runbook:
        raise SystemExit(f"managed settings deployment proof missing: {term}")

exclusions_header = "Do not use this runbook to:"
_, sep, tail = runbook.partition(exclusions_header)
if not sep:
    raise SystemExit("runbook must include the exclusions block")

exclusions_block, _, remainder = tail.partition("\n## ")
if "Copy the template into `.claude/settings.json`." not in exclusions_block:
    raise SystemExit("runbook must explicitly exclude .claude/settings.json deployment")
if ".claude/settings.json" in remainder:
    raise SystemExit("runbook must not direct deployment into .claude/settings.json")

if settings.get("allowManagedHooksOnly") is not True:
    raise SystemExit("template must keep allowManagedHooksOnly true")
if settings.get("allowManagedMcpServersOnly") is not True:
    raise SystemExit("template must keep allowManagedMcpServersOnly true")
if "allowManagedPermissionRulesOnly" in settings:
    raise SystemExit("permission-rule managed-only mode remains deferred")
if settings.get("strictPluginOnlyCustomization") != ["hooks", "mcp"]:
    raise SystemExit("template must lock only hooks and mcp")
if settings.get("allowedMcpServers") != [{"serverName": "github-readonly"}]:
    raise SystemExit("template must allow only github-readonly")

for deferred in ("skills", "agents", "permissions"):
    if deferred in settings:
        raise SystemExit(f"{deferred} must not be locked in this deployment proof")

if settings.get("allowManagedHooksOnly") is True and not settings.get("hooks"):
    required_safety_terms = [
        "STOP: allowManagedHooksOnly is true but no managed hooks are defined.",
        "The current template sets `allowManagedHooksOnly: true`. Active deployment is blocked unless managed replacement hooks are deployed at the same managed scope.",
        "The safety preflight blocks active deployment while managed hook replacements are absent.",
    ]
    for term in required_safety_terms:
        if term not in runbook:
            raise SystemExit(f"runbook must document hook-lockout safety gate: {term}")

print("✅ managed settings deployment proof is valid")
PY
