#!/usr/bin/env bash
set -euo pipefail

base="${1:-HEAD~1}"
head="${2:-HEAD}"
changed="$(git diff --name-only "$base" "$head")"
plans="$(printf '%s\n' "$changed" | grep '^\.claude/plans/.*\.md$' || true)"
code="$(printf '%s\n' "$changed" | grep -v '^$' | grep -v '^\.claude/plans/' | grep -v '^docs/' | grep -v '^README\.md$' | grep -v '^CHANGELOG\.md$' | grep -v '^LICENSE' || true)"
knowledge="$(printf '%s\n' "$changed" | grep -E '^(lessons-learned/|failed-solutions/|templates/)' || true)"

if [ -n "$code" ] && [ -z "$plans" ]; then
  echo "ERROR_FOR_AGENT: code/config/test files changed without a changed .claude/plans/*.md Route Plan."
  exit 1
fi

if [ -n "$code" ] && [ -n "$plans" ]; then
  first_plan=0
  first_code=0
  idx=0
  while IFS= read -r commit; do
    idx=$((idx + 1))
    files="$(git diff-tree --no-commit-id --name-only -r "$commit")"
    if [ "$first_plan" -eq 0 ] && printf '%s\n' "$files" | grep -q '^\.claude/plans/.*\.md$'; then
      first_plan="$idx"
    fi
    code_files="$(printf '%s\n' "$files" | grep -v '^$' | grep -v '^\.claude/plans/' | grep -v '^docs/' | grep -v '^README\.md$' | grep -v '^CHANGELOG\.md$' | grep -v '^LICENSE' || true)"
    if [ "$first_code" -eq 0 ] && [ -n "$code_files" ]; then
      first_code="$idx"
    fi
  done < <(git rev-list --reverse "$base..$head")

  if [ "$first_plan" -eq 0 ] || [ "$first_code" -eq 0 ] || [ "$first_code" -le "$first_plan" ]; then
    echo "ERROR_FOR_AGENT: Route Plan must be committed before the first code/config/test change, not in the same or later commit."
    exit 1
  fi
fi

[ -n "$plans" ] || { echo "No changed plan files."; exit 0; }

field_value() {
  local plan="$1"
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
  ' "$plan"
}

has_heading() {
  local plan="$1"
  local heading="$2"
  grep -qiE "^#{1,4}[[:space:]]+$heading([[:space:]]|$)" "$plan"
}

bad=0
for plan in $plans; do
  task_router="$(field_value "$plan" '^task-router evidence$')"
  workflow="$(field_value "$plan" '^workflow evidence$')"
  templates="$(field_value "$plan" '^templates$')"
  patterns="$(field_value "$plan" '^patterns$')"
  skills="$(field_value "$plan" '^skills$')"
  gates="$(field_value "$plan" '^validation gates$')"

  if [ -z "$task_router" ]; then echo "ERROR_FOR_AGENT: $plan is missing Task-router evidence."; bad=1; fi
  if [ -z "$workflow" ]; then echo "ERROR_FOR_AGENT: $plan is missing Workflow evidence."; bad=1; fi
  if [ -z "$templates" ]; then echo "ERROR_FOR_AGENT: $plan is missing Templates."; bad=1; fi
  if [ -z "$patterns" ]; then echo "ERROR_FOR_AGENT: $plan is missing Patterns."; bad=1; fi
  if [ -z "$skills" ]; then echo "ERROR_FOR_AGENT: $plan is missing Skills."; bad=1; fi
  if [ -z "$gates" ]; then echo "ERROR_FOR_AGENT: $plan is missing Validation gates."; bad=1; fi

  if ! has_heading "$plan" 'Source[[:space:]]+of[[:space:]]+Truth[[:space:]]+Checks'; then
    echo "ERROR_FOR_AGENT: $plan is missing ## Source of Truth Checks."
    bad=1
  fi

  normalized_skills="$(printf '%s' "$skills" | tr '[:upper:]' '[:lower:]' | sed -E 's/[[:space:][:punct:]]+$//' | xargs)"
  if [ -n "$normalized_skills" ] && [[ ! "$normalized_skills" =~ ^(none|n/a|na|not[[:space:]]+required|no[[:space:]]+skills)$ ]]; then
    if ! has_heading "$plan" 'Skill[[:space:]]+Evidence'; then
      echo "ERROR_FOR_AGENT: $plan declares skills '$skills' but lacks ## Skill Evidence."
      bad=1
    fi
  fi

  normalized_templates="$(printf '%s' "$templates" | tr '[:upper:]' '[:lower:]')"
  if printf '%s' "$normalized_templates" | grep -qE '(gap|missing|none|no[[:space:]]+template|not[[:space:]]+available|too[[:space:]]+heavy)'; then
    if [ -z "$knowledge" ] && ! has_heading "$plan" 'Template[[:space:]]+Gap[[:space:]]+Waiver'; then
      echo "ERROR_FOR_AGENT: $plan records a template gap but lacks changed learning/template artifact or ## Template Gap Waiver."
      bad=1
    fi
  fi
done

[ "$bad" -eq 0 ] || exit 1
echo "Workflow evidence checks passed."
