#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-operational-behavior-evidence.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/operational-evidence.log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$LOG_FILE" 2>&1; then echo "unexpected pass: $name"; cat "$LOG_FILE"; exit 1; else echo "ok: $name"; fi; }

write_ok_body() {
  cat > "$1" <<'EOF'
## Operational Behavior Evidence

behavior_summary: Completed a scoped governance update and recorded how the agent behaved.
engineering_os_influence: Route Plan, audit, checker, review, and CI gates constrained scope and forced evidence before merge.
efficiency_signals: commands_run=12; test_runs=3; failed_test_runs=1; ci_runs=1; review_iterations=1.
friction_or_false_positives: One gate wording issue caused an avoidable correction loop; no Project 8 run was performed.
quality_signals: Negative fixture failed, positive fixture passed, and audit wording stayed aligned with source of truth.
usage_surrogate: exact_token_usage_available=no; wall_clock_minutes=unknown; tool_calls=surrogate-only.
next_system_improvement: Track repeated friction patterns and compare future Claude runs against this evidence.
EOF
}

pass checker_present test -f "$CHECK"

write_ok_body "$TMP/ok.md"
pass complete_operational_evidence_passes bash "$CHECK" --body "$TMP/ok.md"

cat > "$TMP/missing.md" <<'EOF'
## Summary

No operational section.
EOF
failcase missing_operational_section_fails bash "$CHECK" --body "$TMP/missing.md"

cat > "$TMP/partial.md" <<'EOF'
## Operational Behavior Evidence

behavior_summary: Only summary exists here.
engineering_os_influence: Route Plan affected the work.
usage_surrogate: exact_token_usage_available=no.
EOF
failcase partial_operational_evidence_fails bash "$CHECK" --body "$TMP/partial.md"

cat > "$TMP/no-exact.md" <<'EOF'
## Operational Behavior Evidence

behavior_summary: Completed a scoped governance update and recorded behavior.
engineering_os_influence: Route Plan, audit, checker, review, and CI gates constrained scope.
efficiency_signals: commands_run=12; test_runs=3; failed_test_runs=1.
friction_or_false_positives: One evidence wording issue required correction.
quality_signals: Negative fixture failed and positive fixture passed.
usage_surrogate: wall_clock_minutes=unknown; tool_calls=surrogate-only.
next_system_improvement: Track repeated friction patterns.
EOF
failcase usage_surrogate_must_state_exact_availability bash "$CHECK" --body "$TMP/no-exact.md"

echo "operational behavior evidence simulations passed"
