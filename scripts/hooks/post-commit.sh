#!/usr/bin/env bash
# post-commit hook — non-blocking reminders after a commit.
# Install: cp scripts/hooks/post-commit.sh .git/hooks/post-commit && chmod +x .git/hooks/post-commit
# Governing policy: core/workflow.md <workflow> (living plan) + core/learning-loop.md <learning_loop>

# workflow.md — the plan is a LIVING tracker. After each committed step, update it.
echo ""
echo "📋 workflow: commit recorded. Keep the plan a living tracker, not a one-time checkbox:"
echo "   → update .claude/plans/<task>.md ## Progress (what's done / next / blockers)"
echo "   → mirror the status in the Notion spec (mcp__Notion__notion-update-page)"

# learning-loop.md — a fix: commit should leave a lesson behind.
TYPE=$(git log -1 --pretty=%s | grep -oE '^[a-zA-Z]+')
if [ "$TYPE" = "fix" ]; then
  echo ""
  echo "📚 learning_loop: fix: commit detected."
  echo "   Root cause documented? → lessons-learned/bugs/ (use _TEMPLATE.md)"
  echo "   Regression test added? → see core/quality-gates.md <pre_commit_review>"
  echo "   If confidence ≥ Medium, promote to Engineering OS via PR."
fi
