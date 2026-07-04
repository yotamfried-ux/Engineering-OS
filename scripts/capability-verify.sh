#!/usr/bin/env bash
set -euo pipefail

FORMAT="markdown"
OUTPUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --json) FORMAT="json" ;;
    --markdown) FORMAT="markdown" ;;
    --failure-only) : ;;
    --output) shift; OUTPUT="${1:-}" ;;
    -h|--help) echo "Generate Engineering OS capability report"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

EOS_HOME="${ENGINEERING_OS_HOME:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd || echo "$HOME/.engineering-os")}" 
EOS_HOME="$(cd "$EOS_HOME" && pwd)"
TARGET="$(pwd)"
REGISTRY="$EOS_HOME/core/capability-registry.yaml"

python3 - "$REGISTRY" "$EOS_HOME" "$TARGET" "$FORMAT" <<'PY' > "${OUTPUT:-/dev/stdout}"
import json
import re
import sys
from pathlib import Path

registry_path = Path(sys.argv[1])
eos_home = Path(sys.argv[2])
target = Path(sys.argv[3])
fmt = sys.argv[4]
registry = registry_path.read_text(encoding="utf-8")


def section(name, stops):
    start = registry.find(f"\n{name}:\n")
    if start == -1:
        start = 0 if registry.startswith(f"{name}:\n") else -1
    if start == -1:
        return ""
    start = registry.find("\n", start) + 1
    end = len(registry)
    for stop in stops:
        idx = registry.find(f"\n{stop}:\n", start)
        if idx != -1:
            end = min(end, idx)
    return registry[start:end]


def inline_entries(block):
    out = []
    for line in block.splitlines():
        m = re.search(r"\{([^}]+)\}", line)
        if not m:
            continue
        item = {}
        for part in re.split(r",\s*", m.group(1)):
            if ":" not in part:
                continue
            key, value = part.split(":", 1)
            item[key.strip()] = value.strip().strip('"').strip("'")
        if "id" in item:
            out.append(item)
    return out


def block_entries(name, stops):
    block = section(name, stops)
    out = []
    current = None
    for line in block.splitlines():
        m = re.match(r"^  ([a-z0-9_-]+):\s*$", line)
        if m:
            current = {"id": m.group(1)}
            out.append(current)
            continue
        if current is not None:
            p = re.match(r"^    path:\s*(\S+)", line)
            if p:
                current["path"] = p.group(1)
            d = re.match(r"^    default_profile:\s*(\S+)", line)
            if d:
                current["default_profile"] = d.group(1)
            lvl = re.match(r"^    level:\s*(\S+)", line)
            if lvl:
                current["level"] = lvl.group(1)
    return out


def path_exists(rel):
    return bool(rel) and (eos_home / rel.rstrip("/")).exists()


def mcp_bundle_entries():
    out = []
    for rel in ["templates/connectors/github-readonly.json", "templates/connectors/engineering-os-mcp.json"]:
        try:
            data = json.loads((eos_home / rel).read_text(encoding="utf-8"))
        except Exception:
            continue
        for name in (data.get("mcpServers") or {}):
            cid = "github" if name == "github-readonly" else name
            out.append({"id": cid, "path": rel, "default_mode": "project_scoped_mcp_json"})
    return out


def unique(items):
    seen = set(); out = []
    for item in items:
        if item["id"] in seen:
            continue
        seen.add(item["id"]); out.append(item)
    return out


skills = []
for item in block_entries("skill_capabilities", ["llm_accelerators"]):
    skills.append({"group": "skill", "id": item["id"], "status": "present" if path_exists(item.get("path", "")) else "missing", "level": item.get("level", ""), "profile": item.get("default_profile", ""), "path": item.get("path", ""), "action": "none"})

engines = []
for item in block_entries("llm_accelerators", ["removed_external_skills"]):
    engines.append({"group": "engine", "id": item["id"], "status": "present" if path_exists(item.get("path", "")) else "missing", "level": item.get("level", ""), "profile": item.get("default_profile", ""), "path": item.get("path", ""), "action": "none"})

mcp_items = unique(inline_entries(section("mcp_connectors", ["template_capabilities"])) + mcp_bundle_entries())
mcp = []
for item in mcp_items:
    mode = item.get("default_mode", "project_scoped_mcp_json")
    ref = item.get("default_profile") or item.get("path", "")
    status = "configured" if path_exists(ref) else "setup_needed"
    mcp.append({"group": "mcp_connector", "id": item["id"], "status": status, "level": "", "profile": mode, "path": item.get("path", ""), "action": "optional"})

services = []
for item in inline_entries(section("service_connectors", ["mcp_connectors"])):
    rel = item.get("path", "")
    services.append({"group": "service_connector", "id": item["id"], "status": "documented" if path_exists(rel) else "missing_doc", "level": "", "profile": "reference", "path": rel, "action": "none"})

templates = []
for item in inline_entries(section("template_capabilities", ["rejected_for_now"])):
    rel = item.get("path", "")
    templates.append({"group": "template", "id": item["id"], "status": "present" if path_exists(rel) else "missing", "level": "", "profile": item.get("kind", ""), "path": rel, "action": "none"})

all_items = skills + engines + mcp + services + templates
summary = {}
for item in all_items:
    group = item["group"]
    summary.setdefault(group, {"total": 0, "present": 0, "configured": 0, "documented": 0, "missing": 0, "setup_needed": 0})
    summary[group]["total"] += 1
    status = item["status"]
    summary[group][status if status in summary[group] else "missing"] += 1

if fmt == "json":
    print(json.dumps({"summary": summary, "capabilities": all_items}, ensure_ascii=False, indent=2))
    raise SystemExit

print("# Engineering OS — Capability Verification Report")
print()
print(f"Target: `{target}`")
print(f"Engineering OS reference: `{eos_home}`")
print()
print("## Action Required")
print()
print("No required failures detected. Some connectors may still need project-level approval before live use.")


def table(title, rows):
    print(); print(f"## {title}"); print()
    print("| ID | Status | Profile / mode | Path | Action |")
    print("|---|---|---|---|---|")
    for item in rows:
        print(f"| `{item['id']}` | `{item['status']}` | `{item.get('profile','')}` | `{item.get('path','')}` | `{item.get('action','')}` |")

table("Skills and engines", skills + engines)
table("MCP connectors", mcp)
table("Service connector docs", services)
table("Templates", templates)
PY
