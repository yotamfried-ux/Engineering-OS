#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
WORKFLOW="$ROOT/scripts/enforcement/enforce-workflow.sh"
RUNTIME="$ROOT/scripts/enforcement/pre-tool-use-runtime-evidence.sh"
CHECK_SKILLS="$ROOT/scripts/enforcement/check-required-skills.sh"
CHECK_REUSE="$ROOT/scripts/enforcement/check-learning-reuse.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/operational-readiness.log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$LOG_FILE" 2>&1; then echo "unexpected pass: $name"; cat "$LOG_FILE"; exit 1; else echo "ok: $name"; fi; }

write_plan() {
  local file="$1" skills="$2" reuse="$3"
  mkdir -p "$(dirname "$file")"
  cat > "$file" <<EOF
# Route Plan

Plan Scope: simple

## Goal

Change the payment webhook safely.

## Plan

1. Read relevant prior lessons.
2. Verify required skills and evidence.
3. Touch only payment webhook code.

## Alternatives

- Skip prior lessons — rejected because this area has verified failures.
- Skip security review — rejected because webhooks are payment/security sensitive.

| Field | Decision |
|---|---|
| Task type | operational learning skill fixture |
| Task class | code_change |
| Domain tags | payments, webhooks, stripe |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | read |
| Workflow evidence | read |
| Target paths | src/payments |
| Templates | not required |
| Architecture guides | runtime learning and skill evidence checked locally |
| Patterns | not required |
| External systems/connectors | github |
| Skills | $skills |
| Validation gates | enforce-workflow.sh, check-required-skills.sh, check-learning-reuse.sh, pre-tool-use-runtime-evidence.sh |
| Evidence to check | runtime hook exit codes and evidence ledger |
| User decisions required | none |

## Capability Evidence

- \`routing.task-router-read\`
- \`workflow.workflow-read\`
- \`plan.route-plan-before-write\`
- \`source.github-repo-read\`

## Connector Selection Waiver

- Scope: this fixture isolates learning-reuse and skill-runtime gates.
- Reason: connector-selection behavior is covered by test-required-connectors.sh.

## Source of Truth Checks

| Source | Status |
|---|---|
| GitHub repo | checked |
| Prior lessons | checked when listed below |

## Definition of Done

- [x] Runtime gate behavior simulated.
EOF
  if [ -n "$reuse" ]; then
    cat >> "$file" <<EOF

## Lessons Reused

$reuse
EOF
  fi
}

write_lessons() {
  mkdir -p lessons-learned/bugs failed-solutions src/payments .claude/plans
  cat > lessons-learned/bugs/payment-webhook-raw-body.md <<'EOF'
# Payment webhook raw body lesson

## מה קרה
Payment webhook signature verification failed after request parsing changed.

## שורש הבעיה
The raw request body was consumed before signature verification.

## השערות שנבדקו
- Network issue — rejected.
- Parser mutation — verified.

## ראיה
Regression fixture fails when the raw body is unavailable.

## רמת ביטחון
High

## איך מזהים מוקדם
Run webhook signature tests before payment changes.

## איך מונעים בעתיד
Read this lesson before editing payment webhook code.

## טסט רגרסיה
scripts/enforcement/tests/test-operational-learning-skills.sh

## סטטוס הבשלה
Verified Lesson

## Applies To Paths
- src/payments

## Domain Tags
- payments
- webhooks
- stripe

## Prevented Future Issues: 0
EOF

  cat > failed-solutions/payment-json-first.md <<'EOF'
# Failed solution: parse JSON before verification

## מה ניסיתי
Parsed JSON before verifying the payment webhook signature.

## למה לא עבד
The parser changed the bytes used by signature verification.

## מה לבדוק במקום
Verify the raw body first.

## Applies To Paths
- src/payments

## Domain Tags
- payments
- webhooks
EOF
}

seed_base_evidence() {
  ( . "$ROOT/scripts/enforcement/lib/evidence.sh" && evidence_reset && evidence_record task_router_read && evidence_record workflow_read && evidence_record connector_used github && evidence_record source_github_repo_read )
}

seed_all_evidence() {
  seed_base_evidence
  ( . "$ROOT/scripts/enforcement/lib/evidence.sh" && evidence_record skill_used superpowers && evidence_record skill_used security-review )
}

write_payload() {
  local file="$1"
  printf '{"hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"%s"}}' "$file"
}

run_workflow_write() {
  local file="$1"
  write_payload "$file" | ENGINEERING_OS_HOME="$ROOT" bash "$WORKFLOW"
}

run_runtime_write() {
  local file="$1"
  write_payload "$file" | ENGINEERING_OS_HOME="$ROOT" EOS_PRETOOL_LEGACY_EXIT=1 bash "$RUNTIME"
}

run_installed_write_hooks() {
  local file="$1"
  ENGINEERING_OS_HOME="$ROOT" EOS_PRETOOL_LEGACY_EXIT=1 python3 - "$file" <<'PY'
import json
import os
import subprocess
import sys
file_path = sys.argv[1]
payload = json.dumps({"hook_event_name": "PreToolUse", "tool_name": "Write", "tool_input": {"file_path": file_path}})
settings = json.load(open(".claude/settings.json", encoding="utf-8"))
for block in settings.get("hooks", {}).get("PreToolUse", []):
    if block.get("matcher") != "Write|Edit|MultiEdit|NotebookEdit":
        continue
    for hook in block.get("hooks", []):
        cmd = hook.get("command", "")
        if not cmd:
            continue
        proc = subprocess.run(cmd, input=payload, text=True, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=os.environ.copy())
        if proc.returncode != 0:
            print(proc.stdout, end="")
            print(proc.stderr, end="")
            sys.exit(proc.returncode)
        for line in proc.stdout.splitlines():
            try:
                decision = json.loads(line)
            except json.JSONDecodeError:
                continue
            specific = decision.get("hookSpecificOutput") if isinstance(decision, dict) else None
            if isinstance(specific, dict) and specific.get("permissionDecision") == "deny":
                print(line)
                sys.exit(2)
            if isinstance(decision, dict) and decision.get("decision") == "block":
                print(line)
                sys.exit(2)
print("installed write hooks passed")
PY
}

run_in_sandbox() {
  rm -rf "$TMP/project"
  mkdir -p "$TMP/project"
  cd "$TMP/project"
  git init >/dev/null
  EOS_CONTRACT_TEST=1 ENGINEERING_OS_HOME="$ROOT" bash "$ROOT/scripts/use-in-project.sh" >/dev/null
  write_lessons
}

reuse_both='- lessons-learned/bugs/payment-webhook-raw-body.md
  - Applied because: payment webhook code touches raw body verification.
  - Prevention: preserve raw body before parsing.
- failed-solutions/payment-json-first.md
  - Applied because: this failed solution is relevant to the same webhook area.
  - Prevention: do not parse JSON before signature verification.'

pass prerequisites_present test -f "$WORKFLOW"
pass skill_checker_present test -f "$CHECK_SKILLS"
pass learning_checker_present test -f "$CHECK_REUSE"
pass runtime_evidence_gate_present test -f "$RUNTIME"

run_in_sandbox
pass install_wires_runtime_evidence grep -q 'pre-tool-use-runtime-evidence.sh' .claude/settings.json
pass install_wires_workflow_gate grep -q 'enforce-workflow.sh' .claude/settings.json
pass install_wires_plan_scope grep -q 'check-plan-scope.sh' .claude/settings.json

write_plan .claude/plans/active.md "superpowers, security-review" ""
failcase learning_reuse_blocks_missing_prior_knowledge run_workflow_write src/payments/webhook.ts

write_plan .claude/plans/active.md "superpowers, security-review" "$reuse_both"
pass learning_reuse_allows_when_lesson_and_failed_solution_are_listed run_workflow_write src/payments/webhook.ts

write_plan .claude/plans/active.md "superpowers" "$reuse_both"
seed_all_evidence
failcase skill_selection_blocks_missing_required_security_skill run_runtime_write src/payments/webhook.ts

write_plan .claude/plans/active.md "superpowers, security-review" "$reuse_both"
seed_base_evidence
( . "$ROOT/scripts/enforcement/lib/evidence.sh" && evidence_record skill_used superpowers )
failcase runtime_evidence_blocks_declared_skill_without_evidence run_runtime_write src/payments/webhook.ts

seed_all_evidence
pass runtime_evidence_allows_declared_skills_with_evidence run_runtime_write src/payments/webhook.ts

write_plan .claude/plans/active.md "superpowers" "$reuse_both"
seed_all_evidence
failcase installed_write_hook_sequence_blocks_missing_required_skill run_installed_write_hooks src/payments/webhook.ts

write_plan .claude/plans/active.md "superpowers, security-review" "$reuse_both"
seed_all_evidence
pass installed_write_hook_sequence_allows_full_learning_and_skill_evidence run_installed_write_hooks src/payments/webhook.ts

echo "operational learning + skills simulations passed"
