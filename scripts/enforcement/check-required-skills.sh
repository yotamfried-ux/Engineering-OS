#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLAN=""
TARGET=""
SKILLS_DIR="$ROOT/external-skills"
CHECK_COVERAGE=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --plan) PLAN="${2:-}"; shift 2 ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    --skills-dir) SKILLS_DIR="${2:-}"; shift 2 ;;
    --check-coverage) CHECK_COVERAGE=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

# Inventory coverage: every external-skills/<name>/ directory must either have a
# selection rule in this checker (a need_skill/deprecation literal below) or an
# explicit entry here documenting why it is never auto-required. New skills
# cannot be silently unselectable.
NOT_AUTO_REQUIRED="gstack:opt-in orchestration for complex multi-role projects, selected manually per task
nemotron:optional L1 accelerator backend, never a required workflow skill
frontend-design:deprecated, flagged by the deprecation rule and replaced by ui-ux-pro-max"

check_coverage() {
  local bad=0 name
  [ -d "$SKILLS_DIR" ] || { echo "missing skills inventory dir: $SKILLS_DIR" >&2; return 1; }
  for dir in "$SKILLS_DIR"/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    if grep -qE "(need_skill|plan_has_skill) ${name}( |\$)" "${BASH_SOURCE[0]}"; then continue; fi
    if printf '%s\n' "$NOT_AUTO_REQUIRED" | grep -qE "^${name}:.{20,}"; then continue; fi
    echo "skill inventory coverage failed: external-skills/${name}/ has no selection rule and no documented not-auto-required entry" >&2
    bad=1
  done
  return "$bad"
}

if [ "$CHECK_COVERAGE" -eq 1 ]; then
  check_coverage || exit 1
  echo "skill requirements coverage passed"
  exit 0
fi

[ -n "$PLAN" ] && [ -f "$PLAN" ] || { echo "missing readable --plan" >&2; exit 2; }
[ -n "$TARGET" ] || { echo "missing --target" >&2; exit 2; }

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

canon_key() {
  printf '%s' "${1:-}" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/<[^>]+>//g; s/`//g; s/^[[:space:]]+|[[:space:]]+$//g; s/[^a-z0-9_-]+/-/g; s/^-+|-+$//g'
}

normalize_list() {
  printf '%s' "${1:-}" \
    | tr ',;' '\n' \
    | sed -E 's/<[^>]+>//g; s/`//g; s/^[-*[:space:]]+//; s/[[:space:]]+$//' \
    | sed '/^$/d'
}

is_none_value() {
  local value
  value="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[[:space:][:punct:]]+$//' | xargs)"
  [[ -z "$value" || "$value" =~ ^(none|n/a|na|not[[:space:]]+required|no[[:space:]]+skills)$ ]]
}

plan_has_skill() {
  local wanted skill
  wanted="$(canon_key "$1")"
  [ -n "$wanted" ] || return 1
  is_none_value "$SKILLS" && return 1
  while IFS= read -r skill; do
    [ "$(canon_key "$skill")" = "$wanted" ] && return 0
  done <<EOF_SKILLS
$(normalize_list "$SKILLS")
EOF_SKILLS
  return 1
}

plan_has_waiver() {
  local wanted
  wanted="$(canon_key "$1")"
  awk '/^##[[:space:]]+Skill Selection Waiver/ { found=1; next } found && /^##[[:space:]]+/ { exit } found { print }' "$PLAN" 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | grep -Eq "(^|[^a-z0-9_-])(${wanted}|all|skill-selection)([^a-z0-9_-]|$)"
}

need_skill() {
  local skill="$1"
  local reason="$2"
  plan_has_skill "$skill" && return 0
  plan_has_waiver "$skill" && return 0
  missing="${missing}${skill} (${reason}); "
}

TASK_CLASS="$(field_value "$PLAN" '^task class$|^task-class$')"
DOMAIN_TAGS="$(field_value "$PLAN" '^domain tags$|^domains$|^tags$')"
SKILLS="$(field_value "$PLAN" '^skills$|^skill$')"
BLOB="$(printf '%s %s %s' "$TASK_CLASS" "$DOMAIN_TAGS" "$TARGET" | tr '[:upper:]' '[:lower:]')"
missing=""

if plan_has_skill frontend-design; then
  missing="${missing}ui-ux-pro-max (frontend-design is deprecated; use ui-ux-pro-max); "
fi

if printf '%s' "$BLOB" | grep -Eq '(^|[^a-z0-9])(ui|ux|frontend|front-end|react|next|css|tailwind|design-system|component|screen|mobile-ui|web-ui)([^a-z0-9]|$)'; then
  need_skill ui-ux-pro-max "UI/frontend task or target path"
fi

if printf '%s' "$BLOB" | grep -Eq '(^|[^a-z0-9])(security|auth|authentication|authorization|jwt|oauth|rbac|secrets?|stripe|payment|payments|webhook|production|prod|deploy|release)([^a-z0-9]|$)'; then
  need_skill security-review "security, auth, payment, webhook, production, or release-sensitive work"
fi

if printf '%s' "$BLOB" | grep -Eq '(^|[^a-z0-9])(large-change|large-code-change|codebase|navigation|architecture|refactor|cross-cutting|multi-file|large-repo|large repo|context-heavy|impact-analysis|long-running)([^a-z0-9]|$)'; then
  need_skill graphify "large codebase/navigation/architecture work"
fi

if printf '%s' "$BLOB" | grep -Eq '(^|[^a-z0-9])(context_or_large_repo_work|large-repo|large repo|context-heavy|impact-analysis|long-running|compaction|output-compaction|token-limit|token-budget)([^a-z0-9]|$)'; then
  need_skill rtk "context-heavy or large-repo work"
fi

if printf '%s' "$TASK_CLASS" | tr '[:upper:]' '[:lower:]' | grep -Eq '^(code_change|bug_fix|new_project_or_saas|feature|refactor)$'; then
  need_skill superpowers "code/planning task class"
fi

if printf '%s' "$BLOB" | grep -Eq '(^|[^a-z0-9])(multi-session|cross-session|context[ -]persistence|context[ -]carryover|session[ -]memory)([^a-z0-9]|$)'; then
  need_skill claude-mem "multi-session/context-carryover work (waivable when the environment lacks claude-mem)"
fi

if printf '%s' "$BLOB" | grep -Eq '(^|[^a-z0-9])(large[ -]refactor|repo-wide[ -]refactor|multi-pr[ -]review|pr-review-heavy)([^a-z0-9]|$)'; then
  need_skill claude-code-workflows "large-refactor or review-heavy work"
fi

if [ -n "$missing" ]; then
  echo "required skills missing from Route Plan Skills field: $missing" >&2
  exit 1
fi

echo "required skill selection checks passed"
