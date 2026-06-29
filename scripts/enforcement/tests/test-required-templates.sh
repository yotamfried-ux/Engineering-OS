#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-required-templates.sh"
WRAPPER="$ROOT/scripts/enforcement/pre-tool-use-template-selection.sh"
PATCH="$ROOT/scripts/enforcement/patch-settings-runtime-evidence.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/required-templates.log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$LOG_FILE" 2>&1; then echo "unexpected pass: $name"; cat "$LOG_FILE"; exit 1; else echo "ok: $name"; fi; }

setup_repo() {
  rm -rf "$TMP/repo"
  mkdir -p "$TMP/repo/.claude/plans" "$TMP/repo/src/frontend" "$TMP/repo/src/api" "$TMP/repo/src/mobile"
  cd "$TMP/repo"
  git init >/dev/null
}

write_plan() {
  local task_class="$1" tags="$2" templates="$3"
  cat > .claude/plans/active.md <<EOF
# Route Plan

## Goal

Fixture goal.

## Plan

1. Select required template.
2. Validate before implementation.

## Alternatives

- Skip templates — rejected when required by task/domain/path.

| Field | Decision |
|---|---|
| Task class | $task_class |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | $tags |
| Templates | $templates |
| Patterns | none |
| External systems/connectors | none |
| Skills | superpowers |

## Source of Truth Checks

| Source | Status |
|---|---|
| fixture | checked |

## Definition of Done

- [x] fixture complete
EOF
}

append_template_waiver() {
  local body="${1:-}"
  cat >> .claude/plans/active.md <<EOF

## Template Selection Waiver

$body
EOF
}

write_payload() {
  local file="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$file"
}

run_check() { (cd "$TMP/repo" && bash "$CHECK" --plan .claude/plans/active.md --target "$1"); }
run_wrapper() { (cd "$TMP/repo" && write_payload "$1" | ENGINEERING_OS_HOME="$ROOT" bash "$WRAPPER"); }

pass checker_present test -f "$CHECK"
pass wrapper_present test -f "$WRAPPER"
pass patcher_present test -f "$PATCH"

setup_repo
write_plan feature "ui, ux, frontend" "not required"
failcase frontend_requires_web_template run_check src/frontend/ProfileCard.tsx

setup_repo
write_plan feature "ui, ux, frontend" "web-application"
pass frontend_with_web_template_passes run_check src/frontend/ProfileCard.tsx

setup_repo
write_plan feature "admin, dashboard, frontend" "web-application"
failcase admin_dashboard_requires_dashboard_template run_check src/frontend/AdminPanel.tsx

setup_repo
write_plan feature "admin, dashboard, frontend" "web-application, admin-dashboard"
pass admin_dashboard_with_required_templates_passes run_check src/frontend/AdminPanel.tsx

setup_repo
write_plan bug_fix "webhook, api, stripe" "none"
failcase api_webhook_requires_api_template run_check src/api/webhook.ts

setup_repo
write_plan bug_fix "webhook, api, stripe" "api-service"
pass api_webhook_with_api_template_passes run_check src/api/webhook.ts

setup_repo
write_plan feature "mobile, android, expo" "mobile-application"
pass mobile_template_passes run_check src/mobile/App.tsx

setup_repo
write_plan feature "ui, ux, frontend" "none"
append_template_waiver ""
failcase empty_template_waiver_is_rejected run_check src/frontend/ProfileCard.tsx

setup_repo
write_plan feature "ui, ux, frontend" "none"
append_template_waiver "Reason: this fixture intentionally uses a custom design spike; fallback is manual review against existing components."
pass template_waiver_requires_real_reason run_check src/frontend/ProfileCard.tsx

setup_repo
write_plan feature "ui, ux, frontend" "none"
failcase plan_write_enforces_template_selection run_wrapper .claude/plans/active.md

setup_repo
write_plan docs "documentation" "none"
pass docs_task_does_not_require_template run_wrapper docs/README.md

setup_repo
mkdir -p .claude
cat > .claude/settings.json <<'EOF'
{"hooks":{"PreToolUse":[{"matcher":"Write|Edit|MultiEdit|NotebookEdit","hooks":[]}]}}
EOF
bash "$PATCH" .claude/settings.json
pass install_patch_wires_template_selection grep -q 'pre-tool-use-template-selection.sh' .claude/settings.json

echo "required template simulations passed"
