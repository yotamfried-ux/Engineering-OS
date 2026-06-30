#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "${EOS_BYPASS_LEARNING:-}" in 1|true|TRUE|yes|YES) exit 0;; esac
case "${EOS_BYPASS_LEARNING_CAPTURE:-}" in 1|true|TRUE|yes|YES) exit 0;; esac
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
[ -n "$staged" ] || exit 0
printf '%s\n' "$staged" | grep -Eq '\.(ts|tsx|js|jsx|py|go|rs|java|kt|rb|cs|cpp|c|h|php|scala|lua|sh|bash|zsh)$' || exit 0
field() { awk -F'|' -v re="$2" 'NF>1{for(i=1;i<NF;i++){x=tolower($i);gsub(/[*_`]/,"",x);gsub(/^[ \t]+|[ \t]+$/,"",x);if(x~re){v=$(i+1);gsub(/^[ \t]+|[ \t]+$/,"",v);print v;exit}}}' "$1" 2>/dev/null || true; }
head_has() { git show ":$1" 2>/dev/null | grep -qiE "^#{1,4}[[:space:]]+$2([[:space:]:]|$)"; }
plan="${EOS_ACTIVE_PLAN:-}"
[ -n "$plan" ] && [ -f "$plan" ] || plan=".claude/plans/active.md"
[ -f "$plan" ] || plan="$(ls -t .claude/plans/*.md 2>/dev/null | grep -vE '/(README|_TEMPLATE)\.md$' | head -n1 || true)"
[ -n "$plan" ] || exit 0
meta="$(printf '%s %s' "$(field "$plan" '^task class$|^task-class$|^type$')" "$(field "$plan" '^domain tags$|^domains$|^tags$')" | tr '[:upper:]' '[:lower:]')"
printf '%s' "$meta" | grep -qE 'bug|debug|incident|rollback|hotfix|regression|production[ -_]*(failure|bug|incident)|post[ -_]*mortem' || exit 0
lessons="$(printf '%s\n' "$staged" | grep -E '^lessons-learned/bugs/[^/]+\.md$' | grep -vE '/(README|_TEMPLATE)\.md$' || true)"
attempts="$(printf '%s\n' "$staged" | grep -E '^failed-solutions/[^/]+\.md$' | grep -vE '/(README|_TEMPLATE)\.md$' || true)"
if grep -qiE '^#{1,4}[[:space:]]+Learning[[:space:]]+Capture[[:space:]]+Waiver([[:space:]:]|$)' "$plan" 2>/dev/null; then
  echo "learning capture failed: waiver cannot replace required lesson." >&2; exit 1
fi
[ -n "$lessons" ] || { echo "learning capture failed: required lesson missing." >&2; exit 1; }
while IFS= read -r lesson; do
  [ -n "$lesson" ] || continue
  for h in 'מה קרה' 'שורש הבעיה' 'השערות שנבדקו' 'ראיה' 'רמת ביטחון' 'איך מזהים מוקדם' 'איך מונעים בעתיד' 'טסט רגרסיה' 'סטטוס הבשלה' 'Prevented Future Issues'; do
    head_has "$lesson" "$h" || { echo "learning capture failed: $lesson missing $h" >&2; exit 1; }
  done
  if ! head_has "$lesson" 'Prevention[[:space:]/-]+Enforcement[[:space:]]+Update' && ! head_has "$lesson" 'Prevention[[:space:]/-]+Enforcement[[:space:]]+Waiver' && ! head_has "$lesson" 'עדכון[[:space:]/-]+מניעה[[:space:]/-]+אכיפה' && ! head_has "$lesson" 'ויתור[[:space:]/-]+מניעה[[:space:]/-]+אכיפה'; then
    echo "learning capture failed: $lesson missing prevention update or waiver" >&2; exit 1
  fi
  bash "$DIR/check-learning-quality.sh" "$lesson" $attempts >/dev/null || exit 1
done <<EOF
$lessons
EOF
