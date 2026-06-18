#!/usr/bin/env bash
# install-self-hooks.sh — installs Engineering OS git hooks into THIS repo's .git/hooks/
# use-in-project.sh refuses to run inside Engineering-OS itself; this script is the fix.
# Usage: bash scripts/install-self-hooks.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SRC="$SCRIPT_DIR/hooks"
HOOK_DST="$(git rev-parse --git-dir)/hooks"

if [ ! -d "$HOOK_SRC" ]; then
  echo "❌ hooks source not found: $HOOK_SRC"
  exit 1
fi

for hook in pre-commit commit-msg post-commit; do
  src="$HOOK_SRC/$hook.sh"
  dst="$HOOK_DST/$hook"
  if [ -f "$src" ]; then
    cp "$src" "$dst"
    chmod +x "$dst"
    echo "✅ installed $hook"
  else
    echo "⚠️  $hook.sh not found in $HOOK_SRC — skipping"
  fi
done

echo "✅ Engineering OS self-hooks installed in $HOOK_DST"
echo "   Verify: ls -la $HOOK_DST | grep -v sample"
