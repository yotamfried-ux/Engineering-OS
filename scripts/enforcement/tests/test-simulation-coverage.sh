#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-simulation-coverage.sh"
TMP="$(mktemp -d)"

pass() { local name="$1"; shift; "$@" >"$TMP/$name.out" 2>&1 || { echo "fail: $name"; cat "$TMP/$name.out"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$TMP/$name.out" 2>&1; then echo "unexpected pass: $name"; cat "$TMP/$name.out"; exit 1; else echo "ok: $name"; fi; }

cat > "$TMP/fixture-test.sh" <<'EOF'
# positive-case-token
# negative-case-token
# invalid-case-token
EOF

good_manifest="$TMP/good.tsv"
cat > "$good_manifest" <<EOF
# gate_id	owner	enforcer	test_file	positive	negative	invalid	waiver	notes
fixture-gate	validation-governance	NONE	$TMP/fixture-test.sh	covered:positive-case-token	covered:negative-case-token	covered:invalid-case-token	waived:This fixture intentionally waives waiver coverage because the gate has no waiver path.	Fixture gate.
EOF

missing_token_manifest="$TMP/missing-token.tsv"
cat > "$missing_token_manifest" <<EOF
# gate_id	owner	enforcer	test_file	positive	negative	invalid	waiver	notes
fixture-gate	validation-governance	NONE	$TMP/fixture-test.sh	covered:positive-case-token	covered:missing-token-fails	covered:invalid-case-token	waived:This fixture intentionally waives waiver coverage because the gate has no waiver path.	Fixture gate.
EOF

malformed_manifest="$TMP/malformed.tsv"
cat > "$malformed_manifest" <<'EOF'
fixture-gate	validation-governance	NONE
EOF

waiver_manifest="$TMP/waiver.tsv"
cat > "$waiver_manifest" <<'EOF'
# gate_id	owner	enforcer	test_file	positive	negative	invalid	waiver	notes
waiver-gate	validation-governance	NONE	NONE	waived:Positive simulation is not applicable for this manual-only fixture gate.	waived:Negative simulation is not applicable for this manual-only fixture gate.	waived:Invalid simulation is not applicable for this manual-only fixture gate.	waived:Waiver simulation is not applicable because this row itself validates explicit waiver text.	Fixture waiver row.
EOF

pass current-manifest-passes bash "$CHECK"
pass single-fixture-manifest-passes env EOS_SIM_COVERAGE_REQUIRED_GATES=fixture-gate EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$good_manifest"
failcase missing-token-fails env EOS_SIM_COVERAGE_REQUIRED_GATES=fixture-gate EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$missing_token_manifest"
failcase malformed-row-fails env EOS_SIM_COVERAGE_REQUIRED_GATES=fixture-gate EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$malformed_manifest"
pass waiver-row-passes env EOS_SIM_COVERAGE_REQUIRED_GATES=waiver-gate EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$waiver_manifest"

echo "simulation coverage validator tests passed"
