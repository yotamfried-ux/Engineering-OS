#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
WRAPPER="$ROOT/scripts/enforcement/pre-tool-use-template-selection.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/template-plan-repair.log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$LOG_FILE" 2>&1; then echo "unexpected pass: $name"; cat "$LOG_FILE"; exit 1; else echo "ok: $name"; fi; }

setup_repo() {
  rm -rf "$TMP/repo"
  mkdir -p "$TMP/repo/.claude/plans"
  cd "$TMP/repo"
  git init >/dev/null
  cat > .claude/plans/active.md <<'EOF'
# Route Plan

| Field | Decision |
|---|---|
| Task class | feature |
| Domain tags | ui, ux, frontend |
| Templates | none |
EOF
}

payload_without_content() {
  printf '{"tool_name":"Write","tool_input":{"file_path":".claude/plans/active.md"}}'
}

payload_with_fixed_content() {
  python3 - <<'PY'
import json
content = '''# Route Plan

| Field | Decision |
|---|---|
| Task class | feature |
| Domain tags | ui, ux, frontend |
| Templates | web-application |
'''
print(json.dumps({"tool_name":"Write","tool_input":{"file_path":".claude/plans/active.md","content":content}}))
PY
}

run_without_content() { (cd "$TMP/repo" && payload_without_content | ENGINEERING_OS_HOME="$ROOT" bash "$WRAPPER"); }
run_with_content() { (cd "$TMP/repo" && payload_with_fixed_content | ENGINEERING_OS_HOME="$ROOT" bash "$WRAPPER"); }

pass wrapper_present test -f "$WRAPPER"
setup_repo
failcase stale_plan_without_repair_is_blocked run_without_content
pass proposed_plan_content_is_validated run_with_content

echo "template plan repair simulation passed"
