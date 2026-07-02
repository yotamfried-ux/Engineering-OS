#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLAN=""
TARGET=""
MANIFEST="$SCRIPT_DIR/connector-requirements.tsv"
INVENTORY="$ROOT/external-systems/README.md"
CHECK_COVERAGE=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --plan) PLAN="${2:-}"; shift 2 ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    --manifest) MANIFEST="${2:-}"; shift 2 ;;
    --inventory) INVENTORY="${2:-}"; shift 2 ;;
    --check-coverage) CHECK_COVERAGE=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -f "$MANIFEST" ] || { echo "missing connector requirements manifest: $MANIFEST" >&2; exit 2; }

# validate_manifest — every row needs connector, mode (auto|manual), ERE for auto
# rows, and a concrete reason. Malformed rows fail closed.
validate_manifest() {
  local conn mode ere reason extra bad=0
  while IFS=$'\t' read -r conn mode ere reason extra; do
    case "${conn:-}" in ''|'#'*) continue ;; esac
    if [ -n "${extra:-}" ]; then echo "connector manifest malformed: $conn has too many columns" >&2; bad=1; continue; fi
    [ -n "$mode" ] && [ -n "$ere" ] && [ -n "$reason" ] || { echo "connector manifest malformed: $conn is missing fields" >&2; bad=1; continue; }
    case "$mode" in
      auto) : ;;
      manual) : ;;
      *) echo "connector manifest malformed: $conn has invalid mode '$mode'" >&2; bad=1 ;;
    esac
    [ "$(printf '%s' "$reason" | wc -c | tr -d ' ')" -ge 20 ] || { echo "connector manifest malformed: $conn reason is too short" >&2; bad=1; }
  done < "$MANIFEST"
  return "$bad"
}

# check_coverage — every connectors/<name>/ entry in the external-systems
# inventory must have a manifest row, so new connectors cannot be silently
# unselectable.
check_coverage() {
  local bad=0 name
  [ -f "$INVENTORY" ] || { echo "missing connector inventory: $INVENTORY" >&2; return 1; }
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    grep -qE "^${name}	" "$MANIFEST" || { echo "connector inventory coverage failed: '$name' has no row in $(basename "$MANIFEST")" >&2; bad=1; }
  done < <(grep -oE 'connectors/[a-z0-9-]+/' "$INVENTORY" | sed -E 's#connectors/([a-z0-9-]+)/#\1#' | sort -u)
  return "$bad"
}

validate_manifest || exit 2
if [ "$CHECK_COVERAGE" -eq 1 ]; then
  check_coverage || exit 1
  echo "connector requirements coverage passed"
  exit 0
fi

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

while IFS=$'\t' read -r conn mode ere reason _extra; do
  case "${conn:-}" in ''|'#'*) continue ;; esac
  [ "$mode" = "auto" ] || continue
  printf '%s' "$combined" | grep -qE "$ere" && add_required "$conn" "$reason"
done < "$MANIFEST"

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
