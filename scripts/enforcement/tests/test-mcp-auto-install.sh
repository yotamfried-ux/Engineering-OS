#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INSTALLER="$ROOT/scripts/install-mcp-servers.sh"
TEMPLATE="$ROOT/templates/connectors/engineering-os-mcp.json"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

test -f "$INSTALLER"
test -f "$TEMPLATE"

python3 -S - "$TEMPLATE" <<'PY'
import json, sys
from pathlib import Path
servers = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")).get("mcpServers", {})
required = "context7 notion stripe supabase playwright nemotron figma sentry postman composio slack linear jira postgres google-drive google-sheets".split()
missing = sorted(set(required) - set(servers))
if missing:
    raise SystemExit(f"missing MCP profiles: {missing}")
for name in required:
    entry = servers[name]
    if name == "playwright":
        assert entry.get("command") == "npx"
        assert "@playwright/mcp" in entry.get("args", [])
    elif name == "nemotron":
        assert entry.get("command") == "uv"
        assert "${ENGINEERING_OS_HOME}/scripts/nemotron-mcp-server.py" in entry.get("args", [])
    else:
        assert entry.get("type") == "http" and entry.get("url")
print("mcp template shape passed")
PY

TARGET="$TMP/target"
mkdir -p "$TARGET"
printf '%s\n' '{"mcpServers":{"custom-local":{"command":"echo","args":["custom"]}}}' > "$TARGET/.mcp.json"
ENGINEERING_OS_HOME="$ROOT" bash "$INSTALLER" "$TARGET" >/dev/null
python3 -S - "$TARGET/.mcp.json" "$ROOT" <<'PY'
import json, sys
from pathlib import Path
mcp = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
root = sys.argv[2]
servers = mcp.get("mcpServers", {})
required = "custom-local github-readonly context7 notion supabase stripe figma sentry postman composio slack linear jira postgres google-drive google-sheets nemotron".split()
missing = sorted(set(required) - set(servers))
if missing:
    raise SystemExit(f"missing installed server: {missing}")
if f"{root}/scripts/nemotron-mcp-server.py" not in servers["nemotron"].get("args", []):
    raise SystemExit("installer did not render ENGINEERING_OS_HOME")
if "${ENGINEERING_OS_HOME}" in json.dumps(mcp):
    raise SystemExit("ENGINEERING_OS_HOME placeholder leaked")
PY

ENGINEERING_OS_HOME="$ROOT" bash "$INSTALLER" "$TARGET" >/dev/null
ls "$TARGET"/.mcp.json.backup.* >/dev/null

BAD="$TMP/bad"
mkdir -p "$BAD"
printf '{not-json}\n' > "$BAD/.mcp.json"
if ENGINEERING_OS_HOME="$ROOT" bash "$INSTALLER" "$BAD" >/tmp/eos-mcp-bad.out 2>&1; then
  echo "invalid existing .mcp.json must fail" >&2
  exit 1
fi
grep -q "existing .mcp.json is not valid JSON" /tmp/eos-mcp-bad.out

echo "MCP auto-install tests passed"
