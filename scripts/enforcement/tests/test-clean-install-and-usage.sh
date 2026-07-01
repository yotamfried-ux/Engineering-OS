#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
USE_IN_PROJECT="$ROOT/scripts/use-in-project.sh"
PRECHECK="$ROOT/scripts/enforcement/pre-tool-use-runtime-evidence.sh"
READ_RECORDER="$ROOT/scripts/enforcement/post-tool-use-read-evidence.sh"
MERGE_CHECK="$ROOT/scripts/enforcement/check-merge-readiness.sh"
JSON_GUARD="$ROOT/scripts/enforcement/pre-tool-use-json-guard.sh"
chmod +x "$USE_IN_PROJECT" "$PRECHECK" "$READ_RECORDER" "$MERGE_CHECK" "$JSON_GUARD"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
TARGET="$TMP/target-app"
mkdir -p "$TARGET"

git init "$TARGET" >/dev/null
git -C "$TARGET" config user.email test@example.com
git -C "$TARGET" config user.name test

expect_file() { [ -f "$1" ] || { echo "  ❌ missing file: $1"; exit 1; }; echo "  ✅ file exists: ${1#$TARGET/}"; }
expect_executable() { [ -x "$1" ] || { echo "  ❌ not executable: $1"; exit 1; }; echo "  ✅ executable: ${1#$TARGET/}"; }
expect_contains() { grep -q "$2" "$1" || { echo "  ❌ expected $1 to contain $2"; exit 1; }; echo "  ✅ contains: ${1#$TARGET/} -> $2"; }
expect_pass() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "  ✅ $name"; else echo "  ❌ expected pass: $name"; exit 1; fi; }
expect_fail() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "  ❌ expected fail: $name"; exit 1; else echo "  ✅ $name"; fi; }

run_install() {
  (cd "$TARGET" && EOS_CONTRACT_TEST=1 ENGINEERING_OS_HOME="$ROOT" bash "$USE_IN_PROJECT" >/dev/null)
}

run_precheck() {
  local file="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$file" | "$PRECHECK" >/dev/null 2>&1
}

record_read() {
  local file="$1"
  printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$file" | "$READ_RECORDER" >/dev/null 2>&1
}

write_usage_plan() {
  mkdir -p "$TARGET/.claude/plans"
  cat > "$TARGET/.claude/plans/usage.md" <<'PLAN'
# Route Plan

| Field | Value |
|---|---|
| Task class | unclassified |
| Task-router evidence | task router was read |
| Workflow evidence | workflow was read |
| Templates | none |
| Patterns | none |
| External systems/connectors | none |
| Skills | none |

## Capability Waiver

Reason: clean install usage simulation uses an unclassified fixture to isolate runtime hook behavior.

## Source of Truth Checks

| Need | Source checked | Result |
|---|---|---|
| Runtime gate behavior | local hook simulation | required |
PLAN
}

make_runs_json() {
  local file="$1" enforcement_status="$2" enforcement_conclusion="$3"
  cat > "$file" <<JSON
{"workflow_runs":[
 {"name":"enforcement-tests","status":"$enforcement_status","conclusion":"$enforcement_conclusion"},
 {"name":"pr-policy","status":"completed","conclusion":"success"},
 {"name":"connector-evidence-policy","status":"completed","conclusion":"success"},
 {"name":"workflow-evidence-policy","status":"completed","conclusion":"success"},
 {"name":"capability-evidence-policy","status":"completed","conclusion":"success"},
 {"name":"plan-policy","status":"completed","conclusion":"success"},
 {"name":"documentation-asset-policy","status":"completed","conclusion":"success"}
]}
JSON
}

echo "── Experiment 1: clean install into target repo ──"
run_install
expect_file "$TARGET/CLAUDE.md"
expect_file "$TARGET/.engineering-os/REFERENCE.md"
expect_file "$TARGET/ENGINEERING_OS_SETUP.md"
expect_file "$TARGET/ENGINEERING_OS_CAPABILITIES.md"
expect_file "$TARGET/.claude/settings.json"
expect_file "$TARGET/.claude/commands/use-engineering-os.md"
expect_file "$TARGET/.claude/commands/superpowers-brainstorm.md"
expect_file "$TARGET/.claude/commands/superpowers-verify.md"
expect_file "$TARGET/.claude/commands/superpowers-plan.md"
expect_executable "$TARGET/.git/hooks/pre-commit"
expect_executable "$TARGET/.git/hooks/commit-msg"
expect_executable "$TARGET/.git/hooks/post-commit"
expect_file "$TARGET/.github/workflows/pr-policy.yml"
expect_file "$TARGET/.github/workflows/plan-policy.yml"
expect_file "$TARGET/.github/workflows/connector-evidence-policy.yml"
expect_file "$TARGET/.github/workflows/workflow-evidence-policy.yml"
expect_file "$TARGET/.github/workflows/capability-evidence-policy.yml"
expect_file "$TARGET/.github/workflows/documentation-asset-policy.yml"
expect_contains "$TARGET/.claude/settings.json" "pre-tool-use-json-guard.sh"
expect_contains "$TARGET/.claude/settings.json" "pre-tool-use-runtime-evidence.sh"
expect_contains "$TARGET/.claude/settings.json" "check-plan-scope.sh"
expect_contains "$TARGET/.claude/settings.json" "$ROOT/scripts/enforcement"

run_install
managed_count="$(grep -c '<!-- BEGIN engineering-os (managed) -->' "$TARGET/CLAUDE.md")"
[ "$managed_count" = "1" ] || { echo "  ❌ managed CLAUDE block duplicated: $managed_count"; exit 1; }
echo "  ✅ install is idempotent: managed block count = 1"

settings_count="$(find "$TARGET/.claude" -name settings.json | wc -l | xargs)"
[ "$settings_count" = "1" ] || { echo "  ❌ settings duplicated: $settings_count"; exit 1; }
echo "  ✅ install is idempotent: one settings file"

echo "── Experiment 2: actual usage gate simulation ──"
cd "$TARGET"
mkdir -p .claude/.evidence
export EOS_EVIDENCE_DIR=".claude/.evidence"
export EOS_PRETOOL_LEGACY_EXIT=1
: > .claude/.evidence/ledger

expect_fail "JSON guard blocks malformed event" bash -c "printf '%s' '{bad json' | '$JSON_GUARD'"
expect_fail "write blocked before any Route Plan exists" run_precheck src/app.ts
write_usage_plan
expect_fail "write still blocked until task-router/workflow are read" run_precheck src/app.ts
record_read core/task-router.md
expect_fail "write still blocked until workflow is read" run_precheck src/app.ts
record_read core/workflow.md
expect_pass "write allowed after plan plus router/workflow evidence" run_precheck src/app.ts

make_runs_json "$TMP/pending.json" in_progress null
expect_fail "merge readiness blocks pending workflow" "$MERGE_CHECK" --runs-json "$TMP/pending.json"
make_runs_json "$TMP/green.json" completed success
expect_pass "merge readiness allows all green workflows" "$MERGE_CHECK" --runs-json "$TMP/green.json"

echo "clean install and usage experiments passed"
