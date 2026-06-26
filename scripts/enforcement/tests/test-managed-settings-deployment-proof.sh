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
    "repository template -> system managed settings path -> Claude Code status/permissions evidence -> rollback",
    "Do not use this runbook to:",
    "Copy the template into `.claude/settings.json`.",
    "Enable managed settings from `use-in-project.sh`.",
    "Add `allowManagedPermissionRulesOnly`.",
    "allowManagedPermissionRulesOnly` remains deferred",
    "sudo install -d /etc/claude-code",
    "/etc/claude-code/managed-settings.json",
    "sudo install -d \"/Library/Application Support/ClaudeCode\"",
    "/Library/Application Support/ClaudeCode/managed-settings.json",
    "claude doctor",
    "/status",
    "/permissions",
    "sha256sum templates/settings/claude-managed-lockdown.json",
    "Deployment Evidence Record",
    "Rollback",
    "Completion criteria",
]

for term in required_runbook_terms:
    if term not in runbook:
        raise SystemExit(f"managed settings deployment proof missing: {term}")

if ".claude/settings.json" in runbook:
    allowed_context = "Copy the template into `.claude/settings.json`."
    if allowed_context not in runbook:
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

print("✅ managed settings deployment proof is valid")
PY
