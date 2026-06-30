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
audit_missing_gap_fails
audit_status_mismatch_fails
audit_extra_gap_fails
EOF

cat > "$TMP/good.tsv" <<EOF
fixture-gap	owner-one	open	P1	Risk description is long enough.	Mitigation description is long enough.	$TMP/test.sh	Closure description is long enough.	NONE	Notes.
EOF
cat > "$TMP/good-audit.md" <<'EOF'
# Audit

## Known gaps freshness ledger

| gap_id | status | priority | audit row / readiness context |
|---|---|---|---|
| fixture-gap | open | P1 | Fixture gap remains open. |
EOF
cat > "$TMP/missing-audit.md" <<'EOF'
# Audit

## Known gaps freshness ledger

| gap_id | status | priority | audit row / readiness context |
|---|---|---|---|
EOF
cat > "$TMP/mismatch-audit.md" <<'EOF'
# Audit

## Known gaps freshness ledger

| gap_id | status | priority | audit row / readiness context |
|---|---|---|---|
| fixture-gap | closed | P1 | Incorrect stale closure. |
EOF
cat > "$TMP/extra-audit.md" <<'EOF'
# Audit

## Known gaps freshness ledger

| gap_id | status | priority | audit row / readiness context |
|---|---|---|---|
| fixture-gap | open | P1 | Fixture gap remains open. |
| unknown-gap | open | P2 | Not in known-gaps. |
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
cat > "$TMP/manual-audit.md" <<'EOF'
# Audit

## Known gaps freshness ledger

| gap_id | status | priority | audit row / readiness context |
|---|---|---|---|
| manual-gap | accepted-manual | P3 | Manual gap accepted. |
EOF

ok current_known_gaps_pass bash "$CHECK"
ok good_fixture_passes env EOS_KNOWN_GAPS_MIN_ROWS=1 bash "$CHECK" "$TMP/good.tsv" "$TMP/good-audit.md"
no audit_missing_gap_fails env EOS_KNOWN_GAPS_MIN_ROWS=1 bash "$CHECK" "$TMP/good.tsv" "$TMP/missing-audit.md"
no audit_status_mismatch_fails env EOS_KNOWN_GAPS_MIN_ROWS=1 bash "$CHECK" "$TMP/good.tsv" "$TMP/mismatch-audit.md"
no audit_extra_gap_fails env EOS_KNOWN_GAPS_MIN_ROWS=1 bash "$CHECK" "$TMP/good.tsv" "$TMP/extra-audit.md"
no missing_field_fails env EOS_KNOWN_GAPS_MIN_ROWS=1 EOS_SKIP_AUDIT_FRESHNESS=1 bash "$CHECK" "$TMP/missing.tsv"
no duplicate_gap_fails env EOS_KNOWN_GAPS_MIN_ROWS=1 EOS_SKIP_AUDIT_FRESHNESS=1 bash "$CHECK" "$TMP/dup.tsv"
ok accepted_manual_passes env EOS_KNOWN_GAPS_MIN_ROWS=1 bash "$CHECK" "$TMP/manual.tsv" "$TMP/manual-audit.md"

echo "known gaps tests passed"
