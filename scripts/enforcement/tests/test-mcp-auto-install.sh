#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INSTALLER="$ROOT/scripts/install-mcp-servers.sh"
TEMPLATE="$ROOT/templates/connectors/engineering-os-mcp.json"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() { echo "ok: $1"; }
fail() { echo "fail: $1" >&2; exit 1; }

test -f "$INSTALLER" || fail "installer exists"
test -f "$TEMPLATE" || fail "mcp template exists"
pass "fixtures_present"

python3 -S - "$TEMPLATE" <<'PY'
import json, sys
from pathlib import Path
servers = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")).get("mcpServers", {})
required = {"context7", "notion", "stripe", "supabase", "playwright", "nemotron", "figma", "sentry", "postman", "composio"}
missing = sorted(required - set(servers))
if missing:
    raise SystemExit(f"missing MCP profiles: {missing}")
for name in ("context7", "notion", "stripe", "supabase", "figma", "sentry", "postman", "composio"):
    entry = servers[name]
    if entry.get("type") != "http" or not entry.get("url"):
        raise SystemExit(f"{name} must be an HTTP MCP server")
if servers["playwright"].get("command") != "npx":
    raise SystemExit("playwright must use npx")
if servers["nemotron"].get("command") != "uv":
    raise SystemExit("nemotron must use uv")
if "${ENGINEERING_OS_HOME}/scripts/nemotron-mcp-server.py" not in servers["nemotron"].get("args", []):
    raise SystemExit("nemotron template must use ENGINEERING_OS_HOME placeholder")
print("mcp template shape passed")
PY
pass "template_shape"

TARGET="$TMP/target"
mkdir -p "$TARGET"
cat > "$TARGET/.mcp.json" <<'JSON'
{"mcpServers":{"custom-local":{"command":"echo","args":["custom"]}}}
JSON

ENGINEERING_OS_HOME="$ROOT" bash "$INSTALLER" "$TARGET" >"$TMP/eos-mcp-install.out"
python3 -S - "$TARGET/.mcp.json" "$ROOT" <<'PY'
import json, sys
from pathlib import Path
mcp = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
root = sys.argv[2]
servers = mcp.get("mcpServers", {})
for name in ["custom-local", "github-readonly", "context7", "notion", "supabase", "stripe", "figma", "sentry", "postman", "composio", "nemotron"]:
    if name not in servers:
        raise SystemExit(f"missing installed server: {name}")
if f"{root}/scripts/nemotron-mcp-server.py" not in servers["nemotron"].get("args", []):
    raise SystemExit("installer did not render ENGINEERING_OS_HOME")
if "${ENGINEERING_OS_HOME}" in json.dumps(mcp):
    raise SystemExit("ENGINEERING_OS_HOME placeholder leaked")
PY
pass "installer_merges_and_renders_bundle"

ENGINEERING_OS_HOME="$ROOT" bash "$INSTALLER" "$TARGET" >"$TMP/eos-mcp-install-2.out"
ls "$TARGET"/.mcp.json.backup.* >/dev/null
pass "installer_is_repeatable_with_backup"

BAD="$TMP/bad"
mkdir -p "$BAD"
printf '{not-json}\n' > "$BAD/.mcp.json"
if ENGINEERING_OS_HOME="$ROOT" bash "$INSTALLER" "$BAD" >"$TMP/eos-mcp-bad.out" 2>&1; then
  fail "invalid existing .mcp.json must fail"
fi
grep -q "existing .mcp.json is not valid JSON" "$TMP/eos-mcp-bad.out"
pass "invalid_existing_config_fails_closed"

echo "MCP auto-install tests passed"
