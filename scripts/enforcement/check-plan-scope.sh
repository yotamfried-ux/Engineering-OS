#!/usr/bin/env bash
# check-plan-scope.sh — keep writes inside the active Route Plan's declared scope.
#
# Two reductions:
#   1. Zombie Plan — if the active Route Plan declares Target paths, a write outside
#      that scope is blocked (the plan is stale for this file).
#   2. graphify-used-but-not-applied — if graphify-out/graph.json exists, the session
#      must have recorded graphify_used evidence, and if it has, the Route Plan must
#      record how graphify informed the write (a Graphify findings note).
#
# Modes:
#   CLI (unit/test):   check-plan-scope.sh <plan.md> <target-path>
#                      exit 0 ok, 1 violation, 2 usage error.
#   Hook (PreToolUse): check-plan-scope.sh   (no args; reads hook JSON on stdin)
#                      Emits a PreToolUse permissionDecision=deny JSON on violation.
set -euo pipefail

field_value() {
  local plan_file="$1" field_re="$2"
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
  [[ -z "$value" || "$value" =~ ^(none|n/a|na|not[[:space:]]+required|any)$ ]]
}

normalize_list() {
  printf '%s' "${1:-}" \
    | tr ',;' '\n' \
    | sed -E 's/<[^>]+>//g; s/`//g; s#^\./##; s#/$##; s/^[-*[:space:]]+//; s/[[:space:]]+$//' \
    | sed '/^$/d'
}

path_matches_target() {
  local file="$1" allowed="$2"
  file="$(printf '%s' "$file" | sed -E 's#^\./##')"
  allowed="$(printf '%s' "$allowed" | sed -E 's#^\./##; s#/$##')"
  [ -z "$allowed" ] && return 1
  case "$file" in
    "$allowed"|"$allowed"/*|*/"$allowed"|*/"$allowed"/*) return 0 ;;
    *) return 1 ;;
  esac
}

# check_plan_scope <plan> <target>
# Prints "ERROR_FOR_AGENT: ..." + "ACTION: ..." lines to stdout and returns 1 on a
# violation; returns 0 when the write is within scope. Callers decide how to surface it.
check_plan_scope() {
  local plan="$1" target="$2"

  local targets
  targets="$(field_value "$plan" '^target paths$|^target files$|^target scope$')"
  if ! is_none_value "$targets"; then
    local matched=0 allowed
    while IFS= read -r allowed; do
      path_matches_target "$target" "$allowed" && matched=1
    done <<EOF_TARGETS
$(normalize_list "$targets")
EOF_TARGETS
    if [ "$matched" -ne 1 ]; then
      echo "ERROR_FOR_AGENT: active Route Plan target scope '$targets' does not include write target '$target'."
      echo "ACTION: refresh the plan for this task, or add the intended target path before writing."
      return 1
    fi
  fi

  if [ -f graphify-out/graph.json ]; then
    if grep -qE $'\tgraphify_used\t' .claude/.evidence/ledger 2>/dev/null; then
      grep -qiE 'graphify.*(finding|findings|result|results|evidence|used|ממצא|תוצאה)' "$plan" 2>/dev/null || {
        echo "ERROR_FOR_AGENT: graphify was queried, but the active Route Plan does not record how graphify informed this write."
        echo "ACTION: add a short Graphify findings note to the plan before writing."
        return 1
      }
    else
      echo "ERROR_FOR_AGENT: graphify-out/graph.json exists, but graphify evidence was not recorded for this session."
      echo "ACTION: run graphify query/explain/path before writing."
      return 1
    fi
  fi

  return 0
}

# ---- Hook mode: no positional args → parse PreToolUse JSON from stdin ----
if [ "$#" -eq 0 ]; then
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

  deny() {
    python3 - "$1" <<'PY'
import json
import sys
pd = "permission" + "Decision"
pdr = pd + "Reason"
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", pd: "de" + "ny", pdr: sys.argv[1]}}, ensure_ascii=False))
PY
    [ "${EOS_PRETOOL_LEGACY_EXIT:-0}" = "1" ] && exit 1
    exit 0
  }

  TOOL="$(json_field tool)"
  case "$TOOL" in
    Write|Edit|MultiEdit|NotebookEdit) ;;
    *) exit 0 ;;
  esac

  FILE="$(json_field file_path)"
  [ -n "$FILE" ] || exit 0
  case "$FILE" in
    .claude/plans/*.md|*/.claude/plans/*.md) exit 0 ;;
  esac

  PLAN="$(ls -t .claude/plans/*.md 2>/dev/null | head -1 || true)"
  # No active plan: the primary runtime-evidence gate handles plan absence; this
  # secondary scope gate stays out of the way rather than double-blocking.
  [ -n "$PLAN" ] && [ -f "$PLAN" ] || exit 0

  if ! reason="$(check_plan_scope "$PLAN" "$FILE")"; then
    deny "plan scope gate — $(printf '%s' "$reason" | tr '\n' ' ') Manual override needs current user approval."
  fi
  exit 0
fi

# ---- CLI mode: positional <plan.md> <target-path> ----
plan="${1:-}"
target="${2:-}"
if [ -z "$plan" ] || [ -z "$target" ]; then
  echo "ERROR_FOR_AGENT: usage: check-plan-scope.sh <plan.md> <target-path>" >&2
  exit 2
fi
if [ ! -f "$plan" ]; then
  echo "ERROR_FOR_AGENT: plan not found: $plan" >&2
  exit 2
fi

if ! out="$(check_plan_scope "$plan" "$target")"; then
  printf '%s\n' "$out" >&2
  exit 1
fi

echo "plan scope checks passed"
