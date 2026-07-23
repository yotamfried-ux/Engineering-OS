#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
MERGE_CHECK="$ROOT/scripts/enforcement/check-merge-readiness.sh"
JSON_GUARD="$ROOT/scripts/enforcement/pre-tool-use-json-guard.sh"
chmod +x "$MERGE_CHECK" "$JSON_GUARD"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

expect_pass() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "  ✅ $name"; else echo "  ❌ expected $name to pass"; exit 1; fi; }
expect_fail() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "  ❌ expected $name to fail"; exit 1; else echo "  ✅ $name"; fi; }

cat > "$TMP/runs-good.json" <<'JSON'
{
  "workflow_runs": [
    {"name":"enforcement-tests","status":"completed","conclusion":"success"},
    {"name":"pr-policy","status":"completed","conclusion":"success"},
    {"name":"connector-evidence-policy","status":"completed","conclusion":"success"},
    {"name":"workflow-evidence-policy","status":"completed","conclusion":"success"},
    {"name":"capability-evidence-policy","status":"completed","conclusion":"success"},
    {"name":"plan-policy","status":"completed","conclusion":"success"},
    {"name":"documentation-asset-policy","status":"completed","conclusion":"success"},
    {"name":"semantic-cleanup-policy","status":"completed","conclusion":"success"},
    {"name":"import-cleanup-policy","status":"completed","conclusion":"success"}
  ]
}
JSON

cat > "$TMP/runs-pr107-bad.json" <<'JSON'
{
  "workflow_runs": [
    {"name":"enforcement-tests","status":"completed","conclusion":"success"},
    {"name":"pr-policy","status":"completed","conclusion":"success"},
    {"name":"capability-evidence-policy","status":"completed","conclusion":"success"},
    {"name":"workflow-evidence-policy","status":"completed","conclusion":"failure"},
    {"name":"connector-evidence-policy","status":"completed","conclusion":"failure"},
    {"name":"plan-policy","status":"completed","conclusion":"success"},
    {"name":"documentation-asset-policy","status":"completed","conclusion":"success"},
    {"name":"semantic-cleanup-policy","status":"completed","conclusion":"success"},
    {"name":"import-cleanup-policy","status":"completed","conclusion":"success"}
  ]
}
JSON

cat > "$TMP/runs-missing.json" <<'JSON'
{
  "workflow_runs": [
    {"name":"enforcement-tests","status":"completed","conclusion":"success"},
    {"name":"pr-policy","status":"completed","conclusion":"success"}
  ]
}
JSON

cat > "$TMP/runs-missing-cleanup.json" <<'JSON'
{
  "workflow_runs": [
    {"name":"enforcement-tests","status":"completed","conclusion":"success"},
    {"name":"pr-policy","status":"completed","conclusion":"success"},
    {"name":"connector-evidence-policy","status":"completed","conclusion":"success"},
    {"name":"workflow-evidence-policy","status":"completed","conclusion":"success"},
    {"name":"capability-evidence-policy","status":"completed","conclusion":"success"},
    {"name":"plan-policy","status":"completed","conclusion":"success"},
    {"name":"documentation-asset-policy","status":"completed","conclusion":"success"}
  ]
}
JSON

cat > "$TMP/runs-old-success-new-failure.json" <<'JSON'
{
  "workflow_runs": [
    {"id":101,"name":"enforcement-tests","head_sha":"1111111111111111111111111111111111111111","run_started_at":"2026-07-22T10:00:00Z","run_attempt":1,"status":"completed","conclusion":"success"},
    {"id":102,"name":"enforcement-tests","head_sha":"1111111111111111111111111111111111111111","run_started_at":"2026-07-22T11:00:00Z","run_attempt":1,"status":"completed","conclusion":"failure"}
  ]
}
JSON

expect_pass "merge readiness accepts all-success required workflows" "$MERGE_CHECK" --runs-json "$TMP/runs-good.json"
expect_fail "merge readiness blocks PR107-style failed evidence workflows" "$MERGE_CHECK" --runs-json "$TMP/runs-pr107-bad.json"
expect_fail "merge readiness blocks missing required workflows" "$MERGE_CHECK" --runs-json "$TMP/runs-missing.json"
expect_fail "merge readiness blocks missing cleanup policy workflows" "$MERGE_CHECK" --runs-json "$TMP/runs-missing-cleanup.json"
expect_fail "merge readiness rejects a newer failure hidden behind an older success" "$MERGE_CHECK" --runs-json "$TMP/runs-old-success-new-failure.json" --required "enforcement-tests"

run_guard_raw() { printf '%s' "$1" | "$JSON_GUARD"; }
expect_fail "JSON guard blocks malformed PreToolUse JSON" run_guard_raw '{"tool_name":"Write","tool_input":'
expect_fail "JSON guard blocks Write without file_path" run_guard_raw '{"tool_name":"Write","tool_input":{}}'
expect_fail "JSON guard blocks Bash without command" run_guard_raw '{"tool_name":"Bash","tool_input":{}}'
expect_pass "JSON guard allows Agent with valid event" run_guard_raw '{"tool_name":"Agent","tool_input":{}}'
expect_pass "JSON guard allows Write with file_path" run_guard_raw '{"tool_name":"Write","tool_input":{"file_path":"src/app.ts"}}'
expect_pass "JSON guard allows Bash with command" run_guard_raw '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}'

echo "operational readiness gate tests passed"
