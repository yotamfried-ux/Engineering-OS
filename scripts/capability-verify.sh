#!/usr/bin/env bash
#
# capability-verify.sh — generate a unified Engineering OS capability report.
#
# It verifies skills and engines through skill-bootstrap, then inventories
# connectors and templates from core/capability-registry.yaml and core/mcp-servers.md.
# It does not auto-install MCP connectors or request OAuth; it reports what is
# present, documented, opt-in, or requires authentication.

set -euo pipefail

FORMAT="markdown"
OUTPUT=""
FAILURE_ONLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --json) FORMAT="json" ;;
    --markdown) FORMAT="markdown" ;;
    --failure-only) FAILURE_ONLY=1 ;;
    --output) shift; OUTPUT="${1:-}" ;;
    -h|--help)
      sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

EOS_HOME="${ENGINEERING_OS_HOME:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd || echo "$HOME/.engineering-os")}"
EOS_HOME="$(cd "$EOS_HOME" && pwd)"
TARGET="$(pwd)"
REGISTRY="$EOS_HOME/core/capability-registry.yaml"
BOOT_JSON="$(mktemp)"
trap 'rm -f "$BOOT_JSON"' EXIT

if [ -x "$EOS_HOME/scripts/skill-bootstrap.sh" ]; then
  ( cd "$TARGET" && ENGINEERING_OS_HOME="$EOS_HOME" "$EOS_HOME/scripts/skill-bootstrap.sh" --json > "$BOOT_JSON" ) 2>/dev/null || printf '{"capabilities":[]}' > "$BOOT_JSON"
else
  printf '{"capabilities":[]}' > "$BOOT_JSON"
fi

python3 - "$REGISTRY" "$TARGET" "$EOS_HOME" "$BOOT_JSON" "$FORMAT" "$FAILURE_ONLY" <<'PY' > "${OUTPUT:-/dev/stdout}"
import json
import os
import re
import sys
from pathlib import Path

registry_path = Path(sys.argv[1])
target = Path(sys.argv[2])
eos_home = Path(sys.argv[3])
boot_path = Path(sys.argv[4])
fmt = sys.argv[5]
failure_only = sys.argv[6] == "1"

registry = registry_path.read_text(encoding="utf-8")
mcp_servers_path = eos_home / "core/mcp-servers.md"
mcp_servers = mcp_servers_path.read_text(encoding="utf-8") if mcp_servers_path.exists() else ""
try:
    boot = json.loads(boot_path.read_text(encoding="utf-8"))
except Exception:
    boot = {"capabilities": []}


def section(name: str, next_names: list[str] | None = None) -> str:
    marker = f"\n{name}:\n"
    start = registry.find(marker)
    if start == -1:
        if registry.startswith(f"{name}:\n"):
            start = 0
        else:
            return ""
    start += len(marker) if start else len(f"{name}:\n")
    end = len(registry)
    for nxt in next_names or []:
        idx = registry.find(f"\n{nxt}:\n", start)
        if idx != -1:
            end = min(end, idx)
    return registry[start:end]


def inline_entries(block: str):
    entries = []
    for line in block.splitlines():
        match = re.search(r"\{([^}]+)\}", line)
        if not match:
            continue
        raw = match.group(1)
        item = {}
        for part in re.split(r",\s*", raw):
            if ":" not in part:
                continue
            key, value = part.split(":", 1)
            item[key.strip()] = value.strip().strip('"').strip("'")
        if "id" in item:
            entries.append(item)
    return entries


def slug(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")


def mcp_server_entries():
    entries = []
    for line in mcp_servers.splitlines():
        if not line.startswith("|") or "**" not in line:
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) < 3:
            continue
        raw_name = re.sub(r"[*`()]", "", cells[0]).strip()
        if not raw_name or raw_name.lower() in {"connector", "סקיל"}:
            continue
        cid = slug(raw_name.split()[0] if raw_name.lower().startswith("nemotron") else raw_name)
        if not cid:
            continue
        entries.append({"id": cid, "path": "core/mcp-servers.md", "default_mode": "reference_opt_in"})
    return entries


def merge_by_id(*groups):
    merged = {}
    for group in groups:
        for item in group:
            merged.setdefault(item["id"], item)
    return list(merged.values())


def path_exists(rel: str) -> bool:
    return (eos_home / rel.rstrip("/")).exists()


def normalize_env_name(name: str) -> str:
    return re.sub(r"[^A-Z0-9]", "_", name.upper())


def env_present(name: str) -> bool:
    base = normalize_env_name(name)
    candidates = {
        f"{base}_TOKEN", f"{base}_API_KEY", f"{base}_KEY", f"{base}_URL",
        f"{base}_AUTH_TOKEN", f"{base}_SECRET_KEY",
    }
    explicit = {
        "github": ["GITHUB_TOKEN", "GH_TOKEN"],
        "notion": ["NOTION_API_KEY", "NOTION_TOKEN"],
        "sentry": ["SENTRY_AUTH_TOKEN", "SENTRY_DSN"],
        "context7": ["CONTEXT7_API_KEY"],
        "stripe": ["STRIPE_SECRET_KEY", "STRIPE_API_KEY"],
        "supabase": ["SUPABASE_ACCESS_TOKEN", "SUPABASE_SERVICE_ROLE_KEY", "SUPABASE_URL"],
        "postgres": ["DATABASE_URL", "POSTGRES_URL"],
        "figma": ["FIGMA_TOKEN", "FIGMA_ACCESS_TOKEN"],
        "discord": ["DISCORD_TOKEN", "DISCORD_BOT_TOKEN"],
        "slack": ["SLACK_BOT_TOKEN", "SLACK_TOKEN"],
        "linear": ["LINEAR_API_KEY"],
        "jira": ["JIRA_API_TOKEN"],
        "google-drive": ["GOOGLE_APPLICATION_CREDENTIALS", "GOOGLE_CLIENT_ID"],
        "google-sheets": ["GOOGLE_APPLICATION_CREDENTIALS", "GOOGLE_CLIENT_ID"],
        "nemotron": ["Nemotron_api_key", "NEMOTRON_API_KEY"],
    }
    candidates.update(explicit.get(name, []))
    return any(os.environ.get(k) for k in candidates)


def mcp_configured(name: str) -> bool:
    sources = [target / ".mcp.json", Path.home() / ".claude.json"]
    needles = {name, name.replace("-", "_"), name.replace("-", "")}
    for src in sources:
        try:
            text = src.read_text(encoding="utf-8")
        except Exception:
            continue
        low = text.lower()
        if any(n.lower() in low for n in needles):
            return True
    return False

skill_engine = []
for item in boot.get("capabilities", []):
    status = item.get("status", "unknown")
    name = item.get("name", "unknown")
    kind = item.get("kind", "capability")
    profile = item.get("profile", "")
    level = item.get("level", "")
    action = "none" if status == "present" else ("required" if profile == "default" else "optional")
    skill_engine.append({
        "group": kind,
        "id": name,
        "status": status,
        "level": level,
        "profile": profile,
        "path": "",
        "action": action,
    })

registry_mcp = inline_entries(section("mcp_connectors", ["template_capabilities"]))
mcp_entries = merge_by_id(registry_mcp, mcp_server_entries())
service_entries = inline_entries(section("service_connectors", ["mcp_connectors"]))
template_entries = inline_entries(section("template_capabilities", ["rejected_for_now"]))

mcp = []
for item in mcp_entries:
    cid = item["id"]
    present = mcp_configured(cid) or env_present(cid)
    mode = item.get("default_mode", "opt_in")
    status = "present" if present else "requires_auth"
    action = "required" if (not present and mode not in {"opt_in", "reference_opt_in"}) else "optional"
    mcp.append({"group": "mcp_connector", "id": cid, "status": status, "level": "", "profile": mode, "path": item.get("path", ""), "action": action})

services = []
for item in service_entries:
    rel = item.get("path", "")
    status = "documented" if rel and path_exists(rel) else "missing_doc"
    services.append({"group": "service_connector", "id": item["id"], "status": status, "level": "", "profile": "reference", "path": rel, "action": "required" if status == "missing_doc" else "none"})

templates = []
for item in template_entries:
    rel = item.get("path", "")
    status = "present" if rel and path_exists(rel) else "missing"
    templates.append({"group": "template", "id": item["id"], "status": status, "level": "", "profile": item.get("kind", ""), "path": rel, "action": "required" if status == "missing" else "none"})

all_items = skill_engine + mcp + services + templates
if failure_only:
    all_items = [i for i in all_items if i["action"] != "none" or i["status"] in {"missing", "missing_doc"}]

summary = {}
for item in all_items:
    g = item["group"]
    summary.setdefault(g, {"total": 0, "present": 0, "missing": 0, "requires_auth": 0, "documented": 0})
    summary[g]["total"] += 1
    st = item["status"]
    if st in summary[g]:
        summary[g][st] += 1
    elif st == "missing_doc":
        summary[g]["missing"] += 1

if fmt == "json":
    print(json.dumps({"summary": summary, "capabilities": all_items}, ensure_ascii=False, indent=2))
    raise SystemExit

print("# Engineering OS — Capability Verification Report")
print()
print(f"Target: `{target}`")
print(f"Engineering OS reference: `{eos_home}`")
print()
print("> This report is generated from `core/capability-registry.yaml`, `core/mcp-servers.md`, and `scripts/skill-bootstrap.sh`. It is a verification report, not an auto-install list. Opt-in connectors may require manual auth/OAuth before use.")
print()
print("## Summary")
print()
print("| Group | Total | Present | Documented | Requires auth | Missing |")
print("|---|---:|---:|---:|---:|---:|")
for group in sorted(summary):
    row = summary[group]
    print(f"| {group} | {row['total']} | {row['present']} | {row['documented']} | {row['requires_auth']} | {row['missing']} |")

print()
print("## Action Required")
print()
actions = [i for i in all_items if i["action"] == "required" or i["status"] in {"missing", "missing_doc"}]
if actions:
    for item in actions:
        print(f"- `{item['id']}` ({item['group']}): `{item['status']}` — {item.get('path') or item.get('profile')}")
else:
    print("No required failures detected. Optional connectors may still need auth when selected for a task.")


def table(title, items):
    print()
    print(f"## {title}")
    print()
    print("| ID | Status | Profile / mode | Path | Action |")
    print("|---|---|---|---|---|")
    for item in items:
        print(f"| `{item['id']}` | `{item['status']}` | `{item.get('profile','')}` | `{item.get('path','')}` | `{item.get('action','')}` |")

table("Skills and engines", skill_engine)
table("MCP connectors", mcp)
table("Service connector docs", services)
table("Templates", templates)
PY
