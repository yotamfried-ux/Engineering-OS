#!/usr/bin/env bash
set -euo pipefail
lesson="${1:-}"
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
meaningful "$lesson" 'שורש הבעיה' 10 'root cause'
meaningful "$lesson" 'ראיה' 8 'evidence'
meaningful "$lesson" 'איך מזהים מוקדם' 6 'early detection'
meaningful "$lesson" 'איך מונעים בעתיד' 8 'prevention'
echo "learning quality checks passed"
