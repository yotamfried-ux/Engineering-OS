#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SETTINGS="$ROOT/.claude/settings.json"

python3 - "$SETTINGS" <<'PY'
import json
import sys
from pathlib import Path

settings = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
post = settings.get("hooks", {}).get("PostToolUse", [])

for block in post:
    if block.get("matcher") != "mcp__.*":
        continue
    commands = [hook.get("command", "") for hook in block.get("hooks", []) if isinstance(hook, dict)]
    if any("post-tool-use-mcp.sh" in command for command in commands):
        print("  ✅ generic MCP recorder is wired in repo settings")
        raise SystemExit(0)

raise SystemExit("missing PostToolUse mcp__.* hook for post-tool-use-mcp.sh")
PY
