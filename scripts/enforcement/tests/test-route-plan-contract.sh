#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-route-plan-contract.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/good.md" <<'MD'
selected_project_type: web-application
selected_template: templates/web-application
selected_roadmap: docs/operations/project-type-roadmaps.md#web-application
selected_result_loop_contract: scripts/enforcement/result-loop-requirements.tsv#web-application
required_user_simulation: browser flow
local_creator_review_path: http://localhost:3000
telemetry_export_path: scripts/monitoring/export-telemetry-run.sh
evidence_policy_rule: metadata-only evidence export
MD

bash "$CHECK" --plan "$TMP/good.md" --target src/app.py

cat > "$TMP/bad.md" <<'MD'
selected_project_type: web-application
selected_template: templates/web-application
selected_roadmap: docs/operations/project-type-roadmaps.md#web-application
MD

if bash "$CHECK" --plan "$TMP/bad.md" --target src/app.py; then
  echo "expected missing fields to fail" >&2
  exit 1
fi

bash "$CHECK" --plan "$TMP/bad.md" --target docs/only.md

echo "route plan checker tests passed"
