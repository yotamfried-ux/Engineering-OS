#!/usr/bin/env bash
# validate-orphans.sh — scans Engineering OS for zombie rules and duplicate policies
# Context isolation: only runs when CWD is inside Engineering OS root.
# Usage: bash scripts/validate-orphans.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EOS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CURRENT_DIR="$(pwd)"

# Safety: never scan external project directories
if [[ "$CURRENT_DIR" != "$EOS_ROOT"* ]]; then
  echo "⚠️  validate-orphans: running outside Engineering OS root — skipping scan"
  echo "    (This script only scans $EOS_ROOT)"
  echo "    To scan Engineering OS, cd to $EOS_ROOT first"
  exit 0
fi

echo "🔍 Scanning Engineering OS for orphaned rules and duplicates..."
echo "   Root: $EOS_ROOT"
echo ""

ERRORS=0
WARNINGS=0

# 1. Check CLAUDE.md navigation table entries point to existing files
echo "── Navigation table integrity ──"
while IFS= read -r link; do
  file="${link#./}"
  if [ ! -e "$EOS_ROOT/$file" ]; then
    echo "❌ ORPHAN: CLAUDE.md references missing file: $file"
    ERRORS=$((ERRORS + 1))
  fi
done < <(grep -oE '\./[a-zA-Z0-9_./-]+\.md' "$EOS_ROOT/CLAUDE.md" 2>/dev/null | sort -u)

[ "$ERRORS" -eq 0 ] && echo "✅ All CLAUDE.md file references exist"

# 2. Check core/ files referenced in CLAUDE.md navigation table
echo ""
echo "── core/ file coverage ──"
CORE_IN_NAV=$(grep -oE 'core/[a-zA-Z0-9_-]+\.md' "$EOS_ROOT/CLAUDE.md" 2>/dev/null | sort -u)
for core_file in "$EOS_ROOT"/core/*.md; do
  base="core/$(basename "$core_file")"
  if ! echo "$CORE_IN_NAV" | grep -q "$base"; then
    echo "⚠️  NOT IN NAV TABLE: $base (add to CLAUDE.md navigation table or remove)"
    WARNINGS=$((WARNINGS + 1))
  fi
done
[ "$WARNINGS" -eq 0 ] && echo "✅ All core/ files appear in navigation table"

# 3. Detect duplicate section headers across core/ files
echo ""
echo "── Duplicate section detection ──"
DUPES=$(grep -rh '^## <' "$EOS_ROOT/core/" 2>/dev/null | sort | uniq -d)
if [ -n "$DUPES" ]; then
  echo "⚠️  Duplicate section tags found across core/ files:"
  echo "$DUPES"
  WARNINGS=$((WARNINGS + 1))
else
  echo "✅ No duplicate section tags in core/"
fi

# Summary
echo ""
echo "─────────────────────────────────"
if [ "$ERRORS" -gt 0 ]; then
  echo "❌ $ERRORS error(s) — fix before merge"
  exit 1
elif [ "$WARNINGS" -gt 0 ]; then
  echo "⚠️  $WARNINGS warning(s) — review before merge"
  exit 0
else
  echo "✅ Engineering OS is clean — no orphans or duplicates found"
fi
