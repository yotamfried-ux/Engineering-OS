#!/bin/bash
# Engineering OS — portable pre-commit hook
# Drop into <project>/.git/hooks/pre-commit and chmod +x
# Blocks commits if linter, tests, or physical test-file scan fails.
# Install: cp scripts/hooks/pre-commit.sh .git/hooks/pre-commit && chmod +x

set -eo pipefail

STAGED=$(git diff --cached --name-only)

# Resolve the Engineering OS reference. Inside the Engineering OS repo this is the
# repo root. Inside a target project installed with use-in-project.sh, the shared
# read-only reference path is stored in .engineering-os/REFERENCE.md.
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
EOS_HOME="${ENGINEERING_OS_HOME:-}"
if [ -z "$EOS_HOME" ] && [ -f "$REPO_ROOT/.engineering-os/REFERENCE.md" ]; then
  EOS_HOME="$(sed -n 's/^- Reference location: `\(.*\)`/\1/p' "$REPO_ROOT/.engineering-os/REFERENCE.md" | head -1)"
fi
EOS_HOME="${EOS_HOME:-$REPO_ROOT}"

IS_EOS_REPO=0
if [ "$(cd "$REPO_ROOT" 2>/dev/null && pwd || true)" = "$(cd "$EOS_HOME" 2>/dev/null && pwd || true)" ]; then
  IS_EOS_REPO=1
fi

enforcer() {
  local script="$1"
  [ -f "$EOS_HOME/scripts/enforcement/$script" ] || return 1
  bash "$EOS_HOME/scripts/enforcement/$script"
}

# Engineering OS repo-governance gates. These protect the Engineering OS repo
# itself; target projects should not be blocked by governance manifests for
# Engineering OS policy files.
if [ "$IS_EOS_REPO" -eq 1 ]; then
  # md ↔ enforcer sync — changing a policy md requires updating its enforcer.
  # Governing policy: core/hooks-policy.md <hooks>. Bypass: EOS_BYPASS_MDSYNC=1
  enforcer enforce-sync.sh || [ ! -f "$EOS_HOME/scripts/enforcement/enforce-sync.sh" ] || exit 1

  # skill-orchestration-policy.md — every external-skills/<name>/ needs its 4 contract
  # files + a registry entry. Governing policy: core/skill-orchestration-policy.md. Bypass: EOS_BYPASS_SKILL=1.
  enforcer enforce-skill.sh || [ ! -f "$EOS_HOME/scripts/enforcement/enforce-skill.sh" ] || exit 1

  # documentation-policy.md — content dirs + root need README; no TBD placeholders in
  # staged docs. Governing policy: core/documentation-policy.md. Bypass: EOS_BYPASS_DOC=1.
  enforcer enforce-documentation.sh || [ ! -f "$EOS_HOME/scripts/enforcement/enforce-documentation.sh" ] || exit 1
fi

# Portable target-project gates.
# quality-gates.md <cleanup> — block debug leftovers (debugger/pdb/pry, conflict markers)
# in the staged diff. Governing policy: core/quality-gates.md. Bypass: EOS_BYPASS_CLEANUP=1.
enforcer enforce-quality.sh || [ ! -f "$EOS_HOME/scripts/enforcement/enforce-quality.sh" ] || exit 1

# resource-management.md <claudeignore> — every project must have a .claudeignore.
# Governing policy: core/resource-management.md. Bypass: EOS_BYPASS_CLAUDEIGNORE=1.
if [ -f "$EOS_HOME/scripts/enforcement/enforce-resource.sh" ]; then
  bash "$EOS_HOME/scripts/enforcement/enforce-resource.sh" precommit || exit 1
fi

# connector-policy.md <environment> — block staged .env files and hardcoded secrets.
# Governing policy: core/connector-policy.md. Bypass: EOS_BYPASS_CONNECTOR=1.
enforcer enforce-connector.sh || [ ! -f "$EOS_HOME/scripts/enforcement/enforce-connector.sh" ] || exit 1

# learning-loop.md — enforce the fixed lesson schema on staged lessons-learned/bugs
# and failed-solutions files. Governing policy: core/learning-loop.md. Bypass: EOS_BYPASS_LEARNING=1.
enforcer enforce-learning.sh || [ ! -f "$EOS_HOME/scripts/enforcement/enforce-learning.sh" ] || exit 1

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
enforcer enforce-tests.sh || [ ! -f "$EOS_HOME/scripts/enforcement/enforce-tests.sh" ] || exit 1

# ── G10: DoD completion gate ──────────────────────────────────────────────────
# Blocks commit when code is staged and the newest plan has unchecked DoD items.
# Governing policy: core/quality-gates.md › <definition_of_done>. Bypass: EOS_BYPASS_DOD=1.
REPO_ROOT_G10="$REPO_ROOT"
EOS_LIB_G10="$EOS_HOME/scripts/enforcement/lib/evidence.sh"
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
