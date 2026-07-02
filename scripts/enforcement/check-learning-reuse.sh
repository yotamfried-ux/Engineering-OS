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

section_items() {
  local file="$1" heading="$2"
  awk -v heading="$heading" '
    /^##[[:space:]]+/ {
      h=$0; sub(/^##[[:space:]]+/, "", h); gsub(/^[ \t]+|[ \t]+$/, "", h)
      if (tolower(h) == tolower(heading)) { found=1; next }
      if (found) exit
    }
    found { print }
  ' "$file" 2>/dev/null | sed -nE 's/^[[:space:]]*[-*][[:space:]]+//p' | sed -E 's/`//g; s/[[:space:]]+$//'
}

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

path_matches() {
  local target="$1" prefix="$2"
  target="$(printf '%s' "$target" | sed -E 's#^\./##')"
  prefix="$(printf '%s' "$prefix" | sed -E 's#^\./##; s#/$##')"
  [ -z "$prefix" ] && return 1
  case "$target" in
    "$prefix"|"$prefix"/*) return 0 ;;
    *) return 1 ;;
  esac
}

normalize_list() {
  printf '%s' "${1:-}" | tr ',;' '\n' | sed -E 's/<[^>]+>//g; s/`//g; s/^[-*[:space:]]+//; s/[[:space:]]+$//' | sed '/^$/d' | tr '[:upper:]' '[:lower:]'
}

plan_mentions_lesson() {
  local lesson="$1" base section
  base="$(basename "$lesson")"
  section="$(awk '/^##[[:space:]]+Lessons Reused/ { found=1; next } found && /^##[[:space:]]+/ { exit } found { print }' "$PLAN" 2>/dev/null)"
  printf '%s\n' "$section" | grep -qF "$lesson" && return 0
  printf '%s\n' "$section" | grep -qF "$base"
}

plan_tags="$(field_value "$PLAN" '^domain tags$|^domains$|^tags$')"
missing=""

for root in lessons-learned failed-solutions; do
  [ -d "$root" ] || continue
  while IFS= read -r lesson; do
    relevant=0
    while IFS= read -r path; do
      path_matches "$TARGET" "$path" && relevant=1
    done <<EOF_PATHS
$(section_items "$lesson" "Applies To Paths")
EOF_PATHS
    if [ "$relevant" -ne 1 ] && [ -n "$plan_tags" ]; then
      while IFS= read -r tag; do
        [ -z "$tag" ] && continue
        normalize_list "$plan_tags" | grep -qxF "$tag" && relevant=1
      done <<EOF_TAGS
$(section_items "$lesson" "Domain Tags" | tr '[:upper:]' '[:lower:]')
EOF_TAGS
    fi
    if [ "$relevant" -eq 1 ] && ! plan_mentions_lesson "$lesson"; then
      missing="${missing}${lesson} "
    fi
  done < <(find "$root" -type f -name '*.md' ! -name README.md ! -name _TEMPLATE.md | sort)
done

if [ -n "$missing" ]; then
  echo "learning reuse required: ${missing}" >&2
  exit 1
fi

# Citation direction: a lesson cited in "Lessons Reused" must actually be
# relevant (path- or tag-matched) to this write, so unrelated citations cannot
# wash the reuse evidence.
lesson_relevant() {
  local lesson="$1" path tag
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    path_matches "$TARGET" "$path" && return 0
  done <<EOF_PATHS
$(section_items "$lesson" "Applies To Paths")
EOF_PATHS
  if [ -n "$plan_tags" ]; then
    while IFS= read -r tag; do
      [ -z "$tag" ] && continue
      normalize_list "$plan_tags" | grep -qxF "$tag" && return 0
    done <<EOF_TAGS
$(section_items "$lesson" "Domain Tags" | tr '[:upper:]' '[:lower:]')
EOF_TAGS
  fi
  return 1
}

irrelevant=""
while IFS= read -r cited; do
  [ -n "$cited" ] || continue
  [ -f "$cited" ] || continue
  lesson_relevant "$cited" || irrelevant="${irrelevant}${cited} "
done < <(awk '/^##[[:space:]]+Lessons Reused/ { found=1; next } found && /^##[[:space:]]+/ { exit } found { print }' "$PLAN" 2>/dev/null \
  | grep -oE '(lessons-learned|failed-solutions)/[A-Za-z0-9_./-]+\.md' | sort -u)

if [ -n "$irrelevant" ]; then
  echo "learning reuse citation invalid: cited lesson(s) match neither the write target paths nor the plan domain tags: ${irrelevant}" >&2
  echo "Remove the unrelated citation, or add matching Applies To Paths / Domain Tags to the lesson if it truly applies." >&2
  exit 1
fi

echo "learning reuse checks passed"
