#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECKER="$ROOT/scripts/enforcement/check-runtime-evidence.sh"
PRECHECK="$ROOT/scripts/enforcement/pre-tool-use-runtime-evidence.sh"
MCP_RECORDER="$ROOT/scripts/enforcement/post-tool-use-mcp.sh"
READ_RECORDER="$ROOT/scripts/enforcement/post-tool-use-read-evidence.sh"
chmod +x "$CHECKER" "$PRECHECK" "$MCP_RECORDER" "$READ_RECORDER"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cd "$TMP"
mkdir -p .claude/plans .claude/.evidence
export EOS_EVIDENCE_DIR=".claude/.evidence"
export EOS_PRETOOL_LEGACY_EXIT=1

write_plan() {
  local connectors="$1" skills="$2" templates="${3:-none}" patterns="${4:-none}" source_truth="${5:-yes}" task_class="${6:-unclassified}" evidence_mode="${7:-waiver}"
  cat > .claude/plans/task.md <<PLAN
# Route Plan

| Field | Value |
|---|---|
| Task class | ${task_class} |
| Task-router evidence | Engineering OS route reviewed |
| Workflow evidence | workflow reviewed |
| Templates | ${templates} |
| Patterns | ${patterns} |
| External systems/connectors | ${connectors} |
| Skills | ${skills} |

PLAN
  case "$evidence_mode" in
    waiver)
      cat >> .claude/plans/task.md <<'PLAN'
## Capability Waiver

Reason: runtime evidence test fixture uses `unclassified` to isolate legacy live evidence behavior.
PLAN
      ;;
    code_change_complete)
      cat >> .claude/plans/task.md <<'PLAN'
## Capability Evidence

- `routing.task-router-read` — task router policy read.
- `workflow.workflow-read` — workflow policy read.
- `plan.route-plan-before-write` — plan exists before implementation.
- `source.github-repo-read` — repository files inspected.
PLAN
      ;;
    code_change_missing)
      cat >> .claude/plans/task.md <<'PLAN'
## Capability Evidence

- `routing.task-router-read` — task router policy read.
- `workflow.workflow-read` — workflow policy read.
- `plan.route-plan-before-write` — plan exists before implementation.
PLAN
      ;;
  esac
  if [ "$source_truth" = "yes" ]; then
    cat >> .claude/plans/task.md <<'PLAN'

## Source of Truth Checks

| Need | Source checked | Result |
|---|---|---|
| Runtime enforcement | local hook evidence | required |
PLAN
  fi
}

run_precheck() {
  local file="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$file" | "$PRECHECK" >/dev/null 2>&1
}

record_read() {
  local file="$1"
  printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$file" | "$READ_RECORDER" >/dev/null 2>&1
}

expect_pass() { local name="$1"; shift; if "$@"; then echo "  ✅ $name"; else echo "  ❌ expected $name to pass"; exit 1; fi; }
expect_fail() { local name="$1"; shift; if "$@"; then echo "  ❌ expected $name to fail"; exit 1; else echo "  ✅ $name"; fi; }

: > .claude/.evidence/ledger
expect_pass "prewrite allows creating route plan first" run_precheck .claude/plans/new-task.md
expect_fail "prewrite blocks code write without route plan" run_precheck src/app.ts

write_plan none none
expect_fail "prewrite blocks plan-only code write without router/workflow reads" run_precheck src/app.ts
record_read core/task-router.md
expect_fail "prewrite still blocks until workflow is read" run_precheck src/app.ts
record_read core/workflow.md
expect_pass "prewrite allows code after router/workflow reads" run_precheck src/app.ts
grep -q 'capability_plan_validated' .claude/.evidence/ledger

: > .claude/.evidence/ledger
write_plan none none none none yes code_change code_change_missing
record_read core/task-router.md
record_read core/workflow.md
expect_fail "prewrite blocks plan missing required registry capability" run_precheck src/app.ts

: > .claude/.evidence/ledger
write_plan none none none none yes code_change code_change_complete
record_read core/task-router.md
record_read core/workflow.md
expect_pass "prewrite accepts plan with required registry capabilities" run_precheck src/app.ts

: > .claude/.evidence/ledger
write_plan none none none none no
record_read core/task-router.md
record_read core/workflow.md
expect_fail "prewrite blocks missing source-of-truth section" run_precheck src/app.ts

: > .claude/.evidence/ledger
write_plan none none templates/github-actions none
record_read core/task-router.md
record_read core/workflow.md
expect_fail "prewrite blocks declared template without template read" run_precheck src/app.ts
mkdir -p templates/github-actions
touch templates/github-actions/security-review-nvidia.yml
record_read templates/github-actions/security-review-nvidia.yml
expect_pass "prewrite accepts template read evidence" run_precheck src/app.ts

: > .claude/.evidence/ledger
write_plan none none none patterns/api
record_read core/task-router.md
record_read core/workflow.md
expect_fail "prewrite blocks declared pattern without pattern read" run_precheck src/app.ts
mkdir -p patterns/api
touch patterns/api/rest-api.md
record_read patterns/api/rest-api.md
expect_pass "prewrite accepts pattern read evidence" run_precheck src/app.ts

: > .claude/.evidence/ledger
write_plan GitHub none none none
record_read core/task-router.md
record_read core/workflow.md
expect_fail "prewrite blocks declared connector without connector use" run_precheck src/app.ts
printf '{"tool_name":"mcp__GitHub__get_pr_info","tool_input":{},"tool_response":{"ok":true}}' | "$MCP_RECORDER" >/dev/null 2>&1
expect_pass "prewrite accepts connector evidence" run_precheck src/app.ts

: > .claude/.evidence/ledger
write_plan none superpowers-verify none none
record_read core/task-router.md
record_read core/workflow.md
expect_fail "prewrite blocks declared skill without skill evidence" run_precheck src/app.ts
printf '%s\tsuperpowers_verify_run\t\n' "$(date +%s)" >> .claude/.evidence/ledger
expect_pass "prewrite accepts skill evidence" run_precheck src/app.ts

: > .claude/.evidence/ledger
cat > .claude/plans/zero.md <<'PLAN'
# Route Plan
No checkbox items here.
PLAN
record_read .claude/plans/zero.md
if grep -q $'dod_initial_zero\t0$' .claude/.evidence/ledger; then
  echo "  ✅ read recorder stores scalar zero DoD count"
else
  echo "  ❌ expected scalar zero DoD count"
  cat .claude/.evidence/ledger
  exit 1
fi

echo "runtime evidence checker tests passed"
