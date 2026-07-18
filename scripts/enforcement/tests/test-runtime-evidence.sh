#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PRECHECK="$ROOT/scripts/enforcement/pre-tool-use-runtime-evidence.sh"
READ_RECORDER="$ROOT/scripts/enforcement/post-tool-use-read-evidence.sh"
chmod +x "$PRECHECK" "$READ_RECORDER"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
mkdir -p .claude/plans .claude/.evidence
export EOS_EVIDENCE_DIR=".claude/.evidence"
export EOS_PRETOOL_LEGACY_EXIT=1

expect_pass() { local name="$1"; shift; if "$@"; then echo "OK $name"; else echo "FAIL expected pass: $name"; exit 1; fi; }
expect_fail() { local name="$1"; shift; if "$@"; then echo "FAIL expected fail: $name"; exit 1; else echo "OK $name"; fi; }

run_precheck() {
  local file="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$file" | "$PRECHECK" >/dev/null 2>&1
}
record_read() {
  local file="$1"
  printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$file" | "$READ_RECORDER" >/dev/null 2>&1
}

write_valid_plan() {
  cat > .claude/plans/task.md <<'PLAN'
# Route Plan

| Field | Value |
|---|---|
| Task type | runtime evidence fixture |
| Task class | unclassified |
| Domain tags | runtime, fixture |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | Engineering OS route reviewed |
| Workflow evidence | workflow reviewed |
| Templates | not required |
| Architecture guides | runtime hook behavior checked locally |
| Patterns | not required |
| External systems/connectors | not required |
| Skills | not required |
| Validation gates | pre-tool-use-runtime-evidence.sh and check-runtime-evidence.sh |
| Evidence to check | hook exit codes and evidence ledger entries |
| User decisions required | none |

## Skill Selection Waiver

- all: runtime fixture isolates non-skill-selection behavior.

## Pattern Selection Waiver

- all: runtime fixture isolates non-pattern-selection behavior.

## Capability Waiver

Reason: runtime evidence test fixture uses unclassified task class to isolate live evidence behavior.

## Source of Truth Checks

| Need | Source checked | Result |
|---|---|---|
| Runtime enforcement | local hook evidence | required |
PLAN
}

: > .claude/.evidence/ledger
expect_fail "write before route plan" run_precheck src/app.ts
write_valid_plan
expect_fail "write before router and workflow reads" run_precheck src/app.ts
record_read core/task-router.md
expect_fail "write before workflow read" run_precheck src/app.ts
record_read core/workflow.md
expect_pass "write after plan and router/workflow evidence" run_precheck src/app.ts
grep -q 'capability_plan_validated' .claude/.evidence/ledger
grep -q $'\truntime_active_plan\t.claude/plans/task.md' .claude/.evidence/ledger

python3 - <<'PY'
from pathlib import Path
path = Path('.claude/plans/task.md')
text = path.read_text(encoding='utf-8')
path.write_text(text.replace(
    '| External systems/connectors | not required |',
    '| External systems/connectors | GitHub |',
), encoding='utf-8')
PY
expect_fail "declared connector without evidence remains blocked" run_precheck src/app.ts
cat >> .claude/plans/task.md <<'PLAN'

## Connector Evidence

- GitHub: waived — this local fixture deliberately validates the documented fallback path.
PLAN
expect_pass "documented connector waiver permits write gate" run_precheck src/app.ts

echo "runtime evidence checker tests passed"
