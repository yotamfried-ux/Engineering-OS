#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-readiness-audit.sh"
chmod +x "$CHECK"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

ok(){ local n="$1"; shift; "$@" >"$TMP/$n.out" 2>&1 || { echo "fail: $n"; cat "$TMP/$n.out"; exit 1; }; echo "ok: $n"; }
no(){ local n="$1"; shift; if "$@" >"$TMP/$n.out" 2>&1; then echo "unexpected pass: $n"; cat "$TMP/$n.out"; exit 1; else echo "ok: $n"; fi; }

# write_audit <out-file> <matrix rows...> — context-free fixture audit.
write_audit(){
  local out="$1"; shift
  {
    cat <<'HEAD'
# Fixture Audit

## Audit metadata

- **Audit owner:** fixture-owner
- **Canonical repository:** fixture/repository
- **Target repository:** fixture/target
- **Canonical gap registry:** docs/operations/known-gaps.tsv
- **Last verified:** 2026-07-22
- **Intended readers:** LLMs, operators, and reviewers

## Purpose and audience

This fixture is independently usable without prior chat context.

## System and repository context

Engineering OS is the governance system; Project 8 is the target repository.

## Non-negotiable decisions

Do not guess, weaken tests, expose secrets, merge, deploy, or start an experiment without the required evidence and approval.

## How an LLM must use this audit

1. Verify live state and do not guess.
2. Select one registered gap and follow its checklist.
3. Work through a pull request, run tests, and require owner approval.

## Source-of-truth hierarchy

1. Live GitHub state.
2. Repository code.
3. `known-gaps.tsv`.
4. `operational-readiness-audit.md`.
5. Runbooks.
6. Plans.
7. Chat is not a durable source.

## Evidence and closure standard

Closure requires the exact repository and path, commit SHA, positive and negative tests, installed target behavior, review evidence, merge and post-merge validation, and secret-safe artifacts.

## Glossary

- Engineering OS — governance framework.
- Project 8 — target repository.
- Behavioral experiment — future product workload.
- Technical qualification session — bounded non-product validation.
- Operational Work History — CI-generated PR evidence.
- Telemetry bundle — validated metadata files.
- Exact-head — evidence for the current commit.
- Hard hook — fail-closed action gate.
- Full operational readiness — every registered gap is closed.

## Readiness statuses

- **Enforced** — deterministic gate.
- **Partially enforced** — deterministic subset with a linked gap.
- **Manual** — vocabulary term only.
- **Manual by design** — checklist plus required review evidence.
- **Waiver-gated** — explicit waiver evidence required.
- **Missing enforcement** — silently skippable, must link a gap.
- **Not applicable** — no enforcement expected.

## Coverage contract

Every incomplete row links a registered gap.

## Readiness-claim contract

Audit completeness does not equal full readiness.

## Known gaps freshness ledger

Fixture ledger is supplied by the TSV fixture.

## Current status matrix

| Area | Status | What is enforced or checked | Remaining gap |
|---|---|---|---|
HEAD
    printf '%s\n' "$@"
    cat <<'TAIL'

## Dependency-ordered closure plan

Close audit integrity, enforcement, target isolation, and technical qualification before the behavioral experiment.

## Definition of full operational readiness

Every registered gap must be closed and every blocking row must be enforced.

## Mandatory end-to-end closure checklists

Each gap requires implementation, positive and negative tests, exact-head review, merge, and post-merge evidence.

## Highest-priority gaps by ROI

Fixture priority list.

## Experiment start decision

The behavioral experiment is blocked until every registered gap is closed, `--assert-full-ready` passes, technical qualification is complete, and owner approval is recorded.

## Future Project 8 workload acceptance contract

The future workload validates Supabase, Vercel, existing features, UI/UX, and end-to-end behavior; it is not a pre-start gap.

## Current audit scope

Fixture scope.
TAIL
  } > "$out"
}

cat > "$TMP/gaps-open.tsv" <<'EOF'
# gap_id	owner	status	priority
fixture-open	owner-one	open	P2
EOF
cat > "$TMP/gaps-accepted-manual.tsv" <<'EOF'
# gap_id	owner	status	priority
fixture-manual	owner-one	accepted-manual	P2
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

write_audit "$TMP/accepted-manual-linked.md" \
  '| Fixture area | Manual by design | Gate: fixture. Owner: fixture. Evidence: Checklist: docs/operations/memory-context-checklist.md review evidence. | gap:fixture-manual is accepted as manual but still tracked. |'
ok accepted_manual_gap_referenced_by_matrix_passes "${FIX_ENV[@]}" bash "$CHECK" "$TMP/accepted-manual-linked.md" "$TMP/gaps-accepted-manual.tsv"

write_audit "$TMP/full-ready.md" \
  '| Fixture area | Enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | fully covered. |'
ok full_ready_closed_fixture_passes "${FIX_ENV[@]}" bash "$CHECK" --assert-full-ready "$TMP/full-ready.md" "$TMP/gaps-closed.tsv"

no full_ready_open_gap_fails "${FIX_ENV[@]}" bash "$CHECK" --assert-full-ready "$TMP/good-partial.md" "$TMP/gaps-open.tsv"
no full_ready_accepted_manual_gap_fails "${FIX_ENV[@]}" bash "$CHECK" --assert-full-ready "$TMP/accepted-manual-linked.md" "$TMP/gaps-accepted-manual.tsv"

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

write_audit "$TMP/hidden-accepted-manual-gap.md" \
  '| Fixture area | Enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | fully covered. |'
no unreferenced_accepted_manual_gap_fails "${FIX_ENV[@]}" bash "$CHECK" "$TMP/hidden-accepted-manual-gap.md" "$TMP/gaps-accepted-manual.tsv"

write_audit "$TMP/no-mbd-def.md" \
  '| Fixture area | Enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | fully covered. |'
sed -i '/\*\*Manual by design\*\*/d' "$TMP/no-mbd-def.md"
no missing_manual_by_design_definition_fails "${FIX_ENV[@]}" bash "$CHECK" "$TMP/no-mbd-def.md" "$TMP/gaps-empty.tsv"

write_audit "$TMP/no-purpose.md" \
  '| Fixture area | Enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | fully covered. |'
sed -i '/^## Purpose and audience$/d' "$TMP/no-purpose.md"
no missing_self_contained_heading_fails "${FIX_ENV[@]}" bash "$CHECK" "$TMP/no-purpose.md" "$TMP/gaps-empty.tsv"

write_audit "$TMP/no-glossary-term.md" \
  '| Fixture area | Enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | fully covered. |'
sed -i '/^- Hard hook /d' "$TMP/no-glossary-term.md"
no missing_glossary_term_fails "${FIX_ENV[@]}" bash "$CHECK" "$TMP/no-glossary-term.md" "$TMP/gaps-empty.tsv"

write_audit "$TMP/bad-experiment-rule.md" \
  '| Fixture area | Enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | fully covered. |'
sed -i 's/every registered gap is closed/every important item is reviewed/' "$TMP/bad-experiment-rule.md"
no incomplete_experiment_start_rule_fails "${FIX_ENV[@]}" bash "$CHECK" "$TMP/bad-experiment-rule.md" "$TMP/gaps-empty.tsv"

write_audit "$TMP/too-few-rows.md" \
  '| Fixture area | Enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | fully covered. |'
no too_few_rows_fails env EOS_READINESS_MIN_ROWS=2 EOS_READINESS_REQUIRE_TERMS=0 bash "$CHECK" "$TMP/too-few-rows.md" "$TMP/gaps-empty.tsv"

write_audit "$TMP/missing-term.md" \
  '| Fixture area | Enforced | Gate: fixture. Owner: fixture. Evidence: fixture. | fully covered. |'
no missing_required_row_fails env EOS_READINESS_MIN_ROWS=1 bash "$CHECK" "$TMP/missing-term.md" "$TMP/gaps-empty.tsv"

echo "readiness audit tests passed"
