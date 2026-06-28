#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-learning-reuse.sh"
RECORD="$ROOT/scripts/enforcement/record-prevented-issue.sh"
WORKFLOW="$ROOT/scripts/enforcement/enforce-workflow.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() { local name="$1"; shift; "$@" >/tmp/eos-learning-reuse.log 2>&1 || { echo "fail: $name"; cat /tmp/eos-learning-reuse.log; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >/tmp/eos-learning-reuse.log 2>&1; then echo "unexpected pass: $name"; cat /tmp/eos-learning-reuse.log; exit 1; else echo "ok: $name"; fi; }

make_plan() {
  local file="$1" tags="$2" reuse="$3"
  cat > "$file" <<EOF
# Route Plan

## Goal

Fixture goal.

## Plan

Run deterministic learning reuse validation.

## Alternatives

Fixture alternative considered.

| Field | Decision |
|---|---|
| Task class | bug_fix |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | $tags |
| Skills | superpowers |

## Capability Waiver

Reason: fixture.

## Source of Truth Checks

| Source | Status |
|---|---|
| fixture | checked |

## Definition of Done

- [x] fixture complete
EOF
  if [ -n "$reuse" ]; then
    cat >> "$file" <<EOF

## Lessons Reused

- $reuse
  - Applied because: fixture touches a learned area.
  - Prevention: preserve the verified guard.
EOF
  fi
}

make_lesson() {
  local file="$1"
  mkdir -p "$(dirname "$file")"
  cat > "$file" <<'EOF'
# Stripe webhook signature lesson

## מה קרה
Webhook verification failed after body parsing changed.

## שורש הבעיה
The raw body was consumed before signature verification.

## השערות שנבדקו
- Network timeout — rejected by local reproduction.
- Raw body mutation — verified by regression fixture.

## ראיה
The fixture reproduces the failure when raw body verification is skipped.

## רמת ביטחון
Medium

## איך מזהים מוקדם
Run the webhook signature regression before payment changes.

## איך מונעים בעתיד
Read this lesson before editing payment webhook code.

## טסט רגרסיה
scripts/enforcement/tests/test-learning-reuse.sh

## סטטוס הבשלה
Verified Lesson

## Applies To Paths
- src/payments

## Domain Tags
- stripe
- payments
- webhooks

## Prevented Future Issues: 0
EOF
}

make_failed_solution() {
  local file="$1"
  mkdir -p "$(dirname "$file")"
  cat > "$file" <<'EOF'
# Failed solution: parse JSON body first

## מה ניסיתי
Parsed request JSON before verifying the webhook signature.

## למה לא עבד
It changed the bytes used by the signature verification step.

## מה לבדוק במקום
Verify the raw body before any parser mutates it.

## Applies To Paths
- src/payments

## Domain Tags
- stripe
- webhooks
EOF
}

run_check() { (cd "$TMP" && bash "$CHECK" --plan "$1" --target "$2"); }
run_workflow_write() { (cd "$TMP" && printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$1" | bash "$WORKFLOW"); }

cd "$TMP"
mkdir -p .claude/plans src/payments
make_lesson lessons-learned/bugs/stripe-webhook-signature.md
make_failed_solution failed-solutions/stripe-json-first.md
make_plan no-reuse.md "stripe, payments" ""
failcase relevant_lesson_requires_reuse run_check "$TMP/no-reuse.md" src/payments/stripe.ts

make_plan with-reuse.md "stripe, payments" "lessons-learned/bugs/stripe-webhook-signature.md"
failcase failed_solution_also_requires_reuse run_check "$TMP/with-reuse.md" src/payments/stripe.ts

make_plan with-both.md "stripe, payments" "lessons-learned/bugs/stripe-webhook-signature.md
- failed-solutions/stripe-json-first.md"
pass all_relevant_knowledge_reused run_check "$TMP/with-both.md" src/payments/stripe.ts

make_plan neutral.md "profile" ""
pass no_relevant_area_is_allowed run_check "$TMP/neutral.md" src/profile/user.ts

cp no-reuse.md .claude/plans/active.md
failcase runtime_blocks_missing_reuse run_workflow_write src/payments/stripe.ts
cp with-both.md .claude/plans/active.md
pass runtime_allows_reused_knowledge run_workflow_write src/payments/stripe.ts

grep -q 'Prevented Future Issues: 0' lessons-learned/bugs/stripe-webhook-signature.md
bash "$RECORD" lessons-learned/bugs/stripe-webhook-signature.md
grep -q 'Prevented Future Issues: 1' lessons-learned/bugs/stripe-webhook-signature.md
bash "$RECORD" lessons-learned/bugs/stripe-webhook-signature.md
grep -q 'Prevented Future Issues: 2' lessons-learned/bugs/stripe-webhook-signature.md

cat > lessons-learned/bugs/no-counter.md <<'EOF'
# No counter

## מה קרה
x
EOF
bash "$RECORD" lessons-learned/bugs/no-counter.md
grep -q 'Prevented Future Issues: 1' lessons-learned/bugs/no-counter.md

echo "learning reuse simulations passed"
