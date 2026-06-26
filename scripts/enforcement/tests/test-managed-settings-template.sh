#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TEMPLATE="$ROOT/templates/settings/claude-managed-lockdown.json"

test -f "$TEMPLATE"

python3 - "$TEMPLATE" <<'PY'
import json
import sys
from pathlib import Path

settings = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))

required_true = [
    "allowManagedHooksOnly",
    "allowManagedMcpServersOnly",
]
for key in required_true:
    if settings.get(key) is not True:
        raise SystemExit(f"{key} must be true")

if "allowManagedPermissionRulesOnly" in settings:
    raise SystemExit("permission-rule managed-only mode is deferred until managed rules exist")

locked = settings.get("strictPluginOnlyCustomization")
if locked != ["hooks", "mcp"]:
    raise SystemExit("strictPluginOnlyCustomization must lock only hooks and mcp")

servers = settings.get("allowedMcpServers")
if servers != [{"serverName": "github-readonly"}]:
    raise SystemExit("allowedMcpServers must allow only github-readonly")

for field in ("skills", "agents"):
    if field in locked:
        raise SystemExit(f"{field} must not be locked in the first rollout")

print("✅ managed settings template is valid")
PY
