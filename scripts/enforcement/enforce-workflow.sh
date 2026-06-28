#!/usr/bin/env bash
# enforce-workflow.sh — deterministic enforcer for core/workflow.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

_eos_var() { printf 'EOS_%s%s' "$(printf '\102\131\120\101\123\123\137')" "$1"; }
_is_on() { local n; n="$(_eos_var "$1")"; eval '[ -n "${'"$n"':-}" ]'; }
_evidence_note() { command -v evidence_record >/dev/null 2>&1 && evidence_record bypass_used "$(_eos_var "$1")" 2>/dev/null || true; }

if _is_on WORKFLOW; then _evidence_note WORKFLOW; exit 0; fi

INPUT="$(cat 2>/dev/null || true)"

read_field() {
  command -v python3 >/dev/null 2>&1 || { printf 'WARNING_FOR_AGENT: python3 not found — enforce-workflow hook degraded\n' >&2; return; }
  printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print('')
    sys.exit(0)
t = d.get('tool_input', d)
field = '$1'
if field == 'tool':
    print(d.get('tool_name', d.get('tool', '')))
elif field == 'file_path':
    print(t.get('file_path', '') or '')
elif field == 'command':
    print(t.get('command', '') or '')
elif field == 'content':
    print(t.get('content', '') or t.get('new_string', '') or '')
" 2>/dev/null || printf ''
}

TOOL="$(read_field tool)"
newest_plan() { ls -t .claude/plans/*.md 2>/dev/null | head -1; }

plan_missing_sections() {
  local pf="$1" missing=""
  grep -qiE 'מטרה|goal|requirements|דרישות' "$pf" || missing="${missing}Goal/מטרה "
  grep -qiE 'תכנון|\bplan\b|steps|שלבים' "$pf" || missing="${missing}Plan/תכנון "
  grep -qiE 'DoD|Definition of Done|תנאי סיום' "$pf" || missing="${missing}DoD/תנאי-סיום "
  grep -qiE 'brainstorm|חלופות|alternatives' "$pf" || missing="${missing}Alternatives/חלופות "
  printf '%s' "$missing"
}

gate_plan_integrity() {
  local file="$1"
  case "$file" in .claude/plans/*.md|*/.claude/plans/*.md) ;; *) return 0 ;; esac
  if _is_on DOD; then _evidence_note DOD; return 0; fi
  local fname initial new_content new_total
  fname="$(basename "$file" .md)"
  initial="$(evidence_get "dod_initial_${fname}" 2>/dev/null || printf '0')"
  [ "${initial:-0}" -eq 0 ] && return 0
  new_content="$(read_field content)"
  [ -z "$new_content" ] && return 0
  new_total="$(printf '%s' "$new_content" | grep -cE '^\- \[(x| )\]' 2>/dev/null || printf '0')"
  [ "${new_total:-0}" -lt "${initial:-0}" ] && { echo "ERROR_FOR_AGENT: DoD integrity gate."; exit 1; }
}

gate_tasks_completion() {
  local file="$1"
  case "$file" in .claude/tasks.json|*/.claude/tasks.json) ;; *) return 0 ;; esac
  if _is_on DOD; then _evidence_note DOD; return 0; fi
  local new_content pf unchecked
  new_content="$(read_field content)"
  [ -z "$new_content" ] && return 0
  printf '%s' "$new_content" | grep -q '"complete"' || return 0
  pf="$(newest_plan)"
  [ -z "$pf" ] && return 0
  unchecked=$(awk '
    /^#{1,4}[[:space:]].*([Dd]o[Dd]|תנאי.סיום)/ { found=1; next }
    found && /^#{1,4}[[:space:]]/ && !/([Dd]o[Dd]|תנאי.סיום)/ { found=0 }
    found && /^\- \[ \]/ { count++ }
    END { print count+0 }
  ' "$pf" 2>/dev/null || printf '0')
  [ "${unchecked:-0}" -gt 0 ] && { echo "ERROR_FOR_AGENT: DoD completion gate."; exit 1; }
}

gate_write() {
  local FILE="$1"
  if [ -z "$FILE" ]; then
    case "$TOOL" in Write|Edit|MultiEdit|NotebookEdit) echo "WARNING_FOR_AGENT: enforce-workflow could not parse file_path." ;; esac
    exit 0
  fi

  gate_plan_integrity "$FILE"
  gate_tasks_completion "$FILE"

  local crit=0
  case "$FILE" in core/*|*/core/*|patterns/*|*/patterns/*|external-skills/*|*/external-skills/*|templates/*|*/templates/*|scripts/*|*/scripts/*|.github/*|*/.github/*|.claude/settings.json|*/.claude/settings.json) crit=1 ;; esac
  case "$FILE" in .github/workflows/*|*/.github/workflows/*) crit=1 ;; esac
  if [ "$crit" -eq 0 ]; then
    case "$FILE" in *.md|*.json|*.yaml|*.yml|*.toml|*.lock|*.env*|*.gitignore|*.editorconfig|*.prettierrc|*.eslintrc) exit 0 ;; esac
    printf '%s' "$FILE" | grep -qE '\.(ts|tsx|js|jsx|py|go|rs|java|swift|kt|rb|cs|cpp|c|h|php|scala|lua|sh|bash|zsh)$' || exit 0
  fi

  local pf missing max_age now mtime age_h
  pf="$(newest_plan)"
  [ -z "$pf" ] && { echo "ERROR_FOR_AGENT: workflow gate — no plan."; exit 1; }
  missing="$(plan_missing_sections "$pf")"
  [ -n "$missing" ] && { echo "ERROR_FOR_AGENT: workflow gate — missing sections: ${missing}"; exit 1; }
  max_age="${EOS_PLAN_MAX_AGE_H:-48}"
  printf '%s' "$max_age" | grep -qE '^[0-9]+$' || { echo "ERROR_FOR_AGENT: invalid plan age setting."; exit 1; }
  if [ "$max_age" != "0" ]; then
    now="$(date +%s 2>/dev/null || echo 0)"
    mtime="$(stat -c %Y "$pf" 2>/dev/null || stat -f %m "$pf" 2>/dev/null || echo "$now")"
    age_h=$(( (now - mtime) / 3600 ))
    [ "$age_h" -ge "$max_age" ] && { echo "ERROR_FOR_AGENT: workflow gate — stale plan."; exit 1; }
  fi

  if [ -f "$SCRIPT_DIR/pre-tool-use-learning-reuse.sh" ]; then
    printf '%s' "$INPUT" | bash "$SCRIPT_DIR/pre-tool-use-learning-reuse.sh"
  fi

  case "$FILE" in patterns/*|*/patterns/*) evidence_has read_pattern_lifecycle || { echo "ERROR_FOR_AGENT: pattern lifecycle evidence missing."; exit 1; } ;; esac
  case "$FILE" in scripts/hooks/*|*/scripts/hooks/*|scripts/enforcement/*|*/scripts/enforcement/*|.claude/settings.json|*/.claude/settings.json) evidence_has read_hooks_policy || { echo "ERROR_FOR_AGENT: hooks policy evidence missing."; exit 1; } ;; esac

  if [ -f graphify-out/graph.json ]; then
    if ! _is_on GRAPHIFY; then evidence_has graphify_used || { echo "ERROR_FOR_AGENT: graphify evidence missing."; exit 1; }; else _evidence_note GRAPHIFY; fi
  fi

  local _domains _dom _g8_matched _any_pattern
  _domains="auth api billing database frontend security testing ai ai-agents authorization infrastructure integrations ui observability"
  _g8_matched=0
  for _dom in $_domains; do
    case "$FILE" in
      *"/${_dom}/"*|*"/${_dom}."*|*"_${_dom}."*|*"${_dom}_"*)
        _g8_matched=1
        if [ -d "patterns/${_dom}" ]; then
          if ! _is_on PATTERNS; then evidence_has "patterns_read_${_dom}" || { echo "ERROR_FOR_AGENT: pattern evidence missing."; exit 1; }; else _evidence_note PATTERNS; fi
        fi
        break ;;
    esac
  done
  if [ "$_g8_matched" -eq 0 ] && [ ! -f "$FILE" ] && [ -d patterns ]; then
    if ! _is_on PATTERNS; then
      _any_pattern="$(grep -F $'\tpatterns_read_' "$(_evidence_file)" 2>/dev/null | head -1 || true)"
      [ -z "$_any_pattern" ] && echo "WARNING_FOR_AGENT: patterns advisory (G12) — creating new file '$(basename "$FILE")' with no patterns read this session."
    else _evidence_note PATTERNS; fi
  fi
  exit 0
}

gate_bash() {
  local CMD="$1" bx
  [ -z "$CMD" ] && exit 0
  bx="$(_eos_var '')"
  printf '%s' "$CMD" | grep -qE "(^[[:space:]]*(export[[:space:]]+)?|[;|&(][[:space:]]*(export[[:space:]]+)?)${bx}[A-Z_]+=" && { echo "ERROR_FOR_AGENT: guarded env assignment."; exit 1; }
  case "$CMD" in *"npm install "[a-zA-Z@]*|*"npm i "[a-zA-Z@]*|*"yarn add "[a-zA-Z@]*|*"pnpm add "[a-zA-Z@]*|*"pip install "[a-zA-Z]*|*"pip3 install "[a-zA-Z]*|*"uv add "[a-zA-Z]*|*"uv pip install "[a-zA-Z]*) ;; *) exit 0 ;; esac
  if _is_on CONTEXT7; then _evidence_note CONTEXT7; exit 0; fi
  evidence_has context7 && exit 0
  echo "ERROR_FOR_AGENT: Context7 evidence missing."
  exit 1
}

gate_agent() {
  if _is_on TASKSJSON; then _evidence_note TASKSJSON; exit 0; fi
  [ -f .claude/tasks.json ] || { echo "ERROR_FOR_AGENT: tasks file missing."; exit 1; }
  schema_result="$(python3 -c 'import json
try:
 d=json.load(open(".claude/tasks.json")); t=d.get("tasks", [])
 print("ok" if isinstance(t,list) and t and all(isinstance(x,dict) and all(k in x for k in ("id","title","status")) for x in t) else "FAIL")
except Exception:
 print("FAIL")' 2>/dev/null || echo FAIL)"
  [ "$schema_result" = ok ] || { echo "ERROR_FOR_AGENT: tasks schema invalid."; exit 1; }
  exit 0
}

case "$TOOL" in
  Write|Edit|MultiEdit|NotebookEdit) gate_write "$(read_field file_path)" ;;
  Bash) gate_bash "$(read_field command)" ;;
  Agent|Task) gate_agent ;;
  *) exit 0 ;;
esac
exit 0
