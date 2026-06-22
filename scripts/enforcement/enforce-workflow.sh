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
  command -v python3 >/dev/null 2>&1 || { printf 'WARNING_FOR_AGENT: python3 not found — enforce-workflow hook degraded\n' >&2; return; }
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
elif field == 'content':
    print(t.get('content', '') or t.get('new_string', '') or '')
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

# ─────────────────────────────────────────────────────────────────────────────
# G9a — gate_plan_integrity: prevent reducing DoD item count in plan files.
# Fires inside gate_write() when a .claude/plans/*.md file is being written.
# ─────────────────────────────────────────────────────────────────────────────
gate_plan_integrity() {
  local file="$1"
  case "$file" in
    .claude/plans/*.md|*/.claude/plans/*.md) ;;
    *) return 0 ;;
  esac
  bypass_active EOS_BYPASS_DOD && return 0

  local fname; fname="$(basename "$file" .md)"
  local initial; initial="$(evidence_get "dod_initial_${fname}" 2>/dev/null || printf '0')"
  [ "${initial:-0}" -eq 0 ] && return 0  # no snapshot yet — first write is allowed

  local new_content; new_content="$(read_field content)"
  [ -z "$new_content" ] && return 0
  local new_total; new_total="$(printf '%s' "$new_content" | grep -cE '^\- \[(x| )\]' 2>/dev/null || printf '0')"
  if [ "${new_total:-0}" -lt "${initial:-0}" ]; then
    echo "ERROR_FOR_AGENT: DoD integrity gate (G9a) — plan had ${initial} DoD item(s), new version has ${new_total}."
    echo "ACTION: DoD items cannot be removed. Mark them [x] to complete; do not delete them."
    echo "BYPASS: EOS_BYPASS_DOD=1 — only with explicit user authorization in the current conversation."
    exit 1
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# G9b — gate_tasks_completion: all DoD items must be [x] before marking complete.
# Fires inside gate_write() when .claude/tasks.json is being written with status=complete.
# ─────────────────────────────────────────────────────────────────────────────
gate_tasks_completion() {
  local file="$1"
  case "$file" in
    .claude/tasks.json|*/.claude/tasks.json) ;;
    *) return 0 ;;
  esac
  bypass_active EOS_BYPASS_DOD && return 0

  local new_content; new_content="$(read_field content)"
  [ -z "$new_content" ] && return 0
  printf '%s' "$new_content" | grep -q '"complete"' || return 0

  local pf; pf="$(newest_plan)"
  [ -z "$pf" ] && return 0

  local unchecked
  unchecked=$(awk '
    /^#{1,4}[[:space:]].*([Dd]o[Dd]|תנאי.סיום)/ { found=1; next }
    found && /^#{1,4}[[:space:]]/ && !/([Dd]o[Dd]|תנאי.סיום)/ { found=0 }
    found && /^\- \[ \]/ { count++ }
    END { print count+0 }
  ' "$pf" 2>/dev/null || printf '0')

  if [ "${unchecked:-0}" -gt 0 ]; then
    echo "ERROR_FOR_AGENT: DoD completion gate (G9b) — plan '$(basename "$pf")' has ${unchecked} unchecked DoD item(s)."
    echo "ACTION: complete all '- [ ]' items in the DoD section before marking task complete."
    echo "BYPASS: EOS_BYPASS_DOD=1 — only with explicit user authorization in the current conversation."
    exit 1
  fi
}

# ═════════════════════════════════════════════════════════════════════════════
# Gate 1 — Write|Edit: entry gate to writing (workflow.md steps 1 + 4)
# ═════════════════════════════════════════════════════════════════════════════
gate_write() {
  local FILE="$1"
  if [ -z "$FILE" ]; then
    # Empty file_path may mean JSON parse failure — warn but allow (avoid false positives).
    case "$TOOL" in
      Write|Edit|MultiEdit|NotebookEdit)
        echo "WARNING_FOR_AGENT: enforce-workflow could not parse file_path — plan gate skipped. Verify python3 is available and hook stdin is valid JSON."
        ;;
    esac
    exit 0
  fi

  # G9a/G9b: run before any early exits — plan files and tasks.json match *.md/*.json
  # and would otherwise exit 0 before reaching the gates at the bottom of this function.
  gate_plan_integrity "$FILE"
  gate_tasks_completion "$FILE"

  # Critical Engineering OS dirs: block regardless of extension (it IS markdown).
  local crit=0
  case "$FILE" in
    core/*|*/core/*|patterns/*|*/patterns/*|external-skills/*|*/external-skills/*|\
    templates/*|*/templates/*|scripts/*|*/scripts/*|\
    .github/*|*/.github/*|.claude/settings.json|*/.claude/settings.json) crit=1 ;;
  esac

  # GitHub Actions workflows are infrastructure code — require a plan like any code file.
  case "$FILE" in
    .github/workflows/*|*/.github/workflows/*) crit=1 ;;
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
    echo "BYPASS: EOS_BYPASS_WORKFLOW=1 — only with explicit user authorization in the current conversation."
    exit 1
  fi

  local missing; missing="$(plan_missing_sections "$pf")"
  if [ -n "$missing" ]; then
    echo "ERROR_FOR_AGENT: workflow.md gate — newest plan ($(basename "$pf")) is missing sections: ${missing}"
    echo "ACTION: add the missing section(s) documenting workflow.md steps 1-4. Then retry."
    echo "BYPASS: EOS_BYPASS_WORKFLOW=1 — only with explicit user authorization in the current conversation."
    exit 1
  fi

  # Freshness: block code writes if the newest plan is stale (default 48h; 0 disables).
  # Uses stat for mtime — reliable across Linux/macOS, no touch -d portability issues.
  local max_age="${EOS_PLAN_MAX_AGE_H:-48}"
  if ! printf '%s' "$max_age" | grep -qE '^[0-9]+$'; then
    echo "ERROR_FOR_AGENT: invalid EOS_PLAN_MAX_AGE_H='$max_age' (expected a non-negative integer)."
    echo "ACTION: unset EOS_PLAN_MAX_AGE_H or set it to a non-negative integer (0 to disable freshness check)."
    exit 1
  fi
  if [ "${max_age}" != "0" ]; then
    local now mtime age_h
    now="$(date +%s 2>/dev/null || echo 0)"
    mtime="$(stat -c %Y "$pf" 2>/dev/null || stat -f %m "$pf" 2>/dev/null || echo "$now")"
    age_h=$(( (now - mtime) / 3600 ))
    if [ "$age_h" -ge "$max_age" ]; then
      echo "ERROR_FOR_AGENT: workflow.md gate — newest plan ($(basename "$pf")) is ${age_h}h old (limit: ${max_age}h, possible zombie plan)."
      echo "ACTION: create/refresh a plan for the current task, or set EOS_PLAN_MAX_AGE_H=0 to disable freshness."
      echo "BYPASS: EOS_BYPASS_WORKFLOW=1 — only with explicit user authorization in the current conversation."
      exit 1
    fi
  fi

  # G6a: patterns/ writes require reading core/pattern-lifecycle.md this session
  case "$FILE" in
    patterns/*|*/patterns/*)
      evidence_has read_pattern_lifecycle || {
        echo "ERROR_FOR_AGENT: core/pattern-lifecycle.md not read in this session."
        echo "ACTION: read core/pattern-lifecycle.md (<lifecycle> section) before modifying patterns."
        echo "BYPASS: EOS_BYPASS_WORKFLOW=1 — only with explicit user authorization in the current conversation."
        exit 1
      }
      ;;
  esac

  # G6b: hooks/enforcement/.claude/settings writes require reading core/hooks-policy.md
  case "$FILE" in
    scripts/hooks/*|*/scripts/hooks/*|scripts/enforcement/*|*/scripts/enforcement/*|\
    .claude/settings.json|*/.claude/settings.json)
      evidence_has read_hooks_policy || {
        echo "ERROR_FOR_AGENT: core/hooks-policy.md not read in this session."
        echo "ACTION: read core/hooks-policy.md before modifying hooks or enforcement scripts."
        echo "BYPASS: EOS_BYPASS_WORKFLOW=1 — only with explicit user authorization in the current conversation."
        exit 1
      }
      ;;
  esac

  # G7: graphify must have been successfully queried before first code write (when graph exists).
  # Evidence is recorded by PostToolUse Bash hook only for graphify query/explain/path/update
  # with non-trivial output (filters out echo graphify, failed runs, --help flags).
  if [ -f "graphify-out/graph.json" ]; then
    bypass_active EOS_BYPASS_GRAPHIFY || evidence_has graphify_used || {
      echo "ERROR_FOR_AGENT: graphify gate (G7) — graphify-out/graph.json exists but graphify was not queried this session."
      echo "ACTION: run graphify query \"<question>\" (or graphify explain/path) to orient before writing code."
      echo "BYPASS: EOS_BYPASS_GRAPHIFY=1 — only with explicit user authorization in the current conversation."
      exit 1
    }
  fi

  # G8: writing to a recognised domain requires reading the matching patterns/<domain>/ first.
  # Independent from G7 — graphify provides structural orientation; patterns provide implementation standards.
  # Evidence 'patterns_searched' is recorded by PostToolUse Read hook when any patterns/** file is read.
  local _domains="auth api billing database frontend security testing ai ai-agents authorization infrastructure integrations ui observability"
  for _dom in $_domains; do
    case "$FILE" in
      *"/${_dom}/"*|*"/${_dom}."*|*"_${_dom}."*|*"${_dom}_"*)
        if [ -d "patterns/${_dom}" ]; then
          bypass_active EOS_BYPASS_PATTERNS || evidence_has patterns_searched || {
            echo "ERROR_FOR_AGENT: patterns gate (G8) — writing to '${_dom}' domain but no patterns/${_dom}/ file was read this session."
            echo "ACTION: read at least one file from patterns/${_dom}/ before writing ${_dom} code."
            echo "BYPASS: EOS_BYPASS_PATTERNS=1 — only with explicit user authorization in the current conversation."
            exit 1
          }
        fi
        break ;;
    esac
  done

  exit 0
}

# ═════════════════════════════════════════════════════════════════════════════
# Gate 2 — Bash: Context7 before installing a package (workflow.md step 2)
# ═════════════════════════════════════════════════════════════════════════════
gate_bash() {
  local CMD="$1"
  [ -z "$CMD" ] && exit 0

  # G3: block if command sets a bypass var — Claude cannot self-disable enforcement.
  # Matches only at command-start positions: ^ | after ; | & | ( or after `export`.
  # Does NOT match when EOS_BYPASS_X= appears as an argument (e.g. echo EOS_BYPASS_X=1).
  if printf '%s' "$CMD" | grep -qE '(^[[:space:]]*(export[[:space:]]+)?|[;|&(][[:space:]]*(export[[:space:]]+)?)EOS_BYPASS_[A-Z_]+='; then
    echo "ERROR_FOR_AGENT: this command sets an EOS_BYPASS_* variable — Claude cannot self-disable enforcement."
    echo "Only the human user may set bypass vars outside the Claude Code session."
    echo "If there is a genuine reason to bypass, inform the user and ask them to set the variable."
    exit 1
  fi

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
  echo "BYPASS: EOS_BYPASS_CONTEXT7=1 — only with explicit user authorization in the current conversation."
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
    echo "BYPASS: EOS_BYPASS_WORKFLOW=1 or EOS_BYPASS_TASKSJSON=1 — only with explicit user authorization in the current conversation."
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
    for i, t in enumerate(tasks):
        if not isinstance(t, dict):
            print(f'FAIL: task at index {i} must be an object, got {type(t).__name__}')
            sys.exit(0)
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
    echo "BYPASS: EOS_BYPASS_WORKFLOW=1 or EOS_BYPASS_TASKSJSON=1 — only with explicit user authorization in the current conversation."
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
