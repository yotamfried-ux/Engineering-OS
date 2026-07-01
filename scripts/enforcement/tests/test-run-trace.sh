#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
GATE="$ROOT/scripts/enforcement/enforce-run-trace.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/run-trace.log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$LOG_FILE" 2>&1; then echo "unexpected pass: $name"; cat "$LOG_FILE"; exit 1; else echo "ok: $name"; fi; }

setup_repo() {
  rm -rf "$TMP/repo"
  mkdir -p "$TMP/repo/.claude/plans" "$TMP/repo/scripts/enforcement" "$TMP/repo/docs/operations" "$TMP/repo/src"
  cd "$TMP/repo"
  git init >/dev/null
  git config user.email test@example.com
  git config user.name test
  echo '# target' > README.md
  git add README.md
  git commit -m baseline >/dev/null
}

write_plan_without_trace() {
  cat > .claude/plans/active.md <<'EOF'
# Route Plan

## Goal

Change connector enforcement.

## Plan

1. Modify enforcement.
2. Run tests.

## Alternatives

- Skip trace — rejected.

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Domain tags | connectors, enforcement |
| External systems/connectors | github, notion |

## Definition of Done

- [x] fixture
EOF
}

write_plan_partial_trace() {
  write_plan_without_trace
  cat >> .claude/plans/active.md <<'EOF'

## Claude Run Trace

- goal: validate connector enforcement.
- hypothesis: connector gate should block missing evidence.
EOF
}

write_plan_complete_trace() {
  write_plan_without_trace
  cat >> .claude/plans/active.md <<'EOF'

## Claude Run Trace

- goal: validate connector enforcement.
- hypothesis: missing connector evidence should block runtime writes.
- connectors: github, notion, context7, sentry, postman; runtime must include connector_used evidence and notion_progress_validated evidence.
- steps: create fixture plan, stage connector enforcement change, run gate.
- evidence: failing and passing gate outcomes are captured by this simulation.
- rejected: memory-only connector choice was rejected.
- result: connector enforcement passes only with full trace and evidence.
- follow-up: keep enforce-run-trace.sh wired into pre-commit.
EOF
}

write_plan_trace_waiver() {
  write_plan_without_trace
  cat >> .claude/plans/active.md <<'EOF'

## Run Trace Waiver

- reason: this fixture intentionally exercises the documented waiver branch for a connector enforcement change.
- scope: scripts/enforcement/check-required-connectors.sh in this temporary simulation repository.
- risk: low; this case verifies that explicit waivers remain visible rather than silently bypassing the gate.
EOF
}

stage_connector_change() {
  mkdir -p scripts/enforcement
  echo '# connector change' > scripts/enforcement/check-required-connectors.sh
  git add scripts/enforcement/check-required-connectors.sh
}

stage_non_trace_change() {
  echo 'plain docs' > NOTE.md
  git add NOTE.md
}

stage_trace_doc() {
  local include_contract="$1"
  mkdir -p docs/operations
  cat > docs/operations/claude-run-trace.md <<'EOF'
# Claude Run Trace

## When to record a trace

Record enforcement and connector simulations.

## Where traces live

Use plans, tasks, lessons, failed-solutions, and operations docs.

## Required fields

Trace must include goal, hypothesis, connectors, steps, evidence, rejected attempts, result, and follow-up.

## Notion progress validation

Notion progress requires notion_progress_validated evidence.

## Relationship to learning

A run trace does not replace a lesson.
EOF
  if [ "$include_contract" = "yes" ]; then
    cat >> docs/operations/claude-run-trace.md <<'EOF'

## Enforcement contract

Connector and enforcement changes require a Claude Run Trace in the active Route Plan.
EOF
  fi
  git add docs/operations/claude-run-trace.md
}

run_gate() { (cd "$TMP/repo" && bash "$GATE"); }

pass gate_present test -f "$GATE"

setup_repo
write_plan_without_trace
stage_connector_change
failcase connector_change_requires_run_trace run_gate

setup_repo
write_plan_partial_trace
stage_connector_change
failcase incomplete_trace_blocks_connector_change run_gate

setup_repo
write_plan_complete_trace
stage_connector_change
pass complete_connector_trace_allows_change run_gate

setup_repo
write_plan_trace_waiver
stage_connector_change
pass focused_run_trace_waiver_allows_connector_change run_gate

setup_repo
stage_non_trace_change
pass unrelated_doc_change_does_not_require_trace run_gate

setup_repo
write_plan_complete_trace
stage_trace_doc no
failcase trace_doc_requires_enforcement_contract_section run_gate

setup_repo
write_plan_complete_trace
stage_trace_doc yes
pass trace_doc_with_contract_section_passes run_gate

echo "run trace simulations passed"
