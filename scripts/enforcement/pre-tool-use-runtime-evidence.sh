#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

bypass_active EOS_BYPASS_RUNTIME_EVIDENCE && exit 0

INPUT="$(cat 2>/dev/null || true)"

json_field() {
  local field="$1"
  printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print('')
    sys.exit(0)
t = d.get('tool_input', d)
field = '$field'
if field == 'tool':
    print(d.get('tool_name', d.get('tool', '')) or '')
elif field == 'file_path':
    print(t.get('file_path', '') or '')
" 2>/dev/null || printf ''
}

field_value() {
  local plan_file="$1"
  local field_re="$2"
  awk -F'|' -v re="$field_re" '
    NF > 1 {
      for (i = 1; i < NF; i++) {
        field = tolower($i)
        gsub(/[*_`]/, "", field)
        gsub(/^[ \t]+|[ \t]+$/, "", field)
        if (field ~ re) {
          value = $(i + 1)
          gsub(/^[ \t]+|[ \t]+$/, "", value)
          print value
          exit
        }
      }
    }
  ' "$plan_file" 2>/dev/null || true
}

is_none_value() {
  local value
  value="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[[:space:][:punct:]]+$//' | xargs)"
  [[ -z "$value" || "$value" =~ ^(none|n/a|na|not[[:space:]]+required|no[[:space:]]+(external[[:space:]]+)?connectors|no[[:space:]]+skills|no[[:space:]]+templates|no[[:space:]]+patterns)$ ]]
}

normalize_list() {
  printf '%s' "${1:-}" \
    | tr ',;' '\n' \
    | sed -E 's/<[^>]+>//g; s/`//g; s/^[-*[:space:]]+//; s/[[:space:]]+$//' \
    | sed '/^$/d'
}

canon_key() {
  printf '%s' "${1:-}" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/^mcp__//; s/__.*$//; s/^[[:space:]]+|[[:space:]]+$//g; s/[^a-z0-9_-]+/-/g; s/^-+|-+$//g'
}

newest_plan() { ls -t .claude/plans/*.md 2>/dev/null | head -1 || true; }

any_evidence_matching() {
  local pattern="$1"
  local f; f="$(_evidence_file)"
  [ -f "$f" ] || return 1
  grep -qE "$pattern" "$f" 2>/dev/null
}

connector_has_evidence() {
  local key
  key="$(canon_key "$1")"
  [ -n "$key" ] || return 0
  evidence_has connector_used "$key" 2>/dev/null || evidence_has "connector_${key}" 2>/dev/null
}

fail() {
  echo "ERROR_FOR_AGENT: runtime evidence gate — $1"
  echo "ACTION: $2"
  echo "BYPASS: EOS_BYPASS_RUNTIME_EVIDENCE=1 — only with explicit user authorization in the current conversation."
  exit 1
}

TOOL="$(json_field tool)"
case "$TOOL" in
  Write|Edit|MultiEdit|NotebookEdit) ;;
  *) exit 0 ;;
esac

FILE="$(json_field file_path)"
[ -n "$FILE" ] || exit 0

# The route plan itself is the first artifact and must be writable before evidence exists.
case "$FILE" in
  .claude/plans/*.md|*/.claude/plans/*.md) exit 0 ;;
esac

# Enforce only code, config, tests, and Engineering OS governance paths.
critical=0
case "$FILE" in
  core/*|*/core/*|patterns/*|*/patterns/*|external-skills/*|*/external-skills/*|external-systems/*|*/external-systems/*|\
  templates/*|*/templates/*|scripts/*|*/scripts/*|\
  .github/*|*/.github/*|.claude/settings.json|*/.claude/settings.json|.claude/tasks.json|*/.claude/tasks.json) critical=1 ;;
esac
if [ "$critical" -eq 0 ]; then
  case "$FILE" in
    *.md|*.txt|*.rst|*.mdx) exit 0 ;;
  esac
  printf '%s' "$FILE" | grep -qE '\.(ts|tsx|js|jsx|py|go|rs|java|swift|kt|rb|cs|cpp|c|h|php|scala|lua|sh|bash|zsh|json|ya?ml|toml|sql)$' || exit 0
fi

PLAN="$(newest_plan)"
[ -n "$PLAN" ] || fail "no Route Plan exists before writing '$FILE'." "create .claude/plans/<task>.md first, then read task-router/workflow and retry."
[ -f "$PLAN" ] || fail "newest Route Plan path is invalid: $PLAN" "create a readable Route Plan under .claude/plans/."

task_router_field="$(field_value "$PLAN" '^task-router evidence$|^task router evidence$')"
workflow_field="$(field_value "$PLAN" '^workflow evidence$')"
[ -n "$task_router_field" ] || fail "Route Plan '$(basename "$PLAN")' is missing Task-router evidence." "route the task through core/task-router.md and record the result in the plan."
[ -n "$workflow_field" ] || fail "Route Plan '$(basename "$PLAN")' is missing Workflow evidence." "read core/workflow.md and record the workflow decision in the plan."

evidence_has task_router_read || fail "core/task-router.md was not read in this session before writing '$FILE'." "read core/task-router.md so the PostToolUse Read hook can record task_router_read."
evidence_has workflow_read || fail "core/workflow.md was not read in this session before writing '$FILE'." "read core/workflow.md so the PostToolUse Read hook can record workflow_read."

templates="$(field_value "$PLAN" '^templates$|^template$')"
patterns="$(field_value "$PLAN" '^patterns$|^pattern$')"
connectors="$(field_value "$PLAN" '^external systems/connectors$|^external systems$|^external connectors$|^connectors$')"

if ! is_none_value "$templates"; then
  evidence_has templates_read || evidence_has template_used || fail "Route Plan declares templates '$templates' but no template read evidence exists." "read the relevant templates/ file before writing implementation code."
fi

if ! is_none_value "$patterns"; then
  any_evidence_matching $'\tpatterns_read_' || evidence_has pattern_used || fail "Route Plan declares patterns '$patterns' but no pattern read evidence exists." "read the relevant patterns/ file before writing implementation code."
fi

if ! grep -qi 'Source of Truth Checks' "$PLAN" 2>/dev/null; then
  fail "Route Plan '$(basename "$PLAN")' is missing Source of Truth Checks." "document the source-of-truth checks in the plan before implementation."
fi

if ! is_none_value "$connectors"; then
  missing=""
  while IFS= read -r connector; do
    [ -n "$connector" ] || continue
    connector_has_evidence "$connector" || missing="${missing}${connector} "
  done <<EOF_CONNECTORS
$(normalize_list "$connectors")
EOF_CONNECTORS
  [ -z "$missing" ] || fail "Route Plan declares connectors '$connectors' but missing connector evidence for: ${missing}." "use each declared connector/source-of-truth before implementation, or change the plan to an explicit none/waiver."
fi

exit 0
