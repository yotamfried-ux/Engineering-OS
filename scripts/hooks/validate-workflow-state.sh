#!/usr/bin/env bash
# validate-workflow-state.sh — blocks code writing before a plan file exists
# Called from PreToolUse Write|Edit hook in .claude/settings.json
# Governing policy: core/workflow.md <workflow> steps 1-4

FILE=$(python3 -c "
import json, sys
try:
  d = json.load(sys.stdin)
  t = d.get('tool_input', d)
  print(t.get('file_path', ''))
except:
  print('')
" 2>/dev/null || echo "")

# Skip empty path
[ -z "$FILE" ] && exit 0

# Engineering OS critical paths — block writes WITHOUT a plan regardless of file extension.
# Rationale: Engineering OS IS markdown; the extension-based skip would bypass enforcement.
CRITICAL_DIRS=("core/" "patterns/" "external-skills/" "templates/" "scripts/hooks/")
IN_CRITICAL_DIR=0
MATCHED_DIR=""
for dir in "${CRITICAL_DIRS[@]}"; do
  if [[ "$FILE" == *"$dir"* ]]; then
    IN_CRITICAL_DIR=1
    MATCHED_DIR="$dir"
    break
  fi
done

if [ "$IN_CRITICAL_DIR" -eq 1 ]; then
  PLAN_COUNT=$(ls .claude/plans/*.md 2>/dev/null | wc -l | tr -d ' ')
  if [ "${PLAN_COUNT:-0}" -eq 0 ]; then
    echo "❌ WORKFLOW BLOCKED: Writing to '$MATCHED_DIR' requires a plan in .claude/plans/*.md"
    echo "   Create .claude/plans/<task-name>.md (see core/workflow.md steps 1-4)"
    exit 1
  fi
  # L2 mandatory: plan must document brainstorming (alternatives considered)
  PLAN_FILE=$(ls .claude/plans/*.md 2>/dev/null | head -1)
  if [ -n "$PLAN_FILE" ] && ! grep -qi "brainstorm\|חלופות\|alternatives\|Brainstorming" "$PLAN_FILE"; then
    echo "❌ WORKFLOW BLOCKED: Plan file is missing a Brainstorm/Alternatives section (L2 mandatory)"
    echo "   Add '## Brainstorming' or '## חלופות שנשקלו' to: $PLAN_FILE"
    echo "   See: core/skill-orchestration-policy.md <execution_levels>"
    exit 1
  fi
  exit 0
fi

# Skip non-code files — plans, config, docs, locks
case "$FILE" in
  *.md|*.json|*.yaml|*.yml|*.toml|*.lock|*.env*|*.gitignore|*.editorconfig|*.prettierrc|*.eslintrc) exit 0 ;;
  *tasks.json*|*session-state*|*CLAUDE.md*|*SETUP*|*REFERENCE*|*.claudeignore*) exit 0 ;;
esac

# Only enforce for code files (not config/markup)
echo "$FILE" | grep -qE '\.(ts|tsx|js|jsx|py|go|rs|java|swift|kt|rb|cs|cpp|c|h|php|scala|lua)$' || exit 0

# Check: any plan file must exist before writing code
PLAN_COUNT=$(ls .claude/plans/*.md 2>/dev/null | wc -l | tr -d ' ')

if [ "${PLAN_COUNT:-0}" -eq 0 ]; then
  echo "❌ WORKFLOW BLOCKED: Cannot write code before creating a plan."
  echo "   Create .claude/plans/<task-name>.md with goal + DoD first."
  echo "   Then run: /plan (plan mode) or write the plan manually."
  echo "   See: core/workflow.md <workflow> steps 1-4"
  exit 1
fi

# Warn (not block) if ALL plan files are >48h old — zombie plan detection
# Create a temporary marker representing "48 hours ago"
MARKER=$(mktemp /tmp/.plan_age_check_XXXXX)
touch -d "48 hours ago" "$MARKER" 2>/dev/null || touch -t "$(date -d '48 hours ago' '+%Y%m%d%H%M' 2>/dev/null || date -v-48H '+%Y%m%d%H%M' 2>/dev/null || echo '202001010000')" "$MARKER" 2>/dev/null || true

if [ -f "$MARKER" ]; then
  FRESH_PLANS=$(find .claude/plans/ -name "*.md" -newer "$MARKER" 2>/dev/null | wc -l | tr -d ' ')
  rm -f "$MARKER"

  if [ "${FRESH_PLANS:-0}" -eq 0 ] && [ "${PLAN_COUNT:-0}" -gt 0 ]; then
    echo "⚠️ WORKFLOW WARNING: All plan files are >48h old — possible zombie plan."
    PLAN_LIST=$(ls .claude/plans/*.md 2>/dev/null | xargs -I{} basename {} 2>/dev/null | tr '\n' ' ')
    echo "   Existing plans: $PLAN_LIST"
    echo "   If starting a NEW task, create .claude/plans/<new-task>.md first."
    # Not exit 1 — multi-day tasks are valid; this is awareness only
  fi
fi

exit 0
