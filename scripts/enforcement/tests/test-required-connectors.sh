#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-required-connectors.sh"
WRAPPER="$ROOT/scripts/enforcement/pre-tool-use-connector-selection.sh"
PATCH="$ROOT/scripts/enforcement/patch-settings-runtime-evidence.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/required-connectors.log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$LOG_FILE" 2>&1; then echo "unexpected pass: $name"; cat "$LOG_FILE"; exit 1; else echo "ok: $name"; fi; }

setup_repo() {
  rm -rf "$TMP/repo"
  mkdir -p "$TMP/repo/.claude/plans" "$TMP/repo/src/payments" "$TMP/repo/src/frontend" "$TMP/repo/src/ops"
  cd "$TMP/repo"
  git init >/dev/null
}

write_plan() {
  local task_class="$1" tags="$2" connectors="$3" notion_section="${4:-yes}"
  cat > .claude/plans/active.md <<EOF
# Route Plan

## Goal

Fixture goal.

## Plan

1. Validate required source-of-truth connectors.
2. Validate progress in Notion during the work.

## Alternatives

- Rely on memory only — rejected because connectors are the source of truth.

| Field | Decision |
|---|---|
| Task class | $task_class |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | $tags |
| Templates | not required |
| Patterns | none |
| External systems/connectors | $connectors |
| Skills | superpowers |

## Source of Truth Checks

| Source | Status |
|---|---|
| fixture | checked |

## Definition of Done

- [x] fixture complete
EOF
  if [ "$notion_section" = "yes" ]; then
    cat >> .claude/plans/active.md <<'EOF'

## Notion Progress Validation

- Planning checkpoint: spec exists or fallback issue exists.
- Mid-work checkpoint: progress/status was re-read or updated.
- Pre-merge checkpoint: Notion reflects final status.
EOF
  fi
}

append_connector_waiver() {
  local body="${1:-}"
  cat >> .claude/plans/active.md <<EOF

## Connector Selection Waiver

$body
EOF
}

write_payload() {
  local file="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$file"
}

run_check() { (cd "$TMP/repo" && bash "$CHECK" --plan .claude/plans/active.md --target "$1"); }
run_wrapper() { (cd "$TMP/repo" && write_payload "$1" | ENGINEERING_OS_HOME="$ROOT" bash "$WRAPPER"); }

seed_evidence() {
  (cd "$TMP/repo" && . "$ROOT/scripts/enforcement/lib/evidence.sh" && evidence_reset && for c in "$@"; do evidence_record connector_used "$c"; done)
}

seed_notion_progress() {
  (cd "$TMP/repo" && . "$ROOT/scripts/enforcement/lib/evidence.sh" && evidence_record notion_progress_validated)
}

pass checker_present test -f "$CHECK"
pass wrapper_present test -f "$WRAPPER"
pass patcher_present test -f "$PATCH"

setup_repo
write_plan bug_fix "payments, webhooks, stripe" "github" yes
failcase bug_payment_plan_requires_all_source_connectors run_check src/payments/webhook.ts

setup_repo
write_plan incident "ops" "github, sentry" yes
failcase incident_requires_notion_progress_connector run_check src/ops/recovery.ts

setup_repo
write_plan incident "ops" "github, notion, sentry" yes
pass incident_with_notion_selection_allows_plan run_check src/ops/recovery.ts

setup_repo
write_plan bug_fix "payments, webhooks, stripe" "github" yes
append_connector_waiver ""
failcase empty_connector_waiver_is_rejected run_check src/payments/webhook.ts

setup_repo
write_plan bug_fix "payments, webhooks, stripe" "github" yes
append_connector_waiver "Reason: this fixture uses a manual fallback source for the other connector checks."
pass connector_waiver_requires_real_reason run_check src/payments/webhook.ts

setup_repo
write_plan bug_fix "payments, webhooks, stripe" "github, notion, context7, sentry, postman, stripe" no
failcase notion_requires_progress_validation_section run_check src/payments/webhook.ts

setup_repo
write_plan bug_fix "payments, webhooks, stripe" "github, notion, context7, sentry, postman" yes
failcase stripe_tagged_plan_requires_stripe_connector run_check src/payments/webhook.ts

setup_repo
write_plan bug_fix "payments, webhooks, stripe" "github, notion, context7, sentry, postman, stripe" yes
pass complete_bug_payment_connector_selection_allows_plan run_check src/payments/webhook.ts

setup_repo
write_plan feature "ui, ux, frontend" "github, notion" yes
failcase ux_plan_requires_figma run_check src/frontend/ProfileCard.tsx

setup_repo
write_plan feature "ui, ux, frontend" "github, notion, figma" yes
pass ux_plan_with_figma_allows_plan run_check src/frontend/ProfileCard.tsx

setup_repo
write_plan feature "ui, ux, frontend" "github, notion" yes
seed_evidence github notion
seed_notion_progress
failcase plan_write_enforces_connector_selection run_wrapper .claude/plans/active.md

setup_repo
write_plan docs "documentation" "none" no
pass none_placeholder_does_not_require_evidence run_wrapper src/README.md

setup_repo
write_plan bug_fix "payments, webhooks, stripe" "github, notion, context7, sentry, postman, stripe" yes
seed_evidence github notion context7 sentry postman stripe
failcase runtime_requires_notion_progress_evidence run_wrapper src/payments/webhook.ts

setup_repo
write_plan bug_fix "payments, webhooks, stripe" "github, notion, context7, sentry, postman, stripe" yes
seed_evidence github notion context7 sentry postman stripe
seed_notion_progress
pass runtime_allows_required_connectors_and_progress run_wrapper src/payments/webhook.ts

setup_repo
write_plan integration "slack, ops" "github, notion" yes
failcase slack_tagged_plan_requires_slack_connector run_check src/ops/notify.ts

setup_repo
write_plan integration "slack, ops" "github, notion, slack" yes
pass slack_tagged_plan_with_slack_passes run_check src/ops/notify.ts

setup_repo
write_plan analysis "math, linear algebra" "none" no
pass linear_algebra_does_not_force_linear_connector run_check src/math/solver.py

setup_repo
write_plan feature "database migration schema" "github, notion" yes
failcase database_migration_requires_postgres_connector run_check src/db/migrate.sql
setup_repo
write_plan feature "database migration schema" "github, notion, postgres, supabase" yes
pass database_migration_with_postgres_passes run_check src/db/migrate.sql

setup_repo
write_plan feature "drive file document asset" "github, notion" yes
failcase drive_document_asset_requires_google_drive_connector run_check src/import/drive.ts
setup_repo
write_plan feature "drive file document asset" "github, notion, google-drive" yes
pass drive_document_asset_with_google_drive_passes run_check src/import/drive.ts

setup_repo
write_plan feature "spreadsheet csv import worksheet" "github, notion" yes
failcase csv_import_requires_google_sheets_connector run_check src/import/sheet.ts
setup_repo
write_plan feature "spreadsheet csv import worksheet" "github, notion, google-sheets" yes
pass csv_import_with_google_sheets_passes run_check src/import/sheet.ts

pass repo_inventory_coverage_passes bash "$CHECK" --check-coverage
cat > "$TMP/inv-extra.md" <<'EOF'
| Foo | `connectors/foo-service/` |
EOF
failcase unmapped_inventory_connector_fails_coverage bash "$CHECK" --check-coverage --inventory "$TMP/inv-extra.md"
printf 'badconn\tauto\n' > "$TMP/bad-manifest.tsv"
failcase malformed_manifest_row_fails bash "$CHECK" --manifest "$TMP/bad-manifest.tsv" --check-coverage

setup_repo
mkdir -p .claude
cat > .claude/settings.json <<'EOF'
{"hooks":{"PreToolUse":[{"matcher":"Write|Edit|MultiEdit|NotebookEdit","hooks":[]}]}}
EOF
bash "$PATCH" .claude/settings.json
pass install_patch_wires_connector_selection grep -q 'pre-tool-use-connector-selection.sh' .claude/settings.json
pass install_patch_wires_notion_progress grep -q 'notion_progress_validated' .claude/settings.json
pass install_patch_surfaces_notion_errors grep -q '2>&1' .claude/settings.json

echo "required connector simulations passed"
