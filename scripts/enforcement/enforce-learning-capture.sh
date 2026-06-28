#!/usr/bin/env bash
set -euo pipefail

# enforce-learning-capture.sh — deterministic capture gate for core/learning-loop.md
#
# Blocks bug/debug/incident/rollback implementation commits unless the staged diff
# includes a new/changed lesson, a failed-solution record, or the active Route Plan
# contains an explicit ## Learning Capture Waiver.
#
# Governing policy: core/learning-loop.md (<learning_loop> / מתי לתעד).
# Bypass: EOS_BYPASS_LEARNING_CAPTURE=1 or EOS_BYPASS_LEARNING=1.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
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
  grep -qiE "^#{1,4}[[:space:]]+${heading_re}([[:space:]]|$)" "$file" 2>/dev/null
}

select_plan() {
  if [ -n "${EOS_ACTIVE_PLAN:-}" ] && [ -f "${EOS_ACTIVE_PLAN:-}" ]; then
    printf '%s\n' "$EOS_ACTIVE_PLAN"
    return 0
  fi
  if [ -f .claude/plans/active.md ]; then
    printf '%s\n' .claude/plans/active.md
    return 0
  fi
  local candidate
  for candidate in $(ls -t .claude/plans/*.md 2>/dev/null || true); do
    case "$(basename "$candidate")" in README.md|_TEMPLATE.md) continue ;; esac
    printf '%s\n' "$candidate"
    return 0
  done
}

plan="$(select_plan || true)"
[ -n "$plan" ] || exit 0

requires_capture() {
  local plan_file="$1" task tags combined
  task="$(field_value "$plan_file" '^task class$|^task-class$|^type$')"
  tags="$(field_value "$plan_file" '^domain tags$|^domains$|^tags$')"
  combined="$(printf '%s %s' "$task" "$tags" | tr '[:upper:]' '[:lower:]')"
  printf '%s' "$combined" | grep -qE 'bug|debug|incident|rollback|hotfix|regression|production[ -_]*(failure|bug|incident)|post[ -_]*mortem'
}

requires_capture "$plan" || exit 0

if has_heading "$plan" 'Learning[[:space:]]+Capture[[:space:]]+Waiver'; then
  exit 0
fi

capture_staged="$(printf '%s\n' "$staged" | grep -E '^(lessons-learned/bugs/[^/]+\.md|failed-solutions/[^/]+\.md)$' | grep -vE '/(README|_TEMPLATE)\.md$' || true)"
if [ -n "$capture_staged" ]; then
  exit 0
fi

echo "❌ COMMIT BLOCKED — learning-loop.md: bug/debug/incident work requires learning capture." >&2
echo "   Active plan: $plan" >&2
echo "   ACTION: stage one of:" >&2
echo "     - lessons-learned/bugs/<lesson>.md with the required lesson schema;" >&2
echo "     - failed-solutions/<attempt>.md with the required failed-solution schema;" >&2
echo "     - or add ## Learning Capture Waiver to the active Route Plan explaining why no lesson is required." >&2
echo "   BYPASS: EOS_BYPASS_LEARNING_CAPTURE=1 — only with explicit user authorization." >&2
exit 1
