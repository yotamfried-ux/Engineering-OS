#!/usr/bin/env bash
set -euo pipefail

base="${1:-HEAD~1}"
head="${2:-HEAD}"
changed="$(git diff --name-only "$base" "$head")"
plans="$(printf '%s\n' "$changed" | grep '^\.claude/plans/.*\.md$' | while read -r p; do [ -f "$p" ] && echo "$p"; done || true)"
code="$(printf '%s\n' "$changed" | grep -v '^$' | grep -v '^\.claude/plans/' | grep -v '^docs/' | grep -v '^README\.md$' | grep -v '^CHANGELOG\.md$' | grep -v '^LICENSE' || true)"
knowledge="$(printf '%s\n' "$changed" | grep -E '^(lessons-learned/|failed-solutions/|templates/)' || true)"

if [ -n "$code" ] && [ -z "$plans" ]; then
  echo "ERROR_FOR_AGENT: code/config/test files changed without a changed .claude/plans/*.md Route Plan."
  exit 1
fi

if [ -n "$code" ] && [ -n "$plans" ]; then
  first_plan=0; first_code=0; idx=0
  while read -r commit; do
    idx=$((idx + 1))
    files="$(git diff-tree --no-commit-id --name-only -r "$commit")"
    if [ "$first_plan" -eq 0 ] && echo "$files" | grep -q '^\.claude/plans/.*\.md$'; then first_plan="$idx"; fi
    code_files="$(echo "$files" | grep -v '^$' | grep -v '^\.claude/plans/' | grep -v '^docs/' | grep -v '^README\.md$' | grep -v '^CHANGELOG\.md$' | grep -v '^LICENSE' || true)"
    if [ "$first_code" -eq 0 ] && [ -n "$code_files" ]; then first_code="$idx"; fi
  done < <(git rev-list --reverse "$base..$head")
  if [ "$first_plan" -eq 0 ] || [ "$first_code" -eq 0 ] || [ "$first_code" -le "$first_plan" ]; then
    echo "ERROR_FOR_AGENT: Route Plan must be committed before the first code/config/test change, not in the same or later commit."
    exit 1
  fi
fi

[ -n "$plans" ] || { echo "No changed plan files."; exit 0; }

field_value() { awk -F'|' -v re="$2" 'NF>1{for(i=1;i<NF;i++){f=tolower($i);gsub(/[*_`]/,"",f);gsub(/^[ \t]+|[ \t]+$/,"",f);if(f~re){v=$(i+1);gsub(/^[ \t]+|[ \t]+$/,"",v);print v;exit}}}' "$1"; }
has_heading() { grep -qiE "^#{1,4}[[:space:]]+$2([[:space:]]|$)" "$1"; }
section_body() { awk -v h="$2" 'BEGIN{f=0}$0~"^#{1,4}[[:space:]]+"h"([[:space:]]|$)"{f=1;next}f&&$0~"^#{1,4}[[:space:]]+"{exit}f{print}' "$1"; }
clean() { printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[`*_]//g;s/^[[:space:]]+|[[:space:]]+$//g;s/[[:space:][:punct:]]+$//'; }
norm_item() { printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]' | sed -E 's/<[^>]+>//g;s/`//g;s/^[[:space:]*-]+//;s/[[:space:][:punct:]]+$//;s/[^a-z0-9_./-]+/-/g;s/^-+|-+$//g'; }

list_has_item() {
  local list="$1" wanted="$2" key
  wanted="$(norm_item "$wanted")"
  while read -r raw || [ -n "$raw" ]; do
    key="$(norm_item "$raw")"
    [ -n "$key" ] || continue
    [ "$key" = "$wanted" ] && return 0
  done < <(printf '%s' "$list" | tr ',;' '\n')
  return 1
}

source_matches_target() {
  local sources="$1"
  local targets="$2"
  printf '%s' "$sources" | grep -Eq 'CLAUDE\.md|core/task-router\.md|core/workflow\.md' && return 0
  while read -r target; do
    key="$(norm_item "$target")"
    [ -z "$key" ] && continue
    dir="${key%/*}"
    base="${key##*/}"
    if printf '%s' "$sources" | tr '[:upper:]' '[:lower:]' | grep -Fq -- "$key"; then return 0; fi
    if [ "$dir" != "$key" ] && printf '%s' "$sources" | tr '[:upper:]' '[:lower:]' | grep -Fq -- "$dir"; then return 0; fi
    if [ -n "$base" ] && printf '%s' "$sources" | tr '[:upper:]' '[:lower:]' | grep -Fq -- "$base"; then return 0; fi
  done < <(printf '%s\n' "$targets" | tr ',;' '\n' | sed '/^[[:space:]]*$/d')
  return 1
}

bad=0
for plan in $plans; do
  task_router="$(field_value "$plan" '^task-router evidence$')"
  workflow="$(field_value "$plan" '^workflow evidence$')"
  templates="$(field_value "$plan" '^templates$')"
  patterns="$(field_value "$plan" '^patterns$')"
  skills="$(field_value "$plan" '^skills$')"
  gates="$(field_value "$plan" '^validation gates$')"
  targets="$(field_value "$plan" '^target paths$|^target path$')"

  for pair in "Task-router evidence::$task_router" "Workflow evidence::$workflow" "Templates::$templates" "Patterns::$patterns" "Skills::$skills" "Validation gates::$gates"; do
    name="${pair%%::*}"; value="$(clean "${pair#*::}")"
    if [[ -z "$value" || "$value" =~ ^(todo|tbd|placeholder|unknown|later|fix[[:space:]]*later|to[[:space:]]*decide)$ ]]; then
      echo "ERROR_FOR_AGENT: $plan has missing or placeholder $name."
      bad=1
    fi
  done

  if ! has_heading "$plan" 'Source[[:space:]]+of[[:space:]]+Truth[[:space:]]+Checks'; then
    echo "ERROR_FOR_AGENT: $plan is missing ## Source of Truth Checks."
    bad=1
  else
    source_section="$(section_body "$plan" 'Source[[:space:]]+of[[:space:]]+Truth[[:space:]]+Checks')"
    count="$(printf '%s\n' "$source_section" | grep -Eci '\|[[:space:]]*[^|]+[[:space:]]*\|[[:space:]]*(checked|read|validated)[[:space:]]*\|' || true)"
    if [ "$count" -lt 2 ]; then
      echo "ERROR_FOR_AGENT: $plan Source of Truth Checks must include at least two checked/read sources."
      bad=1
    fi
    if [ -n "$code" ] && [ -n "$(clean "$targets")" ] && ! source_matches_target "$source_section" "$targets"; then
      echo "ERROR_FOR_AGENT: $plan Source of Truth Checks do not reference any Target paths or canonical routing/workflow source."
      bad=1
    fi
  fi

  if [ -n "$code" ]; then
    if ! has_heading "$plan" 'Claude[[:space:]]+Run[[:space:]]+Trace'; then
      echo "ERROR_FOR_AGENT: $plan changes code/config/tests but lacks ## Claude Run Trace."
      bad=1
    fi
    if ! has_heading "$plan" 'Progress[[:space:]]+Lifecycle[[:space:]]+Evidence'; then
      echo "ERROR_FOR_AGENT: $plan changes code/config/tests but lacks ## Progress Lifecycle Evidence."
      bad=1
    else
      progress="$(section_body "$plan" 'Progress[[:space:]]+Lifecycle[[:space:]]+Evidence' | tr '[:upper:]' '[:lower:]')"
      for marker in start mid pre-merge; do
        if ! printf '%s\n' "$progress" | grep -Eq "(^|[^a-z])${marker}([^a-z]|$)"; then
          echo "ERROR_FOR_AGENT: $plan Progress Lifecycle Evidence must include ${marker} checkpoint evidence."
          bad=1
        fi
      done
    fi
  fi

  skills_clean="$(clean "$skills")"
  if [[ -n "$skills_clean" && ! "$skills_clean" =~ ^(none|n/a|na|not[[:space:]]+required|no[[:space:]]+skills)$ ]]; then
    if ! has_heading "$plan" 'Skill[[:space:]]+Evidence'; then
      echo "ERROR_FOR_AGENT: $plan declares skills '$skills' but lacks ## Skill Evidence."
      bad=1
    else
      evidence="$(section_body "$plan" 'Skill[[:space:]]+Evidence' | tr '[:upper:]' '[:lower:]')"
      while read -r raw || [ -n "$raw" ]; do
        key="$(norm_item "$raw")"
        [ -z "$key" ] && continue
        if ! printf '%s\n' "$evidence" | grep -Fq -- "$key"; then
          echo "ERROR_FOR_AGENT: $plan declares skill '$raw' but Skill Evidence does not mention it."
          bad=1
        fi
      done < <(printf '%s' "$skills" | tr ',;' '\n' | sed '/^[[:space:]]*$/d')
    fi
  fi

  if [ -n "$code" ] && list_has_item "$skills" rtk; then
    if has_heading "$plan" 'RTK[[:space:]]+Usage[[:space:]]+Waiver'; then
      waiver="$(section_body "$plan" 'RTK[[:space:]]+Usage[[:space:]]+Waiver')"
      if ! printf '%s\n' "$waiver" | tr '[:upper:]' '[:lower:]' | grep -q 'rtk'; then
        echo "ERROR_FOR_AGENT: $plan RTK Usage Waiver must mention RTK."
        bad=1
      fi
      if [ "$(printf '%s' "$waiver" | wc -c | tr -d ' ')" -lt 40 ]; then
        echo "ERROR_FOR_AGENT: $plan RTK Usage Waiver must explain why RTK decision-impact evidence is not available."
        bad=1
      fi
    elif ! has_heading "$plan" 'RTK[[:space:]]+Usage[[:space:]]+Evidence'; then
      echo "ERROR_FOR_AGENT: $plan declares rtk for code/config/test changes but lacks ## RTK Usage Evidence."
      bad=1
    else
      rtk_evidence="$(section_body "$plan" 'RTK[[:space:]]+Usage[[:space:]]+Evidence')"
      for marker in source action result decision; do
        if ! printf '%s\n' "$rtk_evidence" | grep -Eiq "(^|[^a-z])${marker}[[:space:]]*:"; then
          echo "ERROR_FOR_AGENT: $plan RTK Usage Evidence must include ${marker}: evidence."
          bad=1
        fi
      done
    fi
  fi

  templates_clean="$(clean "$templates")"
  if echo "$templates_clean" | grep -qE '(gap|missing|none|no[[:space:]]+template|not[[:space:]]+available|too[[:space:]]+heavy)'; then
    if [ -z "$knowledge" ] && ! has_heading "$plan" 'Template[[:space:]]+Gap[[:space:]]+Waiver'; then
      echo "ERROR_FOR_AGENT: $plan records a template gap but lacks changed learning/template artifact or ## Template Gap Waiver."
      bad=1
    fi
  fi

done

[ "$bad" -eq 0 ] || exit 1
echo "Workflow evidence checks passed."
