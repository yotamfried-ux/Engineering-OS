#!/usr/bin/env bash
# post-commit hook — reminds to document root cause after fix: commits
# Install: cp scripts/hooks/post-commit.sh .git/hooks/post-commit && chmod +x .git/hooks/post-commit
# Governing policy: core/learning-loop.md <learning_loop>

TYPE=$(git log -1 --pretty=%s | grep -oE '^[a-zA-Z]+')
[ "$TYPE" != "fix" ] && exit 0

echo ""
echo "📚 learning_loop: fix: commit detected."
echo "   Root cause documented? → lessons-learned/bugs/"
echo "   Regression test added? → see core/quality-gates.md <pre_commit_review>"
echo "   If confidence ≥ Medium, promote to Engineering OS via PR."
