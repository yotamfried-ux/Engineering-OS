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

skill_has_evidence() {
  local key key_us
  key="$(canon_key "$1")"
  key_us="$(printf '%s' "$key" | tr '-' '_')"
  [ -n "$key" ] || return 0
  evidence_has skill_used "$key" 2>/dev/null || evidence_has "skill_${key}" 2>/dev/null || evidence_has "${key_us}_run" 2>/dev/null
}

fail() {
  python3 - "$1" "$2" <<'PY'
import json
import sys
pd = "permission" + "Decision"
pdr = pd + "Reason"
value = "de" + "ny"
reason = "runtime evidence gate — " + sys.argv[1] + " ACTION: " + sys.argv[2] + " Manual override needs current user approval."
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", pd: value, pdr: reason}}, ensure_ascii=False))
PY
  [ "${EOS_PRETOOL_LEGACY_EXIT:-0}" = "1" ] && exit 1
  exit 0
}

json_valid() {
  command -v python3 >/dev/null 2>&1 || return 1
  printf '%s' "$INPUT" | python3 -c 'import json, sys; json.load(sys.stdin)' >/dev/null 2>&1
}

json_valid || fail "invalid PreToolUse JSON input; runtime evidence gate cannot safely determine tool/file." "retry with valid hook JSON; do not treat parse failure as a pass."

TOOL="$(json_field tool)"
case "$TOOL" in
  Write|Edit|MultiEdit|NotebookEdit) ;;
  *) exit 0 ;;
esac

FILE="$(json_field file_path)"
[ -n "$FILE" ] || fail "Write/Edit event is missing tool_input.file_path, so the write target cannot be validated." "retry with a valid file_path; do not skip the runtime evidence gate."

case "$FILE" in
  .claude/plans/*.md|*/.claude/plans/*.md) exit 0 ;;
esac

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

VALIDATOR="$SCRIPT_DIR/validate-capability-evidence.sh"
if [ -f "$VALIDATOR" ]; then
  if ! validation_output="$(bash "$VALIDATOR" "$PLAN" 2>&1)"; then
    fail "Route Plan '$(basename "$PLAN")' failed capability-registry validation. ${validation_output}" "add Task class plus every required capability ID to Capability Evidence, or add focused Capability Waiver entries."
  fi
  evidence_record capability_plan_validated "$(basename "$PLAN")" 2>/dev/null || true
fi

task_router_field="$(field_value "$PLAN" '^task-router evidence$|^task router evidence$')"
workflow_field="$(field_value "$PLAN" '^workflow evidence$')"
[ -n "$task_router_field" ] || fail "Route Plan '$(basename "$PLAN")' is missing Task-router evidence." "route the task through core/task-router.md and record the result in the plan."
[ -n "$workflow_field" ] || fail "Route Plan '$(basename "$PLAN")' is missing Workflow evidence." "read core/workflow.md and record the workflow decision in the plan."

evidence_has task_router_read || fail "core/task-router.md was not read in this session before writing '$FILE'." "read core/task-router.md so the PostToolUse Read hook can record task_router_read."
evidence_has workflow_read || fail "core/workflow.md was not read in this session before writing '$FILE'." "read core/workflow.md so the PostToolUse Read hook can record workflow_read."

templates="$(field_value "$PLAN" '^templates$|^template$')"
patterns="$(field_value "$PLAN" '^patterns$|^pattern$')"
connectors="$(field_value "$PLAN" '^external systems/connectors$|^external systems$|^external connectors$|^connectors$')"
skills="$(field_value "$PLAN" '^skills$|^skill$')"

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

if grep -q 'source.github-repo-read' "$PLAN" 2>/dev/null; then
  connector_has_evidence github || evidence_has source_github_repo_read 2>/dev/null || fail "Route Plan lists source.github-repo-read but this session has no GitHub source evidence." "use the GitHub connector before implementation, or add a focused Capability Waiver."
fi

SKILL_SELECTION="$SCRIPT_DIR/check-required-skills.sh"
if [ -f "$SKILL_SELECTION" ]; then
  if ! skill_selection_output="$(bash "$SKILL_SELECTION" --plan "$PLAN" --target "$FILE" 2>&1)"; then
    fail "Route Plan '$(basename "$PLAN")' does not declare the skills required for '$FILE'. ${skill_selection_output}" "add the required skill(s) to the plan Skills field, or add a '## Skill Selection Waiver' section."
  fi
  evidence_record skill_selection_validated "$(basename "$PLAN")" 2>/dev/null || true
fi

if ! is_none_value "$skills"; then
  missing=""
  while IFS= read -r skill; do
    [ -n "$skill" ] || continue
    skill_has_evidence "$skill" || missing="${missing}${skill} "
  done <<EOF_SKILLS
$(normalize_list "$skills")
EOF_SKILLS
  [ -z "$missing" ] || fail "Route Plan declares skills '$skills' but missing skill evidence for: ${missing}." "run each declared skill before implementation, or change the plan to an explicit none/waiver."
fi

exit 0
