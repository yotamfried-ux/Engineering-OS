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
if not isinstance(args, list) or not isinstance(env, dict):
    raise SystemExit("connector profile has invalid args or env")

passed_env = {current for previous, current in zip(args, args[1:]) if previous == "-e"}
if not set(env).issubset(passed_env):
    raise SystemExit("connector profile does not pass every env key to docker")

read_only_key = next((key for key in env if key.endswith("READ_ONLY")), None)
token_key = next((key for key in env if key.endswith("TOKEN")), None)
toolsets_key = next((key for key in env if key.endswith("TOOLSETS")), None)

checks = [
    server.get("command") == "docker",
    "ghcr.io/github/github-mcp-server" in args,
    read_only_key is not None and env.get(read_only_key) == "1",
    token_key is not None and env.get(token_key) == "${" + token_key + "}",
    toolsets_key is not None,
]
if not all(checks):
    raise SystemExit("connector profile does not match required shape")

items = {item.strip() for item in env.get(toolsets_key, "").split(",") if item.strip()}
allowed = {"context", "repos", "pull_requests", "issues", "actions"}
if items != allowed:
    raise SystemExit("connector profile toolset list changed")
if items & {"all", "default"}:
    raise SystemExit("connector profile includes a broad toolset")

print("✅ GitHub connector profile is valid")
PY
