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
CRITICAL_DIRS=("core" "patterns" "external-skills" "templates" "scripts/hooks")
IN_CRITICAL_DIR=0
MATCHED_DIR=""
for dir in "${CRITICAL_DIRS[@]}"; do
  # Path-aware match: only match as a real directory component, not substring
  if [[ "$FILE" == "$dir/"* ]] || [[ "$FILE" == *"/$dir/"* ]]; then
    IN_CRITICAL_DIR=1
    MATCHED_DIR="$dir/"
    break
  fi
done

if [ "$IN_CRITICAL_DIR" -eq 1 ]; then
  PLAN_COUNT=$(ls .claude/plans/*.md 2>/dev/null | wc -l | xargs)
  if [ "${PLAN_COUNT:-0}" -eq 0 ]; then
    echo "ERROR_FOR_AGENT: Workflow gate blocked — writing to '${MATCHED_DIR}' requires an approved plan."
    echo "ACTION REQUIRED: (1) Run /superpowers-brainstorm to create .claude/plans/<task>.md"
    echo "  (2) Include a '## Brainstorming' section in the plan. (3) Retry the write operation."
    echo "  Reference: core/workflow.md steps 1-4"
    exit 1
  fi
  # L2 mandatory: at least ONE plan must document brainstorming (alternatives considered)
  BRAINSTORM_FOUND=0
  for pf in .claude/plans/*.md; do
    [ -f "$pf" ] || continue
    grep -qi "brainstorm\|חלופות\|alternatives\|Brainstorming" "$pf" && BRAINSTORM_FOUND=1 && break
  done
  if [ "$BRAINSTORM_FOUND" -eq 0 ]; then
    echo "ERROR_FOR_AGENT: Workflow gate blocked — plan file exists but missing Brainstorming section."
    echo "ACTION REQUIRED: Open your plan in .claude/plans/ and add a '## Brainstorming' section"
    echo "  documenting at least 2 alternatives considered. Then retry the write operation."
    echo "  Reference: core/skill-orchestration-policy.md <execution_levels>"
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
echo "$FILE" | grep -qE '\.(ts|tsx|js|jsx|py|go|rs|java|swift|kt|rb|cs|cpp|c|h|php|scala|lua|sh|bash|zsh)$' || exit 0

# Check: any plan file must exist before writing code
PLAN_COUNT=$(ls .claude/plans/*.md 2>/dev/null | wc -l | xargs)

if [ "${PLAN_COUNT:-0}" -eq 0 ]; then
  echo "ERROR_FOR_AGENT: Workflow gate blocked — no plan file exists for this coding task."
  echo "ACTION REQUIRED: (1) Run /superpowers-brainstorm to generate a plan."
  echo "  (2) Save to .claude/plans/<task-name>.md with goal, steps, and DoD."
  echo "  (3) Retry the write. Reference: core/workflow.md <workflow> steps 1-4"
  exit 1
fi

# Warn (not block) if ALL plan files are >48h old — zombie plan detection
# Create a temporary marker representing "48 hours ago"
MARKER=$(mktemp /tmp/.plan_age_check_XXXXX)
touch -d "48 hours ago" "$MARKER" 2>/dev/null || touch -t "$(date -d '48 hours ago' '+%Y%m%d%H%M' 2>/dev/null || date -v-48H '+%Y%m%d%H%M' 2>/dev/null || echo '202001010000')" "$MARKER" 2>/dev/null || true

if [ -f "$MARKER" ]; then
  FRESH_PLANS=$(find .claude/plans/ -name "*.md" -newer "$MARKER" 2>/dev/null | wc -l | xargs)
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
