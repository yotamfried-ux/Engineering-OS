#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
RUNBOOK="$ROOT/docs/operations/active-mcp-verification.md"
PROFILE="$ROOT/templates/connectors/github-readonly.json"

test -f "$RUNBOOK"
test -f "$PROFILE"

python3 - "$RUNBOOK" "$PROFILE" <<'PY'
import json
import sys
from pathlib import Path

runbook = Path(sys.argv[1]).read_text(encoding="utf-8")
profile = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

required_runbook_terms = [
    "templates/connectors/github-readonly.json",
    "repository MCP template -> local target .mcp.json -> Claude Code MCP status evidence -> read-only smoke checks -> rollback or restore",
    "github-readonly",
    "GITHUB_READ_ONLY=1",
    "GITHUB_PERSONAL_ACCESS_TOKEN=${GITHUB_PERSONAL_ACCESS_TOKEN}",
    "GITHUB_TOOLSETS=context,repos,pull_requests,issues,actions",
    "Do not use this runbook to:",
    "Commit a real GitHub token.",
    "Add a write-capable GitHub MCP profile.",
    "Add broad toolsets such as `all` or `default`.",
    "Enable MCP from `use-in-project.sh`.",
    "Auto-install `.mcp.json` into target projects.",
    "Perform a real write operation as a negative test.",
    "bash scripts/enforcement/tests/test-github-connector-profile.sh",
    "bash scripts/enforcement/tests/test-active-mcp-verification.sh",
    "command -v docker >/dev/null",
    "test -n \"${GITHUB_PERSONAL_ACCESS_TOKEN:-}\"",
    "Do not echo, log, paste, commit, or screenshot the token.",
    "Use a least-privilege read-only token for the target repository whenever possible.",
    "cp templates/connectors/github-readonly.json \"$MCP_PATH\"",
    "BACKUP_PATH=\"\"",
    "cp -p \"$MCP_PATH\" \"$BACKUP_PATH\"",
    "printf '\\n.mcp.json\\n.mcp.json.backup.*\\n' >> .git/info/exclude",
    "MCP status/list command used:",
    "github-readonly server visible: yes/no",
    "Read repository metadata check: pass/fail",
    "Read PR or issue metadata check: pass/fail",
    "Read workflow/CI metadata check: pass/fail",
    "Write profile active: yes/no",
    "Forbidden toolsets visible: yes/no",
    "Do not perform a real write operation as a negative test.",
    "No write-capable GitHub MCP profile is active.",
    "The toolsets are exactly context,repos,pull_requests,issues,actions.",
    "No runbook step asks the operator to merge, close, edit, label, delete, or mutate GitHub resources through github-readonly.",
    "BACKUP_PATH=\"<paste the recorded backup path here>\"",
    "Full active MCP proof is complete only after this runbook is executed on one real workstation or target test project",
]

for term in required_runbook_terms:
    if term not in runbook:
        raise SystemExit(f"active MCP verification runbook missing: {term}")

exclusions_header = "Do not use this runbook to:"
_, sep, tail = runbook.partition(exclusions_header)
if not sep:
    raise SystemExit("runbook must include the exclusions block")
exclusions_block, _, remainder = tail.partition("\n## ")
for expected in (
    "Commit a real GitHub token.",
    "Add a write-capable GitHub MCP profile.",
    "Enable MCP from `use-in-project.sh`.",
    "Auto-install `.mcp.json` into target projects.",
):
    if expected not in exclusions_block:
        raise SystemExit(f"runbook exclusions block missing: {expected}")

# Mentions outside the exclusions block are allowed only as explicit negative checks or rollback guidance.
for forbidden_phrase in (
    "Add a write-capable GitHub MCP profile.",
    "Enable MCP from `use-in-project.sh`.",
    "Auto-install `.mcp.json` into target projects.",
):
    if forbidden_phrase in remainder:
        raise SystemExit(f"runbook must not later contradict exclusion: {forbidden_phrase}")

server = profile.get("mcpServers", {}).get("github-readonly")
if not isinstance(server, dict):
    raise SystemExit("missing github-readonly server")
args = server.get("args", [])
env = server.get("env", {})
if not isinstance(args, list) or not isinstance(env, dict):
    raise SystemExit("github-readonly profile has invalid args or env")

if server.get("command") != "docker":
    raise SystemExit("github-readonly must run via docker")
expected_args = [
    "run",
    "-i",
    "--rm",
    "-e",
    "GITHUB_PERSONAL_ACCESS_TOKEN",
    "-e",
    "GITHUB_READ_ONLY",
    "-e",
    "GITHUB_TOOLSETS",
    "ghcr.io/github/github-mcp-server",
]
if args != expected_args:
    raise SystemExit("github-readonly profile must match the approved Docker argv exactly")

expected_env = {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}",
    "GITHUB_READ_ONLY": "1",
    "GITHUB_TOOLSETS": "context,repos,pull_requests,issues,actions",
}
if env != expected_env:
    raise SystemExit("github-readonly profile must match the approved environment map exactly")

passed_env = {current for previous, current in zip(args, args[1:]) if previous == "-e"}
if set(env) != passed_env:
    raise SystemExit("github-readonly must pass exactly every configured env key to docker")

items = {item.strip() for item in env["GITHUB_TOOLSETS"].split(",") if item.strip()}
allowed = {"context", "repos", "pull_requests", "issues", "actions"}
forbidden = {"all", "default", "git", "copilot", "notifications", "gists", "dependabot", "code_security", "discussions"}
if items != allowed:
    raise SystemExit("github-readonly toolsets must remain exactly the approved read-only set")
if items & forbidden:
    raise SystemExit(f"github-readonly contains forbidden toolsets: {sorted(items & forbidden)}")

print("✅ active MCP verification proof is valid")
PY
