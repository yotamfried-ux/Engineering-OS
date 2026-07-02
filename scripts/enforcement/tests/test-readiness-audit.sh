#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-readiness-audit.sh"
chmod +x "$CHECK"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

ok(){ local n="$1"; shift; "$@" >"$TMP/$n.out" 2>&1 || { echo "fail: $n"; cat "$TMP/$n.out"; exit 1; }; echo "ok: $n"; }
no(){ local n="$1"; shift; if "$@" >"$TMP/$n.out" 2>&1; then echo "unexpected pass: $n"; cat "$TMP/$n.out"; exit 1; else echo "ok: $n"; fi; }

# write_audit <out-file> <matrix rows...>  — fixture audit with all required headings
# and status definitions; matrix rows are passed one per argument.
write_audit(){
  local out="$1"; shift
  {
    cat <<'HEAD'
# Fixture Audit

## Readiness statuses

- **Enforced** — deterministic gate.
- **Partially enforced** — deterministic subset with a linked gap.
- **Manual** — vocabulary term only.
- **Manual by design** — checklist plus required review evidence.
- **Waiver-gated** — explicit waiver evidence required.
- **Missing enforcement** — silently skippable, must link a gap.
- **Not applicable** — no enforcement expected.

## Coverage contract

Fixture coverage contract.

## Current status matrix

| Area | Status | What is enforced or checked | Remaining gap |
|---|---|---|---|
HEAD
    printf '%s\n' "$@"
    cat <<'TAIL'

## Definition of full operational readiness

Fixture definition of readiness.

## Highest-priority gaps by ROI

Fixture priority list.
TAIL
  } > "$out"
}

cat > "$TMP/gaps-open.tsv" <<'EOF'
# gap_id	owner	status	priority
fixture-open	owner-one	open	P2
EOF
cat > "$TMP/gaps-closed.tsv" <<'EOF'
# gap_id	owner	status	priority
fixture-closed	owner-one	closed	P2
EOF
cat > "$TMP/gaps-empty.tsv" <<'EOF'
# gap_id	owner	status	priority
EOF

FIX_ENV=(env EOS_READINESS_MIN_ROWS=1 EOS_READINESS_REQUIRE_TERMS=0)

# positive: the real repository audit passes with full defaults.
ok current_audit_passes bash "$CHECK"

write_audit "$TMP/good-partial.md" \
  '| Fixture area | Partially enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | gap:fixture-open tracks the residual. |'
ok partial_with_open_gap_passes "${FIX_ENV[@]}" bash "$CHECK" "$TMP/good-partial.md" "$TMP/gaps-open.tsv"

write_audit "$TMP/bad-partial.md" \
  '| Fixture area | Partially enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | residual text with no link. |'
no partial_without_gap_link_fails "${FIX_ENV[@]}" bash "$CHECK" "$TMP/bad-partial.md" "$TMP/gaps-empty.tsv"

write_audit "$TMP/closed-link.md" \
  '| Fixture area | Partially enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | gap:fixture-closed is already closed. |'
no gap_link_to_closed_gap_fails "${FIX_ENV[@]}" bash "$CHECK" "$TMP/closed-link.md" "$TMP/gaps-closed.tsv"

write_audit "$TMP/unknown-link.md" \
  '| Fixture area | Partially enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | gap:no-such-gap is unknown. |'
no gap_link_to_unknown_gap_fails "${FIX_ENV[@]}" bash "$CHECK" "$TMP/unknown-link.md" "$TMP/gaps-empty.tsv"

write_audit "$TMP/plain-manual.md" \
  '| Fixture area | Manual | Gate: fixture. Owner: fixture. Evidence: fixture. | manual row with no classification. |'
no plain_manual_status_fails "${FIX_ENV[@]}" bash "$CHECK" "$TMP/plain-manual.md" "$TMP/gaps-empty.tsv"

write_audit "$TMP/mbd-no-checklist.md" \
  '| Fixture area | Manual by design | Gate: fixture. Owner: fixture. Evidence: manual review only. | human by design. |'
no manual_by_design_without_checklist_fails "${FIX_ENV[@]}" bash "$CHECK" "$TMP/mbd-no-checklist.md" "$TMP/gaps-empty.tsv"

write_audit "$TMP/mbd-checklist.md" \
  '| Fixture area | Manual by design | Gate: fixture. Owner: fixture. Evidence: Checklist: docs/operations/memory-context-checklist.md review evidence. | human by design. |'
ok manual_by_design_with_checklist_passes "${FIX_ENV[@]}" bash "$CHECK" "$TMP/mbd-checklist.md" "$TMP/gaps-empty.tsv"

write_audit "$TMP/mbd-missing-doc.md" \
  '| Fixture area | Manual by design | Gate: fixture. Owner: fixture. Evidence: Checklist: docs/operations/no-such-checklist.md review evidence. | human by design. |'
no manual_by_design_missing_doc_fails "${FIX_ENV[@]}" bash "$CHECK" "$TMP/mbd-missing-doc.md" "$TMP/gaps-empty.tsv"

write_audit "$TMP/deferred.md" \
  '| Fixture area | Enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | hardening is not yet finished here. |'
no deferred_token_without_gap_fails "${FIX_ENV[@]}" bash "$CHECK" "$TMP/deferred.md" "$TMP/gaps-empty.tsv"

write_audit "$TMP/hidden-gap.md" \
  '| Fixture area | Enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | fully covered. |'
no unreferenced_open_gap_fails "${FIX_ENV[@]}" bash "$CHECK" "$TMP/hidden-gap.md" "$TMP/gaps-open.tsv"

write_audit "$TMP/no-mbd-def.md" \
  '| Fixture area | Enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | fully covered. |'
sed -i '/\*\*Manual by design\*\*/d' "$TMP/no-mbd-def.md"
no missing_manual_by_design_definition_fails "${FIX_ENV[@]}" bash "$CHECK" "$TMP/no-mbd-def.md" "$TMP/gaps-empty.tsv"

write_audit "$TMP/too-few-rows.md" \
  '| Fixture area | Enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | fully covered. |'
no too_few_rows_fails env EOS_READINESS_MIN_ROWS=2 EOS_READINESS_REQUIRE_TERMS=0 bash "$CHECK" "$TMP/too-few-rows.md" "$TMP/gaps-empty.tsv"

write_audit "$TMP/missing-term.md" \
  '| Fixture area | Enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | fully covered. |'
no missing_required_row_fails env EOS_READINESS_MIN_ROWS=1 bash "$CHECK" "$TMP/missing-term.md" "$TMP/gaps-empty.tsv"

echo "readiness audit tests passed"
