#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SETTINGS="$ROOT/.claude/settings.json"
CRITICALITY="$ROOT/scripts/enforcement/hook-criticality.tsv"
READ_RECORDER="$ROOT/scripts/enforcement/post-tool-use-read-evidence.sh"
MCP_RECORDER="$ROOT/scripts/enforcement/post-tool-use-mcp.sh"
BASH_RECORDER="$ROOT/scripts/enforcement/post-tool-use-bash.sh"
chmod +x "$READ_RECORDER" "$MCP_RECORDER" "$BASH_RECORDER"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
mkdir -p .claude/.evidence core patterns/api .claude/commands
: > .claude/.evidence/ledger
export EOS_EVIDENCE_DIR=".claude/.evidence"

evidence_has() {
  local key="$1" value="${2:-}"
  if [ -n "$value" ]; then
    grep -qF "$(printf '\t%s\t%s' "$key" "$value")" .claude/.evidence/ledger
  else
    grep -qF "$(printf '\t%s\t' "$key")" .claude/.evidence/ledger
  fi
}

reset_ledger() { : > .claude/.evidence/ledger; }
run_raw() { local script="$1" raw="$2"; printf '%s' "$raw" | "$script" >/dev/null 2>&1; }
expect_pass() { local name="$1"; shift; if "$@"; then echo "  ✅ $name"; else echo "  ❌ expected pass: $name"; exit 1; fi; }
expect_absent() { local name="$1" key="$2" value="${3:-}"; if evidence_has "$key" "$value"; then echo "  ❌ unexpected evidence for $name: $key $value"; cat .claude/.evidence/ledger; exit 1; else echo "  ✅ $name"; fi; }

# Malformed PostToolUse inputs must be false-evidence-safe: recorder exits may be soft,
# but they must not create proof that a required source/tool was used.
reset_ledger
run_raw "$READ_RECORDER" '{"tool_name":"Read","tool_input":'
expect_absent "malformed Read input records no task-router evidence" task_router_read
expect_absent "malformed Read input records no workflow evidence" workflow_read

reset_ledger
run_raw "$MCP_RECORDER" '{"tool_name":"mcp__GitHub__get_pr_info","tool_input":'
expect_absent "malformed MCP input records no GitHub connector evidence" connector_used github
expect_absent "malformed MCP input records no github_used evidence" github_used

reset_ledger
run_raw "$BASH_RECORDER" '{"tool_name":"Bash","tool_input":'
expect_absent "malformed Bash input records no graphify evidence" graphify_used
expect_absent "malformed Bash input records no test evidence" tests_run

# Valid inputs must still record evidence; otherwise hard gates become impossible to satisfy.
reset_ledger
run_raw "$READ_RECORDER" '{"tool_name":"Read","tool_input":{"file_path":"core/task-router.md"}}'
expect_pass "valid Read records task-router evidence" evidence_has task_router_read
run_raw "$READ_RECORDER" '{"tool_name":"Read","tool_input":{"file_path":"core/workflow.md"}}'
expect_pass "valid Read records workflow evidence" evidence_has workflow_read
run_raw "$READ_RECORDER" '{"tool_name":"Read","tool_input":{"file_path":"patterns/api/rest.md"}}'
expect_pass "valid pattern Read records pattern domain evidence" evidence_has patterns_read_api
expect_pass "valid pattern Read records pattern_used evidence" evidence_has pattern_used api

reset_ledger
run_raw "$MCP_RECORDER" '{"tool_name":"mcp__GitHub__get_pr_info","tool_input":{},"tool_response":{"ok":true}}'
expect_pass "valid MCP records connector_used github" evidence_has connector_used github
expect_pass "valid MCP records connector_github" evidence_has connector_github
expect_pass "valid MCP records github_used" evidence_has github_used

reset_ledger
run_raw "$BASH_RECORDER" '{"tool_name":"Bash","tool_input":{"command":"pytest -q"},"tool_response":"============================= test session starts =============================\n1 passed in 0.01s"}'
expect_pass "valid test command records tests_run" evidence_has tests_run
run_raw "$BASH_RECORDER" '{"tool_name":"Bash","tool_input":{"command":"graphify query architecture"},"tool_response":"Architecture graph query returned multiple nodes and relationships with enough detail."}'
expect_pass "valid graphify command records graphify_used" evidence_has graphify_used

# Machine-readable criticality map must preserve the contract.
test -f "$CRITICALITY"
python3 - "$CRITICALITY" <<'PY'
import csv
import sys
from pathlib import Path

rows = []
for line in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    if not line.strip() or line.startswith("#"):
        continue
    parts = line.split("\t")
    assert len(parts) == 5, f"bad hook-criticality row: {line}"
    event, matcher, unit, klass, semantics = parts
    assert klass in {"hard", "advisory", "recorder", "lifecycle"}, line
    rows.append({"event": event, "matcher": matcher, "unit": unit, "class": klass, "semantics": semantics})

assert any(r["class"] == "hard" and r["event"] == "PreToolUse" for r in rows), "missing hard PreToolUse classification"
assert any(r["class"] == "recorder" and r["event"] == "PostToolUse" for r in rows), "missing PostToolUse recorder classification"
assert any(r["class"] == "advisory" for r in rows), "missing advisory classification"
assert any(r["unit"] == "pre-tool-use-json-guard.sh" and r["class"] == "hard" for r in rows), "JSON guard must be hard"
assert all(r["semantics"] == "fail_closed" for r in rows if r["class"] == "hard"), "hard hooks must fail closed"
assert all(r["semantics"] == "false_evidence_safe" for r in rows if r["class"] == "recorder"), "recorders must be false-evidence-safe"
print("  ✅ hook-criticality.tsv classifies hard/advisory/recorder behavior")
PY

# Settings criticality contract: hard PreToolUse enforcers must not be wrapped in || true,
# and write/bash/agent hard paths must run the JSON guard before downstream enforcers.
python3 - "$SETTINGS" <<'PY'
import json
import sys
from pathlib import Path

settings = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
pre = settings["hooks"].get("PreToolUse", [])
post = settings["hooks"].get("PostToolUse", [])

hard_scripts = (
    "pre-tool-use-json-guard.sh",
    "enforce-bash-entry.sh",
    "enforce-workflow.sh",
    "enforce-debugging.sh",
    "enforce-git.sh",
)

def commands_for(matcher):
    for block in pre:
        if block.get("matcher") == matcher:
            return [h.get("command", "") for h in block.get("hooks", [])]
    raise AssertionError(f"missing PreToolUse matcher {matcher}")

for matcher in ("Bash", "Write|Edit|MultiEdit|NotebookEdit", "Agent"):
    cmds = commands_for(matcher)
    assert cmds, matcher
    assert "pre-tool-use-json-guard.sh" in cmds[0], f"{matcher} must run JSON guard first"
    for cmd in cmds:
        if any(script in cmd for script in hard_scripts):
            assert "|| true" not in cmd, f"hard PreToolUse command must not be soft-wrapped: {cmd}"

# PostToolUse commands are allowed to be soft recorders, but they must be recorder scripts,
# not hidden hard gates disguised with || true.
post_serialized = json.dumps(post, ensure_ascii=False)
for hidden_hard in ("enforce-workflow.sh", "enforce-git.sh", "enforce-debugging.sh", "enforce-bash-entry.sh"):
    assert hidden_hard not in post_serialized, f"hard gate found under PostToolUse: {hidden_hard}"

print("  ✅ settings classify PreToolUse hard gates separately from PostToolUse recorders")
PY

echo "hook classification tests passed"
