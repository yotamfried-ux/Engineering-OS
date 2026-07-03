#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
RUNBOOK="$ROOT/docs/operations/active-mcp-verification.md"
PROFILE="$ROOT/templates/connectors/github-readonly.json"
BUNDLE="$ROOT/templates/connectors/engineering-os-mcp.json"

python3 -S - "$RUNBOOK" "$PROFILE" "$BUNDLE" <<'PY'
import json
import sys
from pathlib import Path

runbook = Path(sys.argv[1]).read_text(encoding="utf-8")
profile = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
bundle = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))

required = [
    "templates/connectors/github-readonly.json",
    "templates/connectors/engineering-os-mcp.json",
    "scripts/install-mcp-servers.sh",
    "scripts/use-in-project.sh",
    "target .mcp.json",
    "github-readonly",
    "context7",
    "notion",
    "supabase",
    "stripe",
    "playwright",
    "nemotron",
    "figma",
    "sentry",
    "postman",
    "composio",
    "Do not use this runbook to:",
    "Add a write-capable GitHub MCP profile.",
    "Perform a real write operation as a negative test.",
    "bash scripts/enforcement/tests/test-mcp-auto-install.sh",
    "command -v docker >/dev/null",
    "command -v npx >/dev/null",
    "command -v uv >/dev/null",
    "claude mcp list",
    "claude mcp get github-readonly",
    "/mcp",
    "MCP status/list command used:",
    "github-readonly server visible: yes/no",
    "Required non-GitHub MCP profiles visible: yes/no",
]
for term in required:
    if term not in runbook:
        raise SystemExit(f"active MCP verification runbook missing: {term}")

server = profile.get("mcpServers", {}).get("github-readonly")
if not isinstance(server, dict):
    raise SystemExit("missing github-readonly server")
args = server.get("args", [])
env = server.get("env", {})
if server.get("command") != "docker":
    raise SystemExit("github-readonly must run via docker")
if "ghcr.io/github/github-mcp-server" not in args:
    raise SystemExit("github-readonly must use official image")
read_only_key = next((key for key in env if key.endswith("READ_ONLY")), None)
toolsets_key = next((key for key in env if key.endswith("TOOLSETS")), None)
if not read_only_key or env.get(read_only_key) != "1":
    raise SystemExit("github-readonly must keep read-only mode")
items = {item.strip() for item in env[toolsets_key].split(",") if item.strip()}
if items != {"context", "repos", "pull_requests", "issues", "actions"}:
    raise SystemExit("github-readonly toolsets changed")

bundle_servers = bundle.get("mcpServers", {})
for name in ("context7", "notion", "stripe", "supabase", "playwright", "nemotron", "figma", "sentry", "postman", "composio"):
    if name not in bundle_servers:
        raise SystemExit(f"MCP bundle missing server: {name}")

print("✅ active MCP verification proof is valid")
PY
