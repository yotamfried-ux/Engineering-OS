#!/bin/bash
# Engineering OS — portable pre-commit hook
# Drop into <project>/.git/hooks/pre-commit and chmod +x
# Blocks commits if linter, tests, or physical test-file scan fails.
# Install: cp scripts/hooks/pre-commit.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

set -eo pipefail

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
if [ -f "$REPO_ROOT/scripts/enforcement/enforce-tests.sh" ]; then
  bash "$REPO_ROOT/scripts/enforcement/enforce-tests.sh" || exit 1
fi

# ── Physical test file enforcement ────────────────────────────────────────────
# Blocks commits when: >2 code files are staged AND the entire project has 0 test files.
# This is a filesystem scan — not a text check of the commit message.
# Note: checks project-wide test existence (not per-change coverage).
#       A project with any test files passes. A project with ZERO tests is blocked on large commits.

STAGED_CODE=$(git diff --cached --name-only 2>/dev/null \
  | grep -E '\.(ts|tsx|js|jsx|py|go|rs)$' \
  | grep -vE '(\.(test|spec)\.(ts|tsx|js|jsx|py)|__tests__|/tests/)' \
  | wc -l | xargs)

if [ "${STAGED_CODE:-0}" -gt 2 ]; then
  # Exempt chore/docs/style/ci/build commits
  COMMIT_TYPE=$(git log --format=%s -1 HEAD 2>/dev/null | grep -oE '^[a-z]+' || echo "")
  case "$COMMIT_TYPE" in chore|docs|style|ci|build) exit 0 ;; esac

  PROJECT_TESTS=$(find . \
    \( -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.test.js" -o -name "*.test.jsx" \
       -o -name "*.spec.ts" -o -name "*.spec.js" \
       -o -name "*.test.py" -o -name "*.spec.py" \
       -o -name "*.test.go" \) \
    -not -path "*/node_modules/*" \
    -not -path "*/.git/*" \
    2>/dev/null | wc -l | xargs)

  if [ "${PROJECT_TESTS:-0}" -eq 0 ]; then
    echo "❌ COMMIT BLOCKED: $STAGED_CODE code files staged, 0 test files found in project."
    echo "   (This check fires only when the ENTIRE project has no tests — not per-file coverage)"
    echo "   Write at least one test file anywhere in the project, then commit."
    echo "   Exempt commit types: chore, docs, style, ci, build"
    exit 1
  fi
fi

# ── G10: DoD completion gate ──────────────────────────────────────────────────
# Blocks commit when code is staged and the newest plan has unchecked DoD items.
# Governing policy: core/quality-gates.md › <definition_of_done>. Bypass: EOS_BYPASS_DOD=1.
REPO_ROOT_G10="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
EOS_LIB_G10="${ENGINEERING_OS_HOME:-$REPO_ROOT_G10}/scripts/enforcement/lib/evidence.sh"
# shellcheck source=../enforcement/lib/evidence.sh
. "$EOS_LIB_G10" 2>/dev/null || true
if ! bypass_active EOS_BYPASS_DOD 2>/dev/null; then
  G10_PLAN="$(ls -t "$REPO_ROOT_G10/.claude/plans/"*.md 2>/dev/null | head -1 || true)"
  G10_CODE="$(git diff --cached --name-only 2>/dev/null \
    | grep -cE '\.(ts|tsx|js|jsx|py|go|rs|sh)$' 2>/dev/null || echo 0)"
  if [ -n "$G10_PLAN" ] && [ "${G10_CODE:-0}" -gt 0 ]; then
    G10_UNCHECKED="$(awk '
      /^#{1,4}[[:space:]].*([Dd]o[Dd]|תנאי.סיום|Definition.of.Done)/ { found=1; next }
      found && /^#{1,4}[[:space:]]/ && !/([Dd]o[Dd]|תנאי.סיום|Definition.of.Done)/ { found=0 }
      found && /^\- \[ \]/ { count++ }
      END { print count+0 }
    ' "$G10_PLAN" 2>/dev/null || echo 0)"
    if [ "${G10_UNCHECKED:-0}" -gt 0 ]; then
      echo "❌ G10 (DoD gate) — ${G10_UNCHECKED} unchecked DoD item(s) in $(basename "$G10_PLAN")."
      echo "   Complete all '- [ ]' items in the DoD section before committing code."
      echo "   BYPASS: EOS_BYPASS_DOD=1 (explicit user authorization required)"
      exit 1
    fi
  fi
fi

# ── G11: Verification gate ─────────────────────────────────────────────────────
# Blocks large commits (>2 code files) when neither /superpowers-verify nor tests ran.
# Governing policy: core/workflow.md step 6. Bypass: EOS_BYPASS_VERIFY=1.
if ! bypass_active EOS_BYPASS_VERIFY 2>/dev/null; then
  G11_CODE="$(git diff --cached --name-only 2>/dev/null \
    | grep -cE '\.(ts|tsx|js|jsx|py|go|rs)$' 2>/dev/null || echo 0)"
  if [ "${G11_CODE:-0}" -gt 2 ]; then
    if ! evidence_has superpowers_verify_run 2>/dev/null && \
       ! evidence_has tests_run 2>/dev/null; then
      echo "❌ G11 (Verification gate) — ${G11_CODE} code files staged but no verification ran this session."
      echo "   Run /superpowers-verify OR ensure tests pass before committing large changes."
      echo "   BYPASS: EOS_BYPASS_VERIFY=1 (explicit user authorization required)"
      exit 1
    fi
  fi
fi