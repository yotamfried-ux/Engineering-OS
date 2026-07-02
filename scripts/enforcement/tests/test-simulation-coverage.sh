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
# not-yet-token
EOF

good_manifest="$TMP/good.tsv"
cat > "$good_manifest" <<EOF
# gate_id	owner	enforcer	test_file	positive	negative	invalid	waiver	notes
fixture-gate	validation-governance	NONE	$TMP/fixture-test.sh	covered:positive-case-token	covered:negative-case-token	covered:invalid-case-token	none-by-design:This fixture gate deliberately exposes no waiver path.	Fixture gate.
EOF

missing_token_manifest="$TMP/missing-token.tsv"
cat > "$missing_token_manifest" <<EOF
# gate_id	owner	enforcer	test_file	positive	negative	invalid	waiver	notes
fixture-gate	validation-governance	NONE	$TMP/fixture-test.sh	covered:positive-case-token	covered:missing-token-fails	covered:invalid-case-token	none-by-design:This fixture gate deliberately exposes no waiver path.	Fixture gate.
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

stale_manifest="$TMP/stale.tsv"
cat > "$stale_manifest" <<EOF
# gate_id	owner	enforcer	test_file	positive	negative	invalid	waiver	notes
stale-gate	validation-governance	NONE	$TMP/fixture-test.sh	covered:positive-case-token	covered:negative-case-token	covered:invalid-case-token	waived:This fixture intentionally keeps old pending coverage text for validation.	Fixture still says future loop should add a direct test.
EOF

token_with_stale_substring_manifest="$TMP/token-with-stale-substring.tsv"
cat > "$token_with_stale_substring_manifest" <<EOF
# gate_id	owner	enforcer	test_file	positive	negative	invalid	waiver	notes
token-not-stale-gate	validation-governance	NONE	$TMP/fixture-test.sh	covered:not-yet-token	covered:negative-case-token	covered:invalid-case-token	none-by-design:This fixture gate deliberately exposes no waiver path.	Literal covered tokens are not scanned for deferred language.
EOF

pass current-manifest-passes bash "$CHECK"
pass current-manifest-includes-run-trace-waiver env EOS_SIM_COVERAGE_REQUIRED_GATES=run-trace-waiver bash "$CHECK"
pass single-fixture-manifest-passes env EOS_SIM_COVERAGE_REQUIRED_GATES=fixture-gate EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$good_manifest"
failcase missing-token-fails env EOS_SIM_COVERAGE_REQUIRED_GATES=fixture-gate EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$missing_token_manifest"
failcase malformed-row-fails env EOS_SIM_COVERAGE_REQUIRED_GATES=fixture-gate EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$malformed_manifest"
pass waiver-row-passes env EOS_SIM_COVERAGE_REQUIRED_GATES=waiver-gate EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$waiver_manifest"
failcase stale-coverage-language-fails env EOS_SIM_COVERAGE_REQUIRED_GATES=stale-gate EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$stale_manifest"
pass covered-token-with-stale-substring-passes env EOS_SIM_COVERAGE_REQUIRED_GATES=token-not-stale-gate EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$token_with_stale_substring_manifest"

# none-by-design token: valid reason passes, short reason fails, deferred language fails,
# and waived: cells describing design decisions are rejected.
nbd_short_manifest="$TMP/nbd-short.tsv"
cat > "$nbd_short_manifest" <<EOF
# gate_id	owner	enforcer	test_file	positive	negative	invalid	waiver	notes
nbd-gate	validation-governance	NONE	$TMP/fixture-test.sh	covered:positive-case-token	covered:negative-case-token	covered:invalid-case-token	none-by-design:too short	Fixture gate.
EOF
failcase none-by-design-short-reason-fails env EOS_SIM_COVERAGE_REQUIRED_GATES=nbd-gate EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$nbd_short_manifest"

nbd_stale_manifest="$TMP/nbd-stale.tsv"
cat > "$nbd_stale_manifest" <<EOF
# gate_id	owner	enforcer	test_file	positive	negative	invalid	waiver	notes
nbd-gate	validation-governance	NONE	$TMP/fixture-test.sh	covered:positive-case-token	covered:negative-case-token	covered:invalid-case-token	none-by-design:This gate has no waiver path and a fixture is pending for later.	Fixture gate.
EOF
failcase none-by-design-deferred-language-fails env EOS_SIM_COVERAGE_REQUIRED_GATES=nbd-gate EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$nbd_stale_manifest"

waived_design_manifest="$TMP/waived-design.tsv"
cat > "$waived_design_manifest" <<EOF
# gate_id	owner	enforcer	test_file	positive	negative	invalid	waiver	notes
design-gate	validation-governance	NONE	$TMP/fixture-test.sh	covered:positive-case-token	covered:negative-case-token	covered:invalid-case-token	waived:This gate is intentionally non-waivable by design in this fixture.	Fixture gate.
EOF
failcase waived-cell-with-design-wording-fails env EOS_SIM_COVERAGE_REQUIRED_GATES=design-gate EOS_SIM_COVERAGE_MIN_ROWS=1 bash "$CHECK" "$waived_design_manifest"

echo "simulation coverage validator tests passed"
