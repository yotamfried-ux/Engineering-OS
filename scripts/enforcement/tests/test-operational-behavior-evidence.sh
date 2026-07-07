#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-operational-behavior-evidence.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/operational-evidence.log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$LOG_FILE" 2>&1; then echo "unexpected pass: $name"; cat "$LOG_FILE"; exit 1; else echo "ok: $name"; fi; }

pass checker_present test -f "$CHECK"

cat > "$TMP/ok.md" <<'EOF'
## Operational Behavior Evidence

behavior_summary: Recorded the run behavior for this scoped change.
engineering_os_influence: Route Plan, audit, checker, review, and CI gates constrained the work.
efficiency_signals: commands_run=12; test_runs=3; failed_test_runs=1.
friction_or_false_positives: One evidence wording issue required correction.
quality_signals: Positive and negative fixtures cover the policy.
usage_surrogate: exact_token_usage_available=no; wall_clock_minutes=unknown; tool_calls=fixture.
next_system_improvement: Track repeated friction patterns.
EOF
pass complete_operational_evidence_passes bash "$CHECK" --body "$TMP/ok.md"

cat > "$TMP/missing.md" <<'EOF'
## Summary

No operational section.
EOF
EOS_DISABLE_PLAN_FALLBACK=1 failcase missing_operational_section_fails bash "$CHECK" --body "$TMP/missing.md"

cat > "$TMP/partial.md" <<'EOF'
## Operational Behavior Evidence

behavior_summary: Only summary exists here.
engineering_os_influence: Route Plan affected the work.
usage_surrogate: exact_token_usage_available=no.
EOF
EOS_DISABLE_PLAN_FALLBACK=1 failcase partial_operational_evidence_fails bash "$CHECK" --body "$TMP/partial.md"

echo "operational behavior evidence simulations passed"
