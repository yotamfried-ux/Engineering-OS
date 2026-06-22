#!/usr/bin/env bash
# enforce-workflow.sh — deterministic enforcer for core/workflow.md
#
# One enforcer per md file (Engineering OS convention). This file enforces
# EVERYTHING workflow.md mandates that is deterministically checkable, including
# the tools/skills it references — not split into per-tool enforcers.
#
# Wired from .claude/settings.json PreToolUse under matchers: Write|Edit, Bash, Agent.
# Routes by tool name (read from stdin). Blocks with exit 1. Bypass: EOS_BYPASS_WORKFLOW=1.
#
# Governing policy: core/workflow.md
#   - Step 1+4 (entry gate to writing): plan must exist with goal/plan/DoD/alternatives
#   - Step 2: Context7 before npm/pip install
#   - <agent_loop>: tasks.json before spawning agents

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

# Master bypass — disables the whole workflow enforcer.
bypass_active EOS_BYPASS_WORKFLOW && exit 0

# ── Parse PreToolUse stdin: tool name, file_path, command ────────────────────
INPUT="$(cat 2>/dev/null || true)"
read_field() {
  printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print(''); sys.exit(0)
t = d.get('tool_input', d)
field = '$1'
if field == 'tool':
    print(d.get('tool_name', d.get('tool', '')))
elif field == 'file_path':
    print(t.get('file_path', '') or '')
elif field == 'command':
    print(t.get('command', '') or '')
" 2>/dev/null || printf ''
}

TOOL="$(read_field tool)"

# ─────────────────────────────────────────────────────────────────────────────
# Helper: does the newest plan document workflow steps 1–4?
# ─────────────────────────────────────────────────────────────────────────────
newest_plan() { ls -t .claude/plans/*.md 2>/dev/null | head -1; }

plan_missing_sections() {
  # Echoes a space-separated list of missing section names (empty = all present).
  local pf="$1" missing=""
  grep -qiE 'מטרה|goal|requirements|דרישות' "$pf" || missing="${missing}Goal/מטרה "
  grep -qiE 'תכנון|\bplan\b|steps|שלבים' "$pf"     || missing="${missing}Plan/תכנון "
  grep -qiE 'DoD|Definition of Done|תנאי סיום'  "$pf" || missing="${missing}DoD/תנאי-סיום "
  grep -qiE 'brainstorm|חלופות|alternatives'    "$pf" || missing="${missing}Alternatives/חלופות "
  printf '%s' "$missing"
}

# ═════════════════════════════════════════════════════════════════════════════
# Gate 1 — Write|Edit: entry gate to writing (workflow.md steps 1 + 4)
# ═════════════════════════════════════════════════════════════════════════════
gate_write() {
  local FILE="$1"
  [ -z "$FILE" ] && exit 0

  # Critical Engineering OS dirs: block regardless of extension (it IS markdown).
  local crit=0
  case "$FILE" in
    core/*|*/core/*|patterns/*|*/patterns/*|external-skills/*|*/external-skills/*|templates/*|*/templates/*|scripts/*|*/scripts/*) crit=1 ;;
  esac

  if [ "$crit" -eq 0 ]; then
    # Non-critical paths: only enforce for code files; skip docs/config.
    case "$FILE" in
      *.md|*.json|*.yaml|*.yml|*.toml|*.lock|*.env*|*.gitignore|*.editorconfig|*.prettierrc|*.eslintrc) exit 0 ;;
    esac
    printf '%s' "$FILE" | grep -qE '\.(ts|tsx|js|jsx|py|go|rs|java|swift|kt|rb|cs|cpp|c|h|php|scala|lua|sh|bash|zsh)$' || exit 0
  fi

  local pf; pf="$(newest_plan)"
  if [ -z "$pf" ]; then
    echo "ERROR_FOR_AGENT: workflow.md gate — no plan exists. Writing code requires a plan first."
    echo "ACTION: create .claude/plans/<task>.md with Goal/מטרה, Plan/תכנון, DoD/תנאי-סיום, Alternatives/חלופות (workflow.md steps 1-4)."
    echo "BYPASS: EOS_BYPASS_WORKFLOW=1"
    exit 1
  fi

  local missing; missing="$(plan_missing_sections "$pf")"
  if [ -n "$missing" ]; then
    echo "ERROR_FOR_AGENT: workflow.md gate — newest plan ($(basename "$pf")) is missing sections: ${missing}"
    echo "ACTION: add the missing section(s) documenting workflow.md steps 1-4. Then retry."
    echo "BYPASS: EOS_BYPASS_WORKFLOW=1"
    exit 1
  fi

  # Freshness: block code writes if the newest plan is stale (default 48h; 0 disables).
  local max_age="${EOS_PLAN_MAX_AGE_H:-48}"
  if [ "${max_age}" != "0" ]; then
    local marker; marker="$(mktemp 2>/dev/null)"
    if [ -n "$marker" ]; then
      if touch -d "${max_age} hours ago" "$marker" 2>/dev/null \
         || touch -t "$(date -v-"${max_age}"H '+%Y%m%d%H%M' 2>/dev/null || echo 200001010000)" "$marker" 2>/dev/null; then
        if [ ! "$pf" -nt "$marker" ]; then
          rm -f "$marker"
          echo "ERROR_FOR_AGENT: workflow.md gate — newest plan ($(basename "$pf")) is older than ${max_age}h (possible zombie plan)."
          echo "ACTION: create/refresh a plan for the current task, or set EOS_PLAN_MAX_AGE_H=0 to disable freshness."
          echo "BYPASS: EOS_BYPASS_WORKFLOW=1"
          exit 1
        fi
      fi
      rm -f "$marker"
    fi
  fi
  exit 0
}

# ═════════════════════════════════════════════════════════════════════════════
# Gate 2 — Bash: Context7 before installing a package (workflow.md step 2)
# ═════════════════════════════════════════════════════════════════════════════
gate_bash() {
  local CMD="$1"
  [ -z "$CMD" ] && exit 0
  # Only fire for real package installs (a package name follows the verb).
  case "$CMD" in
    *"npm install "[a-zA-Z@]*|*"npm i "[a-zA-Z@]*|*"yarn add "[a-zA-Z@]*|*"pnpm add "[a-zA-Z@]*|*"pip install "[a-zA-Z]*|*"pip3 install "[a-zA-Z]*|*"uv add "[a-zA-Z]*|*"uv pip install "[a-zA-Z]*) ;;
    *) exit 0 ;;
  esac
  bypass_active EOS_BYPASS_CONTEXT7 && exit 0
  if evidence_has context7; then
    exit 0
  fi
  echo "ERROR_FOR_AGENT: workflow.md step 2 — query Context7 for the library BEFORE installing it (training data may be outdated)."
  echo "ACTION: use the built-in Context7 connector, or mcp__Context7__resolve-library-id → mcp__Context7__query-docs. Then retry the install."
  echo "BYPASS: EOS_BYPASS_CONTEXT7=1 (or EOS_BYPASS_WORKFLOW=1)"
  exit 1
}

# ═════════════════════════════════════════════════════════════════════════════
# Gate 3 — Agent: tasks.json before spawning agents (workflow.md <agent_loop>)
# ═════════════════════════════════════════════════════════════════════════════
gate_agent() {
  bypass_active EOS_BYPASS_TASKSJSON && exit 0

  if [ ! -f .claude/tasks.json ]; then
    echo "ERROR_FOR_AGENT: workflow.md <agent_loop> — .claude/tasks.json must exist before spawning agents."
    echo "ACTION: create .claude/tasks.json with each agent's goal + status fields (see core/resource-management.md)."
    echo "BYPASS: EOS_BYPASS_WORKFLOW=1 or EOS_BYPASS_TASKSJSON=1"
    exit 1
  fi

  # Schema validation: must have a non-empty tasks array; each item needs id, title, status.
  schema_result="$(python3 -c "
import json, sys
try:
    d = json.load(open('.claude/tasks.json'))
    tasks = d.get('tasks', [])
    if not isinstance(tasks, list) or len(tasks) == 0:
        print('FAIL: tasks array is missing or empty')
        sys.exit(0)
    for t in tasks:
        for f in ('id', 'title', 'status'):
            if f not in t:
                print(f'FAIL: task missing field \"{f}\": {t}')
                sys.exit(0)
    print('ok')
except json.JSONDecodeError as e:
    print(f'FAIL: invalid JSON — {e}')
except Exception as e:
    print(f'FAIL: {e}')
" 2>/dev/null || echo 'FAIL: python3 unavailable')"

  if [ "$schema_result" != "ok" ]; then
    echo "ERROR_FOR_AGENT: workflow.md <agent_loop> — .claude/tasks.json schema invalid: ${schema_result}"
    echo "ACTION: tasks.json must contain: {\"tasks\": [{\"id\": \"...\", \"title\": \"...\", \"status\": \"...\"}]}"
    echo "BYPASS: EOS_BYPASS_WORKFLOW=1 or EOS_BYPASS_TASKSJSON=1"
    exit 1
  fi
  exit 0
}

# ── Route by tool ────────────────────────────────────────────────────────────
case "$TOOL" in
  Write|Edit|MultiEdit|NotebookEdit) gate_write "$(read_field file_path)" ;;
  Bash)                              gate_bash "$(read_field command)" ;;
  Agent|Task)                        gate_agent ;;
  *) exit 0 ;;
esac
exit 0
