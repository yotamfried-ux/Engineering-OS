#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
REGISTRY="$ROOT/core/capability-registry.yaml"

python3 - <<'PY' "$REGISTRY"
import re
import sys
from pathlib import Path

registry = Path(sys.argv[1]).read_text(encoding="utf-8")
failures = []

def require(condition, message):
    if not condition:
        failures.append(message)

require("status: inventory_backed" in registry, "registry status must be inventory_backed")
require("runtime_enabled: false" in registry, "registry must remain non-runtime in this PR")
require("mcp_auto_install_allowed: false" in registry, "MCP auto-install must stay disabled")
require("managed_settings_runtime_lockdown_allowed: false" in registry, "managed settings runtime lockdown must stay disabled")
require("new_project_or_saas:" in registry, "new project / SaaS task class must exist")
require("service_connectors:" in registry, "service connector inventory section must exist")
require("mcp_connectors:" in registry, "MCP connector inventory section must exist")
require("skill_capabilities:" in registry, "skill capability inventory section must exist")
require("llm_accelerators:" in registry, "LLM accelerator inventory section must exist")
require("removed_external_skills:" in registry, "removed/deprecated skill section must exist")

service_and_mcp_paths = len(re.findall(r"path: external-systems/", registry))
mcp_paths = len(re.findall(r"path: external-systems/connectors/", registry))
skill_paths = len(re.findall(r"path: external-skills/", registry))
active_skill_block = re.search(r"(?ms)^skill_capabilities:\n(.*?)(?=^[A-Za-z0-9_-]+:\n|\Z)", registry)
active_skill_count = len(re.findall(r"path: external-skills/", active_skill_block.group(1) if active_skill_block else ""))

require(service_and_mcp_paths >= 26, f"expected at least 26 connector paths, found {service_and_mcp_paths}")
require(mcp_paths >= 12, f"expected at least 12 MCP connector paths, found {mcp_paths}")
require(active_skill_count >= 4, f"expected at least 4 active skill paths, found {active_skill_count}")
require(skill_paths >= active_skill_count, "skill path accounting is inconsistent")

for required in [
    "path: external-systems/connectors/github/",
    "path: external-systems/connectors/notion/",
    "path: external-systems/stripe/",
    "path: external-systems/supabase/",
    "path: external-systems/nvidia-nemotron/",
    "path: external-skills/superpowers/",
    "path: external-skills/security-review/",
    "path: external-skills/graphify/",
    "path: external-skills/ui-ux-pro-max/",
    "path: external-skills/frontend-design/",
    "github-readonly.json",
    "claude-managed-lockdown.json",
]:
    require(required in registry, f"required registry anchor missing: {required}")

active_skill_registry = active_skill_block.group(1) if active_skill_block else ""
require("path: external-skills/nemotron/" not in active_skill_registry, "Nemotron must not be an active skill path")

for forbidden in [
    "skill.ui_ux_pro_max",
    "skill.security_review",
    "skill.claude_mem",
    "toolsets: all",
    "toolsets: default",
    "default_mode: all",
    "default_mode: default",
]:
    require(forbidden not in registry.lower(), f"forbidden registry token present: {forbidden}")

if failures:
    print("❌ capability registry validation failed:")
    for failure in failures:
        print(f" - {failure}")
    sys.exit(1)

print("✅ capability registry validation passed")
print(f"   connector paths: {service_and_mcp_paths}")
print(f"   MCP connector paths: {mcp_paths}")
print(f"   active skills: {active_skill_count}")
PY
