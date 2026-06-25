#!/usr/bin/env bash
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

INPUT="$(cat 2>/dev/null || true)"
FILE="$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print("")
    sys.exit(0)
t = d.get("tool_input", d)
print(t.get("file_path", "") or t.get("path", "") or "")
' 2>/dev/null || true)"

[ -n "$FILE" ] || exit 0
NORMALIZED="$(printf '%s' "$FILE" | sed 's|\\|/|g')"

record_pattern() {
  local dom="$1"
  [ -n "$dom" ] || return 0
  evidence_record "patterns_read_${dom}" 2>/dev/null || true
  evidence_record pattern_used "$dom" 2>/dev/null || true
}

record_template() {
  local name="$1"
  evidence_record templates_read 2>/dev/null || true
  [ -n "$name" ] && evidence_record template_used "$name" 2>/dev/null || true
}

case "$NORMALIZED" in
  core/task-router.md|*/core/task-router.md)
    evidence_record task_router_read 2>/dev/null || true
    ;;
  core/workflow.md|*/core/workflow.md)
    evidence_record workflow_read 2>/dev/null || true
    ;;
  core/pattern-lifecycle.md|*/core/pattern-lifecycle.md)
    evidence_record read_pattern_lifecycle 2>/dev/null || true
    ;;
  core/maintenance-routine.md|*/core/maintenance-routine.md)
    evidence_record read_maintenance_routine 2>/dev/null || true
    ;;
  core/hooks-policy.md|*/core/hooks-policy.md)
    evidence_record read_hooks_policy 2>/dev/null || true
    ;;
  core/connector-policy.md|*/core/connector-policy.md)
    evidence_record source_truth_checked connector-policy 2>/dev/null || true
    ;;
  patterns/*|*/patterns/*)
    dom="$(printf '%s' "$NORMALIZED" | sed 's|.*/patterns/||; s|/.*||')"
    record_pattern "$dom"
    ;;
  templates/*|*/templates/*)
    tmpl="$(printf '%s' "$NORMALIZED" | sed 's|.*/templates/||; s|/.*||')"
    record_template "$tmpl"
    ;;
  external-systems/*|*/external-systems/*)
    system="$(printf '%s' "$NORMALIZED" | sed 's|.*/external-systems/||; s|/.*||')"
    evidence_record source_truth_checked "$system" 2>/dev/null || true
    evidence_record "external_system_${system}" 2>/dev/null || true
    ;;
  .claude/plans/*.md|*/.claude/plans/*.md)
    fname="$(basename "$NORMALIZED" .md)"
    total="$(grep -cE '^\- \[(x| )\]' "$FILE" 2>/dev/null || echo 0)"
    existing="$(evidence_get "dod_initial_${fname}" 2>/dev/null || true)"
    [ -n "$existing" ] || evidence_record "dod_initial_${fname}" "$total" 2>/dev/null || true
    ;;
  .claude/commands/superpowers-verify.md|*/.claude/commands/superpowers-verify.md)
    evidence_record superpowers_verify_run 2>/dev/null || true
    evidence_record skill_used superpowers-verify 2>/dev/null || true
    ;;
esac

exit 0
