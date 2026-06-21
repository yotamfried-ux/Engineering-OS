#!/bin/bash
# Engineering OS — portable pre-commit hook
# Drop into <project>/.git/hooks/pre-commit and chmod +x
# Blocks commits if linter, tests, or physical test-file scan fails.
# Install: cp scripts/hooks/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

set -e

STAGED=$(git diff --cached --name-only)

# md ↔ enforcer sync — changing a policy md requires updating its enforcer.
# Governing policy: core/hooks-policy.md <hooks>. Bypass: EOS_BYPASS_MDSYNC=1
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
if [ -f "$REPO_ROOT/scripts/enforcement/enforce-sync.sh" ]; then
  bash "$REPO_ROOT/scripts/enforcement/enforce-sync.sh" || exit 1
fi

# quality-gates.md <cleanup> — block debug leftovers (debugger/pdb/pry, conflict markers)
# in the staged diff. Governing policy: core/quality-gates.md. Bypass: EOS_BYPASS_CLEANUP=1.
if [ -f "$REPO_ROOT/scripts/enforcement/enforce-quality.sh" ]; then
  bash "$REPO_ROOT/scripts/enforcement/enforce-quality.sh" || exit 1
fi

# resource-management.md <claudeignore> — every project must have a .claudeignore.
# Governing policy: core/resource-management.md. Bypass: EOS_BYPASS_CLAUDEIGNORE=1.
if [ -f "$REPO_ROOT/scripts/enforcement/enforce-resource.sh" ]; then
  bash "$REPO_ROOT/scripts/enforcement/enforce-resource.sh" precommit || exit 1
fi

# connector-policy.md <environment> — block staged .env files and hardcoded secrets.
# Governing policy: core/connector-policy.md. Bypass: EOS_BYPASS_CONNECTOR=1.
if [ -f "$REPO_ROOT/scripts/enforcement/enforce-connector.sh" ]; then
  bash "$REPO_ROOT/scripts/enforcement/enforce-connector.sh" || exit 1
fi

# learning-loop.md — enforce the fixed lesson schema on staged lessons-learned/bugs
# and failed-solutions files. Governing policy: core/learning-loop.md. Bypass: EOS_BYPASS_LEARNING=1.
if [ -f "$REPO_ROOT/scripts/enforcement/enforce-learning.sh" ]; then
  bash "$REPO_ROOT/scripts/enforcement/enforce-learning.sh" || exit 1
fi

# skill-orchestration-policy.md — every external-skills/<name>/ needs its 4 contract
# files + a registry entry. Governing policy: core/skill-orchestration-policy.md. Bypass: EOS_BYPASS_SKILL=1.
if [ -f "$REPO_ROOT/scripts/enforcement/enforce-skill.sh" ]; then
  bash "$REPO_ROOT/scripts/enforcement/enforce-skill.sh" || exit 1
fi

# documentation-policy.md — content dirs + root need README; no TBD placeholders in
# staged docs. Governing policy: core/documentation-policy.md. Bypass: EOS_BYPASS_DOC=1.
if [ -f "$REPO_ROOT/scripts/enforcement/enforce-documentation.sh" ]; then
  bash "$REPO_ROOT/scripts/enforcement/enforce-documentation.sh" || exit 1
fi

# Repo-wide gates above run on every commit (incl. --allow-empty); the remaining
# checks operate on staged content, so short-circuit empty commits here.
[ -z "$STAGED" ] && exit 0

# Block accidental deletion of CLAUDE.md — it is the Engineering OS entry point
if echo "$STAGED" | grep -q "^CLAUDE\.md$"; then
  if ! git show ":CLAUDE.md" > /dev/null 2>&1; then
    echo "❌ BLOCKED: Cannot delete CLAUDE.md — it is the Engineering OS entry point."
    echo "   If intentional, bypass with: SKIP_CLAUDE_CHECK=1 git commit"
    [ "${SKIP_CLAUDE_CHECK:-}" = "1" ] || exit 1
  fi
fi

# quality-gates.md <pre_commit_review> — run EVERY detected stack's lint+test (node,
# python, go, rust, make, shell). A failing check blocks; a missing tool warns.
# Governing policy: core/quality-gates.md. Bypass: EOS_BYPASS_TESTS=1.
# (The "project has zero tests" scan moved to commit-msg.sh, where the commit TYPE
#  is available so chore/docs/… can be exempted correctly.)
if [ -f "$REPO_ROOT/scripts/enforcement/enforce-tests.sh" ]; then
  bash "$REPO_ROOT/scripts/enforcement/enforce-tests.sh" || exit 1
fi

# workflow.md — living-plan reminder (non-blocking). If the newest plan file is older
# than a staged file, the plan probably wasn't updated for this change. The plan is a
# living tracker, not a one-time checkbox.
if [ -d "$REPO_ROOT/.claude/plans" ]; then
  NEWEST_PLAN="$(ls -t "$REPO_ROOT"/.claude/plans/*.md 2>/dev/null | head -1 || true)"
  if [ -n "$NEWEST_PLAN" ]; then
    PLAN_STALE=0
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      [ -f "$REPO_ROOT/$f" ] || continue
      if [ "$REPO_ROOT/$f" -nt "$NEWEST_PLAN" ]; then PLAN_STALE=1; break; fi
    done <<PLANEOF
$STAGED
PLANEOF
    if [ "$PLAN_STALE" -eq 1 ]; then
      echo "⚠️  workflow: staged changes are newer than your plan ($(basename "$NEWEST_PLAN"))."
      echo "   Update the plan's ## Progress section and the Notion spec — keep it a living tracker."
    fi
  fi
fi
