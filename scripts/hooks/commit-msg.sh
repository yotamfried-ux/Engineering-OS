#!/usr/bin/env bash
# commit-msg hook — blocks commits missing required format sections or lying about tests
# Install: cp scripts/hooks/commit-msg.sh .git/hooks/commit-msg && chmod +x .git/hooks/commit-msg
# Governing policy: core/git-policy.md <commit_protocol>

MSG_FILE="$1"
MSG=$(cat "$MSG_FILE")

# Exempt merge/revert commits
case "$MSG" in "Merge "*|"Revert "*) exit 0 ;; esac

# Short commits (≤3 lines) are exempt — hotfixes, chore, ci tweaks
[ "$(echo "$MSG" | wc -l)" -le 3 ] && exit 0

has() { echo "$MSG" | grep -q "$1"; }
MISSING=""
has "✅" || MISSING="${MISSING}✅ "
has "❌" || MISSING="${MISSING}❌ "
has "🔄" || MISSING="${MISSING}🔄 "
has "🧪" || MISSING="${MISSING}🧪 "

if [ -n "$MISSING" ]; then
  echo "❌ COMMIT BLOCKED — commit message missing required sections: $MISSING"
  echo "   Format: ✅ עובד / ❌ לא עובד / 🔄 השתנה / 🧪 בדיקות"
  echo "   See: core/git-policy.md <commit_protocol>"
  exit 1
fi

# Block commits that claim "no tests" — forces explicit N/A justification
TEST_CONTENT=$(echo "$MSG" | grep -A3 "🧪" | tail -3)
if echo "$TEST_CONTENT" | grep -iE "^\s*(none|no tests?|אין|לא נכתבו)\s*$" >/dev/null 2>&1; then
  echo "❌ COMMIT BLOCKED — 🧪 section says 'none'."
  echo "   Either write tests, or document explicitly WHY N/A (e.g., 'chore: no logic changed')."
  echo "   Short commits (≤3 lines) are exempt from this check."
  exit 1
fi

exit 0
