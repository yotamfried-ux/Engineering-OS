#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PRECHECK="$ROOT/scripts/enforcement/pre-tool-use-runtime-evidence.sh"
READ_RECORDER="$ROOT/scripts/enforcement/post-tool-use-read-evidence.sh"
chmod +x "$PRECHECK" "$READ_RECORDER"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG="$TMP/skill-e2e.log"
pass() { local name="$1"; shift; if "$@" >"$LOG" 2>&1; then echo "ok: $name"; else echo "fail: $name"; cat "$LOG"; exit 1; fi; }
failcase() { local name="$1"; shift; if "$@" >"$LOG" 2>&1; then echo "unexpected pass: $name"; cat "$LOG"; exit 1; else echo "ok: $name"; fi; }

run_precheck_in() { local repo="$1" file="$2"; (cd "$repo" && printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$file" | "$PRECHECK"); }
record_read_in() { local repo="$1" file="$2"; (cd "$repo" && printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$file" | "$READ_RECORDER" >/dev/null); }
write_runtime_plan() {
  local repo="$1" skill_value="$2"
  mkdir -p "$repo/.claude/plans" "$repo/.claude/.evidence"
  cat > "$repo/.claude/plans/skill-runtime.md" <<PLAN
# Route Plan

| Field | Value |
|---|---|
| Task type | skill runtime evidence fixture |
| Task class | unclassified |
| Domain tags | skill, runtime, fixture |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | task-router read |
| Workflow evidence | workflow read |
| Templates | not required |
| Architecture guides | runtime skill evidence behavior checked locally |
| Patterns | not required |
| External systems/connectors | not required |
| Skills | $skill_value |
| Validation gates | pre-tool-use-runtime-evidence.sh |
| Evidence to check | runtime hook exit code and evidence ledger |

## Capability Waiver

Reason: skill E2E simulation isolates runtime skill evidence behavior.

## Source of Truth Checks

| Source | Result |
|---|---|
| skill runtime evidence gate | required |
PLAN
}

RUNTIME_REPO="$TMP/runtime-skill"
mkdir -p "$RUNTIME_REPO/.claude/.evidence"
git init "$RUNTIME_REPO" >/dev/null
git -C "$RUNTIME_REPO" config user.email test@example.com
git -C "$RUNTIME_REPO" config user.name test
write_runtime_plan "$RUNTIME_REPO" "superpowers"
: > "$RUNTIME_REPO/.claude/.evidence/ledger"
export EOS_EVIDENCE_DIR=".claude/.evidence"
export EOS_PRETOOL_LEGACY_EXIT=1
record_read_in "$RUNTIME_REPO" core/task-router.md
record_read_in "$RUNTIME_REPO" core/workflow.md
failcase "write fails before skill evidence exists" run_precheck_in "$RUNTIME_REPO" src/app.ts
printf 'now\tskill_used\tsuperpowers\n' >> "$RUNTIME_REPO/.claude/.evidence/ledger"
pass "write passes after skill evidence exists" run_precheck_in "$RUNTIME_REPO" src/app.ts

echo "skill E2E simulations passed"
