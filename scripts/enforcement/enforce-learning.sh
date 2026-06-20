#!/usr/bin/env bash
# enforce-learning.sh — deterministic enforcer for core/learning-loop.md
#
# learning-loop.md is mostly judgment (the loop, confidence levels, post-mortem,
# knowledge maturation, the Prevented counter). The one deterministic rule is the
# fixed LESSON SCHEMA — and making it uniform is precisely what lets the loop work
# programmatically (query / promote / count lessons). Until now the corpus was
# inconsistent, so the loop "didn't work at all". This enforces structure:
#
#   L1 (BLOCK) — every staged lessons-learned/bugs/*.md (except README/_TEMPLATE)
#                must contain the required lesson sections.
#   L2 (BLOCK) — every staged failed-solutions/*.md (except README/_TEMPLATE)
#                must contain the short schema (tried / why it failed / what to try).
#
# Excluded by design: prevention-strategies/ and postmortems/ (separate documented
# formats), and README.md / _TEMPLATE.md helper files.
#
# Invoked from scripts/hooks/pre-commit.sh. Master bypass: EOS_BYPASS_LEARNING=1.
# Governing policy: core/learning-loop.md (סכמת לקח קבועה).

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
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
[ -z "$staged" ] && exit 0

# Required section headers (## <name>) per file type. A header matches if the line
# starts with "## " and contains the phrase (so "## ראיה" or "## ראיה (logs)" both pass).
LESSON_SECTIONS="מה קרה|שורש הבעיה|ראיה|רמת ביטחון|איך מונעים בעתיד|טסט רגרסיה|סטטוס הבשלה|Prevented Future Issues"
FAILSOL_SECTIONS="מה ניסיתי|למה לא עבד|מה לבדוק במקום"

# is_excluded <path> — only README.md and _TEMPLATE.md helpers are not lessons.
# (Scoped narrowly so a lesson can't bypass the gate by being named "_foo.md".)
is_excluded() { case "$(basename "$1")" in README.md|_TEMPLATE.md) return 0 ;; *) return 1 ;; esac; }

# missing_sections <file> <pipe-separated-sections> — echo the sections absent.
# Validates the STAGED blob (git show :path), not the working tree, so a file that
# was staged valid then edited (unstaged) is judged on what will actually commit.
missing_sections() {
  local file="$1" want="$2" sec miss="" content
  content="$(git show ":$file" 2>/dev/null || cat -- "$file" 2>/dev/null || true)"
  local IFS='|'
  for sec in $want; do
    printf '%s\n' "$content" | grep -qE "^##[[:space:]].*$sec" || miss="$miss$sec\n"
  done
  printf '%b' "$miss"
}

fail=0

while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ -f "$f" ] || continue
  case "$f" in
    lessons-learned/bugs/*.md)
      is_excluded "$f" && continue
      miss="$(missing_sections "$f" "$LESSON_SECTIONS")"
      if [ -n "$miss" ]; then
        if ! bypass_active EOS_BYPASS_LESSON; then
          echo "❌ COMMIT BLOCKED — learning-loop.md: lesson '$f' is missing required schema sections:"
          printf '%s' "$miss" | sed 's/^/    ## /'
          echo "  Use lessons-learned/bugs/_TEMPLATE.md as the structure. BYPASS: EOS_BYPASS_LESSON=1 (or EOS_BYPASS_LEARNING=1)."
          fail=1
        fi
      fi
      ;;
    failed-solutions/*.md)
      is_excluded "$f" && continue
      miss="$(missing_sections "$f" "$FAILSOL_SECTIONS")"
      if [ -n "$miss" ]; then
        if ! bypass_active EOS_BYPASS_FAILSOL; then
          echo "❌ COMMIT BLOCKED — learning-loop.md: failed-solution '$f' is missing required sections:"
          printf '%s' "$miss" | sed 's/^/    ## /'
          echo "  Use failed-solutions/_TEMPLATE.md as the structure. BYPASS: EOS_BYPASS_FAILSOL=1 (or EOS_BYPASS_LEARNING=1)."
          fail=1
        fi
      fi
      ;;
  esac
done <<EOF
$staged
EOF

exit "$fail"
