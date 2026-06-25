#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECKER="$ROOT/scripts/enforcement/check-runtime-evidence.sh"
RECORDER="$ROOT/scripts/enforcement/post-tool-use-mcp.sh"
chmod +x "$CHECKER" "$RECORDER"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cd "$TMP"
mkdir -p .claude/plans .claude/.evidence
export EOS_EVIDENCE_DIR=".claude/.evidence"

write_plan() {
  local connectors="$1" skills="$2"
  cat > .claude/plans/task.md <<PLAN
# Route Plan

| Field | Value |
|---|---|
| External systems/connectors | ${connectors} |
| Skills | ${skills} |
PLAN
}

expect_pass() {
  local name="$1"
  if ! "$CHECKER" .claude/plans/task.md; then
    echo "expected $name to pass"
    exit 1
  fi
}

expect_fail() {
  local name="$1"
  if "$CHECKER" .claude/plans/task.md; then
    echo "expected $name to fail"
    exit 1
  fi
}

# No declared connectors or skills should pass with no evidence.
: > .claude/.evidence/ledger
write_plan none none
expect_pass none-needed

# Declared connector should fail before a connector tool records evidence.
: > .claude/.evidence/ledger
write_plan GitHub none
expect_fail connector-missing

# Generic MCP recorder should satisfy connector evidence.
printf '{"tool_name":"mcp__GitHub__search","tool_input":{},"tool_response":{"ok":true}}' | "$RECORDER"
expect_pass connector-present

grep -q 'connector_used' .claude/.evidence/ledger
grep -q 'connector_github' .claude/.evidence/ledger

# Declared superpowers-verify should fail until evidence exists.
: > .claude/.evidence/ledger
write_plan none superpowers-verify
expect_fail skill-missing
printf '%s\tsuperpowers_verify_run\t\n' "$(date +%s)" >> .claude/.evidence/ledger
expect_pass skill-present

# Connector plus skill requires both.
: > .claude/.evidence/ledger
write_plan Sentry superpowers-verify
printf '{"tool_name":"mcp__Sentry__search","tool_input":{},"tool_response":{"ok":true}}' | "$RECORDER"
expect_fail connector-present-skill-missing
printf '%s\tsuperpowers_verify_run\t\n' "$(date +%s)" >> .claude/.evidence/ledger
expect_pass both-present

echo "runtime evidence checker tests passed"
