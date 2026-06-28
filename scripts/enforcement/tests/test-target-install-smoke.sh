#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

TARGET="$TMP/target-project"
git init "$TARGET" >/dev/null
cd "$TARGET"

EOS_CONTRACT_TEST=1 ENGINEERING_OS_HOME="$ROOT" bash "$ROOT/scripts/use-in-project.sh" >/tmp/eos-install.out

test -f CLAUDE.md
test -f ENGINEERING_OS_CAPABILITIES.md
test -f ENGINEERING_OS_SETUP.md
test -f .claude/settings.json
test -f .github/workflows/capability-evidence-policy.yml

grep -q 'ENGINEERING_OS_CAPABILITIES.md' ENGINEERING_OS_SETUP.md
grep -q 'Capability Verification Report' ENGINEERING_OS_CAPABILITIES.md

mkdir -p .claude/plans .claude/.evidence src
cat > .claude/plans/smoke.md <<'PLAN'
# Route Plan

| Field | Value |
|---|---|
| Task class | code_change |
| Task-router evidence | checked |
| Workflow evidence | checked |
| Templates | none |
| Patterns | none |
| External systems/connectors | none |
| Skills | none |

## Capability Evidence

- `routing.task-router-read` — task-router read evidence is recorded in the live ledger.
- `workflow.workflow-read` — workflow read evidence is recorded in the live ledger.
- `plan.route-plan-before-write` — plan exists before implementation write.
- `source.github-repo-read` — repository state was checked before implementation.

## Skill Selection Waiver

- all: install smoke fixture isolates capability and source-evidence flow.

## Source of Truth Checks

| Need | Source checked | Result |
|---|---|---|
| Runtime smoke | installed target project | verified |
PLAN

printf '{"tool_name":"Read","tool_input":{"file_path":"core/task-router.md"}}' \
  | ENGINEERING_OS_HOME="$ROOT" bash "$ROOT/scripts/enforcement/post-tool-use-read-evidence.sh"
printf '{"tool_name":"Read","tool_input":{"file_path":"core/workflow.md"}}' \
  | ENGINEERING_OS_HOME="$ROOT" bash "$ROOT/scripts/enforcement/post-tool-use-read-evidence.sh"

if EOS_PRETOOL_LEGACY_EXIT=1 ENGINEERING_OS_HOME="$ROOT" \
  bash "$ROOT/scripts/enforcement/pre-tool-use-runtime-evidence.sh" \
  <<< '{"tool_name":"Write","tool_input":{"file_path":"src/app.ts"}}'; then
  echo "expected prewrite to fail before live GitHub source evidence"
  exit 1
fi

printf '{"tool_name":"mcp__GitHub__get_pr_info","tool_input":{},"tool_response":{"ok":true}}' \
  | ENGINEERING_OS_HOME="$ROOT" bash "$ROOT/scripts/enforcement/post-tool-use-mcp.sh"

EOS_PRETOOL_LEGACY_EXIT=1 ENGINEERING_OS_HOME="$ROOT" \
  bash "$ROOT/scripts/enforcement/pre-tool-use-runtime-evidence.sh" \
  <<< '{"tool_name":"Write","tool_input":{"file_path":"src/app.ts"}}'

grep -q 'capability_plan_validated' .claude/.evidence/ledger

echo "✅ target install runtime smoke test passed"
