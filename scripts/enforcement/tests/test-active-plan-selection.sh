#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
LIB="$ROOT/scripts/enforcement/lib/evidence.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/plan-selection.log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }

# Recency is declared, not inferred from mtime: lib/plan-time.sh reads a plan's
# 'Plan Timestamp' (or its git history), so these fixtures state their own order.
# PLAN_SEQ increments per plan written, making each new plan one minute newer than
# the last — the ordering the old fixtures got from `sleep 1` plus mtime.
# plan_stamp must be called as a statement, not inside $( ) — command substitution runs
# in a subshell, so the PLAN_SEQ increment would be lost and every plan would share one
# timestamp. It publishes its result in PLAN_STAMP instead.
PLAN_SEQ=0
PLAN_STAMP=""
PLAN_EPOCH0="$(date -u +%s)"
plan_stamp() {
  PLAN_SEQ=$((PLAN_SEQ + 1))
  PLAN_STAMP="$(date -u -d "@$(( PLAN_EPOCH0 - 3600 + PLAN_SEQ * 60 ))" +%Y-%m-%dT%H:%M:%SZ)"
}

write_plan() {
  local path="$1" targets="$2"
  plan_stamp
  cat > "$path" <<EOF
# Route Plan

| Field | Value |
|---|---|
| Task class | unclassified |
| Target paths | $targets |
| Plan Timestamp | $PLAN_STAMP |
EOF
}

# select <hint> — run eos_select_plan in the fixture repo and print the result.
select_plan_in_repo() {
  (cd "$TMP/repo" && . "$LIB" && eos_select_plan "${1:-}")
}

expect_selected() {
  local name="$1" hint="$2" want="$3" got
  got="$(select_plan_in_repo "$hint")"
  if [ "$got" = "$want" ]; then echo "ok: $name"; else echo "fail: $name (expected $want, got $got)"; exit 1; fi
}

mkdir -p "$TMP/repo/.claude/plans"
cd "$TMP/repo"

# Older plan targets scripts/x; newer plan targets docs/y. The write target decides.
write_plan .claude/plans/older-scripts.md "scripts/x"
write_plan .claude/plans/newer-docs.md "docs/y"

expect_selected "matching older plan beats unrelated newest plan" "scripts/x/tool.sh" ".claude/plans/older-scripts.md"
expect_selected "newest matching plan wins for its own target" "docs/y/guide.md" ".claude/plans/newer-docs.md"
expect_selected "no match falls back to newest plan (legacy behavior)" "src/unrelated.ts" ".claude/plans/newer-docs.md"
expect_selected "no hint falls back to newest plan (legacy behavior)" "" ".claude/plans/newer-docs.md"

# Explicit overrides win over target matching.
got="$(cd "$TMP/repo" && EOS_ACTIVE_PLAN=.claude/plans/older-scripts.md bash -c ". '$LIB' && eos_select_plan docs/y/guide.md")"
if [ "$got" = ".claude/plans/older-scripts.md" ]; then echo "ok: EOS_ACTIVE_PLAN overrides target matching"; else echo "fail: EOS_ACTIVE_PLAN override (got $got)"; exit 1; fi

write_plan .claude/plans/active.md "anything/else"
expect_selected "active.md overrides target matching" "scripts/x/tool.sh" ".claude/plans/active.md"
rm .claude/plans/active.md

# Plans without a Target paths field never match but still serve as newest fallback.
plan_stamp
cat > .claude/plans/no-targets.md <<EOF
# Route Plan with no targets table

| Plan Timestamp | $PLAN_STAMP |
EOF
expect_selected "field-less newest plan is fallback only" "scripts/x/tool.sh" ".claude/plans/older-scripts.md"
expect_selected "field-less newest plan wins when nothing matches" "src/unrelated.ts" ".claude/plans/no-targets.md"

# Unscoped Target paths ("none"/"any"/"n/a") mean match-all: a newer unscoped
# plan must win over an older plan with a literal, unrelated prefix match.
write_plan .claude/plans/newer-unscoped.md "none"
expect_selected "newer unscoped plan matches any target" "scripts/x/tool.sh" ".claude/plans/newer-unscoped.md"
expect_selected "newer unscoped plan matches unrelated target too" "src/unrelated.ts" ".claude/plans/newer-unscoped.md"
rm .claude/plans/newer-unscoped.md

# Hook-mode integration: check-plan-scope selects the matching plan, so a write
# inside the older plan's scope is allowed even though a newer unrelated plan exists.
rm .claude/plans/no-targets.md
hook_out="$(cd "$TMP/repo" && printf '{"tool_name":"Write","tool_input":{"file_path":"scripts/x/tool.sh"}}' | bash "$ROOT/scripts/enforcement/check-plan-scope.sh")"
case "$hook_out" in
  *permissionDecision*) echo "fail: hook_mode_selects_matching_plan_for_in_scope_write (denied: $hook_out)"; exit 1 ;;
  *) echo "ok: hook_mode_selects_matching_plan_for_in_scope_write" ;;
esac

echo "active plan selection simulations passed"
