#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-runtime-evidence.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
mkdir -p .claude/plans .claude/.evidence
export EOS_EVIDENCE_DIR=".claude/.evidence"
: > .claude/.evidence/ledger

expect_pass() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "ok: $name"
  else
    echo "fail: expected pass: $name"
    "$@"
    exit 1
  fi
}

expect_fail() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "fail: expected failure: $name"
    exit 1
  fi
  echo "ok: $name"
}

write_plan() {
  local path="$1"
  local connector="$2"
  local evidence_text="${3:-}"
  cat > "$path" <<PLAN
# Runtime plan fixture

| Field | Value |
|---|---|
| External systems/connectors | $connector |
| Skills | not required |

## Connector Evidence

$evidence_text
PLAN
}

write_plan .claude/plans/stale.md GitHub '- GitHub: required by an old unrelated task.'
expect_pass stale_historical_plan_is_ignored_without_session_selection bash "$CHECK"

printf '0\truntime_active_plan\t.claude/plans/stale.md\n' > .claude/.evidence/ledger
expect_fail selected_plan_missing_connector_evidence_is_blocked bash "$CHECK"

printf '0\tconnector_used\tgithub\n' >> .claude/.evidence/ledger
expect_pass selected_plan_with_connector_evidence_passes bash "$CHECK"

write_plan .claude/plans/waived.md GitHub '- GitHub: waived — current task is local-only and does not require external state.'
printf '0\truntime_active_plan\t.claude/plans/waived.md\n' > .claude/.evidence/ledger
expect_pass documented_connector_waiver_passes bash "$CHECK"

write_plan .claude/plans/explicit.md GitHub '- GitHub: required for this explicit current task.'
: > .claude/.evidence/ledger
expect_fail explicit_active_plan_still_enforces_missing_evidence env EOS_ACTIVE_PLAN=.claude/plans/explicit.md bash "$CHECK"
printf '0\tconnector_used\tgithub\n' >> .claude/.evidence/ledger
expect_pass explicit_active_plan_with_evidence_passes env EOS_ACTIVE_PLAN=.claude/plans/explicit.md bash "$CHECK"

expect_fail invalid_explicit_active_plan_fails_closed env EOS_ACTIVE_PLAN=.claude/plans/missing.md bash "$CHECK"

echo "Stop runtime plan scoping tests passed"
