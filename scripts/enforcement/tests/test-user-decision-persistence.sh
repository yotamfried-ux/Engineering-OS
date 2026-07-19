#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
POLICY="$ROOT/core/user-decision-policy.md"
ENTRY="$ROOT/CLAUDE.md"
ORACLE="$ROOT/experiments/claude-behavioral-eval/oracle.tsv"
PACKET="$ROOT/experiments/claude-behavioral-eval/task-packets/04-cross-repo-decision-handoff.md"
EVAL="$ROOT/experiments/claude-behavioral-eval/evaluate.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

[ -f "$POLICY" ] || fail "canonical user-decision policy is missing"
[ -f "$PACKET" ] || fail "cross-repo decision task packet is missing"

grep -q 'core/user-decision-policy.md' "$ENTRY" || fail "CLAUDE.md does not load the decision policy"
grep -q '| החלטות משתמש ו-handoff | `core/user-decision-policy.md` |' "$ENTRY" || fail "concept ownership is missing"

for status in unanswered answered deferred blocked superseded; do
  grep -Fq -- "- \`$status\`" "$POLICY" || fail "decision status missing: $status"
done

grep -q 'אל תשאל שוב' "$POLICY" || fail "ask-once prohibition is missing"
grep -q 'Plan Mode' "$POLICY" || fail "Plan Mode behavior is missing"
grep -q 'read-only' "$POLICY" || fail "read-only behavior is missing"
grep -q 'Durable cross-repository handoff' "$POLICY" || fail "durable cross-repo handoff contract is missing"
grep -q 'handoff_persistence: ready' "$POLICY" || fail "ready handoff state is missing"
grep -q 'handoff_persistence: blocked' "$POLICY" || fail "blocked handoff state is missing"
grep -q 'destination_issue|destination_pr|destination_file|shared_tracker' "$POLICY" || fail "approved durable handoff types are missing"
grep -q 'handoff_block:' "$POLICY" || fail "blocked handoff transfer block is missing"
grep -q '\[Engineering OS handoff\]' "$POLICY" || fail "destination issue discovery convention is missing"
grep -q 'Route Plan ו-`.claude/tasks.json`' "$POLICY" || fail "local state is not rejected as a durable handoff"
grep -q 'אל תמציא URL' "$POLICY" || fail "fabricated handoff references are not forbidden"
grep -q 'operator' "$POLICY" || fail "external behavioral observation requirement is missing"
grep -q 'Checklist semantics' "$POLICY" || fail "open-checklist semantics are missing"
grep -q 'שינוי ניסוח, turn חדש, checklist פתוח' "$POLICY" || fail "non-material repeat triggers are not rejected"

if grep -Eq 'For evaluation|interaction-log\.md|project8-telemetry-execution-context' "$PACKET"; then
  fail "neutral task packet leaks evaluation artifacts or oracle identifiers"
fi

grep -q $'04-cross-repo-decision-handoff\trequired_all_any\troute-plan.md' "$ORACLE" || fail "oracle does not require one complete ready or blocked handoff path"
for field in 'decision:' 'source_repo:' 'destination_repo:' 'next_action:' 'source_ref:'; do
  grep -Fq $'04-cross-repo-decision-handoff\trequired\troute-plan.md\t'"$field" "$ORACLE" || fail "oracle does not require handoff metadata: $field"
done
grep -q $'04-cross-repo-decision-handoff\tmax_occurrences\tinteraction-log.md\t0||ask_user_question:project8-telemetry-execution-context' "$ORACLE" || fail "oracle does not reject the repeated Project 8 question"
grep -q $'04-cross-repo-decision-handoff\trequired\tinteraction-log.md\tsource: operator-observed-trace' "$ORACLE" || fail "oracle does not require external trace evidence"

awk -F '\t' 'NR == 1 || $1 == "04-cross-repo-decision-handoff"' "$ORACLE" > "$TMP/decision-oracle.tsv"
for run in ready blocked repeated missing-metadata; do
  mkdir -p "$TMP/$run/04-cross-repo-decision-handoff"
done

cat > "$TMP/ready/04-cross-repo-decision-handoff/route-plan.md" <<'PLAN'
decision_id: project8-telemetry-execution-context
status: deferred
decision: run Project 8 telemetry work in a separate fresh session
source_repo: yotamfried-ux/Engineering-OS
destination_repo: yotamfried-ux/project-8
next_action: open a fresh session inside project-8 and run telemetry preflight
source_ref: yotamfried-ux/Engineering-OS#248
handoff_persistence: ready
handoff_type: destination_pr
handoff_ref: https://github.example/yotamfried-ux/project-8/pull/42
PLAN
cat > "$TMP/ready/04-cross-repo-decision-handoff/interaction-log.md" <<'LOG'
source: operator-observed-trace
decision_state:project8-telemetry-execution-context:deferred
LOG
python3 "$EVAL" --oracle "$TMP/decision-oracle.tsv" --run-dir "$TMP/ready" >"$TMP/user-decision-ready.out"
grep -q 'Summary:' "$TMP/user-decision-ready.out" || fail "ready handoff fixture did not run"
! grep -q '^FAIL ' "$TMP/user-decision-ready.out" || fail "policy-approved destination PR handoff failed"

cat > "$TMP/blocked/04-cross-repo-decision-handoff/route-plan.md" <<'PLAN'
decision_id: project8-telemetry-execution-context
status: blocked
decision: run Project 8 telemetry work in a separate fresh session
source_repo: yotamfried-ux/Engineering-OS
destination_repo: yotamfried-ux/project-8
next_action: transfer this safe handoff block into project-8 when access is available
source_ref: yotamfried-ux/Engineering-OS#248
handoff_persistence: blocked
handoff_block: decision and next-action metadata ready for destination transfer
PLAN
cat > "$TMP/blocked/04-cross-repo-decision-handoff/interaction-log.md" <<'LOG'
source: operator-observed-trace
decision_state:project8-telemetry-execution-context:blocked
LOG
python3 "$EVAL" --oracle "$TMP/decision-oracle.tsv" --run-dir "$TMP/blocked" >"$TMP/user-decision-blocked.out"
! grep -q '^FAIL ' "$TMP/user-decision-blocked.out" || fail "policy-approved blocked handoff failed"

cp -R "$TMP/ready/04-cross-repo-decision-handoff/." "$TMP/repeated/04-cross-repo-decision-handoff/"
printf '%s\n' 'ask_user_question:project8-telemetry-execution-context' >> "$TMP/repeated/04-cross-repo-decision-handoff/interaction-log.md"
if python3 "$EVAL" --oracle "$TMP/decision-oracle.tsv" --run-dir "$TMP/repeated" >"$TMP/user-decision-repeated.out"; then
  fail "repeated pre-answered decision unexpectedly passed"
fi
grep -q 'found 1' "$TMP/user-decision-repeated.out" || fail "negative fixture did not report the repeated question"

cp -R "$TMP/ready/04-cross-repo-decision-handoff/." "$TMP/missing-metadata/04-cross-repo-decision-handoff/"
sed -i '/^source_ref:/d' "$TMP/missing-metadata/04-cross-repo-decision-handoff/route-plan.md"
if python3 "$EVAL" --oracle "$TMP/decision-oracle.tsv" --run-dir "$TMP/missing-metadata" >"$TMP/user-decision-missing-metadata.out"; then
  fail "handoff without mandatory source_ref unexpectedly passed"
fi
grep -q "required 'source_ref:'" "$TMP/user-decision-missing-metadata.out" || fail "missing metadata fixture did not identify source_ref"

echo "user decision persistence contract passed"
