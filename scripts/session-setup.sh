#!/usr/bin/env bash
#
# session-setup.sh — runs at every SessionStart (via .claude/settings.json hook).
# Ensures resource-saving tools (graphify, RTK) are installed and ready.
# Safe to run repeatedly; fails gracefully if network is unavailable.
#
# Governing policy: core/resource-management.md  (<graphify-pre-code>, <rtk>)
# Hook registration: .claude/settings.json (SessionStart)

set -u

EOS_ROOT="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)"
export ENGINEERING_OS_HOME="$EOS_ROOT"

G=$'\033[32m'; Y=$'\033[33m'; D=$'\033[2m'; Z=$'\033[0m'
ok()   { printf '%s✅%s %s\n' "$G" "$Z" "$1"; }
warn() { printf '%s⚠️ %s%s\n' "$Y" "$Z" "$1"; }
info() { printf '%s[session]%s %s\n' "$D" "$Z" "$1"; }

# ── 1. HTTPS override (no SSH agent in web sessions) ─────────────────────────
git config --global url."https://github.com/".insteadOf "git@github.com:" 2>/dev/null || true

# ── 2. Nemotron (Nvidia) — MUST run before graphify so OPENAI_* vars are set ─
# graphify reads OPENAI_API_KEY + OPENAI_BASE_URL for community naming.
# Without this block running first, graphify finds no LLM backend and may
# fall back to ANTHROPIC_API_KEY (present in Claude Code env) — which is
# explicitly forbidden. Use --no-label instead when Nemotron key is absent.
# Governing policy: external-skills/nemotron/activation.md
if [ -n "${Nemotron_api_key:-}" ]; then
  export OPENAI_API_KEY="${Nemotron_api_key}"
  export OPENAI_BASE_URL="https://integrate.api.nvidia.com/v1"
  export OPENAI_MODEL="nvidia/nemotron-super-49b-v1"
  ok "Nemotron API configured — graphify will use Nvidia backend"
else
  warn "Nemotron_api_key not set — graphify will use local extraction only (no LLM naming)"
fi

# ── 3. graphify ──────────────────────────────────────────────────────────────
if ! command -v graphify >/dev/null 2>&1; then
  info "graphify not found — installing..."
  if command -v uv >/dev/null 2>&1; then
    uv tool install graphifyy --quiet 2>&1 | tail -1 && ok "graphify installed" || warn "graphify install failed"
  elif command -v pip3 >/dev/null 2>&1; then
    pip3 install graphifyy --quiet 2>&1 | tail -1 && ok "graphify installed (pip)" || warn "graphify install failed"
  else
    warn "graphify unavailable: no uv or pip3 found"
  fi
fi

if command -v graphify >/dev/null 2>&1; then
  GRAPH="$EOS_ROOT/graphify-out/graph.json"
  if [ ! -f "$GRAPH" ]; then
    info "building knowledge graph..."
    if [ -n "${Nemotron_api_key:-}" ]; then
      ( cd "$EOS_ROOT" && graphify extract . --backend=openai 2>&1 | tail -2 ) \
        && ok "graphify graph built (Nvidia backend)" \
        || warn "graphify extract failed (see error above)"
    else
      ( cd "$EOS_ROOT" && graphify extract . 2>&1 | tail -2 ) \
        && ok "graphify graph built" \
        || warn "graphify extract failed (see error above)"
    fi
  else
    NODES=$(python3 -c "import json; g=json.load(open('$GRAPH')); print(len(g.get('nodes',[])))" 2>/dev/null || echo "?")
    ok "graphify ready — $NODES nodes in graph"
  fi

  # Generate GRAPH_REPORT.md and wiki/ for broad navigation (referenced in CLAUDE.md)
  if [ ! -f "$EOS_ROOT/graphify-out/GRAPH_REPORT.md" ]; then
    info "generating GRAPH_REPORT.md and wiki/..."
    if [ -n "${Nemotron_api_key:-}" ]; then
      ( cd "$EOS_ROOT" && graphify cluster-only . --backend=openai 2>&1 | tail -2 ) \
        && ok "GRAPH_REPORT.md and wiki/ generated (Nvidia backend)" \
        || warn "graphify cluster-only failed"
    else
      # --no-label prevents graphify auto-detecting ANTHROPIC_API_KEY in Claude Code env
      ( cd "$EOS_ROOT" && graphify cluster-only . --no-label 2>&1 | tail -2 ) \
        && ok "GRAPH_REPORT.md and wiki/ generated (local, no LLM naming)" \
        || warn "graphify cluster-only failed"
    fi
  fi
fi

# ── 4. RTK ───────────────────────────────────────────────────────────────────
if ! command -v rtk >/dev/null 2>&1; then
  info "RTK not found — installing..."
  if command -v cargo >/dev/null 2>&1; then
    cargo install --git https://github.com/rtk-ai/rtk --quiet 2>&1 | tail -1 \
      && ok "RTK installed" \
      || warn "RTK install failed (network/cargo issue)"
  else
    warn "RTK unavailable: cargo not found (install via: brew install rtk)"
  fi
fi

if command -v rtk >/dev/null 2>&1; then
  ok "RTK $(rtk --version 2>/dev/null | head -1) ready (60-90% Bash token savings)"
fi

# ── 5. claude-mem (best-effort, non-fatal) ────────────────────────────────────
if command -v claude-mem >/dev/null 2>&1; then
  claude-mem start >/dev/null 2>&1 &
  CLAUDEMEM_PID=$!
  disown 2>/dev/null || true
  sleep 1
  if kill -0 "$CLAUDEMEM_PID" 2>/dev/null; then
    ok "claude-mem worker started (cross-session memory)"
  else
    info "claude-mem start attempted — worker may not persist in remote sessions (known limitation)"
  fi
else
  info "claude-mem not installed — /plugin marketplace add thedotmack/claude-mem"
fi

# ── 6. Nvidia Nemotron smoke test ────────────────────────────────────────────
bash "${EOS_ROOT}/scripts/test-nvidia-capabilities.sh" 2>/dev/null || true

# ── 7. project_context check ─────────────────────────────────────────────────
if [ -f "CLAUDE.md" ] && grep -qE "מטרת הפרויקט במשפט|Goal: <|<project goal>|PURPOSE: TBD" CLAUDE.md 2>/dev/null; then
  warn "CLAUDE.md <project_context> is a template — FILL IT before starting work!"
fi

# ── 8. learning_loop check ───────────────────────────────────────────────────
RECENT_FIXES=$(git log --oneline -10 2>/dev/null | grep -c " fix:" || echo 0)
LESSON_ADDS=$(git log --oneline -10 --diff-filter=A -- 'lessons-learned/**' 2>/dev/null | wc -l | tr -d ' ')
if [ "${RECENT_FIXES:-0}" -gt 0 ] && [ "${LESSON_ADDS:-0}" -eq 0 ]; then
  warn "${RECENT_FIXES} fix: commit(s) in last 10, 0 lessons-learned entries — learning_loop? (core/learning-loop.md)"
fi

# ── 9. L2 Mandatory Skills + active blockers status ──────────────────────────
printf '\n%s📋 L2 MANDATORY (physical blockers active):%s\n' "$Y" "$Z"
printf '  ✋ Write/Edit → code blocked without .claude/plans/*.md (validate-workflow-state.sh)\n'
printf '  ✋ Agent → blocked without .claude/tasks.json (PreToolUse hook, exit 1)\n'
printf '  ✋ pre-commit → blocked if >2 code files staged + 0 test files in project\n'
printf '  ✋ commit-msg → blocked if missing ✅❌🔄🧪 sections\n'
printf '  ⚡ Context7 STRONGLY recommended before every npm/pip install\n'
# superpowers: check if plugin is installed, otherwise point to slash commands
if command -v claude >/dev/null 2>&1 && claude plugin list 2>/dev/null | grep -q superpowers; then
  printf '  ⚡ superpowers plugin active ✅ — Skill("superpowers:brainstorming") available\n'
else
  printf '  ⚡ superpowers plugin NOT installed — use portable slash commands:\n'
  printf '       /superpowers-brainstorm  (L2 mandatory: before features)\n'
  printf '       /superpowers-verify      (L2 mandatory: before done)\n'
  printf '       /superpowers-plan        (recommended: before non-trivial code)\n'
fi

# Show existing plan files with timestamps (zombie plan awareness)
EXISTING_PLANS=$(ls -lt .claude/plans/*.md 2>/dev/null | head -5)
if [ -n "$EXISTING_PLANS" ]; then
  printf '\n%s📋 Existing plans (check if current for this task!):%s\n' "$Y" "$Z"
  echo "$EXISTING_PLANS" | awk '{print "  " $NF, $6, $7, $8}'
fi

# ── Done ─────────────────────────────────────────────────────────────────────
printf '\n'
info "session setup complete."
