#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
GATE="$ROOT/scripts/enforcement/enforce-learning-capture.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/learning-capture.log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$LOG_FILE" 2>&1; then echo "unexpected pass: $name"; cat "$LOG_FILE"; exit 1; else echo "ok: $name"; fi; }

setup_repo() {
  rm -rf "$TMP/repo"
  mkdir -p "$TMP/repo/.claude/plans" "$TMP/repo/src/payments" "$TMP/repo/lessons-learned/bugs" "$TMP/repo/failed-solutions"
  cd "$TMP/repo"
  git init >/dev/null
  git config user.email test@example.com
  git config user.name test
  echo 'baseline' > README.md
  git add README.md
  git commit -m baseline >/dev/null
}

write_plan() {
  local task_class="$1" tags="$2" waiver="${3:-}"
  cat > .claude/plans/active.md <<EOF
# Route Plan

## Goal

Fixture goal.

## Plan

1. Change implementation.
2. Capture learning when required.

## Alternatives

- Skip learning — rejected when this is bug/debug work.

| Field | Decision |
|---|---|
| Task class | $task_class |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | $tags |
| Templates | not required |
| Patterns | none |
| External systems/connectors | none |
| Skills | superpowers |

## Source of Truth Checks

| Source | Status |
|---|---|
| fixture | checked |

## Definition of Done

- [x] fixture complete
EOF
  if [ -n "$waiver" ]; then
    cat >> .claude/plans/active.md <<EOF

## Learning Capture Waiver

$waiver
EOF
  fi
}

stage_code() {
  mkdir -p src/payments
  printf 'export const value = %s;\n' "${1:-1}" > src/payments/webhook.ts
  git add src/payments/webhook.ts
}

stage_doc_only() {
  echo 'docs only' > NOTE.md
  git add NOTE.md
}

stage_incomplete_lesson() {
  cat > lessons-learned/bugs/payment-placeholder.md <<'EOF'
# Placeholder

TODO
EOF
  git add lessons-learned/bugs/payment-placeholder.md
}

stage_valid_lesson() {
  cat > lessons-learned/bugs/payment-regression.md <<'EOF'
# Payment regression lesson

## מה קרה
Webhook regression occurred.

## שורש הבעיה
The bug root cause was verified by a failing test.

## השערות שנבדקו
- Timeout hypothesis — rejected by logs.
- Raw body mutation — verified by regression test.

## ראיה
Regression test failed before the fix and passed after the fix.

## רמת ביטחון
Medium

## איך מזהים מוקדם
Run the webhook regression before payment changes.

## איך מונעים בעתיד
Keep the regression test and read this lesson before touching the webhook.

## טסט רגרסיה
scripts/enforcement/tests/test-learning-capture.sh

## סטטוס הבשלה
Verified Lesson

## Prevented Future Issues: 0

## Prevention/Enforcement Update
Added or kept a regression/enforcement check that prevents this class of issue.
EOF
  git add lessons-learned/bugs/payment-regression.md
}

stage_failed_solution() {
  cat > failed-solutions/payment-timeout.md <<'EOF'
# Failed solution: increase timeout

## מה ניסיתי
Increased the webhook timeout.

## למה לא עבד
The root cause was raw body mutation, not latency.

## מה לבדוק במקום
Verify the raw body before parsing.
EOF
  git add failed-solutions/payment-timeout.md
}

run_gate() { (cd "$TMP/repo" && bash "$GATE"); }

pass gate_file_present test -f "$GATE"

setup_repo
write_plan bug_fix "payments, webhooks"
stage_code 1
failcase bug_fix_requires_full_lesson run_gate

setup_repo
write_plan bug_fix "payments, webhooks"
stage_code 11
stage_incomplete_lesson
failcase placeholder_lesson_does_not_satisfy_capture run_gate

setup_repo
write_plan debugging "payments, webhooks"
stage_code 2
stage_valid_lesson
pass debugging_allows_staged_lesson run_gate

setup_repo
write_plan incident "payments, webhooks"
stage_code 3
stage_failed_solution
failcase failed_solution_alone_does_not_satisfy_bug_capture run_gate

setup_repo
write_plan incident "payments, webhooks"
stage_code 33
stage_failed_solution
stage_valid_lesson
pass incident_allows_failed_solution_plus_lesson run_gate

setup_repo
write_plan bug_fix "payments, webhooks" "This was a trivial typo with no reusable root cause and no failed attempt."
stage_code 4
failcase waiver_does_not_replace_bug_lesson run_gate

setup_repo
write_plan feature "payments, webhooks"
stage_code 5
pass non_learning_task_not_blocked run_gate

setup_repo
write_plan bug_fix "payments, webhooks"
stage_doc_only
pass docs_only_change_not_blocked run_gate

setup_repo
write_plan feature "payments, webhooks"
cat > .claude/plans/old-bug.md <<'EOF'
# Old plan

| Field | Decision |
|---|---|
| Task class | bug_fix |
| Domain tags | payments |
EOF
stage_code 6
pass active_plan_preferred_over_other_plans run_gate

echo "learning capture simulations passed"
