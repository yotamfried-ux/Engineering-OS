#!/usr/bin/env bash
set -euo pipefail

PLAN=""
TARGET=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --plan) PLAN="${2:-}"; shift 2 ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -n "$PLAN" ] && [ -f "$PLAN" ] || { echo "missing readable --plan" >&2; exit 2; }
[ -n "$TARGET" ] || { echo "missing --target" >&2; exit 2; }

field_value() {
  local plan_file="$1" field_re="$2"
  awk -F'|' -v re="$field_re" '
    NF > 1 {
      for (i = 1; i < NF; i++) {
        field = tolower($i); gsub(/[*_`]/, "", field); gsub(/^[ \t]+|[ \t]+$/, "", field)
        if (field ~ re) { value = $(i + 1); gsub(/^[ \t]+|[ \t]+$/, "", value); print value; exit }
      }
    }
  ' "$plan_file" 2>/dev/null || true
}

has_heading() { grep -qiE "^#{1,4}[[:space:]]+${2}([[:space:]]|$)" "$1" 2>/dev/null; }
section_text() {
  awk -v re="$2" '
    BEGIN { found=0 }
    /^#{1,4}[[:space:]]+/ { line=tolower($0); if (line ~ tolower(re)) { found=1; next }; if (found) exit }
    found { print }
  ' "$1" 2>/dev/null || true
}
canon_key() { printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]' | sed -E 's#^templates/##; s#/readme\.md$##; s#\.md$##; s/^[[:space:]]+|[[:space:]]+$//g; s/[^a-z0-9_-]+/-/g; s/^-+|-+$//g'; }
normalize_list() { printf '%s' "${1:-}" | tr ',;' '\n' | sed -E 's/<[^>]+>//g; s/`//g; s/^[-*[:space:]]+//; s/[[:space:]]+$//' | sed '/^$/d'; }
contains_template() {
  local wanted item
  wanted="$(canon_key "$1")"
  while IFS= read -r item; do [ -n "$item" ] && [ "$(canon_key "$item")" = "$wanted" ] && return 0; done <<EOF_LIST
$(normalize_list "$2")
EOF_LIST
  return 1
}
add_required() {
  local key="$1" reason="$2"
  key="$(canon_key "$key")"; [ -n "$key" ] || return 0
  case " $required " in *" $key "*) return 0 ;; esac
  required="$required $key"; reasons="${reasons}${key}: ${reason}; "
}
valid_template_waiver() {
  has_heading "$PLAN" 'Template[[:space:]]+Selection[[:space:]]+Waiver' || return 1
  local body
  body="$(section_text "$PLAN" 'template[[:space:]]+selection[[:space:]]+waiver' | sed -E '/^[[:space:]]*$/d; /^[[:space:]]*<!--/d')"
  [ "$(printf '%s' "$body" | wc -c | tr -d ' ')" -ge 20 ] || return 1
  printf '%s\n' "$body" | grep -qiE 'reason|because|fallback|not applicable|custom|manual|unsupported|environment|availability'
}

task="$(field_value "$PLAN" '^task class$|^task-class$|^type$')"
tags="$(field_value "$PLAN" '^domain tags$|^domains$|^tags$')"
templates="$(field_value "$PLAN" '^templates$|^template$')"
combined="$(printf '%s %s %s' "$task" "$tags" "$TARGET" | tr '[:upper:]' '[:lower:]')"
required=""; reasons=""

printf '%s' "$combined" | grep -qE 'saas|multi-tenant|subscription|billing' && add_required saas-platform "SaaS/subscription work should start from the SaaS platform template"
printf '%s' "$combined" | grep -qE 'booking|appointment|scheduler|calendar' && add_required booking-system "booking/scheduling work should use the booking-system template"
printf '%s' "$combined" | grep -qE 'api|rest|endpoint|microservice|server' && add_required api-service "API/server work should use the API service template"
printf '%s' "$combined" | grep -qE 'web|frontend|ui|ux|component|screen|page|react|next' && add_required web-application "web/frontend work should use the web application template"
printf '%s' "$combined" | grep -qE 'admin|dashboard|backoffice|control panel' && add_required admin-dashboard "admin/dashboard work should use the admin dashboard template"
printf '%s' "$combined" | grep -qE 'mobile|android|ios|expo|react native' && add_required mobile-application "mobile work should use the mobile application template"
printf '%s' "$combined" | grep -qE 'agent|ai-agent|multi-agent|llm|tool-calling' && add_required ai-agent "AI-agent work should use the AI agent template"
printf '%s' "$combined" | grep -qE 'data pipeline|etl|elt|analytics|warehouse|reporting' && add_required data-pipeline "data/analytics pipeline work should use the data pipeline template"
printf '%s' "$combined" | grep -qE 'automation|workflow|zapier|make|n8n' && add_required automation-system "automation work should use the automation system template"
printf '%s' "$combined" | grep -qE 'extension|browser extension|chrome' && add_required browser-extension "browser extension work should use the browser extension template"
printf '%s' "$combined" | grep -qE 'cli|command line|terminal tool' && add_required cli-tool "CLI work should use the CLI tool template"

[ -n "${required// /}" ] || { echo "required template checks passed"; exit 0; }

if has_heading "$PLAN" 'Template[[:space:]]+Selection[[:space:]]+Waiver'; then
  valid_template_waiver && { echo "required template checks passed via Template Selection Waiver"; exit 0; }
  echo "template selection waiver invalid: add a specific reason/fallback." >&2; exit 1
fi
missing=""
for tpl in $required; do contains_template "$tpl" "$templates" || missing="${missing}${tpl} "; done
[ -z "$missing" ] || { echo "required templates missing: ${missing}. Reasons: ${reasons}" >&2; echo "Add them to Templates, or add ## Template Selection Waiver with a specific reason/fallback." >&2; exit 1; }
echo "required template checks passed"
