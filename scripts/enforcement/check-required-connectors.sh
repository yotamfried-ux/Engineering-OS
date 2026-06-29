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

has_heading() {
  local file="$1" heading_re="$2"
  grep -qiE "^#{1,4}[[:space:]]+${heading_re}([[:space:]]|$)" "$file" 2>/dev/null
}

section_text() {
  local file="$1" heading_re="$2"
  awk -v re="$heading_re" '
    BEGIN { found=0 }
    /^#{1,4}[[:space:]]+/ {
      line=tolower($0)
      if (line ~ tolower(re)) { found=1; next }
      if (found) exit
    }
    found { print }
  ' "$file" 2>/dev/null || true
}

canon_key() {
  printf '%s' "${1:-}" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/^mcp__//; s/__.*$//; s/^[[:space:]]+|[[:space:]]+$//g; s/[^a-z0-9_-]+/-/g; s/^-+|-+$//g'
}

normalize_list() {
  printf '%s' "${1:-}" \
    | tr ',;' '\n' \
    | sed -E 's/<[^>]+>//g; s/`//g; s/^[-*[:space:]]+//; s/[[:space:]]+$//' \
    | sed '/^$/d'
}

contains_connector() {
  local wanted="$1" list="$2" item
  wanted="$(canon_key "$wanted")"
  while IFS= read -r item; do
    [ -n "$item" ] || continue
    [ "$(canon_key "$item")" = "$wanted" ] && return 0
  done <<EOF_LIST
$(normalize_list "$list")
EOF_LIST
  return 1
}

add_required() {
  local key="$1" reason="$2"
  key="$(canon_key "$key")"
  [ -n "$key" ] || return 0
  case " $required " in *" $key "*) return 0 ;; esac
  required="$required $key"
  reasons="${reasons}${key}: ${reason}; "
}

valid_connector_waiver() {
  has_heading "$PLAN" 'Connector[[:space:]]+Selection[[:space:]]+Waiver' || return 1
  local body
  body="$(section_text "$PLAN" 'connector[[:space:]]+selection[[:space:]]+waiver' | sed -E '/^[[:space:]]*$/d; /^[[:space:]]*<!--/d')"
  [ "$(printf '%s' "$body" | wc -c | tr -d ' ')" -ge 20 ] || return 1
  printf '%s\n' "$body" | grep -qiE 'reason|because|fallback|unavailable|availability|manual|unsupported|environment'
}

task="$(field_value "$PLAN" '^task class$|^task-class$|^type$')"
tags="$(field_value "$PLAN" '^domain tags$|^domains$|^tags$')"
connectors="$(field_value "$PLAN" '^external systems/connectors$|^external systems$|^external connectors$|^connectors$')"
combined="$(printf '%s %s %s' "$task" "$tags" "$TARGET" | tr '[:upper:]' '[:lower:]')"
required=""
reasons=""

if printf '%s' "$combined" | grep -qE 'code|bug|debug|feature|refactor|engineering_os|governance|hook|enforcement|script|repo|github|\.github|pull|pr|branch|merge|commit'; then
  add_required github "repo/code/PR state must be read from GitHub rather than guessed"
fi

if printf '%s' "$combined" | grep -qE 'code_change|bug|debug|incident|rollback|hotfix|regression|feature|refactor|new_project|saas|engineering_os|governance|implementation|architecture|multi-file|non-trivial'; then
  add_required notion "non-trivial work must be planned and progress-validated in Notion"
fi

if printf '%s' "$combined" | grep -qE 'api|sdk|library|framework|package|dependency|npm|pip|stripe|supabase|firebase|clerk|vercel|react|next|expo|openai|anthropic'; then
  add_required context7 "API/library/framework work needs current official documentation"
fi

if printf '%s' "$combined" | grep -qE 'debug|bug|incident|rollback|hotfix|regression|crash|sentry|production[ -_]*(failure|bug|incident)'; then
  add_required sentry "debugging/incident work must inspect runtime error data when available"
fi

if printf '%s' "$combined" | grep -qE 'supabase|database|db|sql|migration|rls|storage|data|auth table|row level'; then
  add_required supabase "database/auth/data state must be queried from the configured backend"
fi

if printf '%s' "$combined" | grep -qE 'vercel|deploy|deployment|hosting|production|env|environment variable|release'; then
  add_required vercel "deployment/environment state must be validated from the hosting platform"
fi

if printf '%s' "$combined" | grep -qE 'figma|ui|ux|design|frontend|component|screen|wireframe|prototype'; then
  add_required figma "UI/UX/design work must use the design source-of-truth when available"
fi

if printf '%s' "$combined" | grep -qE 'expo|mobile|android|ios|react native|app build|apk|ipa'; then
  add_required expo "mobile build/deploy state must be validated through Expo when applicable"
fi

if printf '%s' "$combined" | grep -qE 'postman|endpoint|http|rest|api test|webhook|request|response'; then
  add_required postman "API endpoints/integrations need request/response validation"
fi

[ -n "${required// /}" ] || { echo "required connector checks passed"; exit 0; }

if has_heading "$PLAN" 'Connector[[:space:]]+Selection[[:space:]]+Waiver'; then
  if valid_connector_waiver; then
    echo "required connector checks passed via Connector Selection Waiver"
    exit 0
  fi
  echo "connector selection waiver invalid: add a specific fallback or availability reason." >&2
  exit 1
fi

missing=""
for conn in $required; do
  contains_connector "$conn" "$connectors" || missing="${missing}${conn} "
done

if [ -n "$missing" ]; then
  echo "required connectors missing: ${missing}. Reasons: ${reasons}" >&2
  echo "Add them to External systems/connectors, or add ## Connector Selection Waiver with a specific fallback or availability reason." >&2
  exit 1
fi

if contains_connector notion "$connectors"; then
  has_heading "$PLAN" 'Notion[[:space:]]+Progress[[:space:]]+Validation' || {
    echo "notion progress validation missing: Notion must be updated and re-validated during non-trivial work." >&2
    exit 1
  }
fi

echo "required connector checks passed"
