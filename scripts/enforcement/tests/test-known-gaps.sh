#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-known-gaps.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
ok(){ local n="$1"; shift; "$@" >"$TMP/$n.out" 2>&1 || { echo "fail: $n"; cat "$TMP/$n.out"; exit 1; }; echo "ok: $n"; }
no(){ local n="$1"; shift; if "$@" >"$TMP/$n.out" 2>&1; then echo "unexpected pass: $n"; cat "$TMP/$n.out"; exit 1; else echo "ok: $n"; fi; }
cat > "$TMP/test.sh" <<'EOF'
current_known_gaps_pass
missing_field_fails
duplicate_gap_fails
accepted_manual_passes
EOF
cat > "$TMP/good.tsv" <<EOF
fixture-gap	owner-one	open	P1	Risk description is long enough.	Mitigation description is long enough.	$TMP/test.sh	Closure description is long enough.	NONE	Notes.
EOF
cat > "$TMP/missing.tsv" <<EOF
fixture-gap	owner-one	open	P1	Risk description is long enough.		$TMP/test.sh	Closure description is long enough.	NONE	Notes.
EOF
cat > "$TMP/dup.tsv" <<EOF
fixture-gap	owner-one	open	P1	Risk description is long enough.	Mitigation description is long enough.	$TMP/test.sh	Closure description is long enough.	NONE	Notes.
fixture-gap	owner-two	open	P2	Risk description is long enough.	Mitigation description is long enough.	$TMP/test.sh	Closure description is long enough.	NONE	Notes.
EOF
cat > "$TMP/manual.tsv" <<EOF
manual-gap	owner-one	accepted-manual	P3	Risk description is long enough.	Mitigation description is long enough.	NONE	Closure description is long enough.	NONE	accepted_manual_passes
EOF
ok current_known_gaps_pass bash "$CHECK"
ok good_fixture_passes env EOS_KNOWN_GAPS_MIN_ROWS=1 bash "$CHECK" "$TMP/good.tsv"
no missing_field_fails env EOS_KNOWN_GAPS_MIN_ROWS=1 bash "$CHECK" "$TMP/missing.tsv"
no duplicate_gap_fails env EOS_KNOWN_GAPS_MIN_ROWS=1 bash "$CHECK" "$TMP/dup.tsv"
ok accepted_manual_passes env EOS_KNOWN_GAPS_MIN_ROWS=1 bash "$CHECK" "$TMP/manual.tsv"
