#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-simulation-coverage.sh"
ROUTE_CHECK="$ROOT/scripts/enforcement/check-route-plan-contract.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
ok(){ local n="$1"; shift; "$@" >"$TMP/$n.out" 2>&1 || { cat "$TMP/$n.out"; exit 1; }; echo "ok: $n"; }
no(){ local n="$1"; shift; if "$@" >"$TMP/$n.out" 2>&1; then cat "$TMP/$n.out"; exit 1; else echo "ok: $n"; fi; }
cat > "$TMP/t.sh" <<'EOF'
required_map_ok
required_map_gap
required_map_dup
required_map_waiver
EOF
cat > "$TMP/c.tsv" <<EOF
fixture	validation-governance	NONE	$TMP/t.sh	covered:required_map_ok	covered:required_map_gap	covered:required_map_dup	covered:required_map_waiver	Fixture row.
EOF
cat > "$TMP/good.tsv" <<'EOF'
fixture	validation-governance	active	Fixture is required.
EOF
cat > "$TMP/gap.tsv" <<'EOF'
other	validation-governance	active	Other is required.
EOF
cat > "$TMP/dup.tsv" <<'EOF'
fixture	validation-governance	active	Fixture is required.
fixture	validation-governance	active	Fixture is duplicated.
EOF
cat > "$TMP/waive.tsv" <<'EOF'
manual	manual-governance	waived	Manual fixture waiver has enough detail.
EOF
ok required_map_ok env EOS_SIM_COVERAGE_REQUIRED_GATES_FILE="$TMP/good.tsv" EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$TMP/c.tsv"
no required_map_gap env EOS_SIM_COVERAGE_REQUIRED_GATES_FILE="$TMP/gap.tsv" EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$TMP/c.tsv"
no required_map_dup env EOS_SIM_COVERAGE_REQUIRED_GATES_FILE="$TMP/dup.tsv" EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$TMP/c.tsv"
ok required_map_waiver env EOS_SIM_COVERAGE_REQUIRED_GATES_FILE="$TMP/waive.tsv" EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$TMP/c.tsv"

cat > "$TMP/route-good.md" <<'EOF'
selected_project_type: web-application
selected_template: templates/web-application
selected_roadmap: docs/operations/project-type-roadmaps.md#web-application
selected_result_loop_contract: scripts/enforcement/result-loop-requirements.tsv#web-application
required_user_simulation: browser flow
local_creator_review_path: http://localhost:3000
telemetry_export_path: scripts/monitoring/export-telemetry-run.sh
evidence_policy_rule: metadata-only evidence export
EOF
cat > "$TMP/route-bad.md" <<'EOF'
selected_project_type: web-application
selected_template: templates/web-application
selected_roadmap: docs/operations/project-type-roadmaps.md#web-application
EOF
ok route_plan_contract_ok bash "$ROUTE_CHECK" --plan "$TMP/route-good.md" --target src/app.py
no route_plan_contract_missing_fields bash "$ROUTE_CHECK" --plan "$TMP/route-bad.md" --target src/app.py
ok route_plan_contract_docs_only bash "$ROUTE_CHECK" --plan "$TMP/route-bad.md" --target docs/only.md
