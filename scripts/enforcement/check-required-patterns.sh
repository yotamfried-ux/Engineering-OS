#!/usr/bin/env bash
# check-required-patterns.sh — registry-driven required-pattern selection gate.
#
# When a Route Plan domain tag exactly matches a pattern domain declared in
# patterns/registry.yaml, the plan must consult that domain's patterns: the
# Patterns field must name a patterns/<domain>/ asset, or the plan must carry a
# ## Pattern Selection Waiver naming the domain (or "all"). Matching is exact
# tag-to-domain equality, never substrings, so unrelated tags are not forced.
# Pattern-fit judgment beyond domain consultation stays review-based by design.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLAN=""
TARGET=""
REGISTRY="$ROOT/patterns/registry.yaml"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --plan) PLAN="${2:-}"; shift 2 ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    --registry) REGISTRY="${2:-}"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -n "$PLAN" ] && [ -f "$PLAN" ] || { echo "missing readable --plan" >&2; exit 2; }
[ -n "$TARGET" ] || { echo "missing --target" >&2; exit 2; }
[ -f "$REGISTRY" ] || { echo "missing pattern registry: $REGISTRY" >&2; exit 2; }

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

normalize_list() {
  printf '%s' "${1:-}" \
    | tr ',;' '\n' \
    | sed -E 's/<[^>]+>//g; s/`//g; s/^[-*[:space:]]+//; s/[[:space:]]+$//; s/^[[:space:]]+//' \
    | sed '/^$/d' \
    | tr '[:upper:]' '[:lower:]'
}

# Fail closed on an unreadable/empty registry: no domains means nothing can be
# required, so an empty extraction is an error (validated once, at top level,
# not inside a subshell where exit would be swallowed).
DOMAINS="$(sed -nE 's/^[[:space:]]+domain:[[:space:]]*([a-z0-9-]+)[[:space:]]*$/\1/p' "$REGISTRY" | sort -u)"
if [ -z "$DOMAINS" ]; then
  echo "pattern registry malformed: no 'domain:' entries found in $REGISTRY" >&2
  exit 2
fi

plan_waives_domain() {
  local domain="$1"
  awk '/^##[[:space:]]+Pattern Selection Waiver/ { found=1; next } found && /^##[[:space:]]+/ { exit } found { print }' "$PLAN" 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | grep -Eq "(^|[^a-z0-9_-])(${domain}|all|pattern-selection)([^a-z0-9_-]|$)"
}

TAGS="$(field_value "$PLAN" '^domain tags$|^domains$|^tags$')"
PATTERNS="$(field_value "$PLAN" '^patterns$|^pattern$')"
missing=""

while IFS= read -r tag; do
  [ -n "$tag" ] || continue
  printf '%s\n' "$DOMAINS" | grep -qxF "$tag" || continue
  if printf '%s' "$PATTERNS" | tr '[:upper:]' '[:lower:]' | grep -q "patterns/${tag}"; then
    continue
  fi
  plan_waives_domain "$tag" && continue
  missing="${missing}${tag} "
done <<EOF_TAGS
$(normalize_list "$TAGS")
EOF_TAGS

if [ -n "$missing" ]; then
  echo "required patterns missing: domain tag(s) [${missing% }] match patterns/registry.yaml domains, but the Patterns field names no patterns/<domain>/ asset." >&2
  echo "Add the domain's patterns/ asset to the Patterns field, or add ## Pattern Selection Waiver naming the domain with a reason." >&2
  exit 1
fi

echo "required pattern selection checks passed"
