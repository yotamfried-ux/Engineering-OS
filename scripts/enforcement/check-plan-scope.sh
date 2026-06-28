#!/usr/bin/env bash
set -euo pipefail

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

targets="$(field_value "$plan" '^target paths$|^target files$|^target scope$')"
if ! is_none_value "$targets"; then
  matched=0
  while IFS= read -r allowed; do
    path_matches_target "$target" "$allowed" && matched=1
  done <<EOF_TARGETS
$(normalize_list "$targets")
EOF_TARGETS
  if [ "$matched" -ne 1 ]; then
    echo "ERROR_FOR_AGENT: active Route Plan target scope '$targets' does not include write target '$target'." >&2
    echo "ACTION: refresh the plan for this task, or add the intended target path before writing." >&2
    exit 1
  fi
fi

if [ -f graphify-out/graph.json ]; then
  if grep -qE $'\tgraphify_used\t' .claude/.evidence/ledger 2>/dev/null; then
    grep -qiE 'graphify.*(finding|findings|result|results|evidence|used|ממצא|תוצאה)' "$plan" 2>/dev/null || {
      echo "ERROR_FOR_AGENT: graphify was queried, but the active Route Plan does not record how graphify informed this write." >&2
      echo "ACTION: add a short Graphify findings note to the plan before writing." >&2
      exit 1
    }
  else
    echo "ERROR_FOR_AGENT: graphify-out/graph.json exists, but graphify evidence was not recorded for this session." >&2
    echo "ACTION: run graphify query/explain/path before writing." >&2
    exit 1
  fi
fi

echo "plan scope checks passed"
