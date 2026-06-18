#!/usr/bin/env bash
# setup.sh — one-time bootstrap after git clone of Engineering OS
# Usage: bash scripts/setup.sh
# Usage (check-only, no changes): bash scripts/setup.sh --check
set -euo pipefail

CHECK_ONLY="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EOS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "⚙️  Engineering OS setup — $EOS_ROOT"

ERRORS=0

# 1. Install git hooks
if [ "$CHECK_ONLY" = "--check" ]; then
  HOOK_DST="$(git rev-parse --git-dir)/hooks"
  for hook in pre-commit commit-msg post-commit; do
    if [ -x "$HOOK_DST/$hook" ]; then
      echo "✅ hook installed: $hook"
    else
      echo "❌ hook MISSING: $hook"
      ERRORS=$((ERRORS + 1))
    fi
  done
else
  bash "$SCRIPT_DIR/install-self-hooks.sh"
fi

# 2. Verify project_context is filled
if grep -q 'Goal: <' "$EOS_ROOT/CLAUDE.md" 2>/dev/null; then
  echo "⚠️  CLAUDE.md <project_context> is still a template — fill it before starting work"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ CLAUDE.md project_context is filled"
fi

# 3. Verify CLAUDE.md exists (guard against accidental deletion)
if [ ! -f "$EOS_ROOT/CLAUDE.md" ]; then
  echo "❌ CRITICAL: CLAUDE.md is missing!"
  echo "   Restore with: git checkout \$(git log --all --oneline -- CLAUDE.md | head -1 | cut -d' ' -f1) -- CLAUDE.md"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ CLAUDE.md present ($(wc -l < "$EOS_ROOT/CLAUDE.md") lines)"
fi

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "⚠️  Setup completed with $ERRORS issue(s) — address them before starting work"
  exit 1
fi

echo ""
echo "✅ Setup complete. Engineering OS is ready."
echo "   Run: git log --oneline -5 to verify state."
