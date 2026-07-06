#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-route-plan-contract.py"
TMP="$(mktemp -d)"

cat > "$TMP/good.md" <<'MD'
# Good Route Plan

| Field | Value |
|---|---|
| selected_project_type | web-application |
| selected_template | templates/web-application |
| selected_roadmap | docs/operations/project-type-roadmaps.md#web-application |
| selected_result_loop_contract | docs/operations/result-loop-contract-plan.md#web-application planned requirement gap:result-loop-gate |
| required_user_simulation | Playwright browser flow covering happy path and failure path |
| local_creator_review_path | http://localhost:3000 |
| telemetry_export_path | scripts/monitoring/export-telemetry-run.sh |
| evidence_redaction_rule | metadata-only; redact restricted evidence before export |
MD

python3 "$CHECK" --plan "$TMP/good.md" --target src/app.py

cat > "$TMP/good-waiver.md" <<'MD'
# Good Governance Route Plan

selected_project_type: waiver: Engineering OS governance maintenance, not a target project
selected_template: waiver: governance maintenance has no scaffold template
selected_roadmap: waiver: target-project roadmap catalog is not the subject of this policy change
selected_result_loop_contract: planned requirement via docs/operations/result-loop-contract-plan.md
required_user_simulation: scripts/enforcement/tests/test-route-plan-contract.sh fixture coverage
local_creator_review_path: local CLI enforcement tests
telemetry_export_path: scripts/monitoring/export-telemetry-run.sh
vidence_redaction_rule: metadata-only; redact restricted evidence before export
MD

if python3 "$CHECK" --plan "$TMP/good-waiver.md" --target scripts/enforcement/x.sh; then
  echo "expected typo in required field to fail" >&2
  exit 1
fi
sed 's/^vidence_redaction_rule/evidence_redaction_rule/' "$TMP/good-waiver.md" > "$TMP/good-waiver-fixed.md"
python3 "$CHECK" --plan "$TMP/good-waiver-fixed.md" --target scripts/enforcement/x.sh

cat > "$TMP/bad.md" <<'MD'
# Bad Route Plan

selected_project_type: web-application
selected_template: templates/web-application
selected_roadmap: TBD
selected_result_loop_contract: none
required_user_simulation: Playwright flow
local_creator_review_path: http://localhost:3000
telemetry_export_path: scripts/monitoring/export-telemetry-run.sh
evidence_redaction_rule: metadata-only; redact restricted evidence before export
MD

if python3 "$CHECK" --plan "$TMP/bad.md" --target src/app.py; then
  echo "expected missing roadmap/contract to fail" >&2
  exit 1
fi

python3 "$CHECK" --plan "$TMP/bad.md" --target docs/only.md

echo "route plan contract fixture tests passed"
