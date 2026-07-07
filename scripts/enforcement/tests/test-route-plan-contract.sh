#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-route-plan-contract.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/good.md" <<'MD'
# Good Route Plan
selected_project_type: web-application
selected_template: templates/web-application
selected_roadmap: docs/operations/project-type-roadmaps.md#web-application
selected_result_loop_contract: scripts/enforcement/result-loop-requirements.tsv#web-application
required_user_simulation: Playwright browser flow
local_creator_review_path: http://localhost:3000
telemetry_export_path: scripts/monitoring/export-telemetry-run.sh
evidence_redaction_rule: metadata-only evidence export
MD

python3 "$CHECK" --plan "$TMP/good.md" --target src/app.py

cat > "$TMP/good-waiver.md" <<'MD'
# Good Governance Route Plan
selected_project_type: waiver: Engineering OS governance maintenance
selected_template: waiver: governance maintenance has no scaffold template
selected_roadmap: waiver: target-project roadmap catalog is not the subject of this policy change
selected_result_loop_contract: scripts/enforcement/result-loop-requirements.tsv checked
required_user_simulation: scripts/enforcement/tests/test-route-plan-contract.sh fixture coverage
local_creator_review_path: local CLI enforcement tests
telemetry_export_path: scripts/monitoring/export-telemetry-run.sh
evidence_redaction_rule: metadata-only evidence export
MD

python3 "$CHECK" --plan "$TMP/good-waiver.md" --target scripts/enforcement/x.sh

cat > "$TMP/bad.md" <<'MD'
# Bad Route Plan
selected_project_type: web-application
selected_template: templates/web-application
selected_roadmap: TBD
selected_result_loop_contract: none
required_user_simulation: Playwright flow
local_creator_review_path: http://localhost:3000
telemetry_export_path: scripts/monitoring/export-telemetry-run.sh
evidence_redaction_rule: metadata-only evidence export
MD

if python3 "$CHECK" --plan "$TMP/bad.md" --target src/app.py; then
  echo "expected missing roadmap or contract to fail" >&2
  exit 1
fi

python3 "$CHECK" --plan "$TMP/bad.md" --target docs/only.md

echo "route plan contract fixture tests passed"