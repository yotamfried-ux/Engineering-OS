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
  grep -Eq "`?$status`?" "$POLICY" || fail "decision status missing: $status"
done

grep -q 'אל תשאל שוב' "$POLICY" || fail "ask-once prohibition is missing"
grep -q 'Plan Mode' "$POLICY" || fail "Plan Mode behavior is missing"
grep -q 'read-only' "$POLICY" || fail "read-only behavior is missing"
grep -q 'Cross-repo / unavailable workspace' "$POLICY" || fail "cross-repo handoff behavior is missing"
grep -q 'Checklist semantics' "$POLICY" || fail "open-checklist semantics are missing"
grep -q 'שינוי ניסוח, turn חדש, checklist פתוח' "$POLICY" || fail "non-material repeat triggers are not rejected"

grep -q $'04-cross-repo-decision-handoff\tmax_occurrences\tinteraction-log.md\t0||ask_user_question:project8-telemetry-execution-context' "$ORACLE" || fail "oracle does not reject the repeated Project 8 question"

mkdir -p "$TMP/pass/04-cross-repo-decision-handoff" "$TMP/fail/04-cross-repo-decision-handoff"
cat > "$TMP/pass/04-cross-repo-decision-handoff/route-plan.md" <<'PLAN'
decision_id: project8-telemetry-execution-context
status: deferred
next_action: open a fresh session inside project-8 and run telemetry preflight
PLAN
cat > "$TMP/pass/04-cross-repo-decision-handoff/interaction-log.md" <<'LOG'
decision_state:project8-telemetry-execution-context:deferred
LOG
python3 "$EVAL" --oracle "$ORACLE" --run-dir "$TMP/pass" >/tmp/user-decision-pass.out
grep -q '04-cross-repo-decision-handoff: at most 0 occurrence' /tmp/user-decision-pass.out || fail "positive fixture did not score the ask-once rule"

cp -R "$TMP/pass/04-cross-repo-decision-handoff/." "$TMP/fail/04-cross-repo-decision-handoff/"
printf '%s\n' 'ask_user_question:project8-telemetry-execution-context' >> "$TMP/fail/04-cross-repo-decision-handoff/interaction-log.md"
if python3 "$EVAL" --oracle "$ORACLE" --run-dir "$TMP/fail" >/tmp/user-decision-fail.out; then
  fail "repeated pre-answered decision unexpectedly passed"
fi
grep -q 'found 1' /tmp/user-decision-fail.out || fail "negative fixture did not report the repeated question"

echo "user decision persistence contract passed"
