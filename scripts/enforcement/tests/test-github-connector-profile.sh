#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PROFILE="$ROOT/templates/connectors/github-readonly.json"

test -f "$PROFILE"

python3 - "$PROFILE" <<'PY'
import json
import sys
from pathlib import Path

profile = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
server = profile.get("mcpServers", {}).get("github-readonly")
if not isinstance(server, dict):
    raise SystemExit("missing connector profile")

args = server.get("args", [])
env = server.get("env", {})

checks = [
    server.get("command") == "docker",
    "ghcr.io/github/github-mcp-server" in args,
    env.get("GITHUB_READ_ONLY") == "1",
    env.get("GITHUB_PERSONAL_ACCESS_TOKEN") == "${GITHUB_PERSONAL_ACCESS_TOKEN}",
]
if not all(checks):
    raise SystemExit("connector profile does not match required shape")

items = {item.strip() for item in env.get("GITHUB_TOOLSETS", "").split(",") if item.strip()}
allowed = {"context", "repos", "pull_requests", "issues", "actions"}
if items != allowed:
    raise SystemExit("connector profile toolset list changed")
if items & {"all", "default"}:
    raise SystemExit("connector profile includes a broad toolset")

print("✅ GitHub connector profile is valid")
PY
