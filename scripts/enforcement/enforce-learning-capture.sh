#!/usr/bin/env bash
set -euo pipefail

# enforce-learning-capture.sh — deterministic capture gate for core/learning-loop.md
#
# Bug/debug/incident/rollback implementation work must stage a complete lesson.
# Failed-solutions are additional evidence, not a substitute for the bug lesson.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true
if ! declare -f bypass_active >/dev/null 2>&1; then
  bypass_active() {
    local name="${1:-}"; [ -z "$name" ] && return 1
    case "${!name:-}" in 1|true|TRUE|yes|YES) return 0 ;; *) return 1 ;; esac
  }
fi

bypass_active EOS_BYPASS_LEARNING && exit 0
bypass_active EOS_BYPASS_LEARNING_CAPTURE && exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
[ -n "$staged" ] || exit 0

code_staged="$(printf '%s\n' "$staged" | grep -E '\.(ts|tsx|js|jsx|py|go|rs|java|kt|rb|cs|cpp|c|h|php|scala|lua|sh|bash|zsh)$' || true)"
[ -n "$code_staged" ] || exit 0

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

has_heading() {
  local file="$1" heading_re="$2"
  grep -qiE "^#{1,4}[[:space:]]+${heading_re}([[:space:]:]|$)" "$file" 2>/dev/null
}

staged_blob_has_heading() {
  local path="$1" heading="$2"
  git show ":$path" 2>/dev/null | grep -qiE "^#{1,4}[[:space:]]+${heading}([[:space:]:]|$)"
}

complete_staged_lesson() {
  local path="$1" missing=""
  for heading in \
    'מה קרה' \
    'שורש הבעיה' \
    'השערות שנבדקו' \
    'ראיה' \
    'רמת ביטחון' \
    'איך מזהים מוקדם' \
    'איך מונעים בעתיד' \
    'טסט רגרסיה' \
    'סטטוס הבשלה' \
    'Prevented Future Issues'; do
    staged_blob_has_heading "$path" "$heading" || missing="${missing}${heading}; "
  done
  if ! staged_blob_has_heading "$path" 'Prevention[[:space:]/-]+Enforcement[[:space:]]+Update' \
     && ! staged_blob_has_heading "$path" 'Prevention[[:space:]/-]+Enforcement[[:space:]]+Waiver' \
     && ! staged_blob_has_heading "$path" 'עדכון[[:space:]/-]+מניעה[[:space:]/-]+אכיפה' \
     && ! staged_blob_has_heading "$path" 'ויתור[[:space:]/-]+מניעה[[:space:]/-]+אכיפה'; then
    missing="${missing}Prevention/Enforcement Update or Waiver; "
  fi
  [ -z "$missing" ] || { echo "learning capture failed: staged lesson '$path' is incomplete: ${missing}" >&2; return 1; }
}

select_plan() {
  if [ -n "${EOS_ACTIVE_PLAN:-}" ] && [ -f "${EOS_ACTIVE_PLAN:-}" ]; then printf '%s\n' "$EOS_ACTIVE_PLAN"; return 0; fi
  if [ -f .claude/plans/active.md ]; then printf '%s\n' .claude/plans/active.md; return 0; fi
  local candidate
  for candidate in $(ls -t .claude/plans/*.md 2>/dev/null || true); do
    case "$(basename "$candidate")" in README.md|_TEMPLATE.md) continue ;; esac
    printf '%s\n' "$candidate"; return 0
  done
}

plan="$(select_plan || true)"
[ -n "$plan" ] || exit 0

requires_full_lesson() {
  local plan_file="$1" task tags combined
  task="$(field_value "$plan_file" '^task class$|^task-class$|^type$')"
  tags="$(field_value "$plan_file" '^domain tags$|^domains$|^tags$')"
  combined="$(printf '%s %s' "$task" "$tags" | tr '[:upper:]' '[:lower:]')"
  printf '%s' "$combined" | grep -qE 'bug|debug|incident|rollback|hotfix|regression|production[ -_]*(failure|bug|incident)|post[ -_]*mortem'
}

requires_full_lesson "$plan" || exit 0

lesson_staged="$(printf '%s\n' "$staged" | grep -E '^lessons-learned/bugs/[^/]+\.md$' | grep -vE '/(README|_TEMPLATE)\.md$' || true)"
if [ -n "$lesson_staged" ]; then
  while IFS= read -r lesson; do
    [ -n "$lesson" ] || continue
    complete_staged_lesson "$lesson" || exit 1
  done <<EOF_LESSONS
$lesson_staged
EOF_LESSONS
  exit 0
fi

failed_staged="$(printf '%s\n' "$staged" | grep -E '^failed-solutions/[^/]+\.md$' | grep -vE '/(README|_TEMPLATE)\.md$' || true)"

if has_heading "$plan" 'Learning[[:space:]]+Capture[[:space:]]+Waiver'; then
  echo "learning capture failed: waiver cannot replace a bug/debug/incident lesson." >&2
  echo "active plan: $plan" >&2
  echo "action: stage lessons-learned/bugs/<lesson>.md with the full required schema." >&2
  exit 1
fi

if [ -n "$failed_staged" ]; then
  echo "learning capture failed: failed-solution staged but no bug lesson staged." >&2
  echo "active plan: $plan" >&2
  echo "action: also stage lessons-learned/bugs/<lesson>.md with root cause, evidence, prevention, regression test, and maturity status." >&2
  exit 1
fi

echo "learning capture failed: bug/debug/incident work requires a full lesson." >&2
echo "active plan: $plan" >&2
echo "action: stage lessons-learned/bugs/<lesson>.md with the required lesson schema." >&2
exit 1
