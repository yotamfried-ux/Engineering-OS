#!/usr/bin/env bash
#
# install-mcp-servers.sh — install Engineering OS project-scoped MCP servers
# into a target project's .mcp.json.
#
# This installs server CONFIGURATION only. It never writes credentials. OAuth and
# environment-variable secrets stay user/project-owned and are completed via
# Claude Code /mcp or environment setup.

set -euo pipefail

TARGET="${1:-$(pwd)}"
EOS_HOME="${ENGINEERING_OS_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BUNDLE_TEMPLATE="${EOS_HOME}/templates/connectors/engineering-os-mcp.json"
GITHUB_TEMPLATE="${EOS_HOME}/templates/connectors/github-readonly.json"
MCP_PATH="${TARGET}/.mcp.json"

red()  { printf '\033[31m%s\033[0m\n' "$*"; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
dim()  { printf '\033[2m%s\033[0m\n' "$*"; }

[ -d "$TARGET" ] || { red "target directory does not exist: $TARGET"; exit 2; }
[ -f "$BUNDLE_TEMPLATE" ] || { red "missing MCP bundle template: $BUNDLE_TEMPLATE"; exit 2; }
[ -f "$GITHUB_TEMPLATE" ] || { red "missing GitHub MCP template: $GITHUB_TEMPLATE"; exit 2; }

mkdir -p "$TARGET"

python3 -S - "$BUNDLE_TEMPLATE" "$GITHUB_TEMPLATE" "$MCP_PATH" "$EOS_HOME" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

bundle_path = Path(sys.argv[1])
github_path = Path(sys.argv[2])
mcp_path = Path(sys.argv[3])
eos_home = sys.argv[4]

def read_servers(path):
    data = json.loads(path.read_text(encoding="utf-8"))
    servers = data.get("mcpServers")
    if not isinstance(servers, dict) or not servers:
        raise SystemExit(f"MCP template must contain non-empty mcpServers: {path}")
    return servers

servers = {}
servers.update(read_servers(github_path))
servers.update(read_servers(bundle_path))

for name, entry in servers.items():
    if not isinstance(entry, dict):
        raise SystemExit(f"MCP server entry must be an object: {name}")
    if entry.get("type") in {"http", "streamable-http", "sse", "ws"}:
        if not entry.get("url"):
            raise SystemExit(f"remote MCP server is missing url: {name}")
    elif entry.get("type") == "stdio" or "command" in entry:
        if not entry.get("command"):
            raise SystemExit(f"stdio MCP server is missing command: {name}")
    else:
        raise SystemExit(f"MCP server must declare either type/url or command: {name}")

def rewrite(value):
    if isinstance(value, dict):
        return {key: rewrite(val) for key, val in value.items()}
    if isinstance(value, list):
        return [rewrite(item) for item in value]
    if isinstance(value, str):
        return value.replace("${ENGINEERING_OS_HOME}", eos_home)
    return value

servers = rewrite(servers)

existing = {}
if mcp_path.exists():
    try:
        existing = json.loads(mcp_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"existing .mcp.json is not valid JSON: {exc}")
    if not isinstance(existing, dict):
        raise SystemExit("existing .mcp.json must be a JSON object")
    backup = mcp_path.with_name(f".mcp.json.backup.{datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')}")
    backup.write_text(mcp_path.read_text(encoding="utf-8"), encoding="utf-8")
else:
    backup = None

merged = dict(existing)
merged_servers = dict(existing.get("mcpServers", {}))
if not isinstance(merged_servers, dict):
    raise SystemExit("existing .mcp.json mcpServers must be a JSON object")

# Engineering OS owns these server names. Re-running the installer intentionally
# refreshes them to the current safe profile while preserving any custom servers.
merged_servers.update(servers)
merged["mcpServers"] = merged_servers

mcp_path.write_text(json.dumps(merged, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

print(f"installed {len(servers)} Engineering OS MCP server profiles into {mcp_path}")
if backup:
    print(f"backup: {backup}")
print("credentials were not written; authenticate in Claude Code with /mcp or claude mcp login <server>")
PY

grn "Project-scoped MCP configuration ready: $MCP_PATH"
dim "Open Claude Code in the target and run: claude mcp list  # or /mcp"
