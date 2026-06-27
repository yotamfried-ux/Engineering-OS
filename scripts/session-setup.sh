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

# Reset the per-session evidence ledger (read by scripts/enforcement/*).
# Ledger is project-cwd relative (.claude/.evidence/ledger); see lib/evidence.sh.
. "$EOS_ROOT/scripts/enforcement/lib/evidence.sh" 2>/dev/null && evidence_reset 2>/dev/null || true

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
# Governing policy: external-systems/nvidia-nemotron/activation.md
if [ -n "${Nemotron_api_key:-}" ]; then
  export OPENAI_API_KEY="${Nemotron_api_key}"
  export OPENAI_BASE_URL="https://integrate.api.nvidia.com/v1"
  export OPENAI_MODEL="nvidia/nemotron-super-49b-v1"
  ok "Nemotron API configured — graphify will use Nvidia backend"
else
  warn "Nemotron_api_key not set — graphify will run without LLM naming (--no-label) to prevent ANTHROPIC_API_KEY fallback"
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
      ( cd "$EOS_ROOT" && graphify extract . --no-label 2>&1 | tail -2 ) \
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

  # Report doc files excluded when no LLM backend is available
  if [ -z "${Nemotron_api_key:-}" ]; then
    DOC_COUNT=$(find "$EOS_ROOT" -name "*.md" \
      -not -path "*/.git/*" -not -path "*/graphify-out/*" \
      2>/dev/null | wc -l | xargs)
    info "graphify: ${DOC_COUNT} .md docs NOT in graph — add Nemotron_api_key to include them"
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
  # Register global hook if not already present; rtk may have been just installed
  # so explicitly include cargo bin dir in PATH before checking/running rtk init -g.
  export PATH="${HOME}/.cargo/bin:${PATH}"
  if ! grep -q '"rtk hook"' "$HOME/.claude/settings.json" 2>/dev/null; then
    rtk init -g >/dev/null 2>&1 \
      && info "RTK global hook registered in ~/.claude/settings.json" \
      || warn "rtk init -g failed — run manually: rtk init -g"
  fi
  ok "RTK $(rtk --version 2>/dev/null | head -1) ready (60-90% Bash token savings)"
fi

# ── 5. claude-mem (best-effort, non-fatal) ────────────────────────────────────
if command -v claude-mem >/dev/null 2>&1; then
  if curl -sf http://localhost:37777/health >/dev/null 2>&1; then
    ok "claude-mem worker already running"
  else
    # nohup + stdin redirect avoids TTY requirement in hook (non-interactive) context.
    nohup claude-mem start </dev/null >/dev/null 2>&1 &
    disown 2>/dev/null || true
    # Polling: up to 5 attempts × 1s to let the worker bind to :37777.
    _CM_UP=0
    for _i in 1 2 3 4 5; do
      sleep 1
      if curl -sf http://localhost:37777/health >/dev/null 2>&1; then
        _CM_UP=1; break
      fi
    done
    if [ "$_CM_UP" -eq 1 ]; then
      ok "claude-mem worker started (cross-session memory)"
    else
      info "claude-mem start attempted — worker did not respond on :37777 (may need manual start)"
    fi
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
# grep -c prints "0" AND exits 1 on no match; `|| echo 0` would append a 2nd "0"
# (yielding "0\n0" → "integer expression expected" at the test below). Handle the
# exit code via assignment instead, keeping the value a single line.
RECENT_FIXES=$(git log --oneline -10 2>/dev/null | grep -c " fix:") || RECENT_FIXES=0
LESSON_ADDS=$(git log --oneline -10 --diff-filter=A -- 'lessons-learned/**' 2>/dev/null | wc -l | xargs)
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

# ── 10. Installation readiness report — defines "done", no manual actions needed ──
printf '\n%s🔍 Installation Status:%s\n' "$G" "$Z"
_FAIL=0

if command -v graphify >/dev/null 2>&1 && [ -f "$EOS_ROOT/graphify-out/graph.json" ]; then
  if _N=$(GRAPH_JSON="$EOS_ROOT/graphify-out/graph.json" python3 - <<'PY' 2>/dev/null
import json, os
with open(os.environ["GRAPH_JSON"], "r", encoding="utf-8") as f:
    g = json.load(f)
print(len(g.get("nodes", [])))
PY
  ); then
    printf '  ✅ graphify: %s nodes in graph\n' "$_N"
  else
    printf '  ❌ graphify: graph.json unreadable/invalid\n'; _FAIL=$((_FAIL+1))
  fi
else
  printf '  ❌ graphify: graph.json missing\n'; _FAIL=$((_FAIL+1))
fi

if command -v rtk >/dev/null 2>&1; then
  _GLOBAL=$(grep -q '"rtk hook"' "$HOME/.claude/settings.json" 2>/dev/null && echo "1" || echo "0")
  _PROJECT=$(grep -q '"rtk hook"' ".claude/settings.json" 2>/dev/null && echo "1" || echo "0")
  if [ "$_GLOBAL" = "1" ] && [ "$_PROJECT" = "1" ]; then
    _RTK_SCOPE="global+project"
  elif [ "$_GLOBAL" = "1" ]; then
    _RTK_SCOPE="global-only"
  else
    _RTK_SCOPE="project-only"
  fi
  printf '  ✅ RTK: %s (%s hook)\n' "$(rtk --version 2>/dev/null | head -1)" "$_RTK_SCOPE"
else
  printf '  ❌ RTK: not installed\n'; _FAIL=$((_FAIL+1))
fi

if curl -sf http://localhost:37777/health >/dev/null 2>&1; then
  printf '  ✅ claude-mem: worker running on :37777\n'
elif command -v claude-mem >/dev/null 2>&1; then
  printf '  ⚠️  claude-mem: installed but worker not responding on :37777\n'; _FAIL=$((_FAIL+1))
else
  printf '  ➖ claude-mem: not installed\n'
fi

if [ -n "${Nemotron_api_key:-}" ]; then
  printf '  ✅ Nemotron: API key set — graphify includes code + docs\n'
else
  printf '  ⚠️  Nemotron: no API key — graphify code-only (docs excluded)\n'
fi

if [ "$_FAIL" -eq 0 ]; then
  printf '\n%s✅ All tools ready — no manual actions needed%s\n' "$G" "$Z"
else
  printf '\n%s⚠️  %s item(s) need attention (see above)%s\n' "$Y" "$_FAIL" "$Z"
fi

# ── 11. Plan continuity check (G2: plans don't survive compaction) ───────────
_check_plan_continuity() {
  local plan_dir=".claude/plans"
  local max_age_h="${EOS_PLAN_MAX_AGE_H:-48}"

  if [ ! -d "$plan_dir" ] || [ -z "$(ls "$plan_dir"/*.md 2>/dev/null)" ]; then
    printf '\n%s⚠️  [Engineering OS] No plan file in .claude/plans/%s\n' "$Y" "$Z"
    printf '   If continuing work from a previous session, create a plan before writing code:\n'
    printf '   .claude/plans/<task>.md with Goal/Plan/DoD/Alternatives\n\n'
    return
  fi

  local newest; newest="$(ls -t "$plan_dir"/*.md 2>/dev/null | head -1)"
  local now mtime age_h
  now="$(date +%s 2>/dev/null || echo 0)"
  mtime="$(stat -c %Y "$newest" 2>/dev/null || stat -f %m "$newest" 2>/dev/null || echo 0)"
  age_h=$(( (now - mtime) / 3600 ))

  if [ "$age_h" -ge "$max_age_h" ]; then
    printf '\n%s⚠️  [Engineering OS] Stale plan: %s (age: %dh > %dh)%s\n' \
      "$Y" "$(basename "$newest")" "$age_h" "$max_age_h" "$Z"
    printf '   Create/refresh a plan before writing code (EOS_PLAN_MAX_AGE_H=0 to disable).\n\n'
  fi
}
_check_plan_continuity

# ── Compaction gap detection ──────────────────────────────────────────────────
# Warn when on a feature branch with commits but no plan files — plans are not
# stored in git and are lost when a remote container is replaced after compaction.
_current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
_plan_count=$(ls .claude/plans/*.md 2>/dev/null | wc -l | xargs)
_commits_ahead=$(git rev-list --count "$(git merge-base HEAD origin/main 2>/dev/null || echo HEAD)"..HEAD 2>/dev/null || echo 0)

if [ "$_current_branch" != "main" ] && [ "$_current_branch" != "unknown" ] \
   && [ "${_plan_count:-0}" -eq 0 ] && [ "${_commits_ahead:-0}" -gt 0 ]; then
  printf '\n'
  warn "COMPACTION GAP: branch '$_current_branch' has $_commits_ahead commit(s) ahead of main"
  warn "  but .claude/plans/ is empty. Plans may have been lost in a context compaction."
  warn "  ACTION: Create .claude/plans/<task>.md before writing any code."
  printf '\n'
fi

# ── Done ─────────────────────────────────────────────────────────────────────
printf '\n'
info "session setup complete."
