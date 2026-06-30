#!/usr/bin/env bash
set -euo pipefail
lesson="${1:-}"
shift || true
[ -n "$lesson" ] || { echo "learning quality failed: missing lesson path" >&2; exit 1; }
blob() { git show ":$1" 2>/dev/null || true; }
section() {
  local file="$1" heading="$2"
  blob "$file" | awk -v re="^#{1,4}[[:space:]]+${heading}([[:space:]:/-]|$)" '
    $0 ~ re { on=1; next }
    on && $0 ~ /^#{1,4}[[:space:]]+/ { exit }
    on { print }
  '
}
word_count() { tr -cs '[:alnum:]_./-' '\n' | grep -E '.{3,}' | wc -l | tr -d ' '; }
meaningful() {
  local file="$1" heading="$2" min="$3" label="$4" text count
  text="$(section "$file" "$heading")"
  if printf '%s\n' "$text" | grep -qiE '\b(todo|tbd|placeholder|unknown|n/?a|none|fix later|not sure|unclear)\b'; then
    echo "learning quality failed: $file $label has placeholder text" >&2; exit 1
  fi
  count="$(printf '%s\n' "$text" | word_count)"
  [ "${count:-0}" -ge "$min" ] || { echo "learning quality failed: $file $label is too short" >&2; exit 1; }
}
path_ok() {
  local p="$1"; p="${p%%[.,;:)]}"
  [ -e "$p" ] && return 0
  git ls-files --error-unmatch "$p" >/dev/null 2>&1 && return 0
  return 1
}
section_has_path() {
  local file="$1" heading="$2" prefix="$3" label="$4" token
  while IFS= read -r token; do
    [ -n "$token" ] || continue
    printf '%s\n' "$token" | grep -Eq "$prefix" || continue
    path_ok "$token" && return 0
  done <<EOF_PATHS
$(section "$file" "$heading" | grep -Eo '([.]github|scripts|tests|test|src|core|docs)/[^ `)\]]+' || true)
EOF_PATHS
  echo "learning quality failed: $file $label must reference a tracked or staged path" >&2
  exit 1
}
meaningful "$lesson" 'שורש הבעיה' 10 'root cause'
meaningful "$lesson" 'ראיה' 8 'evidence'
meaningful "$lesson" 'איך מזהים מוקדם' 6 'early detection'
meaningful "$lesson" 'איך מונעים בעתיד' 8 'prevention'
section_has_path "$lesson" 'טסט רגרסיה' '^(scripts|tests|test|src)/' 'regression test'
if blob "$lesson" | grep -qiE '^#{1,4}[[:space:]]+Prevention[[:space:]/-]+Enforcement[[:space:]]+Update'; then
  section_has_path "$lesson" 'Prevention[[:space:]/-]+Enforcement[[:space:]]+Update' '^([.]github|scripts|tests|test)/' 'prevention update'
fi
lesson_text="$(blob "$lesson")"
for attempt in "$@"; do
  [ -n "$attempt" ] || continue
  related=0
  for token in $(basename "$attempt" .md | tr '_-' '  '); do
    [ "${#token}" -lt 4 ] && continue
    printf '%s\n' "$lesson_text" | grep -qi -- "$token" && related=1
  done
  [ "$related" -eq 1 ] || { echo "learning quality failed: $attempt is not referenced by $lesson" >&2; exit 1; }
done
echo "learning quality checks passed"
