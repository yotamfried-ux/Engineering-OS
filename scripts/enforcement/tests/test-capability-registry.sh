#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
REGISTRY="$ROOT/core/capability-registry.yaml"
SYSTEMS="$ROOT/external-systems/README.md"
SKILLS="$ROOT/external-skills/README.md"

python3 - <<'PY' "$REGISTRY" "$SYSTEMS" "$SKILLS"
import re
import sys
from pathlib import Path

registry = Path(sys.argv[1]).read_text(encoding="utf-8")
systems = Path(sys.argv[2]).read_text(encoding="utf-8")
skills = Path(sys.argv[3]).read_text(encoding="utf-8")

failures = []

def require(condition, message):
    if not condition:
        failures.append(message)


def top_level_section(text, name):
    pattern = rf"(?ms)^{re.escape(name)}:\n(.*?)(?=^[A-Za-z0-9_-]+:\n|\Z)"
    match = re.search(pattern, text)
    require(match is not None, f"missing registry section: {name}")
    return match.group(1) if match else ""


def md_section(text, heading):
    pattern = rf"(?ms)^## {re.escape(heading)}\n(.*?)(?=^## |\Z)"
    match = re.search(pattern, text)
    require(match is not None, f"missing README section: {heading}")
    return match.group(1) if match else ""


def extract_table_paths(markdown):
    paths = []
    for line in markdown.splitlines():
        if "|" not in line or "`" not in line:
            continue
        for path in re.findall(r"`([^`]+/)`", line):
            paths.append(path)
    return paths

require("status: inventory_backed" in registry, "registry status must be inventory_backed")
require("runtime_enabled: false" in registry, "registry must remain non-runtime in this PR")
require("mcp_auto_install_allowed: false" in registry, "MCP auto-install must stay disabled")
require("managed_settings_runtime_lockdown_allowed: false" in registry, "managed-settings runtime lockdown must stay disabled")
require("new_project_or_saas:" in registry, "registry must include new_project_or_saas task class")

service_inventory_text = systems.split("## MCP Connectors", 1)[0]
mcp_inventory_text = md_section(systems, "MCP Connectors")
service_paths = extract_table_paths(service_inventory_text)
mcp_paths = extract_table_paths(mcp_inventory_text)

service_registry = top_level_section(registry, "service_connectors")
mcp_registry = top_level_section(registry, "mcp_connectors")
skill_registry = top_level_section(registry, "skill_capabilities")
accelerator_registry = top_level_section(registry, "llm_accelerators")
removed_skill_registry = top_level_section(registry, "removed_external_skills")
template_registry = top_level_section(registry, "template_capabilities")
capabilities = top_level_section(registry, "capabilities")

total_connector_count = len(re.findall(r"path: external-systems/", service_registry + mcp_registry))
mcp_connector_count = len(re.findall(r"path: external-systems/connectors/", mcp_registry))
skill_count = len(re.findall(r"path: external-skills/", skill_registry))

require(total_connector_count >= 26, f"expected at least 26 total connector entries, found {total_connector_count}")
require(mcp_connector_count >= 12, f"expected at least 12 MCP connector entries, found {mcp_connector_count}")
require(skill_count >= 4, f"expected at least 4 active skill entries, found {skill_count}")

for path in service_paths:
    expected = f"path: external-systems/{path}"
    require(expected in service_registry, f"registry missing service connector path from README in service_connectors: {expected}")

for path in mcp_paths:
    expected = f"path: external-systems/{path}"
    require(expected in mcp_registry, f"registry missing MCP connector path from README in mcp_connectors: {expected}")

skill_paths = []
for line in skills.splitlines():
    if "**[" not in line or "./" not in line:
        continue
    match = re.search(r"\]\(\./([^/]+)/\)", line)
    if match:
        skill_paths.append(match.group(1))

require(len(skill_paths) >= 4, f"expected at least 4 documented skills/accelerators, found {len(skill_paths)}")
skill_union = "\n".join([skill_registry, accelerator_registry, removed_skill_registry])
for skill in skill_paths:
    expected = f"path: external-skills/{skill}/"
    require(expected in skill_union, f"registry missing documented external skill/accelerator/deprecated path: {expected}")

require("path: external-skills/nemotron/" in accelerator_registry, "Nemotron must be represented as an llm_accelerator, not an active skill")
require("path: external-skills/nemotron/" not in skill_registry, "Nemotron must not be counted as an active skill")
require("path: external-skills/frontend-design/" in removed_skill_registry, "frontend-design must be represented as deprecated/reference-only")
require("path: external-skills/frontend-design/" not in skill_registry, "frontend-design must not be active")

for token in ("skill.ui_ux_pro_max", "skill.security_review", "skill.claude_mem"):
    require(token not in registry, f"underscored skill capability reference must not appear: {token}")

capability_keys = set(re.findall(r"^  ([A-Za-z0-9_.-]+):\n", capabilities, flags=re.M))
required = re.findall(r"^      - ([A-Za-z0-9_.-]+)\n", registry, flags=re.M)
for cap in required:
    require(cap in capability_keys, f"required capability is not resolvable in capabilities: {cap}")

require("toolsets: all" not in registry.lower(), "broad MCP toolset 'all' must not appear")
require("toolsets: default" not in registry.lower(), "broad MCP toolset 'default' must not appear")
require("default_mode: all" not in registry.lower(), "broad default_mode all must not appear")
require("default_mode: default" not in registry.lower(), "broad default_mode default must not appear")

require("github-readonly.json" in template_registry, "GitHub read-only connector template must be represented")
require("claude-managed-lockdown.json" in template_registry, "managed settings template must be represented")

if failures:
    print("❌ capability registry validation failed:")
    for failure in failures:
        print(f" - {failure}")
    sys.exit(1)

print("✅ capability registry validation passed")
print(f"   service connectors: {len(service_paths)} documented / covered")
print(f"   MCP connectors: {len(mcp_paths)} documented / covered")
print(f"   active skills: {skill_count} covered")
PY
